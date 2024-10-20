// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import {Errors} from "./library/Errors.sol";
import {ProofParseLib, ProofStructLib} from "./library/ProofParse.sol";

enum QueryMode {
    SIGNATURE,
    MULTISIG,
    PROOF
}

struct DataQuery {
    bytes32 subId;
    bytes1 queryMode;
    address callbackAddress;
    address managerAddress;
    uint64 callbackGasLimit;
    bytes extraParams;
}

struct DataQueryRecord {
    address managerAddress;  // 20 bytes
    bytes1 queryMode;        // 1 byte
    bytes11 rsv11bytes;      // 11 bytes
}

event DataQueryExecuted(
    bytes32 indexed requestId,
    uint256 indexed nonce,
    DataQuery dataQuery
);

event DataQueryFallback(
    bytes32 indexed requestId
);

event DataQueryCancelled(
    bytes32 indexed requestId
);

event DataCommitmentExecuted(
    bytes32 indexed requestId,
    uint256 indexed taskId,
    address indexed callbackAddress,
    QueryMode queryMode
);

contract OracleXClient is Initializable, UUPSUpgradeable, AccessControlUpgradeable, ReentrancyGuardUpgradeable  {
    using MessageHashUtils for bytes32;
    using ProofParseLib for bytes;
    using ECDSA for bytes32;

    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");

    bytes32 public constant VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");

    bytes32 public constant FALLBACK_MANAGER_ROLE = keccak256("FALLBACK_MANAGER_ROLE");

    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");

    bytes32 public constant VERIFIER_MANAGER_ROLE =
        keccak256("VERIFIER_MANAGER_ROLE");

    mapping(bytes32 => DataQueryRecord) public dataQueries;

    uint256 private _nonce = 0;

    uint8 private _mutiSigThreshold = 0;

    mapping(uint256 => address) public verifiers;

    receive() external payable {}

    /// ********* interaction start ***********

    function dataQuerySubmit(
        DataQuery calldata dataQuery
    ) external  returns (bytes32 requestId) {
        requestId = keccak256(abi.encode(_nonce, dataQuery));
        dataQueries[requestId] = DataQueryRecord({
            managerAddress: dataQuery.managerAddress,
            queryMode: dataQuery.queryMode,
            rsv11bytes: bytes11(0)
        });
        emit DataQueryExecuted(requestId, _nonce++, dataQuery);
    }

    function dataCommitmentByProof(
        bytes calldata dataCommitmentProof
    ) external onlyRole(RELAYER_ROLE) nonReentrant {
        ProofStructLib.ProofPublicInput memory proofPublicInput = dataCommitmentProof.parseProof();
        bytes1 queryMode = bytes1(uint8(QueryMode.PROOF));
        DataQueryRecord memory dataQueryRecord = dataQueries[proofPublicInput.requestId];
        
        if (dataQueryRecord.queryMode > queryMode) {
            revert Errors.QueryModeMismatch();
        }

        if (dataQueryRecord.managerAddress == address(0)) {
            revert Errors.CommitmentFailure();
        }

        delete dataQueries[proofPublicInput.requestId];

        {
            (bool success, ) = _getVerifier(proofPublicInput.taskId).call(dataCommitmentProof);
            if (!success) {
                revert Errors.ProofVerificationFailure();
            }
        }

        {  
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
        }

        emit DataCommitmentExecuted(
            proofPublicInput.requestId,
            proofPublicInput.taskId,
            proofPublicInput.callbackAddress,
            QueryMode.PROOF
        );
    }

    function dataCommitmentBySignature(
        bytes4 callbackSelector,
        bytes32 requestId,
        address callbackAddress,
        uint64 callbackGasLimit,
        bytes calldata data,
        bytes[] calldata dataCommitmentSignatures
    ) external onlyRole(RELAYER_ROLE) nonReentrant {
        QueryMode queryMode = dataCommitmentSignatures.length > 0 ? QueryMode.SIGNATURE : QueryMode.MULTISIG;
        DataQueryRecord memory dataQueryRecord = dataQueries[requestId];
        
        if (dataQueryRecord.queryMode > bytes1(uint8(queryMode))) {
            revert Errors.QueryModeMismatch();
        }

        if (dataQueryRecord.managerAddress == address(0)) {
            revert Errors.CommitmentFailure();
        }

        delete dataQueries[requestId];

        uint8 signerCounts = 0;
        for (uint256 i = 0; i < dataCommitmentSignatures.length; i++) {
            if (!_signatureVerify(keccak256(
                abi.encode(
                    address(this),
                    block.chainid,
                    callbackSelector, 
                    requestId,
                    callbackAddress,
                    callbackGasLimit,
                    data
                )
            ), dataCommitmentSignatures[i])) {
                revert Errors.SignatureVerificationFailure();
            }
            signerCounts++;
        }

        if (signerCounts == 0) {
            revert Errors.SignatureLengthError();
        }else if (signerCounts > 1) {
            if (signerCounts < _mutiSigThreshold) {
                revert Errors.MutiSignatureNotEnough();
            }
        }

        {  
            (bool success, ) = callbackAddress.call{
                gas: callbackGasLimit
                }(
                abi.encodeWithSelector(
                    callbackSelector,
                    requestId,
                    data
                )
            );

            if (!success) {
                revert Errors.ProofVerificationFailure();
            }
        }

        emit DataCommitmentExecuted(
            requestId,
            0,
            callbackAddress,
            queryMode
        );
    }

    function dataQueryCancel(
        bytes32 requestId
    ) external {
        if (msg.sender != dataQueries[requestId].managerAddress) {
            revert Errors.AccessDenied();
        }
        delete dataQueries[requestId];
        emit DataQueryCancelled(requestId);
    }

    function dataQueryFallback(
        bytes32 requestId
    ) external onlyRole(FALLBACK_MANAGER_ROLE) {
        delete dataQueries[requestId];
        emit DataQueryFallback(requestId);
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
        return hasRole(SIGNER_ROLE, _hash.toEthSignedMessageHash().recover(_signature));
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
        _oracleXRolesInit(_admin, _fallbackManager, _relayers, _validators, _signers, _verifierManagers);
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

    function _setSignerRole(
        address[] memory _signers
    ) internal {
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
