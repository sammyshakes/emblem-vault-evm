// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title IIsSerialized Interface
/// @notice Interface for handling serialized tokens in the Emblem Vault system
/// @dev This interface manages serial numbers for tokens, allowing tracking of specific instances
interface IIsSerialized {
    /// @notice Check if the contract supports serialization
    /// @return True if the contract supports serialization
    function isSerialized() external view returns (bool);

    /// @notice Get the serial number for a token at a specific index
    /// @param tokenId The ID of the token
    /// @param index The index of the serial number to retrieve
    /// @return The serial number at the specified index
    function getSerial(uint256 tokenId, uint256 index) external view returns (uint256);

    /// @notice Get the first serial number owned by an address for a specific token ID
    /// @param owner The address of the owner
    /// @param tokenId The ID of the token
    /// @return The first serial number found for the owner and token ID
    function getFirstSerialByOwner(address owner, uint256 tokenId)
        external
        view
        returns (uint256);

    /// @notice Get the owner of a specific serial number
    /// @param serialNumber The serial number to query
    /// @return The address of the owner of the serial number
    function getOwnerOfSerial(uint256 serialNumber) external view returns (address);

    /// @notice Get the serial number for a specific owner at a specific index
    /// @param _owner The address of the owner
    /// @param tokenId The ID of the token
    /// @param index The index of the serial number to retrieve
    /// @return The serial number at the specified index for the owner
    function getSerialByOwnerAtIndex(address _owner, uint256 tokenId, uint256 index)
        external
        view
        returns (uint256);

    /// @notice Get the token ID associated with a serial number
    /// @param serialNumber The serial number to query
    /// @return The token ID associated with the serial number
    function getTokenIdForSerialNumber(uint256 serialNumber) external view returns (uint256);
}
