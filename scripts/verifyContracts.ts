import hre, { ethers } from "hardhat";
import { getDeployParameters } from "./utils";

async function main(): Promise<void> {
  const deployParameters = await getDeployParameters();

  const orbiterLottery = "0xAD571EB266E5894622d407f5989A81403C32D829";
  if (orbiterLottery) {
    console.log("Verify OrbiterLottery");
    try {
      await hre.run("verify:verify", {
        address: orbiterLottery,
        constructorArguments: [
          deployParameters.owner,
          deployParameters.signers,
        ],
      });
    } catch (error) {
      console.error(error);
      console.log(
        "constructor args:",
        ethers.AbiCoder.defaultAbiCoder().encode(
          ["address", "address[]"],
          [deployParameters.owner, deployParameters.signers]
        )
      );
    }
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
