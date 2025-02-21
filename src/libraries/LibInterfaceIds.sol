// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../interfaces/IERC165.sol";
import "../interfaces/IIsSerialized.sol";

/// @title LibInterfaceIds
/// @notice Library for interface ID constants and checks
/// @dev Centralizes interface detection logic used across facets
library LibInterfaceIds {
    // Interface IDs
    bytes4 constant INTERFACE_ID_ERC165 = 0x01ffc9a7;
    bytes4 constant INTERFACE_ID_ERC721A = 0xf4a95f26;
    bytes4 constant INTERFACE_ID_ERC1155 = 0xd9b67a26;
    bytes4 constant INTERFACE_ID_SERIALIZED = 0x5d837754; // type(IIsSerialized).interfaceId

    // Diamond Interface IDs
    bytes4 constant INTERFACE_ID_DIAMOND_CUT = 0x1f931c1c;
    bytes4 constant INTERFACE_ID_DIAMOND_LOUPE = 0x48e2b093;
    bytes4 constant INTERFACE_ID_ERC173 = 0x7f5828d0; // Ownership

    // Token Standards (for getTokenStandard return values)
    uint8 constant TOKEN_STANDARD_ERC721A = 1;
    uint8 constant TOKEN_STANDARD_ERC1155 = 2;
    uint8 constant TOKEN_STANDARD_UNKNOWN = 0;

    /// @notice Check if a contract supports ERC721A
    /// @param contractAddress The contract to check
    /// @return True if the contract supports ERC721A
    function isERC721A(address contractAddress) internal view returns (bool) {
        return IERC165(contractAddress).supportsInterface(INTERFACE_ID_ERC721A);
    }

    /// @notice Check if a contract supports ERC1155
    /// @param contractAddress The contract to check
    /// @return True if the contract supports ERC1155
    function isERC1155(address contractAddress) internal view returns (bool) {
        return IERC165(contractAddress).supportsInterface(INTERFACE_ID_ERC1155);
    }

    /// @notice Check if a contract supports serialization
    /// @param contractAddress The contract to check
    /// @return True if the contract supports serialization
    function isSerialized(address contractAddress) internal view returns (bool) {
        return IERC165(contractAddress).supportsInterface(INTERFACE_ID_SERIALIZED);
    }

    /// @notice Get the token standard type
    /// @param contractAddress The contract to check
    /// @return Token standard type (see TOKEN_STANDARD constants)
    function getTokenStandard(address contractAddress) internal view returns (uint8) {
        if (isERC721A(contractAddress)) return TOKEN_STANDARD_ERC721A;
        if (isERC1155(contractAddress)) return TOKEN_STANDARD_ERC1155;
        return TOKEN_STANDARD_UNKNOWN;
    }

    /// @notice Check if a contract supports a specific interface
    /// @param contractAddress The contract to check
    /// @param interfaceId The interface ID to check for
    /// @return True if the contract supports the interface
    function supportsInterface(address contractAddress, bytes4 interfaceId)
        internal
        view
        returns (bool)
    {
        return IERC165(contractAddress).supportsInterface(interfaceId);
    }

    /// @notice Register standard diamond interfaces
    /// @param ds Storage pointer to register interfaces on
    function registerDiamondInterfaces(mapping(bytes4 => bool) storage ds) internal {
        ds[INTERFACE_ID_ERC165] = true;
        ds[INTERFACE_ID_DIAMOND_CUT] = true;
        ds[INTERFACE_ID_DIAMOND_LOUPE] = true;
        ds[INTERFACE_ID_ERC173] = true;
    }
}
