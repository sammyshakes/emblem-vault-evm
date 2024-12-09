// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title IVaultBeacon
 * @notice Interface for vault beacon contracts
 */
interface IVaultBeacon is IERC165 {
    /**
     * @notice Get the current implementation address
     * @return The address of the current implementation
     */
    function implementation() external view returns (address);

    /**
     * @notice Get the current owner
     * @return The address of the current owner
     */
    function owner() external view returns (address);

    /**
     * @notice Upgrade to a new implementation
     * @param newImplementation Address of the new implementation
     */
    function upgrade(address newImplementation) external;

    /**
     * @notice Transfer ownership of the beacon
     * @param newOwner Address of the new owner
     */
    function transferOwnership(address newOwner) external;

    /**
     * @dev Custom errors
     */
    error NotOwner();
    error ZeroAddress();
    error InvalidImplementation();

    /**
     * @notice Emitted when implementation is upgraded
     */
    event ImplementationUpgraded(address indexed oldImplementation, address indexed newImplementation);

    /**
     * @notice Emitted when ownership is transferred
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}
