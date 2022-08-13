// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const { expect } = require("chai");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');
  const [deployer, addr1, addr2, addr3, addr4, ...addrs] = await ethers.getSigners();

  const TokenScenario2 = await hre.ethers.getContractFactory("TokenScenario2");
  const initialSupply1 = hre.ethers.utils.parseEther("1000000");
  const tokenName1 = "Willy";
  const tokenSymbol1 = "WILLY";
  const token1 = await TokenScenario2.deploy(initialSupply1, tokenName1, tokenSymbol1);

  console.log(`Token named ${tokenName1} deployed to ${token1.address}`);

  const initialSupply2 = hre.ethers.utils.parseEther("2000000");
  const tokenName2 = "Johnson";
  const tokenSymbol2 = "JNSN";
  const token2 = await TokenScenario2.deploy(initialSupply2, tokenName2, tokenSymbol2);

  console.log(`Token named ${tokenName2} deployed to ${token2.address}`);

  const tokenAddresses = [token1.address, token2.address];
  const exchangeRates = [100, 200];
  // We get the contract to deploy
  const Scenario2 = await hre.ethers.getContractFactory("Scenario2");
  const scenario2 = await Scenario2.deploy(tokenAddresses, exchangeRates, (60 * 24));

  console.log("Scenario2 deployed to:", scenario2.address);

  const scenario2SupplyToken1 = hre.ethers.utils.parseEther("500000");
  const scenario2SupplyToken2 = hre.ethers.utils.parseEther("1000000");
  await token1.connect(deployer).transfer(scenario2.address, scenario2SupplyToken1);
  await token2.connect(deployer).transfer(scenario2.address, scenario2SupplyToken2);


  scenario2BalanceToken1 = await token1.balanceOf(scenario2.address)
  console.log("Scenario2 Balance of token 1: ", hre.ethers.utils.formatEther(scenario2BalanceToken1));
  scenario2BalanceToken2 = await token2.balanceOf(scenario2.address)
  console.log("Scenario2 Balance of token 2: ", hre.ethers.utils.formatEther(scenario2BalanceToken2));

  /// Have three accounts go and stake tokens at different levels
  /// Have a few try to pull out early and fail
  /// Stake too much and too little

  await scenario2.connect(addr1).stake({value: hre.ethers.utils.parseEther("1")});
  await scenario2.connect(addr2).stake({value: hre.ethers.utils.parseEther("10")});
  await scenario2.connect(addr3).stake({value: hre.ethers.utils.parseEther("100")});
  await expect(scenario2.connect(addr4).stake({value: hre.ethers.utils.parseEther("1000")})).to.be.revertedWith("Sent Too Much ETH. Maximum 100 ETH");
  await expect(scenario2.connect(addr4).stake({value: 1000}))
    .to.be.revertedWith("Sent Too Little ETH. Minimum 1 ETH");
  await expect(scenario2.connect(addr1).stake({value: hre.ethers.utils.parseEther("1")}))
    .to.be.revertedWith("You cannot stake!")

  console.log("Added all stakes with no errors!")

  /// Forward time 12 hours
  await hre.network.provider.send("evm_increaseTime", [60*60*12]);
  await hre.network.provider.send("evm_mine")

  /// Have a few accounts try to pull out and fail
  await expect(scenario2.connect(addr1).withdrawStake())
    .to.be.revertedWith("Cannot Withdraw Yet")
  await expect(scenario2.connect(addr2).withdrawReward())
    .to.be.revertedWith("Cannot Withdraw Yet")
  await expect(scenario2.connect(addr3).stake({value: hre.ethers.utils.parseEther("1")}))
    .to.be.revertedWith("You cannot stake!")

  console.log("12 Hours Passed and cannot withdraw, continuing...")

  /// Forward time by another 12 hours
  await hre.network.provider.send("evm_increaseTime", [60*60*12]);
  await hre.network.provider.send("evm_mine")

  /// Have every pull out everything
  await scenario2.connect(addr1).withdrawStake()
  console.log("addr1 withdrew stake")
  await scenario2.connect(addr1).withdrawReward()
  console.log("addr1 withdrew reward")

  await scenario2.connect(addr2).withdrawStake()
  await expect(scenario2.connect(addr2).stake({value: hre.ethers.utils.parseEther("1")}))
    .to.be.revertedWith("You cannot stake!")
  await scenario2.connect(addr2).withdrawReward()
  
  await scenario2.connect(addr3).withdrawReward()  
  await expect(scenario2.connect(addr3).stake({value: hre.ethers.utils.parseEther("1")}))
    .to.be.revertedWith("You cannot stake!")
  await scenario2.connect(addr3).withdrawStake()

  console.log("Able to withdraw all funds")

  // Try to re-withdraw
  await expect(scenario2.connect(addr1).withdrawStake()).to.be.revertedWith("No Value to Unstake")
  await expect(scenario2.connect(addr1).withdrawReward()).to.be.revertedWith("No Stake Reward to Claim")

  console.log("Could not re-withdraw")

  /// Check balances of people
  tbaddr1_token1 = await token1.balanceOf(addr1.address);
  tbaddr1_token2 = await token2.balanceOf(addr1.address);
  tbaddr2_token1 = await token1.balanceOf(addr2.address);
  tbaddr2_token2 = await token2.balanceOf(addr2.address);
  tbaddr3_token1 = await token1.balanceOf(addr3.address);
  tbaddr3_token2 = await token2.balanceOf(addr3.address);
  
  expect(tbaddr1_token1).to.equal(hre.ethers.utils.parseEther("100"));
  expect(tbaddr1_token2).to.equal(hre.ethers.utils.parseEther("200"));
  expect(tbaddr2_token1).to.equal(hre.ethers.utils.parseEther("1000"));
  expect(tbaddr2_token2).to.equal(hre.ethers.utils.parseEther("2000"));
  expect(tbaddr3_token1).to.equal(hre.ethers.utils.parseEther("10000"));
  expect(tbaddr3_token2).to.equal(hre.ethers.utils.parseEther("20000"));

  console.log("Token values match expected!")

  /// Have one person restake
  await scenario2.connect(addr1).stake({value: hre.ethers.utils.parseEther("1")});

  console.log("Address able to re-stake.");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
