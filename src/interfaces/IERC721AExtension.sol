// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title IERC721AExtension
/// @notice Extension interface for ERC721A with additional functionality for Emblem Vaults
/// @dev Extends ERC721A with external/internal token ID mapping
interface IERC721AExtension {
    /// @notice Get the internal token ID for an external token ID
    /// @param externalTokenId The external token ID
    /// @return The internal token ID used by ERC721A
    function getInternalTokenId(uint256 externalTokenId) external view returns (uint256);

    /// @notice Get the external token ID for an internal token ID
    /// @param internalTokenId The internal token ID used by ERC721A
    /// @return The external token ID
    function getExternalTokenId(uint256 internalTokenId) external view returns (uint256);

    /// @notice Set the base URI for token metadata
    /// @param baseURI New base URI
    function setBaseURI(string calldata baseURI) external;

    /// @notice Set the name and symbol of the token
    /// @param name_ New name
    /// @param symbol_ New symbol
    function setDetails(string calldata name_, string calldata symbol_) external;
}
