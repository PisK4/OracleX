import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { expect } from "chai";
import {
  AddressLike,
  Wallet,
  ZeroAddress,
  hexlify,
  randomBytes,
  toBeArray,
  toBigInt,
} from "ethers";
import { ethers } from "hardhat";
import { FootballBetting, OracleX } from "../typechain-types";

import {
  delpoyFootballBetting,
  deployOracleX,
} from "../scripts/oracleX.deploy";
import { bet } from "../scripts/footballbetting.actions";
import {
  DataCommitment2,
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

  before(async () => {
    deployers = await ethers.getSigners();
    signer = deployers[0];
    oracleX = await deployOracleX();
    matchResultSubscriptionId = ethers.randomBytes(32);
    oddsSubscriptionId = ethers.randomBytes(32);
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

  it.skip("footballBetting should be able to bet", async () => {
    await bet(signer, footballBetting, 1);

    // check user bet
    const betInfo = await footballBetting.userBets(signer.getAddress());
    console.log("betInfo: ", betInfo);
  });
});
