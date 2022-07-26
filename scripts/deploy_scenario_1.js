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

  const Token = await hre.ethers.getContractFactory("Token");
  const initialSupply = hre.ethers.utils.parseEther("1000000");
  const token = await Token.deploy(initialSupply);

  console.log("Token deployed to:", token.address);

  // We get the contract to deploy
  const Scenario1 = await hre.ethers.getContractFactory("Scenario1");
  //const scenario1 = await Scenario1.deploy();
  const scenario1 = await Scenario1.deploy(token.address, 100, (60 * 24));

  console.log("Scenario1 deployed to:", scenario1.address);

  const scenario1Supply = hre.ethers.utils.parseEther("500000");
  await token.connect(deployer).transfer(scenario1.address, scenario1Supply);

  scenario1Balance = await token.balanceOf(scenario1.address)
  console.log("Scenario1 Balance: ", hre.ethers.utils.formatEther(scenario1Balance));

  /// Have three accounts go and stake tokens at different levels
  /// Have a few try to pull out early and fail
  /// Stake too much and too little

  /// Changing locked time
  await scenario1.connect(deployer).changeLockedTime(60 * 12) // tokens are now locked for 12 hours

  /// Changing exchange rate
  await scenario1.connect(deployer).changeExchangeRate(200) // we now have 200 Token = 1 ETH

  await scenario1.connect(addr1).stake({value: hre.ethers.utils.parseEther("1")});
  await scenario1.connect(addr2).stake({value: hre.ethers.utils.parseEther("10")});
  await scenario1.connect(addr3).stake({value: hre.ethers.utils.parseEther("100")});
  await expect(scenario1.connect(addr4).stake({value: hre.ethers.utils.parseEther("1000")}))
    .to.be.revertedWith("Sent Too Much ETH. Maximum 100 ETH");
  await expect(scenario1.connect(addr4).stake({value: 1000}))
    .to.be.revertedWith("Sent Too Little ETH. Minimum 1 ETH");
  await expect(scenario1.connect(addr1).stake({value: hre.ethers.utils.parseEther("1")}))
    .to.be.revertedWith("You cannot stake!")

  console.log("Added all stakes with not errors!")

  /// Forward time 12 hours
  console.log("fast forwarding 12 hours...");
  await hre.network.provider.send("evm_increaseTime", [60*60*12]);
  await hre.network.provider.send("evm_mine")

  console.log("12 Hours Passed and should be able to withdraw, let's see...")

  /// Have every pull out everything
  await scenario1.connect(addr1).withdrawStake()
  await scenario1.connect(addr1).withdrawReward()

  await scenario1.connect(addr2).withdrawStake()
  await expect(scenario1.connect(addr2).stake({value: hre.ethers.utils.parseEther("1")}))
    .to.be.revertedWith("You cannot stake!")
  await scenario1.connect(addr2).withdrawReward()
  
  await scenario1.connect(addr3).withdrawReward()  
  await expect(scenario1.connect(addr3).stake({value: hre.ethers.utils.parseEther("1")}))
    .to.be.revertedWith("You cannot stake!")
  await scenario1.connect(addr3).withdrawStake()

  console.log("We can withdraw all funds now that 12 hours have passed!")

  // Try to re-withdraw
  await expect(scenario1.connect(addr1).withdrawStake()).to.be.revertedWith("No Value to Unstake")
  await expect(scenario1.connect(addr1).withdrawReward()).to.be.revertedWith("No Stake Reward to Claim")

  console.log("Could not re-withdraw")

  /// Check balances of people
  tbaddr1 = await token.balanceOf(addr1.address);
  tbaddr2 = await token.balanceOf(addr2.address);
  tbaddr3 = await token.balanceOf(addr3.address);

  expect(tbaddr1).to.equal(hre.ethers.utils.parseEther("200"));
  expect(tbaddr2).to.equal(hre.ethers.utils.parseEther("2000"));
  expect(tbaddr3).to.equal(hre.ethers.utils.parseEther("20000"));

  console.log("Token values match expected!")

  /// Have one person restake
  await scenario1.connect(addr1).stake({value: hre.ethers.utils.parseEther("1")});

  console.log("Address able to re-stake.")
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
