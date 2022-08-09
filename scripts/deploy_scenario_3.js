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
  const Scenario3 = await hre.ethers.getContractFactory("Scenario3");
  //const scenario3 = await Scenario3.deploy();
  const scenario3 = await Scenario3.deploy(token.address, (60 * 24), [100, 50, 25], [60*24*7, 60*24*14, 60*24*21], 3);

  console.log("Scenario3 deployed to:", scenario3.address);

  const scenario3Supply = hre.ethers.utils.parseEther("500000");
  await token.connect(deployer).transfer(scenario3.address, scenario3Supply);

  scenario3Balance = await token.balanceOf(scenario3.address)
  console.log("Scenario3 Balance: ", hre.ethers.utils.formatEther(scenario3Balance));

  /// Have three accounts go and stake tokens at different levels
  /// Have a few try to pull out early and fail
  /// Stake too much and too little

  await scenario3.connect(addr1).stake({value: hre.ethers.utils.parseEther("1")});
  await scenario3.connect(addr2).stake({value: hre.ethers.utils.parseEther("10")});
  // await scenario3.connect(addr3).stake({value: hre.ethers.utils.parseEther("100")});
  await expect(scenario3.connect(addr4).stake({value: hre.ethers.utils.parseEther("1000")}))
    .to.be.revertedWith("Sent Too Much ETH. Maximum 100 ETH");
  await expect(scenario3.connect(addr4).stake({value: 1000}))
    .to.be.revertedWith("Sent Too Little ETH. Minimum 1 ETH");
  await expect(scenario3.connect(addr1).stake({value: hre.ethers.utils.parseEther("1")}))
    .to.be.revertedWith("You cannot stake!")

  console.log("Added all stakes without errors!")

  /// Forward time 7 days
  await hre.network.provider.send("evm_increaseTime", [60*60*24*7]);
  await hre.network.provider.send("evm_mine");

  // addr3 stakes 100 ETH after 7 days, should get 5000 tokens when attempting to pull out
  await scenario3.connect(addr3).stake({value: hre.ethers.utils.parseEther("100")});

  /// Have addr3 try to pull out and fail
  await expect(scenario3.connect(addr3).withdrawStake())
    .to.be.revertedWith("Cannot Withdraw Yet")

  // have addr1 and addr2 pull out
  await scenario3.connect(addr1).withdrawStake()
  console.log("addr1 has withdrawn steak");

  await scenario3.connect(addr1).withdrawReward()
  console.log("addr1 has withdrawn reward");

  await scenario3.connect(addr2).withdrawStake()
  await scenario3.connect(addr2).withdrawReward()

  // addr3 already staked
  await expect(scenario3.connect(addr3).stake({value: hre.ethers.utils.parseEther("1")}))
    .to.be.revertedWith("You cannot stake!")

  console.log("7 days have passed so far; addr1 and 2 staked at the beginning so they get 100 MYT per ETH, but addr3, having staked 7 days after, gets 50 MYT per ETH");

  /// fast forward 24 hours so that addr3 can withdraw
  await hre.network.provider.send("evm_increaseTime", [60*60*24]);

  /// Have addr3 pull out
  await scenario3.connect(addr3).withdrawStake()
  await scenario3.connect(addr3).withdrawReward()

  // await scenario3.connect(addr2).withdrawStake()
  // await expect(scenario3.connect(addr2).stake({value: hre.ethers.utils.parseEther("1")}))
  //   .to.be.revertedWith("You cannot stake!")
  // await scenario3.connect(addr2).withdrawReward()
  
  // await scenario3.connect(addr3).withdrawReward()  
  // await expect(scenario3.connect(addr3).stake({value: hre.ethers.utils.parseEther("1")}))
  //   .to.be.revertedWith("You cannot stake!")
  // await scenario3.connect(addr3).withdrawStake()

  console.log("Able to withdraw all funds")

  // Try to re-withdraw
  await expect(scenario3.connect(addr1).withdrawStake()).to.be.revertedWith("No Value to Unstake")
  await expect(scenario3.connect(addr1).withdrawReward()).to.be.revertedWith("No Stake Reward to Claim")

  await expect(scenario3.connect(addr2).withdrawStake()).to.be.revertedWith("No Value to Unstake")
  await expect(scenario3.connect(addr2).withdrawReward()).to.be.revertedWith("No Stake Reward to Claim")

  await expect(scenario3.connect(addr3).withdrawStake()).to.be.revertedWith("No Value to Unstake")
  await expect(scenario3.connect(addr3).withdrawReward()).to.be.revertedWith("No Stake Reward to Claim")

  console.log("Could not re-withdraw")

  /// Check balances of people
  tbaddr1 = await token.balanceOf(addr1.address);
  tbaddr2 = await token.balanceOf(addr2.address);
  tbaddr3 = await token.balanceOf(addr3.address);

  expect(tbaddr1).to.equal(hre.ethers.utils.parseEther("100"));
  expect(tbaddr2).to.equal(hre.ethers.utils.parseEther("1000"));
  expect(tbaddr3).to.equal(hre.ethers.utils.parseEther("5000"));

  console.log("Token values match expected!")

  /// Have one person restake
  await scenario3.connect(addr1).stake({value: hre.ethers.utils.parseEther("1")});

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
