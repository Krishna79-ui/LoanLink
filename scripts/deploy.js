const hre = require("hardhat");

async function main() {
  // Deploy or use existing token address
  const tokenAddress = "0x..."; // Replace with your token address

  const LoanLink = await hre.ethers.getContractFactory("LoanLink");
  const loanLink = await LoanLink.deploy(tokenAddress);

  await loanLink.deployed();

  console.log(
    `LoanLink deployed to Core Blockchain at address: ${loanLink.address}`
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
