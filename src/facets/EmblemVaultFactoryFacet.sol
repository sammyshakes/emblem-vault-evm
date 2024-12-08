// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../libraries/LibDiamond.sol";
import "../libraries/LibEmblemVaultStorage.sol";
import "../factories/VaultFactory.sol";
import "../interfaces/IVaultBeacon.sol";

/**
 * @title EmblemVaultFactoryFacet
 * @notice Facet for managing vault creation and implementation upgrades
 * @dev Integrates with beacon proxy pattern for vault management
 */
contract EmblemVaultFactoryFacet {
    // Events
    event VaultFactorySet(address indexed oldFactory, address indexed newFactory);
    event VaultImplementationUpgraded(uint8 indexed vaultType, address indexed newImplementation);
    event VaultCollectionCreated(address indexed vault, uint8 indexed vaultType, string name);

    // Custom errors
    error InvalidVaultType();
    error ZeroAddress();
    error FactoryNotSet();
    error InitializationFailed();

    // Constants
    uint8 public constant ERC721_TYPE = 1;
    uint8 public constant ERC1155_TYPE = 2;

    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    /**
     * @notice Set the vault factory address
     * @param _factory Address of the new factory
     */
    function setVaultFactory(address _factory) external onlyOwner {
        if (_factory == address(0)) revert ZeroAddress();

        LibEmblemVaultStorage.VaultStorage storage vs = LibEmblemVaultStorage.vaultStorage();
        address oldFactory = vs.vaultFactory;
        vs.vaultFactory = _factory;

        emit VaultFactorySet(oldFactory, _factory);
    }

    /**
     * @notice Create a new vault collection
     * @param name The name of the collection
     * @param symbol The symbol (for ERC721) or URI (for ERC1155)
     * @param vaultType The type of vault (1 for ERC721, 2 for ERC1155)
     * @return vault The address of the new vault
     */
    function createVaultCollection(string memory name, string memory symbol, uint8 vaultType)
        external
        onlyOwner
        returns (address vault)
    {
        LibEmblemVaultStorage.VaultStorage storage vs = LibEmblemVaultStorage.vaultStorage();
        if (vs.vaultFactory == address(0)) revert FactoryNotSet();

        VaultFactory factory = VaultFactory(vs.vaultFactory);

        if (vaultType == ERC721_TYPE) {
            vault = factory.createERC721Vault(name, symbol);
        } else if (vaultType == ERC1155_TYPE) {
            vault = factory.createERC1155Vault(symbol); // symbol parameter used as URI for ERC1155
        } else {
            revert InvalidVaultType();
        }

        // Register the new vault
        LibEmblemVaultStorage.registerContract(vault, vaultType);

        emit VaultCollectionCreated(vault, vaultType, name);
    }

    /**
     * @notice Upgrade vault implementation
     * @param vaultType The type of vault to upgrade
     * @param newImplementation Address of the new implementation
     */
    function upgradeVaultImplementation(uint8 vaultType, address newImplementation) external onlyOwner {
        if (newImplementation == address(0)) revert ZeroAddress();

        LibEmblemVaultStorage.VaultStorage storage vs = LibEmblemVaultStorage.vaultStorage();
        if (vs.vaultFactory == address(0)) revert FactoryNotSet();

        VaultFactory factory = VaultFactory(vs.vaultFactory);
        address beacon;

        if (vaultType == ERC721_TYPE) {
            beacon = factory.erc721Beacon();
        } else if (vaultType == ERC1155_TYPE) {
            beacon = factory.erc1155Beacon();
        } else {
            revert InvalidVaultType();
        }

        IVaultBeacon(beacon).upgrade(newImplementation);

        emit VaultImplementationUpgraded(vaultType, newImplementation);
    }

    /**
     * @notice Get the current implementation for a vault type
     * @param vaultType The type of vault
     * @return The current implementation address
     */
    function getVaultImplementation(uint8 vaultType) external view returns (address) {
        LibEmblemVaultStorage.VaultStorage storage vs = LibEmblemVaultStorage.vaultStorage();
        if (vs.vaultFactory == address(0)) revert FactoryNotSet();

        return VaultFactory(vs.vaultFactory).getImplementation(vaultType);
    }

    /**
     * @notice Get the beacon address for a vault type
     * @param vaultType The type of vault
     * @return The beacon address
     */
    function getVaultBeacon(uint8 vaultType) external view returns (address) {
        LibEmblemVaultStorage.VaultStorage storage vs = LibEmblemVaultStorage.vaultStorage();
        if (vs.vaultFactory == address(0)) revert FactoryNotSet();

        return VaultFactory(vs.vaultFactory).getBeacon(vaultType);
    }

    /**
     * @notice Check if an address is a vault created by this system
     * @param vault The address to check
     * @return bool True if the address is a vault
     */
    function isVault(address vault) external view returns (bool) {
        LibEmblemVaultStorage.VaultStorage storage vs = LibEmblemVaultStorage.vaultStorage();
        if (vs.vaultFactory == address(0)) return false;

        return VaultFactory(vs.vaultFactory).isVault(vault);
    }

    /**
     * @notice Get the factory address
     * @return The current factory address
     */
    function getVaultFactory() external view returns (address) {
        return LibEmblemVaultStorage.vaultStorage().vaultFactory;
    }
}
