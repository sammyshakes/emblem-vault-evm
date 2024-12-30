// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "ERC721A-Upgradeable/IERC721AUpgradeable.sol";

/// @title IERC721AVault
/// @notice Interface for ERC721A vault implementation with extended functionality
/// @dev Combines minting, burning, and token ID mapping capabilities
interface IERC721AVault is IERC721AUpgradeable {
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

    /// @notice Mint a new token with an external ID
    /// @param to Address to mint to
    /// @param externalTokenId External token ID to mint
    function mint(address to, uint256 externalTokenId) external;

    /// @notice Mint a new token with an external ID and additional data
    /// @param to Address to mint to
    /// @param externalTokenId External token ID to mint
    /// @param data Additional data to pass to the mint
    function mintWithData(address to, uint256 externalTokenId, bytes calldata data) external;

    /// @notice Batch mint new tokens with external IDs
    /// @param to Address to mint to
    /// @param externalTokenIds Array of external token IDs to mint
    function batchMint(address to, uint256[] calldata externalTokenIds) external;

    /// @notice Batch mint new tokens with external IDs and additional data
    /// @param to Address to mint to
    /// @param externalTokenIds Array of external token IDs to mint
    /// @param data Additional data to pass to the mint
    function batchMintWithData(address to, uint256[] calldata externalTokenIds, bytes calldata data)
        external;

    /// @notice Burn a token
    /// @param internalTokenId Internal token ID to burn
    function burn(uint256 internalTokenId) external;

    /// @notice Burn a token with additional data
    /// @param internalTokenId Internal token ID to burn
    /// @param data Additional data to pass to the burn
    function burnWithData(uint256 internalTokenId, bytes calldata data) external;

    /// @notice Batch burn tokens
    /// @param internalTokenIds Array of internal token IDs to burn
    function batchBurn(uint256[] calldata internalTokenIds) external;

    /// @notice Batch burn tokens with additional data
    /// @param internalTokenIds Array of internal token IDs to burn
    /// @param data Additional data to pass to the burn
    function batchBurnWithData(uint256[] calldata internalTokenIds, bytes calldata data) external;

    /// @notice Get the version of the implementation
    /// @return The version string
    function version() external pure returns (string memory);

    /// @notice Get the interface ID
    /// @return The interface ID
    function interfaceId() external pure returns (bytes4);

    /// @notice Get the beacon address
    /// @return The beacon contract address
    function beacon() external view returns (address);

    /// @notice Get the implementation address
    /// @return The implementation contract address
    function implementation() external view returns (address);
}
