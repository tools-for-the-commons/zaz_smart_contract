// import { BigNumber } from "ethers";

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Start deploy...");
    console.log("Deploying contracts with the account:", deployer.address);
    let nonce = await ethers.provider.getTransactionCount(deployer.address); // get currence nonce
    let gasPrice = await ethers.provider.getFeeData().then(fee => fee.gasPrice);
    const gasLimit = 9000000; // Valor aumentado para garantir que haja gás suficiente
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
