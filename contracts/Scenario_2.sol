//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Staker2 {
    IERC20 private token1;
    IERC20 private token2;

    uint256 lockedTimeMinutes;
    /// Number of whole tokens to 1 ETH
    uint256 exchangeRate1;
    uint256 exchangeRate2;

    struct userStake {
        bool cannotStake;
        uint256 etherStaked;
        uint256 stakeReward1;
        uint256 stakeReward2;
        uint256 unlockTime;
    }
    mapping(address => userStake) currentStakes;

    event userStaked(address indexed _user, uint256 etherStakes);
    event userWithdrawStake(address indexed _user, uint256 etherStakes);
    event userWithdrawReward(
        address indexed _user,
        uint256 stakeReward1,
        uint256 stakeReward2
    );

    constructor(
        IERC20 _token1,
        uint256 _exchangeRate1,
        IERC20 _token2,
        uint256 _exchangeRate2,
        uint256 _lockedTimeMinutes
    ) {
        token1 = _token1;
        token2 = _token2;
        exchangeRate1 = _exchangeRate1;
        exchangeRate2 = _exchangeRate2;
        lockedTimeMinutes = _lockedTimeMinutes * 1 minutes;
    }

    modifier checkRestake() {
        _;
        if (
            currentStakes[msg.sender].etherStaked == 0 &&
            currentStakes[msg.sender].stakeReward == 0
        ) {
            currentStakes[msg.sender].cannotStake = false;
        }
    }

    // User Stakes Token in Smart Contract
    function stake() external payable {
        //Require that the can stake
        require(
            currentStakes[msg.sender].cannotStake == false,
            "You cannot stake!"
        );

        // Require ETH is between 1 and 100 ETH
        require(msg.value >= 1 ether, "Sent Too Little ETH. Minimum 1 ETH");
        require(msg.value <= 100 ether, "Sent Too Much ETH. Maximum 100 ETH");

        // Create new userStake value
        userStake memory nextStake;

        nextStake.cannotStake = true;
        nextStake.etherStaked = msg.value;
        nextStake.stakeReward1 = msg.value * exchangeRate1;
        nextStake.stakeReward2 = msg.value * exchangeRate2;
        nextStake.unlockTime = block.timestamp + lockedTimeMinutes;

        currentStakes[msg.sender] = nextStake;

        // Emit Staking Event
        emit userStaked(msg.sender, msg.value);
    }

    //User withdraws full stake from contract
    function withdrawStake() external payable checkRestake {
        //Check Time Requirement
        require(
            block.timestamp >= currentStakes[msg.sender].unlockTime,
            "Cannot Withdraw Yet"
        );
        require(
            currentStakes[msg.sender].etherStaked > 0,
            "No Value to Unstake"
        );

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
        require(
            block.timestamp >= currentStakes[msg.sender].unlockTime,
            "Cannot Withdraw Yet"
        );
        require(
            currentStakes[msg.sender].stakeReward > 0,
            "No Stake Reward to Claim"
        );

        uint256 userRewardAmount1 = currentStakes[msg.sender].stakeReward1;
        uint256 userRewardAmount2 = currentStakes[msg.sender].stakeReward2;
        currentStakes[msg.sender].stakeReward1 = 0;
        currentStakes[msg.sender].stakeReward2 = 0;

        token1.transfer(msg.sender, userRewardAmount1);
        token2.transfer(msg.sender, userRewardAmount2);

        //Emit Withdraw Event
        emit userWithdrawReward(
            msg.sender,
            userRewardAmount1,
            userRewardAmount2
        );
    }
}

// //SPDX-License-Identifier: MIT
// pragma solidity ^0.8.0 <0.9.0;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// contract Staker2 {
//     uint256 lockedTimeMinutes;

//     struct tokenStruct {
//         uint256 exchangeRate;
//         IERC20 token;
//     }

//     mapping(uint256 => tokenStruct) rewards;

