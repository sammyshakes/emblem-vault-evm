// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../libraries/LibDiamond.sol";
import "../libraries/LibEmblemVaultStorage.sol";
import "../factories/VaultCollectionFactory.sol";
import "../interfaces/IVaultBeacon.sol";
import "../implementations/ERC721VaultImplementation.sol";
import "../implementations/ERC1155VaultImplementation.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title EmblemVaultCollectionFacet
 * @notice Facet for managing vault collections and their implementations
 * @dev Integrates with beacon proxy pattern for collection management
 */
contract EmblemVaultCollectionFacet {
    // Events
    event CollectionFactorySet(address indexed oldFactory, address indexed newFactory);
    event CollectionImplementationUpgraded(
        uint8 indexed collectionType, address indexed newImplementation
    );
    event VaultCollectionCreated(
        address indexed collection, uint8 indexed collectionType, string name
    );
    event CollectionBaseURIUpdated(address indexed collection, string newBaseURI);
    event CollectionURIUpdated(address indexed collection, string newURI);

    // Custom errors
    error InvalidCollectionType();
    error ZeroAddress();
    error FactoryNotSet();
    error InitializationFailed();
    error NotACollection();
    error InvalidCollectionOperation();
    error NotCollectionOwner();

    // Constants
    uint8 public constant ERC721_TYPE = 1;
    uint8 public constant ERC1155_TYPE = 2;

    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    modifier onlyValidCollection(address collection) {
        if (!isCollection(collection)) revert NotACollection();
        _;
    }

    /**
     * @notice Set the collection factory address
     * @param _factory Address of the new factory
     */
    function setCollectionFactory(address _factory) external onlyOwner {
        if (_factory == address(0)) revert ZeroAddress();

        LibEmblemVaultStorage.VaultStorage storage vs = LibEmblemVaultStorage.vaultStorage();
        address oldFactory = vs.vaultFactory;
        vs.vaultFactory = _factory;

        emit CollectionFactorySet(oldFactory, _factory);
    }

    /**
     * @notice Create a new vault collection
     * @param name The name of the collection
     * @param symbol The symbol (for ERC721) or URI (for ERC1155)
     * @param collectionType The type of collection (1 for ERC721, 2 for ERC1155)
     * @return collection The address of the new collection contract
     */
    function createVaultCollection(string memory name, string memory symbol, uint8 collectionType)
        external
        onlyOwner
        returns (address collection)
    {
        LibEmblemVaultStorage.VaultStorage storage vs = LibEmblemVaultStorage.vaultStorage();
        if (vs.vaultFactory == address(0)) revert FactoryNotSet();

        VaultCollectionFactory factory = VaultCollectionFactory(vs.vaultFactory);

        if (collectionType == ERC721_TYPE) {
            collection = factory.createERC721Collection(name, symbol);
        } else if (collectionType == ERC1155_TYPE) {
            collection = factory.createERC1155Collection(symbol); // symbol parameter used as URI for ERC1155
        } else {
            revert InvalidCollectionType();
        }

        // Register the new collection
        LibEmblemVaultStorage.registerContract(collection, collectionType);

        emit VaultCollectionCreated(collection, collectionType, name);
    }

    /**
     * @notice Set base URI for an ERC721 collection
     * @param collection The collection address
     * @param newBaseURI The new base URI
     */
    function setCollectionBaseURI(address collection, string memory newBaseURI)
        external
        onlyOwner
        onlyValidCollection(collection)
    {
        // Get collection type from storage
        LibEmblemVaultStorage.VaultStorage storage vs = LibEmblemVaultStorage.vaultStorage();
        uint256 collectionType = vs.registeredContracts[collection];
        if (collectionType != ERC721_TYPE) revert InvalidCollectionOperation();

        // Verify diamond owns the collection
        if (OwnableUpgradeable(collection).owner() != address(this)) {
            revert NotCollectionOwner();
        }

        // Update base URI
        ERC721VaultImplementation(collection).setBaseURI(newBaseURI);

        emit CollectionBaseURIUpdated(collection, newBaseURI);
    }

    /**
     * @notice Set URI for an ERC1155 collection
     * @param collection The collection address
     * @param newURI The new URI
     */
    function setCollectionURI(address collection, string memory newURI)
        external
        onlyOwner
        onlyValidCollection(collection)
    {
        // Get collection type from storage
        LibEmblemVaultStorage.VaultStorage storage vs = LibEmblemVaultStorage.vaultStorage();
        uint256 collectionType = vs.registeredContracts[collection];
        if (collectionType != ERC1155_TYPE) revert InvalidCollectionOperation();

        // Verify diamond owns the collection
        if (OwnableUpgradeable(collection).owner() != address(this)) {
            revert NotCollectionOwner();
        }

        // Update URI using setURI from ERC1155VaultImplementation
        ERC1155VaultImplementation(collection).setURI(newURI);

        emit CollectionURIUpdated(collection, newURI);
    }

    /**
     * @notice Upgrade collection implementation
     * @param collectionType The type of collection to upgrade
     * @param newImplementation Address of the new implementation
     */
    function upgradeCollectionImplementation(uint8 collectionType, address newImplementation)
        external
        onlyOwner
    {
        if (newImplementation == address(0)) revert ZeroAddress();

        LibEmblemVaultStorage.VaultStorage storage vs = LibEmblemVaultStorage.vaultStorage();
        if (vs.vaultFactory == address(0)) revert FactoryNotSet();

        VaultCollectionFactory factory = VaultCollectionFactory(vs.vaultFactory);
        address beacon;

        if (collectionType == ERC721_TYPE) {
            beacon = factory.erc721Beacon();
        } else if (collectionType == ERC1155_TYPE) {
            beacon = factory.erc1155Beacon();
        } else {
            revert InvalidCollectionType();
        }

        IVaultBeacon(beacon).upgrade(newImplementation);

        emit CollectionImplementationUpgraded(collectionType, newImplementation);
    }

    /**
     * @notice Get the current implementation for a collection type
     * @param collectionType The type of collection
     * @return The current implementation address
     */
    function getCollectionImplementation(uint8 collectionType) external view returns (address) {
        LibEmblemVaultStorage.VaultStorage storage vs = LibEmblemVaultStorage.vaultStorage();
        if (vs.vaultFactory == address(0)) revert FactoryNotSet();

        return VaultCollectionFactory(vs.vaultFactory).getImplementation(collectionType);
    }

    /**
     * @notice Get the beacon address for a collection type
     * @param collectionType The type of collection
     * @return The beacon address
     */
    function getCollectionBeacon(uint8 collectionType) external view returns (address) {
        LibEmblemVaultStorage.VaultStorage storage vs = LibEmblemVaultStorage.vaultStorage();
        if (vs.vaultFactory == address(0)) revert FactoryNotSet();

        return VaultCollectionFactory(vs.vaultFactory).getBeacon(collectionType);
    }

    /**
     * @notice Check if an address is a vault collection created by this system
     * @param collection The address to check
     * @return bool True if the address is a vault collection
     */
    function isCollection(address collection) public view returns (bool) {
        LibEmblemVaultStorage.VaultStorage storage vs = LibEmblemVaultStorage.vaultStorage();
        if (vs.vaultFactory == address(0)) return false;

        return VaultCollectionFactory(vs.vaultFactory).isCollection(collection);
    }

    /**
     * @notice Get the collection factory address
     * @return The current collection factory address
     */
    function getCollectionFactory() external view returns (address) {
        return LibEmblemVaultStorage.vaultStorage().vaultFactory;
    }
}
