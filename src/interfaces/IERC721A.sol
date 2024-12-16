// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title IERC721A Interface
/// @notice Interface for ERC721A token with additional functionality for Emblem Vaults
/// @dev Extends ERC721A with custom minting and data handling capabilities
interface IERC721A {
    /// @notice Mint a new token
    /// @param _to Address to mint the token to
    /// @param _tokenId External token ID to mint
    function mint(address _to, uint256 _tokenId) external;

    /// @notice Mint a new token with additional data
    /// @param _to Address to mint the token to
    /// @param _tokenId External token ID to mint
    /// @param data Additional data to include with the mint
    function mintWithData(address _to, uint256 _tokenId, bytes calldata data) external;

    /// @notice Mint multiple tokens
    /// @param to Array of addresses to mint tokens to
    /// @param tokenIds Array of token IDs to mint
    function mintMany(address[] memory to, uint256[] memory tokenIds) external;

    /// @notice Burn a token
    /// @param tokenId Token ID to burn
    function burn(uint256 tokenId) external;

    /// @notice Burn a token with additional data
    /// @param tokenId Token ID to burn
    /// @param data Additional data to include with the burn
    function burnWithData(uint256 tokenId, bytes calldata data) external;

    /// @notice Get the internal token ID for an external token ID
    /// @param tokenId External token ID
    /// @return Internal token ID
    function getInternalTokenId(uint256 tokenId) external view returns (uint256);

    /// @notice Get the owner of a token
    /// @param tokenId Token ID to query
    /// @return Address of the token owner
    function ownerOf(uint256 tokenId) external view returns (address);

    /// @notice Set the base URI for token metadata
    /// @param baseURI New base URI
    function setBaseURI(string memory baseURI) external;

    /// @notice Set the name and symbol of the token
    /// @param name_ New name
    /// @param symbol_ New symbol
    function setDetails(string memory name_, string memory symbol_) external;

    /// @notice Check if the contract supports an interface
    /// @param interfaceId The interface identifier
    /// @return True if the contract supports the interface
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
