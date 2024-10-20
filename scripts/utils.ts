import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import {
  ContractTransactionResponse,
  Interface,
  LogDescription,
  TransactionReceipt,
  Wallet,
} from "ethers";
import fs from "fs";
import { ethers } from "hardhat";
import path from "path";

export function callDataCost(data: string): bigint {
  return BigInt(
    ethers
      .toBeArray(data)
      .map((x) => (x === 0 ? 4 : 16))
      .reduce((sum, x) => sum + x)
  );
}
export interface GasMonitor {
  action?: string;
  totoalGas: bigint;
  inputDataGas: bigint;
  excutionGas: bigint;
}

export const calculateTxGas = async (
  tx: ContractTransactionResponse,
  title?: string,
  getTransactionfee = false,
  index?: number
): Promise<GasMonitor> => {
  let gasMonitor: GasMonitor = {} as GasMonitor;

  const { maxPriorityFeePerGas } = await ethers.provider.getFeeData();
  const transactionReceipt = await tx.wait();
  // const basefee = baseFeePerGas!.toNumber();
  const gasUsed = transactionReceipt!.gasUsed;
  const gasPrice = tx.gasPrice;
  // const transactionfee = gasUsed * basefee;
  const inputGasUsed = callDataCost(tx.data);
  // const priorityFee = tx.effectiveGasPrice?.sub(basefee).toNumber();
  gasMonitor = {
    action: title?.toString(),
    totoalGas: gasUsed,
    inputDataGas: inputGasUsed,
    excutionGas: gasUsed - inputGasUsed - 21000n,
  };
  return gasMonitor;
};

export async function getCurrentTime() {
  const block = await ethers.provider.getBlock("latest");
  if (block !== null) {
    return block.timestamp;
  }
  return 0;
}

export function parseEvents(
  iface: Interface,
  receipt: TransactionReceipt
): (LogDescription | undefined | null)[] {
  return receipt.logs
    .map((log) => {
      try {
        const aLog = JSON.parse(JSON.stringify(log));
        return iface.parseLog(aLog);
      } catch (e) {
        return undefined;
      }
    })
    .filter((n: LogDescription | undefined | null) => n);
}

export async function deployerConfiguration(
  privateKey?: string
): Promise<HardhatEthersSigner | Wallet> {
  let currentProvider = ethers.provider;
  let deployer;
  if (privateKey) {
    deployer = new ethers.Wallet(privateKey, currentProvider);
    return deployer;
  }
  if (process.env.DEPLOYER_PRIVATE_KEY) {
    deployer = new ethers.Wallet(
      process.env.DEPLOYER_PRIVATE_KEY,
      currentProvider
    );
    console.log(
      "Using DEPLOYER_PRIVATE_KEY deployer with address: ",
      deployer.address
    );
  } else {
    [deployer] = await ethers.getSigners();
    console.log("Using hardhat deployer with address: ", deployer.address);
  }
  return deployer;
}

const pathDeployParameters = path.join(__dirname, "./deploy_parameters.json");
export function getDeployParameters() {
  if (!fs.existsSync(pathDeployParameters)) {
    throw new Error("deploy_parameters.json doesn't exist");
  } else {
    const contractsString = fs.readFileSync(pathDeployParameters, "utf8");
    return JSON.parse(contractsString);
  }
}
