// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IOracleX} from "./interface/IOracleX.sol";

abstract contract OracleXAccessBase {
    error AccessDenied();
    error NotImplement();

    IOracleX public oracleX;

    modifier onlyOracleX() {
        if (msg.sender != address(oracleX)) {
            revert AccessDenied();
        }
        _;
    }

    constructor(address _oracleX) {
        __oracleXInit(_oracleX);
    }

    function __oracleXInit(address _oracleX) internal {
        oracleX = IOracleX(_oracleX);
    }

    function receiveDataFromOracleX(
        bytes32 requestId,
        bytes calldata rawData
    ) external onlyOracleX {
        _receiveRawDataFromOracleX(requestId, rawData);
    }

    function _receiveRawDataFromOracleX(
        bytes32 requestId,
        bytes calldata rawData
    ) internal virtual {
        (requestId, rawData);
        revert NotImplement();
    }
}
