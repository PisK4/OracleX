import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import hre, { ethers, upgrades } from "hardhat";
import { FootballBetting, OracleX, OracleX__factory } from "../typechain-types";
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
  dataLength: BigNumberish;
  data: string;
  proof: string;
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

export async function dataCommitmentByProofPassiveMode(
  dataCommitment: DataCommitment1,
  oracleX: OracleX
) {
  const publicInput: ProofPublicInput = {
    taskId: 0,
    callbackSelector: dataCommitment.callbackSelector,
    queryMode: "0x00",
    requestId: dataCommitment.requestId,
    subId: dataCommitment.requestId,
    callbackAddress: dataCommitment.callbackAddress,
    callbackGasLimit: dataCommitment.callbackGasLimit,
    dataLength: dataCommitment.dataLength,
    data: dataCommitment.data,
    proof: dataCommitment.proof,
  };
  const proof = publicInputEncode(publicInput);
  // console.log("proof", proof);
  return await oracleX.dataCommitmentByProof(proof);
}

interface ProofPublicInput {
  taskId: BigNumberish;
  callbackSelector: string;
  queryMode: string;
  requestId: Uint8Array;
  subId: Uint8Array;
  callbackAddress: AddressLike;
  callbackGasLimit: BigNumberish;
  dataLength: BigNumberish;
  data: string;
  proof: string;
}

export const publicInputType = [
  "uint64",
  "bytes4",
  "bytes1",
  "bytes32",
  "bytes32",
  "address",
  "uint64",
  "uint256",
  "bytes",
];

export function publicInputEncode(proofPublicInput: ProofPublicInput) {
  const padTaskId = ethers.zeroPadValue(
    toBeArray(proofPublicInput.taskId.toString()),
    8
  );
  console.log("padTaskId", padTaskId);
  const padCallbackSelector = ethers.zeroPadValue(
    toBeArray(proofPublicInput.callbackSelector),
    4
  );
  console.log("padCallbackSelector", padCallbackSelector);

  const padQueryMode = ethers.zeroPadValue(
    toBeArray(proofPublicInput.queryMode),
    1
  );

  console.log("padQueryMode", padQueryMode);

  const padRequestId = ethers.zeroPadValue(
    toBeArray(ethers.hexlify(proofPublicInput.requestId)),
    32
  );

  console.log("padRequestId", padRequestId);

  const padSubId = ethers.zeroPadValue(
    toBeArray(ethers.hexlify(proofPublicInput.subId)),
    32
  );

  console.log("padSubId", padSubId);

  const padCallbackAddress = ethers.zeroPadValue(
    toBeArray(ethers.hexlify(proofPublicInput.callbackAddress.toString())),
    20
  );

  console.log("padCallbackAddress", padCallbackAddress);

  const padCallbackGasLimit = ethers.zeroPadValue(
    toBeArray(proofPublicInput.callbackGasLimit.toString()),
    8
  );

  console.log("padCallbackGasLimit", padCallbackGasLimit);

  const padDataLength = ethers.zeroPadValue(
    toBeArray(proofPublicInput.dataLength.toString()),
    32
  );

  const padData = ethers.zeroPadValue(
    toBeArray(ethers.hexlify(proofPublicInput.data)),
    32
  );

  console.log("padData", padData);

  const publicInputData =
    "0x" +
    padTaskId.replace("0x", "") +
    padCallbackSelector.replace("0x", "") +
    padQueryMode.replace("0x", "") +
    padRequestId.replace("0x", "") +
    padSubId.replace("0x", "") +
    padCallbackAddress.replace("0x", "") +
    padCallbackGasLimit.replace("0x", "") +
    padDataLength.replace("0x", "") +
    padData.replace("0x", "") +
    proofPublicInput.proof.replace("0x", "");

  const encodedata = ethers.AbiCoder.defaultAbiCoder().encode(
    ["bytes"],
    [publicInputData]
  );

  return "0x8e760afe" + encodedata.replace("0x", "");
}
