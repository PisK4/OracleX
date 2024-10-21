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
import { OracleX } from "../typechain-types";

import { deployOracleX } from "../scripts/OracleX.deploy";

describe("OracleX Test", () => {
  let deployer: HardhatEthersSigner;
  let oracleX: OracleX;

  before(async () => {
    oracleX = await deployOracleX();
  });

  it("oracleX should be deployed", async () => {
    expect(await oracleX.getAddress()).to.not.equal(ZeroAddress);
  });
});
