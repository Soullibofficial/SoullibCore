
// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
// require('@nomiclabs/hardhat-ethers');
// const { ethers, upgrades } = require('hardhat');
const Web3 = require("web3");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  console.log(
    "Deploying SLIB TOKEN: "
  )
  const SlibOne = await ethers.getContractFactory("SlibOne");
  const slibOne = await SlibOne.deploy("0xe29D321FB47c03e3b3aab3fF1AB78b344F9De3cD");
  await slibOne.deployed();
  console.log("SLIB deployed to:", slibOne.address);
  
  // console.log(
  //   "Deploying SLIB LOGIC: "
  //   )
  //   const Soullib = await ethers.getContractFactory("SoullibOneFile");
  //   const soullib = await Soullib.deploy("0x099B8DEb426F7800114AdeEecFf7586501b4ad69", "0xe29D321FB47c03e3b3aab3fF1AB78b344F9De3cD");
  //   await soullib.deployed();
  // console.log("Soullib deployed to:", soullib.address);
  
  
  
  const TSUPPLY = await slibOne.functions.totalSupply();
  console.log("TSUPPLY: ", Web3.utils.hexToNumberString(TSUPPLY[0]._hex));
}
  
  // We recommend this pattern to be able to use async/await everywhere
  // and properly handle errors.
  main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
  
