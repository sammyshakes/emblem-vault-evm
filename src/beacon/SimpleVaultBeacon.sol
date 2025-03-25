// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "../libraries/LibErrors.sol";

/**
 * @title SimpleVaultBeacon
 * @notice Simplified beacon contract for vault implementations
 * @dev Follows EIP-1967 beacon pattern but doesn't check for IERC165 support
 */
contract SimpleVaultBeacon is IERC165 {
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
 * @title SimpleERC721VaultBeacon
 * @notice Simplified beacon for ERC721 vault implementations
 */
contract SimpleERC721VaultBeacon is SimpleVaultBeacon {
    constructor(address _implementation) SimpleVaultBeacon(_implementation) {}
}

/**
 * @title SimpleERC1155VaultBeacon
 * @notice Simplified beacon for ERC1155 vault implementations
 */
contract SimpleERC1155VaultBeacon is SimpleVaultBeacon {
    constructor(address _implementation) SimpleVaultBeacon(_implementation) {}
}
