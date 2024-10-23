import hre, { ethers, upgrades } from "hardhat";
import { FootballBetting, OracleX, OracleX__factory } from "../typechain-types";

export async function deployOracleX() {
  const signer = (await ethers.getSigners())[0];
  const signerAddress = await signer.getAddress();
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
