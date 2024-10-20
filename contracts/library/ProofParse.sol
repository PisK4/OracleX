// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

library ProofParseLib {
    function parseProof(
        bytes calldata proof
    )
        external
        pure
        returns (ProofStructLib.ProofPublicInput memory proofPublicInput)
    {
        proofPublicInput = ProofStructLib.ProofPublicInput({
            taskId: 0,
            callbackSelector: 0x12345678,
            requestId: 0x0000000000000000000000000000000000000000000000000000000000000000,
            callbackAddress: 0x0000000000000000000000000000000000000000,
            callbackGasLimit: 0,
            data: proof
        });
    }
}

library ProofStructLib {
    struct ProofPublicInput {
        uint64 taskId;
        bytes4 callbackSelector;
        bytes32 requestId;
        address callbackAddress;
        uint64 callbackGasLimit;
        bytes data;
    }
}