//     struct userStake {
//         bool cannotStake;
//         uint256 etherStaked;
//         uint256[2] stakeRewardAmounts;
//         uint256 unlockTime;
//     }
//     mapping(address => userStake) currentStakes;

//     event userStaked(address indexed _user, uint256 etherStakes);
//     event userWithdrawStake(address indexed _user, uint256 etherStakes);
//     event userWithdrawReward(
//         address indexed _user,
//         uint256[2] stakeRewardAmounts
//     );

//     constructor(
//         uint256 _numTokens,
//         tokenStruct[] memory _tokensObjects,
//         uint256 _lockedTimeMinutes
//     ) {
//         lockedTimeMinutes = _lockedTimeMinutes;

//         for (uint256 i = 0; i < _numTokens; i++) {
//             rewards[i].exchangeRate = _tokensObjects[i].exchangeRate;
//             rewards[i].token = _tokensObjects[i].token;
//         }
//     }

//     modifier checkRestake() {
//         _;
//         if (
//             currentStakes[msg.sender].etherStaked == 0 &&
//             currentStakes[msg.sender].stakeRewardAmounts.length == 0
//         ) {
//             currentStakes[msg.sender].cannotStake = false;
//         }
//     }

//     // User Stakes Token in Smart Contract
//     function stake() external payable {
//         //Require that the can stake
//         require(
//             currentStakes[msg.sender].cannotStake == false,
//             "You cannot stake!"
//         );

//         // Require ETH is between 1 and 100 ETH
//         require(msg.value >= 1 ether, "Sent Too Little ETH. Minimum 1 ETH");
//         require(msg.value <= 100 ether, "Sent Too Much ETH. Maximum 100 ETH");

//         // Create new userStake value
//         userStake memory nextStake;

//         nextStake.cannotStake = true;
//         nextStake.etherStaked = msg.value;
//         nextStake.unlockTime = block.timestamp + lockedTimeMinutes;
//         for (uint256 i = 0; i < 2; i++) {
//             nextStake.stakeRewardAmounts[i] =
//                 msg.value *
//                 rewards[i].exchangeRate;
//         }

//         currentStakes[msg.sender] = nextStake;

//         // Emit Staking Event
//         emit userStaked(msg.sender, msg.value);
//     }

//     //User withdraws full stake from contract
//     function withdrawStake() external payable checkRestake {
//         //Check Time Requirement
//         require(
//             block.timestamp >= currentStakes[msg.sender].unlockTime,
//             "Cannot Withdraw Stake Yet"
//         );
//         require(
//             currentStakes[msg.sender].etherStaked > 0,
//             "No Value to Unstake"
//         );

//         uint256 userStakedAmount = currentStakes[msg.sender].etherStaked;
//         currentStakes[msg.sender].etherStaked = 0;

//         (bool success, ) = msg.sender.call{value: userStakedAmount}("");
//         require(success, "Call Failed");

//         //Emit Withdraw Event
//         emit userWithdrawStake(msg.sender, userStakedAmount);
//     }

//     //User withdraws full stake reward from contract
//     function withdrawReward() external checkRestake {
//         require(
//             block.timestamp >= currentStakes[msg.sender].unlockTime,
//             "Cannot Withdraw Reward Yet"
//         );
//         require(
//             currentStakes[msg.sender].stakeRewardAmounts.length == 2,
//             "No Stake Reward to Claim"
//         );

//         uint256[2] memory userRewardAmount = currentStakes[msg.sender]
//             .stakeRewardAmounts;
//         for (uint256 i = 0; i < 2; i++) {
//             currentStakes[msg.sender].stakeRewardAmounts[0] = 0;
//         }
//         for (uint256 j = 0; j < 2; j++) {
//             rewards[j].token.transfer(msg.sender, userRewardAmount[j]);
//         }

//         //Emit Withdraw Event
//         emit userWithdrawReward(msg.sender, userRewardAmount);
//     }
// }
