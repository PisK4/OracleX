// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IOracleX {
    enum AuthMode {
        SIGNATURE,
        MULTISIG,
        PROOF
    }

    enum QueryMode {
        PASSIVE,
        ACTIVE
    }

    struct QueryPassiveMode {
        bytes32 subId;
        bytes1 authMode;
        address callbackAddress;
        address managerAddress;
        uint64 callbackGasLimit;
        bytes extraParams;
    }

    struct QueryActiveMode {
        bytes32 subId;
        bytes1 authMode;
        address managerAddress;
        bytes extraParams;
    }

    struct QueryRecord {
        address managerAddress; // 20 bytes
        bytes1 authMode; // 1 byte
        bytes1 queryMode; // 1 byte
        bool suspended; // 1 byte
        bytes9 rsv9bytes; // 10 bytes
    }

    event QueryPassiveModeSubmitted(
        bytes32 indexed requestId,
        uint256 indexed nonce,
        QueryPassiveMode dataQuery
    );

    event QueryActiveModeSubmitted(
        bytes32 indexed subId,
        QueryActiveMode dataQuery
    );

    event DataQueryFallback(bytes32 indexed id);

    event DataQueryCancelled(bytes32 indexed id);

    event DataQuerySuspended(bytes32 indexed id);

    event DataCommitmentExecutedPassive(
        bytes32 indexed requestId,
        uint256 indexed taskId,
        address indexed callbackAddress,
        AuthMode authMode
    );

    event DataCommitmentExecutedActive(
        bytes32 indexed subId,
        AuthMode authMode
    );

    function queryPassiveDataStreamFromOracleX(
        QueryPassiveMode calldata dataQuery
    ) external returns (bytes32 requestId);

    function queryActiveDataStreamFromOracleX(
        QueryActiveMode calldata dataQuery
    ) external;

    function fetchActiveDataStreamFromOracleX(
        bytes32 subId
    ) external view returns (bytes memory dataQuery);

    function dataCommitmentByProof(bytes calldata dataCommitmentProof) external;

    function dataCommitmentBySignature(
        bytes4 callbackSelector,
        bytes32 requestId,
        address callbackAddress,
        uint64 callbackGasLimit,
        bytes calldata data,
        bytes[] calldata dataCommitmentSignatures
    ) external;

    function dataCommitmentBySignature(
        bytes32 subId,
        bytes calldata data,
        bytes[] calldata dataCommitmentSignatures
    ) external;

    function dataQueryCancel(bytes32 id) external;

    function dataQuerySuspend(bytes32 id) external;

    function dataQueryFallback(bytes32 id) external;
}
