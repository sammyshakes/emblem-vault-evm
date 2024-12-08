// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title IVaultBeacon
 * @notice Interface for vault beacon contracts
 */
interface IVaultBeacon {
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
     * @notice Check if interface is supported
     * @param interfaceId The interface identifier
     * @return bool True if the interface is supported
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

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
