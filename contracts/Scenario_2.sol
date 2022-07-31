//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Staker2 {

    IERC20 private token;

    uint256 lockedTimeMinutes;
    /// Number of whole tokens to 1 ETH
    uint256 exchangeRate;

    struct userStake {
        bool cannotStake;
        uint256 etherStaked;
        uint256 stakeReward;
        uint256 unlockTime; 
    }
    mapping(address => userStake) currentStakes;

    event userStaked(address indexed _user, uint256 etherStakes);
    event userWithdrawStake(address indexed _user, uint256 etherStakes);
    event userWithdrawReward(address indexed _user, uint256 stakeReward);

    constructor (IERC20 _token, uint256 _exchangeRate, uint256 _lockedTimeMinutes) {
        token = _token;
        exchangeRate = _exchangeRate;
        lockedTimeMinutes = _lockedTimeMinutes * 1 minutes;
    }

    modifier checkRestake {
        _;
        if(currentStakes[msg.sender].etherStaked == 0 && currentStakes[msg.sender].stakeReward == 0) {
            currentStakes[msg.sender].cannotStake = false;
        }
    }

    // User Stakes Token in Smart Contract
    function stake() payable external {
        //Require that the can stake
        require(currentStakes[msg.sender].cannotStake == false, "You cannot stake!");

        // Require ETH is between 1 and 100 ETH
        require(msg.value >= 1 ether, "Sent Too Little ETH. Minimum 1 ETH");
        require(msg.value <= 100 ether, "Sent Too Much ETH. Maximum 100 ETH");

        // Create new userStake value
        userStake memory nextStake;

        nextStake.cannotStake = true;
        nextStake.etherStaked = msg.value;
        nextStake.stakeReward = msg.value * exchangeRate;
        nextStake.unlockTime = block.timestamp + lockedTimeMinutes;

        currentStakes[msg.sender] = nextStake;

        // Emit Staking Event
        emit userStaked(msg.sender, msg.value);
    }

    //User withdraws full stake from contract
    function withdrawStake() payable external checkRestake {
        //Check Time Requirement
        require(block.timestamp >= currentStakes[msg.sender].unlockTime, "Cannot Withdraw Yet");
        require(currentStakes[msg.sender].etherStaked > 0, "No Value to Unstake");

        uint256 userStakedAmount = currentStakes[msg.sender].etherStaked;
        currentStakes[msg.sender].etherStaked = 0;

        (bool success, ) = msg.sender.call{value: userStakedAmount}("");
        require(success, "Call Failed");

        //Emit Withdraw Event
        emit userWithdrawStake(msg.sender, userStakedAmount);
    }

    //User withdraws full stake reward from contract
    function withdrawReward() external checkRestake {
        //Check Time Requirement
        require(block.timestamp >= currentStakes[msg.sender].unlockTime, "Cannot Withdraw Yet");
        require(currentStakes[msg.sender].stakeReward > 0, "No Stake Reward to Claim");

        uint256 userRewardAmount = currentStakes[msg.sender].stakeReward;
        currentStakes[msg.sender].stakeReward = 0;

        token.transfer(msg.sender, userRewardAmount);

        //Emit Withdraw Event
        emit userWithdrawReward(msg.sender, userRewardAmount);
    }

}
