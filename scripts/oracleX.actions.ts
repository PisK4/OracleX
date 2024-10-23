import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import hre, { ethers, upgrades } from "hardhat";
import { FootballBetting, OracleX } from "../typechain-types";
import {
  AddressLike,
  BigNumberish,
  Wallet,
  ZeroAddress,
  hexlify,
  randomBytes,
  toBeArray,
  toBigInt,
} from "ethers";

export const dataCommitBySigType1 = [
  "address",
  "uint256",
  "bytes4",
  "bytes32",
  "address",
  "uint64",
  "bytes",
];

export const dataCommitBySigType2 = ["address", "uint256", "bytes32", "bytes"];

export interface DataCommitment1 {
  oracleXAddr: string;
  currChainId: BigNumberish;
  callbackSelector: string;
  requestId: Uint8Array;
  callbackAddress: string;
  callbackGasLimit: BigNumberish;
  data: string;
}

export interface DataCommitment2 {
  oracleXAddr: string;
  currChainId: BigNumberish;
  subscriptionId: Uint8Array;
  data: string;
}

export async function passiveModeDataSig(
  signer: HardhatEthersSigner,
  dataCommitment: DataCommitment1
) {
  const AbiCoder = ethers.AbiCoder.defaultAbiCoder();
  const encodeMessageHash = ethers.keccak256(
    AbiCoder.encode(dataCommitBySigType1, [
      dataCommitment.oracleXAddr,
      dataCommitment.currChainId,
      dataCommitment.callbackSelector,
      dataCommitment.requestId,
      dataCommitment.callbackAddress,
      dataCommitment.callbackGasLimit,
      dataCommitment.data,
    ])
  );
  return await signer.signMessage(toBeArray(encodeMessageHash));
}

export async function activeModeDataSig(
  signer: HardhatEthersSigner,
  dataCommitment: DataCommitment2
) {
  const AbiCoder = ethers.AbiCoder.defaultAbiCoder();
  const encodeMessageHash = ethers.keccak256(
    AbiCoder.encode(dataCommitBySigType2, [
      dataCommitment.oracleXAddr,
      dataCommitment.currChainId,
      dataCommitment.subscriptionId,
      dataCommitment.data,
    ])
  );
  return await signer.signMessage(toBeArray(encodeMessageHash));
}

export async function dataCommitmentBySignatureActiveMode(
  signer: HardhatEthersSigner,
  dataCommitment: DataCommitment2,
  oracleX: OracleX
) {
  const signature = await activeModeDataSig(signer, dataCommitment);
  return await oracleX.dataCommitmentBySignatureA(
    dataCommitment.subscriptionId,
    dataCommitment.data,
    [signature]
  );
}
