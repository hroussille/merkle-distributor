// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import {IMerkleDistributor} from "contracts/interfaces/IMerkleDistributor.sol";
import {MerkleDistributorWithDeadline} from "contracts/MerkleDistributorWithDeadline.sol";

contract MerkleDistributorWithDeadlineConstructorTest is Test {

    address token;
    bytes32 root;
    uint256 endTime;

    MerkleDistributorWithDeadline distributor;

    function setUp() external {
        token = makeAddr("Token");
        root = keccak256(abi.encodePacked("merkle root"));
        endTime = block.timestamp + 1 days;

        distributor = new MerkleDistributorWithDeadline(token, root, endTime);
    }

    function test_RevertWhen_TheDeadlineIsBeforeTheCurrentTime() external  {
        // It should revert
        vm.expectRevert(IMerkleDistributor.EndTimeInPast.selector);
        new MerkleDistributorWithDeadline(token, root, block.timestamp - 1);
    }

    function test_WhenTheDeadlineIsAfterTheCurrentTime() external view {
        // It should set the token to the provided address
        vm.assertEq(distributor.token(), token);

        // It should set the merkle root to the given root
        vm.assertEq(distributor.merkleRoot(), root);

        // It should set the deadline to the given timestamp
        vm.assertEq(distributor.endTime(), endTime);
    }
}
