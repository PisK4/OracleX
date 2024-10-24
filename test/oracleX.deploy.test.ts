import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { expect } from "chai";
import {
  AddressLike,
  BytesLike,
  Wallet,
  ZeroAddress,
  hexlify,
  randomBytes,
  toBeArray,
  toBigInt,
} from "ethers";
import { ethers } from "hardhat";
import {
  FootballBetting,
  OracleX,
  Verifier,
  Verifier__factory,
} from "../typechain-types";

import {
  delpoyFootballBetting,
  deployOracleX,
} from "../scripts/oracleX.deploy";
import { bet } from "../scripts/footballbetting.actions";
import {
  DataCommitment1,
  DataCommitment2,
  dataCommitmentByProofPassiveMode,
  dataCommitmentBySignatureActiveMode,
} from "../scripts/oracleX.actions";

describe("OracleX Test", () => {
  let deployers: HardhatEthersSigner[];
  let signer: HardhatEthersSigner;
  let oracleX: OracleX;
  let footballBetting: FootballBetting;
  let matchResultSubscriptionId: Uint8Array;
  let oddsSubscriptionId: Uint8Array;
  let chainId: bigint;
  let requestId: string;

  before(async () => {
    deployers = await ethers.getSigners();
    signer = deployers[0];
    oracleX = await deployOracleX();
    matchResultSubscriptionId = new Uint8Array([
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01,
    ]);
    oddsSubscriptionId = new Uint8Array([
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02,
    ]);
    console.log(`matchResultSubscriptionId: ${matchResultSubscriptionId}`);
    footballBetting = await delpoyFootballBetting(
      await oracleX.getAddress(),
      matchResultSubscriptionId,
      oddsSubscriptionId
    );
    chainId = (await ethers.provider.getNetwork()).chainId;
  });

  it("oracleX should be deployed", async () => {
    expect(await oracleX.getAddress()).to.not.equal(ZeroAddress);
  });

  it("footballBetting should be deployed", async () => {
    expect(await footballBetting.getAddress()).to.not.equal(ZeroAddress);
  });

  it.skip("oracleX should be able to commit data", async () => {
    const AbiCoder = ethers.AbiCoder.defaultAbiCoder();
    const dataCommitment: DataCommitment2 = {
      oracleXAddr: await oracleX.getAddress(),
      currChainId: chainId,
      subscriptionId: oddsSubscriptionId,
      data: AbiCoder.encode(["uint256"], [2]),
    };

    const tx = await dataCommitmentBySignatureActiveMode(
      signer,
      dataCommitment,
      oracleX
    );
    await tx.wait();
  });

  it.skip("oracleX should be able to commit proof", async () => {
    const dataCommitment: DataCommitment1 = {
      oracleXAddr: await oracleX.getAddress(),
      currChainId: chainId,
      callbackSelector: "0x1103ada8",
      requestId: toBeArray(
        "0xecb1c6668396fa700b6f7d19039b051bf7a01bd499ea08896f6a2341d88a8504"
      ),
      callbackAddress: await footballBetting.getAddress(),
      callbackGasLimit: 50000,
      data: "0x0000000000000000000000000000000000000000000000000000000000000002",
    };

    const tx = await dataCommitmentByProofPassiveMode(dataCommitment, oracleX);
    await tx.wait();
    console.log("commit proof tx: ", tx.hash);
  });

  it.skip("footballBetting should be able to bet", async () => {
    await bet(signer, footballBetting, 1);

    // check user bet
    const betInfo = await footballBetting.userBets(signer.getAddress());
    console.log("betInfo: ", betInfo);
  });
});
