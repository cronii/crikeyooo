// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {CrikeyToken} from "../CrikeyToken.sol";
import {LinearVester, IERC20} from "../LinearVester.sol";

contract LinearVesterTest is Test {
    CrikeyToken testToken;
    LinearVester testVester;
    address deployer = 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496;
    uint256 totalSupply = 100000000 * 10 ** 18;

    function setUp() public {
        testToken = new CrikeyToken("Crikey Token", "CRIKEY", 18);
        testVester = new LinearVester(IERC20(address(testToken)));
    }

    function test_CreateLockup() public {
        assertEq(testToken.balanceOf(deployer), totalSupply);
        testToken.approve(address(testVester), totalSupply);
        testVester.createLockup(totalSupply, 100000, 200000);
        assertEq(testToken.balanceOf(deployer), 0);
        assertEq(testToken.balanceOf(address(testVester)), totalSupply);
    }

    function test_RevertCreateLockupIfNotBeneficiary() public {
        vm.prank(address(0xBEEF));
        vm.expectRevert("UNAUTHORIZED");
        testVester.createLockup(100000000, 100000, 200000);
    }

    function test_RevertCreateLockupIfAlreadyLocked() public {
        testToken.approve(address(testVester), totalSupply);
        testVester.createLockup(100000000, 100000, 200000);
        vm.expectRevert("Already Locked");
        testVester.createLockup(100000000, 100000, 200000);
    }

    function test_RevertCreateLockupIfInsufficientBalance() public {
        uint256 tooMuch = 200000000 * 10 ** 18;
        testToken.approve(address(testVester), totalSupply);
        vm.expectRevert("Insufficient Balance");
        testVester.createLockup(tooMuch, 100000, 200000);
    }

    function test_RevertCreateLockupIfInvalidLockPeriod() public {
        testToken.approve(address(testVester), totalSupply);
        vm.expectRevert("Invalid Lock Period");
        testVester.createLockup(totalSupply, 200000, 100000);
    }

    function test_GetUnlockedFull() public {
        testToken.approve(address(testVester), totalSupply);
        testVester.createLockup(totalSupply, 100000, 200000);
        vm.warp(200001);
        assertEq(testVester.getUnlocked(), totalSupply);
    }

    function test_GetUnlockedHalf() public {
        testToken.approve(address(testVester), totalSupply);
        testVester.createLockup(totalSupply, 100000, 200000);
        vm.warp(150000);
        assertEq(testVester.getUnlocked(), totalSupply / 2);
    }

    function test_WithdrawVested() public {
        testToken.approve(address(testVester), totalSupply);
        testVester.createLockup(totalSupply, 100000, 200000);
        assertEq(testToken.balanceOf(deployer), 0);
        assertEq(testToken.balanceOf(address(testVester)), totalSupply);

        vm.warp(200001);
        testVester.withdrawVested();
        assertEq(testToken.balanceOf(deployer), totalSupply);
        assertEq(testToken.balanceOf(address(testVester)), 0);
    }

    function test_RevertWithdrawIfNotBeneficiary() public {
        testToken.approve(address(testVester), totalSupply);
        testVester.createLockup(totalSupply, 100000, 200000);

        vm.warp(200001);
        vm.prank(address(0xBEEF));
        vm.expectRevert("UNAUTHORIZED");
        testVester.withdrawVested();
    }
}
