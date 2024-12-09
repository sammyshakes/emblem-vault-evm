// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title VaultBeacon
 * @notice Beacon contract for vault implementations
 * @dev Follows EIP-1967 beacon pattern
 */
contract VaultBeacon is IERC165 {
    // Events
    event ImplementationUpgraded(address indexed oldImplementation, address indexed newImplementation);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // State variables
    address public implementation;
    address public owner;

    // Custom errors
    error NotOwner();
    error ZeroAddress();
    error InvalidImplementation();

    // Modifiers
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    /**
     * @notice Constructor
     * @param _implementation Initial implementation address
     */
    constructor(address _implementation) {
        if (_implementation == address(0)) revert ZeroAddress();

        // Verify implementation supports required interfaces
        if (!IERC165(_implementation).supportsInterface(type(IERC165).interfaceId)) {
            revert InvalidImplementation();
        }

        implementation = _implementation;
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @notice Upgrade the implementation
     * @param newImplementation Address of the new implementation
     */
    function upgrade(address newImplementation) external onlyOwner {
        if (newImplementation == address(0)) revert ZeroAddress();

        // Verify new implementation supports required interfaces
        if (!IERC165(newImplementation).supportsInterface(type(IERC165).interfaceId)) {
            revert InvalidImplementation();
        }

        emit ImplementationUpgraded(implementation, newImplementation);
        implementation = newImplementation;
    }

    /**
     * @notice Transfer ownership of the beacon
     * @param newOwner Address of the new owner
     */
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert ZeroAddress();
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @notice Interface support check
     * @param interfaceId Interface identifier
     * @return bool True if interface is supported
     */
    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

/**
 * @title ERC721VaultBeacon
 * @notice Beacon for ERC721 vault implementations
 */
contract ERC721VaultBeacon is VaultBeacon {
    constructor(address _implementation) VaultBeacon(_implementation) {}
}

/**
 * @title ERC1155VaultBeacon
 * @notice Beacon for ERC1155 vault implementations
 */
contract ERC1155VaultBeacon is VaultBeacon {
    constructor(address _implementation) VaultBeacon(_implementation) {}
}
