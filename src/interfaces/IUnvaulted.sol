// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title IUnvaulted Interface
/// @notice Interface for handling unvault status and operations in the Emblem Vault system
/// @dev This interface manages the unvaulting process for vaults
interface IUnvaulted {
    /// @notice Check if a token has been unvaulted
    /// @return True if the token has been unvaulted
    function isUnvaulted(address _nftAddress, uint256 tokenId, bytes32[] memory proof)
        external
        view
        returns (bool);

    /// @notice Unvault a token
    /// @param _nftAddress The address of the NFT contract
    /// @param tokenId The ID of the token to unvault
    /// @param proof The merkle proof for verification
    function unvault(address _nftAddress, uint256 tokenId, bytes32[] memory proof) external;
}
