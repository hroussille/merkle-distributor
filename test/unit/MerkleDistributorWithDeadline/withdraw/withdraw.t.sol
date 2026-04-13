// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import {MintableERC20} from "contracts/test/MintableERC20.sol";
import {IMerkleDistributor} from "contracts/interfaces/IMerkleDistributor.sol";
import {MerkleDistributorWithDeadline} from "contracts/MerkleDistributorWithDeadline.sol";

contract MerkleDistributorWithDeadlineWithdrawTest is Test {

    address token;
    bytes32 root;
    uint256 endTime;

    MerkleDistributorWithDeadline distributor;

    function setUp() external {
        MintableERC20 tokenContract = new MintableERC20("Test Token", "TTK");
        token = address(tokenContract);
        root = keccak256(abi.encodePacked("merkle root"));
        endTime = block.timestamp + 1 days;
        distributor = new MerkleDistributorWithDeadline(token, root, endTime);
    }

    function test_RevertWhen_TheCallerIsNotTheOwner() external {
        // It should revert
        vm.prank(makeAddr("NotOwner"));
        vm.expectRevert("Ownable: caller is not the owner");
        distributor.withdraw();
    }

    modifier whenTheCallerIsTheOwner() {
        assertEq(distributor.owner(), address(this));
        _;
    }

    function test_RevertWhen_TheDeadlineHasNotPassed() external whenTheCallerIsTheOwner {
        // It should revert
        vm.expectRevert(IMerkleDistributor.NoWithdrawDuringClaim.selector);
        distributor.withdraw();
    }

    function test_WhenTheDeadlineHasPassed() external whenTheCallerIsTheOwner {
        // Sent tokens to the distributor
        MintableERC20(token).mint(address(distributor), 100);
        vm.assertEq(MintableERC20(distributor.token()).balanceOf(address(distributor)), 100);
        vm.assertEq(MintableERC20(distributor.token()).balanceOf(address(this)), 0);

        // It should withdraw all remaining tokens to the owner
        vm.warp(endTime + 1);
        distributor.withdraw();
        vm.assertEq(MintableERC20(distributor.token()).balanceOf(address(distributor)), 0);
        vm.assertEq(MintableERC20(distributor.token()).balanceOf(address(this)), 100);
    }
}
