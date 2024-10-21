import hre, { ethers, upgrades } from "hardhat";

export async function deployOracleX() {
  const signer = (await ethers.getSigners())[0];
  const signerAddress = await signer.getAddress();
  console.log("Deployer address: ", signerAddress);
  const OracleXName = "OracleX";
  const OracleXFactory = await ethers.getContractFactory(OracleXName);
  const initializerArgs = [
    signerAddress,
    signerAddress,
    [signerAddress],
    [signerAddress],
    [signerAddress],
    [signerAddress],
  ];
  const OracleX = await upgrades.deployProxy(OracleXFactory, initializerArgs, {
    kind: "uups",
    initializer: "initialize",
  });
  console.log("OracleX deployed to: ", await OracleX.getAddress());
  return OracleX;
}
