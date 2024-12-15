// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title LibCollectionTypes
/// @notice Library for collection type constants and helpers
/// @dev Centralizes collection type definitions used across the system
library LibCollectionTypes {
    // Collection Types
    uint8 constant ERC721_TYPE = 1;
    uint8 constant ERC1155_TYPE = 2;

    /// @notice Check if collection type is valid
    /// @param collectionType The type to check
    /// @return True if the collection type is valid
    function isValidCollectionType(uint8 collectionType) internal pure returns (bool) {
        return collectionType == ERC721_TYPE || collectionType == ERC1155_TYPE;
    }

    /// @notice Check if collection type is ERC721
    /// @param collectionType The type to check
    /// @return True if the collection type is ERC721
    function isERC721Type(uint8 collectionType) internal pure returns (bool) {
        return collectionType == ERC721_TYPE;
    }

    /// @notice Check if collection type is ERC1155
    /// @param collectionType The type to check
    /// @return True if the collection type is ERC1155
    function isERC1155Type(uint8 collectionType) internal pure returns (bool) {
        return collectionType == ERC1155_TYPE;
    }
}
