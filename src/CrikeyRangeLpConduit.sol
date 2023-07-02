// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "CrocSwap-protocol/libraries/PoolSpecs.sol";
import "CrocSwap-protocol/interfaces/ICrocLpConduit.sol";
import "solmate/tokens/ERC20.sol";

contract CrikeyRangeLpConduit is ERC20, ICrocLpConduit {
    bytes32 public immutable poolHash;
    address public immutable baseToken;
    address public immutable quoteToken;
    uint256 public immutable poolType;

    constructor(address base, address quote, uint256 poolIdx) ERC20("Croc Range LP ERC20 Token", "LP-CrocRange", 18) {
        require(quote != address(0) && base != quote && quote > base, "Invalid Token Pair");

        baseToken = base;
        quoteToken = quote;
        poolType = poolIdx;
        poolHash = PoolSpecs.encodeKey(base, quote, poolIdx);
    }

    function depositCrocLiq(address sender, bytes32 pool, int24 lowerTick, int24 upperTick, uint128 seeds, uint64)
        public
        override
        returns (bool)
    {
        require(pool == poolHash, "Wrong pool");
        require(lowerTick != 0 && upperTick != 0, "Non-Range LP Deposit");
        _mint(sender, seeds);
        return true;
    }

    function withdrawCrocLiq(address sender, bytes32 pool, int24 lowerTick, int24 upperTick, uint128 seeds, uint64)
        public
        override
        returns (bool)
    {
        require(pool == poolHash, "Wrong pool");
        require(lowerTick != 0 && upperTick != 0, "Non-Range LP Deposit");
        _burn(sender, seeds);
        return true;
    }
}