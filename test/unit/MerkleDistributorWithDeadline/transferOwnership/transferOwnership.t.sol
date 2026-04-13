// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import {MintableERC20} from "contracts/test/MintableERC20.sol";
import {IMerkleDistributor} from "contracts/interfaces/IMerkleDistributor.sol";
import {MerkleDistributorWithDeadline} from "contracts/MerkleDistributorWithDeadline.sol";
import {TestMerkleTree} from "../../../utils/TestMerkleTree.sol";

contract MerkleDistributorWithDeadlineRenounceOwnershipTest is
    Test,
    TestMerkleTree
{
    address token;
    bytes32 root;
    Claim claim;

    MerkleDistributorWithDeadline distributor;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function setUp() external {
        MintableERC20 tokenContract = new MintableERC20("Test Token", "TTK");
        token = address(tokenContract);
        root = MERKLE_ROOT;
        distributor = new MerkleDistributorWithDeadline(
            token,
            root,
            block.timestamp + 1 days
        );
        tokenContract.mint(address(distributor), type(uint256).max);
        claim = claims[0];
    }

    function test_RevertWhen_TheCallerIsNotTheOwner() external {
        address notOwner = address(0x123);
        vm.assertNotEq(distributor.owner(), notOwner);

        // It should revert
        vm.prank(notOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        distributor.transferOwnership(address(0x456));
    }

    modifier whenTheCallerIsTheOwner() {
        // Ensure that the caller is the owner of the contract
        vm.assertEq(distributor.owner(), address(this));
        _;
    }

    function test_RevertWhen_TheNewOwnerIsTheZeroAddress()
        external
        whenTheCallerIsTheOwner
    {
        // It should revert
        vm.expectRevert("Ownable: new owner is the zero address");
        distributor.transferOwnership(address(0));
    }

    function test_WhenTheNewOwnerIsAValidAddress()
        external
        whenTheCallerIsTheOwner
    {
        address newOwner = address(0x456);
        vm.expectEmit(true, true, true, true);
        emit OwnershipTransferred(address(this), newOwner);
        distributor.transferOwnership(newOwner);

        // The new owner should be set correctly
        vm.assertEq(distributor.owner(), newOwner);
    }
}
