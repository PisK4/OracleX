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
        // proofPublicInput = ProofPublicInput({
        //     taskId: uint64(bytes8(proof[4:12])),
        //     callbackSelector: bytes4(proof[12:16]),
        //     queryMode: bytes1(proof[16]),
        //     requestId: bytes32(proof[17:49]),
        //     subId: bytes32(proof[49:81]),
        //     callbackAddress: address(bytes20(proof[81:101])),
        //     callbackGasLimit: uint64(bytes8(proof[101:109])),
        //     data: bytes(proof[109:])
        // });

        proofPublicInput = ProofPublicInput({
            taskId: uint64(bytes8(proof[68:76])),
            callbackSelector: bytes4(proof[76:80]),
            queryMode: bytes1(proof[80]),
            requestId: bytes32(proof[81:113]),
            subId: bytes32(proof[113:145]),
            callbackAddress: address(bytes20(proof[145:165])),
            callbackGasLimit: uint64(bytes8(proof[165:173])),
            data: bytes(proof[173:])
        });
    }
}
