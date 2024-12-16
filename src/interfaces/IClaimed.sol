// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title IClaimed Interface
/// @notice Interface for handling claim status and operations in the Emblem Vault system
/// @dev This interface manages the claiming process for vaults
interface IClaimed {
    /// @notice Check if a token has been claimed
    /// @param _nftAddress The address of the NFT contract
    /// @param tokenId The ID of the token
    /// @param proof Proof data for claim verification
    /// @return True if the token has been claimed
    function isClaimed(address _nftAddress, uint256 tokenId, bytes32[] memory proof)
        external
        view
        returns (bool);

    /// @notice Claim a token
    /// @param _nftAddress The address of the NFT contract
    /// @param tokenId The ID of the token
    /// @param claimer The address claiming the token
    function claim(address _nftAddress, uint256 tokenId, address claimer) external;
}
