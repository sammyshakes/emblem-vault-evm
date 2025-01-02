// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../libraries/LibDiamond.sol";
import "../libraries/LibEmblemVaultStorage.sol";

/// @title EmblemVaultInitFacet
/// @notice Handles initialization and configuration of the Emblem Vault system
/// @dev Sets up initial state and provides configuration getters
contract EmblemVaultInitFacet {
    // Events
    event VaultInitialized(
        address indexed owner, string metadataBaseUri, bool byPassable, bool initialized
    );
    event InterfaceIdSet(bytes4 indexed interfaceId, string name);
    event ClaimerContractSet(address indexed claimerContract);
    event WitnessInitialized(address indexed witness, uint256 witnessCount);
    event BypassStateInitialized(bool byPassable);

    // Custom errors
    error ZeroAddress();
    error NotContractOwner();
    error AlreadyInitialized();
    error InitializationFailed();

    /// @notice Initialize the vault system
    /// @param _owner Address of the initial owner
    function initialize(address _owner) external {
        if (_owner == address(0)) revert ZeroAddress();
        if (msg.sender != LibDiamond.contractOwner()) revert NotContractOwner();

        LibEmblemVaultStorage.VaultStorage storage vs = LibEmblemVaultStorage.vaultStorage();
        if (vs.initialized) revert AlreadyInitialized();

        // Set initial configuration
        vs.metadataBaseUri = "https://v2.emblemvault.io/meta/";
        vs.recipientAddress = _owner;

        // Set interface IDs
        vs.INTERFACE_ID_ERC1155 = 0xd9b67a26;
        vs.INTERFACE_ID_ERC20 = 0x74a1476f;
        // vs.INTERFACE_ID_ERC721 = 0x80ac58cd;
        vs.INTERFACE_ID_ERC721A = 0xf4a95f26;

        // Add owner as initial witness
        vs.witnesses[_owner] = true;
        vs.witnessCount = 1;

        // Initialize with no claimer contract
        vs.claimerContract = address(0);

        // Initialize bypass state
        vs.byPassable = false;

        // Mark as initialized
        vs.initialized = true;

        // Emit events
        emit VaultInitialized(_owner, vs.metadataBaseUri, vs.byPassable, vs.initialized);
        emit InterfaceIdSet(vs.INTERFACE_ID_ERC1155, "ERC1155");
        emit InterfaceIdSet(vs.INTERFACE_ID_ERC20, "ERC20");
        emit InterfaceIdSet(vs.INTERFACE_ID_ERC721A, "ERC721A");
        emit WitnessInitialized(_owner, vs.witnessCount);
        emit BypassStateInitialized(vs.byPassable);
        emit ClaimerContractSet(vs.claimerContract);
    }

    /// @notice Check if the system is initialized
    /// @return True if the system is initialized
    function isInitialized() external view returns (bool) {
        return LibEmblemVaultStorage.vaultStorage().initialized;
    }

    /// @notice Get all interface IDs
    /// @return erc1155 The ERC1155 interface ID
    /// @return erc20 The ERC20 interface ID
    /// @return erc721a The ERC721A interface ID
    function getInterfaceIds()
        external
        view
        returns (bytes4 erc1155, bytes4 erc20, bytes4 erc721a)
    {
        LibEmblemVaultStorage.VaultStorage storage vs = LibEmblemVaultStorage.vaultStorage();
        return (vs.INTERFACE_ID_ERC1155, vs.INTERFACE_ID_ERC20, vs.INTERFACE_ID_ERC721A);
    }

    /// @notice Get the current system configuration
    /// @return metadataBaseUri The base URI for metadata
    /// @return recipientAddress The recipient address for payments
    /// @return quoteContract The quote contract address
    /// @return claimerContract The claimer contract address
    /// @return byPassable The bypass state
    /// @return witnessCount The number of active witnesses
    function getConfiguration()
        external
        view
        returns (
            string memory metadataBaseUri,
            address recipientAddress,
            address quoteContract,
            address claimerContract,
            bool byPassable,
            uint256 witnessCount
        )
    {
        LibEmblemVaultStorage.VaultStorage storage vs = LibEmblemVaultStorage.vaultStorage();
        return (
            vs.metadataBaseUri,
            vs.recipientAddress,
            vs.quoteContract,
            vs.claimerContract,
            vs.byPassable,
            vs.witnessCount
        );
    }

    /// @notice Get initialization details
    /// @return owner The current owner address
    /// @return initialized Whether the system is initialized
    /// @return witnessCount The number of witnesses
    function getInitializationDetails()
        external
        view
        returns (address owner, bool initialized, uint256 witnessCount)
    {
        LibEmblemVaultStorage.VaultStorage storage vs = LibEmblemVaultStorage.vaultStorage();
        return (LibDiamond.contractOwner(), vs.initialized, vs.witnessCount);
    }

    /// @notice Get the contract version
    /// @return The version string
    function version() external pure returns (string memory) {
        return "1";
    }
}
