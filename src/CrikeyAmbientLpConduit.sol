// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {PoolSpecs} from "CrocSwap-protocol/libraries/PoolSpecs.sol";
import {ICrocLpConduit} from "CrocSwap-protocol/interfaces/ICrocLpConduit.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {Auth, Authority} from "solmate/auth/Auth.sol";

contract CrikeyAmbientLpConduit is Auth, ERC20, ICrocLpConduit {
    bytes32 public immutable poolHash;
    address public immutable baseToken;
    address public immutable quoteToken;
    uint256 public immutable poolType;

    constructor(address base, address quote, uint256 poolIdx) ERC20("Croc Ambient LP ERC20 Token", "LP-CrocAmb", 18) Auth(msg.sender, Authority(address(0))) {
        require(quote != address(0) && base != quote && quote > base, "Invalid Token Pair");

        baseToken = base;
        quoteToken = quote;
        poolType = poolIdx;
        poolHash = PoolSpecs.encodeKey(base, quote, poolIdx);
    }

    function depositCrocLiq(address sender, bytes32 pool, int24 lowerTick, int24 upperTick, uint128 seeds, uint64)
        public
        override
        requiresAuth
        returns (bool)
    {
        require(pool == poolHash, "Wrong pool");
        require(lowerTick == 0 && upperTick == 0, "Non-Ambient LP Deposit");
        _mint(sender, seeds);
        return true;
    }

    function withdrawCrocLiq(address sender, bytes32 pool, int24 lowerTick, int24 upperTick, uint128 seeds, uint64)
        public
        override
        requiresAuth
        returns (bool)
    {
        require(pool == poolHash, "Wrong pool");
        require(lowerTick == 0 && upperTick == 0, "Non-Ambient LP Deposit");
        _burn(sender, seeds);
        return true;
    }
}
