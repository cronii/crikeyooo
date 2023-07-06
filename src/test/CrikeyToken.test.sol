// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {CrikeyToken} from "../CrikeyToken.sol";

contract CrikeyTokenTest is Test {
    address deployer;
    CrikeyToken testToken;

    function test_initToken() public {
        deployer = 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496;
        testToken = new CrikeyToken("Crikey Token", "CRIKEY", 18);

        assertEq(testToken.name(), "Crikey Token");
        assertEq(testToken.symbol(), "CRIKEY");
        assertEq(testToken.decimals(), 18);
        assertEq(testToken.totalSupply(), 100000000 * 10 ** testToken.decimals());
        assertEq(testToken.balanceOf(deployer), 100000000 * 10 ** testToken.decimals());
    }
}
