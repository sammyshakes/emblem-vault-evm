// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "../libraries/LibErrors.sol";

/**
 * @title VaultBeacon
 * @notice Beacon contract for vault implementations
 * @dev Follows EIP-1967 beacon pattern
 */
contract VaultBeacon is IERC165 {
    // Events
    event ImplementationUpgraded(
        address indexed oldImplementation, address indexed newImplementation
    );
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // State variables
    address public implementation;
    address public owner;

    // Modifiers
    modifier onlyOwner() {
        if (msg.sender != owner) revert LibErrors.Unauthorized(msg.sender);
        _;
    }

    /**
     * @notice Constructor
     * @param _implementation Initial implementation address
     */
    constructor(address _implementation) {
        LibErrors.revertIfZeroAddress(_implementation);

        // Verify implementation supports required interfaces
        if (!IERC165(_implementation).supportsInterface(type(IERC165).interfaceId)) {
            revert LibErrors.InvalidImplementation();
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
        LibErrors.revertIfZeroAddress(newImplementation);

        // Verify new implementation supports required interfaces
        if (!IERC165(newImplementation).supportsInterface(type(IERC165).interfaceId)) {
            revert LibErrors.InvalidImplementation();
        }

        emit ImplementationUpgraded(implementation, newImplementation);
        implementation = newImplementation;
    }

    /**
     * @notice Transfer ownership of the beacon
     * @param newOwner Address of the new owner
     */
    function transferOwnership(address newOwner) external onlyOwner {
        LibErrors.revertIfZeroAddress(newOwner);
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
