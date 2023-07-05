// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {CrikeyRangeLpConduit} from "../CrikeyRangeLpConduit.sol";

contract CrikeyRangeLpConduitTest is Test {
    address owner;
    address sender;
    address crocLpContract;
    bytes32 expectedPoolHash;
    bytes32 wrongPoolHash;
    CrikeyRangeLpConduit testConduit;

    function setUp() public {
        owner = 0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84;
        sender = address(0x1);
        crocLpContract = address(0xBEEF);
        expectedPoolHash = 0xf14b97521d2ba8399ee7b9be53ec1eb470416373ed113505baff7e5a63825ced;
        wrongPoolHash = 0xf14b97521d2ba8399ee7b9be53ec1eb470416373ed113505baff7e5a6382DEAD;
        testConduit =
            new CrikeyRangeLpConduit(crocLpContract, address(0), 0xa6024a169C2fC6BFD0fEabEe150b86d268aAf4CE, 36000);
    }

    function test_OwnerCanSetCrocswap() public {
        assertEq(testConduit.crocLpContract(), crocLpContract);
        testConduit.setCrocswap(address(0x2));
        assertEq(testConduit.crocLpContract(), address(0x2));
    }

    function test_RevertIfNonownerSetCrocswap() public {
        vm.prank(address(0x2));
        vm.expectRevert("UNAUTHORIZED");
        testConduit.setCrocswap(address(0x2));
        assertEq(testConduit.crocLpContract(), crocLpContract);
    }

    function test_CrocswapCanDepositCrocLiq() public {
        vm.prank(crocLpContract);
        testConduit.depositCrocLiq(sender, expectedPoolHash, 0, 8000, 1000, 0);
        assertEq(testConduit.balanceOf(sender), 1000);
    }

    function test_RevertDepositIfNotCrocswap() public {
        vm.expectRevert("UNAUTHORIZED");
        testConduit.depositCrocLiq(sender, expectedPoolHash, 0, 8000, 1000, 0);
    }

    function test_RevertDepositIfWrongPool() public {
        vm.prank(crocLpContract);
        vm.expectRevert("Wrong pool");
        testConduit.depositCrocLiq(owner, wrongPoolHash, 0, 8000, 1000, 0);
    }

    function test_RevertDepositIfAmbientLp() public {
        vm.prank(crocLpContract);
        vm.expectRevert("Non-Range LP Deposit");
        testConduit.depositCrocLiq(owner, expectedPoolHash, 0, 0, 1000, 0);
    }

    function test_CrocswapCanWithdrawCrocLiq() public {
        vm.prank(crocLpContract);
        testConduit.depositCrocLiq(sender, expectedPoolHash, 0, 8000, 1000, 0);
        assertEq(testConduit.balanceOf(sender), 1000);

        vm.prank(crocLpContract);
        testConduit.withdrawCrocLiq(sender, expectedPoolHash, 0, 8000, 1000, 0);
        assertEq(testConduit.balanceOf(sender), 0);
    }

    function test_RevertWithdrawIfWrongPool() public {
        vm.prank(crocLpContract);
        testConduit.depositCrocLiq(owner, expectedPoolHash, 0, 8000, 1000, 0);

        vm.prank(crocLpContract);
        vm.expectRevert("Wrong pool");
        testConduit.withdrawCrocLiq(owner, wrongPoolHash, 0, 8000, 1000, 0);
    }

    function test_RevertWithdrawIfAmbientLp() public {
        vm.prank(crocLpContract);
        testConduit.depositCrocLiq(owner, expectedPoolHash, 0, 8000, 1000, 0);

        vm.prank(crocLpContract);
        vm.expectRevert("Non-Range LP Deposit");
        testConduit.withdrawCrocLiq(owner, expectedPoolHash, 0, 0, 1000, 0);
    }

    function test_RevertIfWithdrawGreaterThanBalance() public {
        vm.prank(crocLpContract);
        testConduit.depositCrocLiq(owner, expectedPoolHash, 0, 8000, 500, 0);

        vm.prank(crocLpContract);
        vm.expectRevert("Insufficient LP Token Balance");
        testConduit.withdrawCrocLiq(owner, expectedPoolHash, 0, 8000, 1000, 0);
    }

    function test_RevertWithdrawIfNotOwnerOrAuthority() public {
        vm.prank(crocLpContract);
        testConduit.depositCrocLiq(sender, expectedPoolHash, 0, 8000, 1000, 0);

        vm.prank(sender);
        vm.expectRevert("UNAUTHORIZED");
        testConduit.withdrawCrocLiq(sender, expectedPoolHash, 0, 8000, 1000, 0);
    }
}
