// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.17;

import {IMerkleDistributor} from "./interfaces/IMerkleDistributor.sol";
import {MerkleDistributor} from "./MerkleDistributor.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MerkleDistributorWithDeadline is MerkleDistributor, Ownable {
    using SafeERC20 for IERC20;

    uint256 public immutable endTime;

    constructor(address token_, bytes32 merkleRoot_, uint256 endTime_) MerkleDistributor(token_, merkleRoot_) {
        if (endTime_ <= block.timestamp) revert IMerkleDistributor.EndTimeInPast();
        endTime = endTime_;
    }

    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) public override {
        if (block.timestamp > endTime) revert IMerkleDistributor.ClaimWindowFinished();
        super.claim(index, account, amount, merkleProof);
    }

    function withdraw() external onlyOwner {
        /// IfStatementMutation(`block.timestamp < endTime` |==> `true`) of: `if (block.timestamp < endTime) revert IMerkleDistributor.NoWithdrawDuringClaim();`
        if (true) revert IMerkleDistributor.NoWithdrawDuringClaim();
        IERC20(token).safeTransfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }
}