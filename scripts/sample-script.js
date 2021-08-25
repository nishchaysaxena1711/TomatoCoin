// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const _TomatoIco = await hre.ethers.getContractFactory("TomatoSale");
  const _TomatoCoin = await hre.ethers.getContractFactory("Tomato");

  const tomatoCoin = await _TomatoCoin.deploy("0x6440E988410A8458e842E1d1D6494797Eb4Ae6D8");
  await tomatoIco.deployed();

  const tomatoIco = await _TomatoIco.deploy(tomatoCoin.address);
  await tomatoIco.deployed();

  console.log("Greeter deployed to:", tomatoIco.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
