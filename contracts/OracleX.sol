// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import {Errors} from "./library/Errors.sol";
import {IOracleX} from "./interface/IOracleX.sol";
import {ProofParseLib} from "./library/ProofParseLib.sol";

contract OracleX is
    IOracleX,
    Initializable,
    UUPSUpgradeable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable
{
    using MessageHashUtils for bytes32;
    using ProofParseLib for bytes;
    using ECDSA for bytes32;

    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");

    bytes32 public constant VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");

    bytes32 public constant FALLBACK_MANAGER_ROLE =
        keccak256("FALLBACK_MANAGER_ROLE");

    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");

    bytes32 public constant VERIFIER_MANAGER_ROLE =
        keccak256("VERIFIER_MANAGER_ROLE");

    mapping(bytes32 => QueryRecord) public queryRecords;

    uint256 private _nonce;

    uint8 private _mutiSigThreshold;

    mapping(bytes32 => bytes) public activeData;

    mapping(uint256 => address) public verifiers;

    receive() external payable {}

    /// ********* interaction start ***********

    function queryPassiveDataStreamFromOracleX(
        QueryPassiveMode calldata dataQuery
    ) external override returns (bytes32 requestId) {
        requestId = keccak256(abi.encode(_nonce, dataQuery));
        queryRecords[requestId] = QueryRecord({
            managerAddress: dataQuery.managerAddress,
            authMode: dataQuery.authMode,
            queryMode: bytes1(uint8(QueryMode.PASSIVE)),
            suspended: false,
            rsv9bytes: bytes9(0)
        });
        emit QueryPassiveModeSubmitted(requestId, _nonce++, dataQuery);
    }

    function queryActiveDataStreamFromOracleX(
        QueryActiveMode calldata dataQuery
    ) external override {
        queryRecords[dataQuery.subId] = QueryRecord({
            managerAddress: dataQuery.managerAddress,
            authMode: dataQuery.authMode,
            queryMode: bytes1(uint8(QueryMode.ACTIVE)),
            suspended: false,
            rsv9bytes: bytes9(0)
        });
        emit QueryActiveModeSubmitted(dataQuery.subId, dataQuery);
    }

    function fetchActiveDataStreamFromOracleX(
        bytes32 subId
    ) external view override returns (bytes memory dataQuery) {
        dataQuery = activeData[subId];
    }

    function dataCommitmentByProof(
        bytes calldata dataCommitmentProof
    ) external override onlyRole(RELAYER_ROLE) nonReentrant {
        ProofParseLib.ProofPublicInput
            memory proofPublicInput = dataCommitmentProof.parseProof();
        bytes1 authMode = bytes1(uint8(AuthMode.PROOF));
        QueryRecord memory dataQueryRecord = proofPublicInput.queryMode ==
            bytes1(uint8(QueryMode.PASSIVE))
            ? queryRecords[proofPublicInput.requestId]
            : queryRecords[proofPublicInput.subId];

        if (dataQueryRecord.authMode > authMode) {
            revert Errors.QueryModeMismatch();
        }

        if (dataQueryRecord.managerAddress == address(0)) {
            revert Errors.CommitmentFailure();
        }

        if (dataQueryRecord.suspended) {
            revert Errors.MissionSuspended();
        }

        delete queryRecords[proofPublicInput.requestId];

        {
            (bool success, ) = _getVerifier(proofPublicInput.taskId).call(
                dataCommitmentProof
            );
            if (!success) {
                revert Errors.ProofVerificationFailure();
            }
        }

        if (proofPublicInput.queryMode == bytes1(uint8(QueryMode.PASSIVE))) {
            (bool success, ) = proofPublicInput.callbackAddress.call{
                gas: proofPublicInput.callbackGasLimit
            }(
                abi.encodeWithSelector(
                    proofPublicInput.callbackSelector,
                    proofPublicInput.requestId,
                    proofPublicInput.data
                )
            );

            if (!success) {
                revert Errors.ProofVerificationFailure();
            }

            emit DataCommitmentExecutedPassive(
                proofPublicInput.requestId,
                proofPublicInput.taskId,
                proofPublicInput.callbackAddress,
                AuthMode.PROOF
            );
        } else if (
            proofPublicInput.queryMode == bytes1(uint8(QueryMode.ACTIVE))
        ) {
            activeData[proofPublicInput.subId] = proofPublicInput.data;
            emit DataCommitmentExecutedActive(
                proofPublicInput.subId,
                AuthMode.PROOF
            );
        } else {
            revert Errors.NotImplement();
        }
    }

    function dataCommitmentBySignatureP(
        bytes4 callbackSelector,
        bytes32 requestId,
        address callbackAddress,
        uint64 callbackGasLimit,
        bytes calldata data,
        bytes[] calldata dataCommitmentSignatures
    ) external override onlyRole(RELAYER_ROLE) nonReentrant {
        AuthMode authMode = dataCommitmentSignatures.length > 0
            ? AuthMode.SIGNATURE
            : AuthMode.MULTISIG;
        QueryRecord memory dataQueryRecord = queryRecords[requestId];

        if (dataQueryRecord.authMode > bytes1(uint8(authMode))) {
            revert Errors.QueryModeMismatch();
        }

        if (dataQueryRecord.managerAddress == address(0)) {
            revert Errors.CommitmentFailure();
        }

        if (dataQueryRecord.suspended) {
            revert Errors.MissionSuspended();
        }

        delete queryRecords[requestId];

        uint8 signerCounts = 0;
        for (uint256 i = 0; i < dataCommitmentSignatures.length; i++) {
            if (
                !_signatureVerify(
                    keccak256(
                        abi.encode(
                            address(this),
                            block.chainid,
                            callbackSelector,
                            requestId,
                            callbackAddress,
                            callbackGasLimit,
                            data
                        )
                    ),
                    dataCommitmentSignatures[i]
                )
            ) {
                revert Errors.SignatureVerificationFailure();
            }
            signerCounts++;
        }

        if (signerCounts == 0) {
            revert Errors.SignatureLengthError();
        } else if (signerCounts > 1) {
            if (signerCounts < _mutiSigThreshold) {
                revert Errors.MutiSignatureNotEnough();
            }
        }

        {
            (bool success, ) = callbackAddress.call{gas: callbackGasLimit}(
                abi.encodeWithSelector(callbackSelector, requestId, data)
            );

            if (!success) {
                revert Errors.ProofVerificationFailure();
            }
        }

        emit DataCommitmentExecutedPassive(
            requestId,
            0,
            callbackAddress,
            authMode
        );
    }

    function dataCommitmentBySignatureA(
        bytes32 subId,
        bytes calldata data,
        bytes[] calldata dataCommitmentSignatures
    ) external override onlyRole(RELAYER_ROLE) nonReentrant {
        AuthMode authMode = dataCommitmentSignatures.length > 0
            ? AuthMode.SIGNATURE
            : AuthMode.MULTISIG;
        QueryRecord memory dataQueryRecord = queryRecords[subId];

        if (dataQueryRecord.authMode > bytes1(uint8(authMode))) {
            revert Errors.QueryModeMismatch();
        }

        if (dataQueryRecord.managerAddress == address(0)) {
            revert Errors.CommitmentFailure();
        }

        uint8 signerCounts = 0;
        for (uint256 i = 0; i < dataCommitmentSignatures.length; i++) {
            if (
                !_signatureVerify(
                    keccak256(
                        abi.encode(address(this), block.chainid, subId, data)
                    ),
                    dataCommitmentSignatures[i]
                )
            ) {
                revert Errors.SignatureVerificationFailure();
            }
            signerCounts++;
        }

        if (signerCounts == 0) {
            revert Errors.SignatureLengthError();
        } else if (signerCounts > 1) {
            if (signerCounts < _mutiSigThreshold) {
                revert Errors.MutiSignatureNotEnough();
            }
        }

        activeData[subId] = data;

        emit DataCommitmentExecutedActive(subId, authMode);
    }

    function dataQueryCancel(bytes32 id) external override {
        if (msg.sender != queryRecords[id].managerAddress) {
            revert Errors.AccessDenied();
        }
        delete queryRecords[id];
        emit DataQueryCancelled(id);
    }

    function dataQuerySuspend(bytes32 id) external override {
        if (msg.sender != queryRecords[id].managerAddress) {
            revert Errors.AccessDenied();
        }
        queryRecords[id].suspended = true;
        emit DataQuerySuspended(id);
    }

    function dataQueryFallback(
        bytes32 id
    ) external override onlyRole(FALLBACK_MANAGER_ROLE) {
        delete queryRecords[id];
        emit DataQueryFallback(id);
    }

    /// ********* interaction end ***********

    /// ********* internal functions start ***********
    function _getVerifier(uint256 taskId) internal view returns (address) {
        address verifier = verifiers[taskId];
        if (verifier == address(0)) {
            revert Errors.InvalidVerifier();
        }
        return verifier;
    }

    function _signatureVerify(
        bytes32 _hash,
        bytes memory _signature
    ) internal view returns (bool) {
        return
            hasRole(
                SIGNER_ROLE,
                _hash.toEthSignedMessageHash().recover(_signature)
            );
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    /// ********* internal functions end ***********

    /// ********* governance start ***********

    function setVerifier(
        uint256 taskId,
        address verifier
    ) external onlyRole(VERIFIER_MANAGER_ROLE) {
        verifiers[taskId] = verifier;
    }

    function transferOwnership(
        address newOwner
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(DEFAULT_ADMIN_ROLE, newOwner);
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// *********** governance end ***********

    /// ********* initialize start ***********
    function initialize(
        address _admin,
        address _fallbackManager,
        address[] memory _relayers,
        address[] memory _validators,
        address[] memory _signers,
        address[] memory _verifierManagers
    ) public initializer {
        _oracleXRolesInit(
            _admin,
            _fallbackManager,
            _relayers,
            _validators,
            _signers,
            _verifierManagers
        );
        __UUPSUpgradeable_init();
    }

    function _oracleXRolesInit(
        address _admin,
        address _fallbackManager,
        address[] memory _relayers,
        address[] memory _validators,
        address[] memory _signers,
        address[] memory _verifierManagers
    ) internal {
        if (_admin == address(0)) {
            revert Errors.InvalidAddress();
        }
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);

        if (_fallbackManager == address(0)) {
            revert Errors.InvalidAddress();
        }
        _grantRole(FALLBACK_MANAGER_ROLE, _fallbackManager);

        for (uint256 i = 0; i < _relayers.length; i++) {
            if (_relayers[i] == address(0)) {
                revert Errors.InvalidAddress();
            }
            _grantRole(RELAYER_ROLE, _relayers[i]);
        }

        for (uint256 i = 0; i < _validators.length; i++) {
            if (_validators[i] == address(0)) {
                revert Errors.InvalidAddress();
            }
            _grantRole(VALIDATOR_ROLE, _validators[i]);
        }

        _setSignerRole(_signers);

        for (uint256 i = 0; i < _verifierManagers.length; i++) {
            if (_verifierManagers[i] == address(0)) {
                revert Errors.InvalidAddress();
            }
            _grantRole(VERIFIER_MANAGER_ROLE, _verifierManagers[i]);
        }
    }

    function _setSignerRole(address[] memory _signers) internal {
        if (_signers.length == 0) {
            revert Errors.InvalidAddress();
        }

        uint8 signerCounts;

        for (uint256 i = 0; i < _signers.length; i++) {
            if (_signers[i] == address(0)) {
                revert Errors.InvalidAddress();
            }
            _grantRole(SIGNER_ROLE, _signers[i]);
            signerCounts++;
        }

        _mutiSigThreshold = (signerCounts + 2) / 3;
    }

    /// ********* initialize end ***********

    /// ********* settings start ***********
    /**
     * @dev **For Upgradeable contracts**
     * The size of the __gap array is calculated so that the amount of storage
     * used by a contract always adds up to the same number (in this case 50 storage slots).
     * See https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#modifying-your-contracts
     */
    uint256[50] private __gap;

    function version() public pure returns (string memory) {
        return "v1.0.0";
    }

    /// ********* settings end ***********
}
