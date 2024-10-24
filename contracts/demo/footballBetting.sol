// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IOracleX} from "../interface/IOracleX.sol";
import {OracleXAccessBase} from "../OracleXAccessBase.sol";

enum WINNER {
    INVALID,
    HOME,
    AWAY
}

struct Bet {
    WINNER winner;
    uint64 odds;
    uint256 betValue;
}

event MatchResultReceived(WINNER indexed winner, uint256 timestamp);

contract FootballBetting is OracleXAccessBase, Ownable {
    error AlreadyBet();
    error OddsError();
    error BettingNotAllowed();
    error cliaimNotAllowed();
    error UserBetWrong();
    bytes32 public matchResultSubscriptionId;
    bytes32 public oddsSubscriptionId;

    // users bets on the match
    mapping(address => Bet) public userBets;

    // match result
    WINNER public matchResult = WINNER.INVALID;

    bool public betStarted = false;

    modifier BettingIsAllowed() {
        if (!betStarted) {
            revert BettingNotAllowed();
        }
        _;
    }

    modifier ClaimIsAllowed() {
        if (betStarted) {
            revert cliaimNotAllowed();
        }
        _;
    }

    constructor(
        address _oracleX,
        bytes32 _matchResultSubscriptionId,
        bytes32 _oddsSubscriptionId
    ) OracleXAccessBase(_oracleX) Ownable(msg.sender) {
        matchResultSubscriptionId = _matchResultSubscriptionId;
        oddsSubscriptionId = _oddsSubscriptionId;

        oracleX.queryPassiveDataStreamFromOracleX(
            IOracleX.QueryPassiveMode({
                subId: matchResultSubscriptionId,
                authMode: bytes1(uint8(IOracleX.AuthMode.PROOF)),
                callbackAddress: address(this),
                managerAddress: owner(),
                callbackGasLimit: 50000,
                extraParams: new bytes(0)
            })
        );

        oracleX.queryActiveDataStreamFromOracleX(
            IOracleX.QueryActiveMode({
                subId: oddsSubscriptionId,
                authMode: bytes1(uint8(IOracleX.AuthMode.SIGNATURE)),
                managerAddress: owner(),
                extraParams: new bytes(0)
            })
        );

        betStarted = true;
    }

    function bet(WINNER winner) external payable BettingIsAllowed {
        // check if user is allready bet
        if (userBets[msg.sender].winner != WINNER.INVALID) {
            revert AlreadyBet();
        }

        uint64 odds = abi.decode(
            oracleX.fetchActiveDataStreamFromOracleX(oddsSubscriptionId),
            (uint64)
        );

        if (odds == 0) {
            revert OddsError();
        }

        Bet memory _bet = Bet({
            winner: winner,
            odds: odds,
            betValue: msg.value
        });
        userBets[msg.sender] = _bet;
    }

    function claim() external ClaimIsAllowed {
        Bet memory _bet = userBets[msg.sender];
        if (_bet.winner != matchResult) {
            revert UserBetWrong();
        }
        delete userBets[msg.sender];
        payable(msg.sender).transfer(_bet.betValue * _bet.odds);
    }

    function _receiveRawDataFromOracleX(
        bytes32 /*requestId*/,
        bytes calldata rawData
    ) internal override {
        matchResult = WINNER(abi.decode(rawData, (uint8)));
        betStarted = false;
        emit MatchResultReceived(matchResult, block.timestamp);
    }

    struct QueryPassiveMode {
        bytes32 subId;
        bytes1 authMode;
        address callbackAddress;
        address managerAddress;
        uint64 callbackGasLimit;
        bytes extraParams;
    }
}
