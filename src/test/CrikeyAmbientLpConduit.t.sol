// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {CrikeyAmbientLpConduit} from "../CrikeyAmbientLpConduit.sol";

contract CrikeyAmbientLpConduitTest is Test {
    address owner = 0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84;
    address sender = address(0x1);
    address crocLpContract = address(0xBEEF);
    bytes32 expectedPoolHash = 0xf14b97521d2ba8399ee7b9be53ec1eb470416373ed113505baff7e5a63825ced;
    bytes32 wrongPoolHash = 0xf14b97521d2ba8399ee7b9be53ec1eb470416373ed113505baff7e5a6382DEAD;
    CrikeyAmbientLpConduit testConduit;

    function setUp() public {
        testConduit = new CrikeyAmbientLpConduit(crocLpContract, address(0), 0xa6024a169C2fC6BFD0fEabEe150b86d268aAf4CE, 36000);
    }

    function test_OwnerCanSetCrocswap() public {
        assertEq(testConduit.crocLpContract(), crocLpContract);
        testConduit.setCrocswap(address(0x2));
        assertEq(testConduit.crocLpContract(), address(0x2));
    }

    function test_RevertSetCrocswapIfNotOwner() public {
        vm.prank(crocLpContract);
        vm.expectRevert("UNAUTHORIZED");
        testConduit.setCrocswap(address(0x2));
        assertEq(testConduit.crocLpContract(), crocLpContract);
    }

    function test_CrocswapCanDepositCrocLiq() public {
        vm.prank(crocLpContract);
        testConduit.depositCrocLiq(sender, expectedPoolHash, 0, 0, 1000, 0);
        assertEq(testConduit.balanceOf(sender), 1000);
    }

    function test_RevertDepositIfNotCrocswap() public {
        vm.expectRevert("UNAUTHORIZED");
        testConduit.depositCrocLiq(owner, expectedPoolHash, 0, 0, 1000, 0);
    }

    function test_RevertDepositIfWrongPool() public {
        vm.prank(crocLpContract);
        vm.expectRevert("Wrong pool");
        testConduit.depositCrocLiq(owner, wrongPoolHash, 0, 0, 1000, 0);
    }

    function test_RevertDepositIfRangeLp() public {
        vm.prank(crocLpContract);
        vm.expectRevert("Non-Ambient LP Deposit");
        testConduit.depositCrocLiq(owner, expectedPoolHash, 0, 80000, 1000, 0);
    }

    function test_CrocswapCanWithdrawCrocLiq() public {
        vm.startPrank(crocLpContract);
        testConduit.depositCrocLiq(sender, expectedPoolHash, 0, 0, 1000, 0);
        assertEq(testConduit.balanceOf(sender), 1000);

        testConduit.withdrawCrocLiq(sender, expectedPoolHash, 0, 0, 1000, 0);
        assertEq(testConduit.balanceOf(sender), 0);
    }

    function test_RevertWithdrawIfWrongPool() public {
        vm.startPrank(crocLpContract);
        testConduit.depositCrocLiq(owner, expectedPoolHash, 0, 0, 1000, 0);

        vm.expectRevert("Wrong pool");
        testConduit.withdrawCrocLiq(owner, wrongPoolHash, 0, 0, 1000, 0);
    }

    function test_RevertWithdrawIfRangeLp() public {
        vm.startPrank(crocLpContract);
        testConduit.depositCrocLiq(owner, expectedPoolHash, 0, 0, 1000, 0);

        vm.expectRevert("Non-Ambient LP Deposit");
        testConduit.withdrawCrocLiq(owner, expectedPoolHash, 0, 80000, 1000, 0);
    }

    function test_RevertIfWithdrawGreaterThanBalance() public {
        vm.startPrank(crocLpContract);
        testConduit.depositCrocLiq(owner, expectedPoolHash, 0, 0, 500, 0);

        vm.expectRevert("Insufficient LP Token Balance");
        testConduit.withdrawCrocLiq(owner, expectedPoolHash, 0, 0, 1000, 0);
    }

    function test_RevertWithdrawIfNotCrocswap() public {
        vm.prank(crocLpContract);
        testConduit.depositCrocLiq(sender, expectedPoolHash, 0, 0, 1000, 0);

        vm.prank(sender);
        vm.expectRevert("UNAUTHORIZED");
        testConduit.withdrawCrocLiq(sender, expectedPoolHash, 0, 0, 1000, 0);
    }
}
