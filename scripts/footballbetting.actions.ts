import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import hre, { ethers, upgrades } from "hardhat";
import { FootballBetting } from "../typechain-types";
import { BigNumberish } from "ethers";

export async function bet(
  signer: HardhatEthersSigner,
  footballBetting: FootballBetting,
  winner: number = 1,
  betValue: BigNumberish = ethers.parseEther("0.1")
) {
  const tx = await footballBetting
    .connect(signer)
    .bet(winner, { value: betValue });
  const txReceipt = await tx.wait();
  const gasFee = (txReceipt?.gasUsed || 0n) * (txReceipt?.gasPrice || 0n);

  console.log(`waiting for user bet: ${ethers.formatEther(betValue)} ETH...`);
  return tx;
}
