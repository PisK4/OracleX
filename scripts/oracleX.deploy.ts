import hre, { ethers, upgrades } from "hardhat";
import { FootballBetting, OracleX, OracleX__factory } from "../typechain-types";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { promisify } from "util";
import { exec } from "child_process";
import { Wallet } from "ethers";

export async function deployOracleX() {
  const signers = await ethers.getSigners();
  const signer = signers[0];
  const deployer = signers[2];
  const deployerB = signers[3];
  const verifier = await deployProofVerifier(signer);
  console.log("verifier deployed to : ", verifier);
  const signerAddress = await signer.getAddress();
  const deployerAddress = await deployer.getAddress();
  const deployerBAddress = await deployerB.getAddress();
  const OracleXName = "OracleX";
  const OracleXFactory = await ethers.getContractFactory(OracleXName);
  const initializerArgs = [
    signerAddress,
    signerAddress,
    verifier,
    [signerAddress, deployerAddress, deployerBAddress],
    [signerAddress, deployerAddress, deployerBAddress],
    [signerAddress, deployerAddress, deployerBAddress],
    [signerAddress, deployerAddress, deployerBAddress],
  ];
  const OracleX = await upgrades.deployProxy(OracleXFactory, initializerArgs, {
    kind: "uups",
    initializer: "initialize",
  });
  const oracleXAddress = await OracleX.getAddress();
  console.log("OracleX deployed to: ", oracleXAddress);

  return new OracleX__factory(signer).attach(oracleXAddress) as OracleX;
}

export async function delpoyFootballBetting(
  oracleXAddr: string,
  matchResultSubscriptionId: Uint8Array,
  oddsSubscriptionId: Uint8Array
) {
  const signer = (await ethers.getSigners())[0];
  const FootballBettingFactory = await ethers.getContractFactory(
    "FootballBetting"
  );
  const FootballBetting = (await FootballBettingFactory.connect(signer).deploy(
    oracleXAddr,
    matchResultSubscriptionId,
    oddsSubscriptionId
  )) as FootballBetting;

  console.log(
    "FootballBetting deployed to: ",
    await FootballBetting.getAddress()
  );
  return FootballBetting;
}

export async function deployProofVerifier(deployer: HardhatEthersSigner) {
  const verifierBytecode = await compile_yul("contracts/proofVerifier.yul");
  return await deployYul(verifierBytecode, deployer);
}

export async function deployYul(
  bytesCode: string,
  deployer: Wallet | HardhatEthersSigner
) {
  const VerifierAbi = [
    {
      payable: true,
      stateMutability: "payable",
      type: "fallback",
    },
  ];

  const verifierFactory = new ethers.ContractFactory(
    VerifierAbi,
    bytesCode!,
    deployer
  );

  const verifier = await verifierFactory.deploy();
  await verifier.waitForDeployment();
  return await verifier.getAddress();
}

export const compile_yul = async (codePath: string): Promise<string> => {
  if (process.env.RUNTIMECOMPILE) {
    const cmd = `solc --bin --yul --optimize-runs 200 ${codePath}`;

    const output = await executeCommand(cmd);
    const string_slice = output.split(/[\s\n]/);
    const evm_compiled_code = string_slice[string_slice.length - 2];

    return evm_compiled_code;
  } else {
    return "0x608060405234801561001057600080fd5b50610159806100206000396000f3fe608060405234801561001057600080fd5b506004361061002b5760003560e01c80638e760afe14610030575b600080fd5b61004361003e36600461008a565b610045565b005b8061004f57600080fd5b60005a90505b610062620c3500826100fc565b5a101561005557828260405161007992919061013c565b604051908190039020600055505050565b6000806020838503121561009d57600080fd5b823567ffffffffffffffff808211156100b557600080fd5b818501915085601f8301126100c957600080fd5b8135818111156100d857600080fd5b8660208285010111156100ea57600080fd5b60209290920196919550909350505050565b81810381811115610136577f4e487b7100000000000000000000000000000000000000000000000000000000600052601160045260246000fd5b92915050565b818382376000910190815291905056fea164736f6c6343000817000a";
  }
};

const executeCommand = async (command: string): Promise<string> => {
  const execAsync = promisify(exec);
  try {
    const { stdout, stderr } = await execAsync(command);
    if (stderr) {
      throw new Error(stderr);
    }
    return stdout;
  } catch (error) {
    throw new Error(`Failed to execute command: ${error}`);
  }
};
