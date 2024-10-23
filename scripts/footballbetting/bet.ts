import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import hre, { ethers, upgrades } from "hardhat";
import { FootballBetting } from "../../typechain-types";
import { BigNumberish } from "ethers";
import { bet } from "../footballbetting.actions";

async function main() {
  const [signer] = await hre.ethers.getSigners();
  const footballbettingAddress =
    process.env.FOOTBALL_BETTING_ADDRESS! ||
    "0xb71D7A9381b85D67CBc9E3302492656057964bc0";
  const footballBetting = await ethers.getContractAt(
    "FootballBetting",
    footballbettingAddress,
    signer
  );
  const tx = await bet(signer, footballBetting);
  await tx.wait();
  console.log(`bet success, tx hash: ${tx.hash}`);
}

if (require.main === module) {
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
}
