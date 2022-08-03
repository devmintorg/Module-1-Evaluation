//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {
    constructor(
        uint256 initialSupply,
        string memory tokenName,
        string memory tokenAbbr
    ) ERC20(tokenName, tokenAbbr) {
        _mint(msg.sender, initialSupply);
    }
}
