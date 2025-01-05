// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract FailingETHReceiver {
    // Always revert when receiving ETH
    receive() external payable {
        revert("ETH transfer rejected");
    }

    fallback() external payable {
        revert("ETH transfer rejected");
    }
}
