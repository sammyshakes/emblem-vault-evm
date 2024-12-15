// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../interfaces/IERC165.sol";

/// @title LibInterfaceIds
/// @notice Library for interface ID constants and checks
/// @dev Centralizes interface detection logic used across facets
library LibInterfaceIds {
    // Interface IDs
    bytes4 constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 constant INTERFACE_ID_ERC721A = bytes4(keccak256("ERC721A"));
    bytes4 constant INTERFACE_ID_ERC1155 = 0xd9b67a26;
    bytes4 constant INTERFACE_ID_SERIALIZED = bytes4(keccak256("IsSerialized"));

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

    /// @notice Check if a contract supports ERC721
    /// @param contractAddress The contract to check
    /// @return True if the contract supports ERC721
    function isERC721(address contractAddress) internal view returns (bool) {
        return IERC165(contractAddress).supportsInterface(INTERFACE_ID_ERC721);
    }

    /// @notice Check if a contract supports serialization
    /// @param contractAddress The contract to check
    /// @return True if the contract supports serialization
    function isSerialized(address contractAddress) internal view returns (bool) {
        return IERC165(contractAddress).supportsInterface(INTERFACE_ID_SERIALIZED);
    }

    /// @notice Get the token standard type
    /// @param contractAddress The contract to check
    /// @return 1 for ERC721A, 2 for ERC1155, 3 for ERC721, 0 for unsupported
    function getTokenStandard(address contractAddress) internal view returns (uint8) {
        if (isERC721A(contractAddress)) return 1;
        if (isERC1155(contractAddress)) return 2;
        if (isERC721(contractAddress)) return 3;
        return 0;
    }
}
