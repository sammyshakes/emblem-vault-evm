// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title IERC20 Interface
/// @notice Standard interface for ERC20 tokens
/// @dev Interface for the basic functionality of an ERC20 token
interface IERC20 {
    /// @notice Get the total supply of the token
    /// @return The total supply
    function totalSupply() external view returns (uint256);

    /// @notice Get the balance of an account
    /// @param account The address to query
    /// @return The balance of the account
    function balanceOf(address account) external view returns (uint256);

    /// @notice Transfer tokens to a specified address
    /// @param to The address to transfer to
    /// @param amount The amount to transfer
    /// @return True if the transfer was successful
    function transfer(address to, uint256 amount) external returns (bool);

    /// @notice Get the amount of tokens that an owner allowed to a spender
    /// @param owner The address that owns the tokens
    /// @param spender The address that can spend the tokens
    /// @return The amount of tokens still available for the spender
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Approve a spender to spend tokens
    /// @param spender The address that can spend the tokens
    /// @param amount The amount of tokens to allow
    /// @return True if the approval was successful
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Transfer tokens from one address to another
    /// @param from The address to transfer from
    /// @param to The address to transfer to
    /// @param amount The amount to transfer
    /// @return True if the transfer was successful
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    /// @notice Emitted when tokens are transferred
    /// @param from The address tokens are transferred from
    /// @param to The address tokens are transferred to
    /// @param value The amount of tokens transferred
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @notice Emitted when allowance is set
    /// @param owner The address that owns the tokens
    /// @param spender The address that can spend the tokens
    /// @param value The amount of tokens allowed
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
