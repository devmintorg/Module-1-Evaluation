//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Scenario3 {

    IERC20 private token;

    uint256 lockedTimeMinutes;
    /// Number of whole tokens to 1 ETH
    uint256[] exchangeRatesOverTime;
    uint256[] timesForExchangeRates;

    uint256 numberOfExchangeRates;

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

    constructor (IERC20 _token, uint256 _lockedTimeMinutes, uint256[] memory _exchangeRatesOverTime, uint256[] memory _timesForExchangeRates, uint256 _totalItems) {
        require(_exchangeRatesOverTime.length == _timesForExchangeRates.length, "You need an equal number of times and exchange rates");
        token = _token;
        exchangeRatesOverTime = _exchangeRatesOverTime;
        numberOfExchangeRates = _totalItems;
        for(uint i = 0; i < _totalItems; i++) {
            timesForExchangeRates.push(block.timestamp + (_timesForExchangeRates[i] * 1 minutes));
        } 
        lockedTimeMinutes = _lockedTimeMinutes * 1 minutes;
    }

    modifier checkRestake {
        _;
        if(currentStakes[msg.sender].etherStaked == 0 && currentStakes[msg.sender].stakeReward == 0) {
            currentStakes[msg.sender].cannotStake = false;
        }
    }

    function findExchangeRewardByTime() public view returns (uint256) {
        uint256 reward;
        for(uint256 i = numberOfExchangeRates; i > 0; i--) {
            if(block.timestamp <= timesForExchangeRates[i - 1]) {
                reward = exchangeRatesOverTime[i - 1];
            }
        }
        return reward;
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
        nextStake.unlockTime = block.timestamp + lockedTimeMinutes;
        uint256 exchangeRate = findExchangeRewardByTime();
        nextStake.stakeReward = exchangeRate * msg.value;
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

    //User withdraws fu ll stake reward from contract
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
