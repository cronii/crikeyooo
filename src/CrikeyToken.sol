// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "solmate/tokens/ERC20.sol";

contract CrikeyToken is ERC20 {
    uint256 public currentTokenId;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) ERC20(_name, _symbol, _decimals) {
        _mint(msg.sender, 100000000 * 10 ** _decimals);
    }
}
