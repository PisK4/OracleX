// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

library ProofParseLib {
    struct ProofPublicInput {
        uint64 taskId;
        bytes4 callbackSelector;
        bytes1 queryMode;
        bytes32 requestId;
        bytes32 subId;
        address callbackAddress;
        uint64 callbackGasLimit;
        bytes data;
    }
    function parseProof(
        bytes calldata proof
    ) internal pure returns (ProofPublicInput memory proofPublicInput) {
        proofPublicInput = ProofPublicInput({
            taskId: 0,
            callbackSelector: 0x12345678,
            queryMode: 0,
            requestId: 0x0000000000000000000000000000000000000000000000000000000000000000,
            subId: 0x0000000000000000000000000000000000000000000000000000000000000000,
            callbackAddress: 0x0000000000000000000000000000000000000000,
            callbackGasLimit: 0,
            data: proof
        });
    }
}
