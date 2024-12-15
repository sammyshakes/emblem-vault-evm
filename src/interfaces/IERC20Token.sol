// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC20Token {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}
