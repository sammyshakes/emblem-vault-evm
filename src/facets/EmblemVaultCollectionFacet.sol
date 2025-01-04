// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../libraries/LibDiamond.sol";
import "../libraries/LibEmblemVaultStorage.sol";
import "../libraries/LibErrors.sol";
import "../libraries/LibCollectionTypes.sol";
import "../interfaces/IVaultBeacon.sol";
import "../interfaces/IVaultCollectionFactory.sol";

/**
 * @title EmblemVaultCollectionFacet
 * @notice Facet for managing vault collections and their implementations
 * @dev Integrates with beacon proxy pattern for collection management
 */
contract EmblemVaultCollectionFacet {
    using LibCollectionTypes for uint8;

    // Events
    event CollectionFactorySet(address indexed oldFactory, address indexed newFactory);
    event CollectionOwnerSet(address indexed owner);
    event CollectionImplementationUpgraded(
        uint8 indexed collectionType, address indexed newImplementation
    );
    event VaultCollectionCreated(
        address indexed collection, uint8 indexed collectionType, string name
    );
    event CollectionBaseURIUpdated(address indexed collection, string newBaseURI);
    event CollectionURIUpdated(address indexed collection, string newURI);

    // ------------------------------------------------------------------------
    // MODIFIERS
    // ------------------------------------------------------------------------
    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    modifier onlyValidCollection(address collection) {
        LibEmblemVaultStorage.VaultStorage storage vs = LibEmblemVaultStorage.vaultStorage();
        LibErrors.revertIfFactoryNotSet(vs.vaultFactory);
        LibErrors.revertIfInvalidCollection(
            collection, IVaultCollectionFactory(vs.vaultFactory).isCollection(collection)
        );
        _;
    }

    /**
     * @notice Set the collection owner address
     * @param owner The address of the new collection owner
     */
    function setCollectionOwner(address owner) external onlyOwner {
        LibEmblemVaultStorage.setCollectionOwner(owner);
        emit CollectionOwnerSet(owner);
    }

    /**
     * @notice Get the current collection owner address
     * @return The address of the current collection owner
     */
    function getCollectionOwner() external view returns (address) {
        return LibEmblemVaultStorage.getCollectionOwner();
    }

    /**
     * @notice Set the collection factory address
     * @param _factory Address of the new factory
     */
    function setCollectionFactory(address _factory) external onlyOwner {
        LibErrors.revertIfZeroAddress(_factory);

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
        if (!collectionType.isValidCollectionType()) {
            revert LibErrors.InvalidCollectionType(collectionType);
        }

        LibEmblemVaultStorage.VaultStorage storage vs = LibEmblemVaultStorage.vaultStorage();
        LibErrors.revertIfFactoryNotSet(vs.vaultFactory);

        IVaultCollectionFactory factory = IVaultCollectionFactory(vs.vaultFactory);

        if (collectionType.isERC721Type()) {
            collection = factory.createERC721Collection(name, symbol);
        } else {
            collection = factory.createERC1155Collection(symbol); // symbol parameter used as URI for ERC1155
        }

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
        IVaultCollectionFactory factory =
            IVaultCollectionFactory(LibEmblemVaultStorage.vaultStorage().vaultFactory);
        uint8 collectionType = factory.getCollectionType(collection);
        if (!collectionType.isERC721Type()) {
            revert LibErrors.InvalidCollectionOperation(collection);
        }

        // Update base URI
        (bool success,) = collection.call(abi.encodeWithSignature("setBaseURI(string)", newBaseURI));
        require(success, "setBaseURI failed");

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
        IVaultCollectionFactory factory =
            IVaultCollectionFactory(LibEmblemVaultStorage.vaultStorage().vaultFactory);
        uint8 collectionType = factory.getCollectionType(collection);
        if (!collectionType.isERC1155Type()) {
            revert LibErrors.InvalidCollectionOperation(collection);
        }

        // Update URI using setURI
        (bool success,) = collection.call(abi.encodeWithSignature("setURI(string)", newURI));
        require(success, "setURI failed");

        emit CollectionURIUpdated(collection, newURI);
    }

    /**
     * @notice Upgrade collection implementation
     * @param collectionType The type of collection (1 for ERC721, 2 for ERC1155)
     * @param newImplementation Address of the new implementation
     */
    function upgradeCollectionImplementation(uint8 collectionType, address newImplementation)
        external
        onlyOwner
    {
        LibErrors.revertIfZeroAddress(newImplementation);
        if (!collectionType.isValidCollectionType()) {
            revert LibErrors.InvalidCollectionType(collectionType);
        }

        LibEmblemVaultStorage.VaultStorage storage vs = LibEmblemVaultStorage.vaultStorage();
        LibErrors.revertIfFactoryNotSet(vs.vaultFactory);

        IVaultCollectionFactory factory = IVaultCollectionFactory(vs.vaultFactory);
        address beacon;

        if (collectionType.isERC721Type()) {
            beacon = factory.erc721Beacon();
        } else {
            beacon = factory.erc1155Beacon();
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
        if (!collectionType.isValidCollectionType()) {
            revert LibErrors.InvalidCollectionType(collectionType);
        }

        LibEmblemVaultStorage.VaultStorage storage vs = LibEmblemVaultStorage.vaultStorage();
        LibErrors.revertIfFactoryNotSet(vs.vaultFactory);

        return IVaultCollectionFactory(vs.vaultFactory).getImplementation(collectionType);
    }

    /**
     * @notice Get the beacon address for a collection type
     * @param collectionType The type of collection
     * @return The beacon address
     */
    function getCollectionBeacon(uint8 collectionType) external view returns (address) {
        if (!collectionType.isValidCollectionType()) {
            revert LibErrors.InvalidCollectionType(collectionType);
        }

        LibEmblemVaultStorage.VaultStorage storage vs = LibEmblemVaultStorage.vaultStorage();
        LibErrors.revertIfFactoryNotSet(vs.vaultFactory);

        return IVaultCollectionFactory(vs.vaultFactory).getBeacon(collectionType);
    }

    /**
     * @notice Check if an address is a vault collection created by this system
     * @param collection The address to check
     * @return bool True if the address is a vault collection
     */
    function isCollection(address collection) public view returns (bool) {
        LibEmblemVaultStorage.VaultStorage storage vs = LibEmblemVaultStorage.vaultStorage();
        if (vs.vaultFactory == address(0)) return false;

        return IVaultCollectionFactory(vs.vaultFactory).isCollection(collection);
    }

    /**
     * @notice Get the type of a collection
     * @param collection The collection address
     * @return The collection type (1 for ERC721, 2 for ERC1155)
     */
    function getCollectionType(address collection) external view returns (uint8) {
        LibEmblemVaultStorage.VaultStorage storage vs = LibEmblemVaultStorage.vaultStorage();
        LibErrors.revertIfFactoryNotSet(vs.vaultFactory);

        return IVaultCollectionFactory(vs.vaultFactory).getCollectionType(collection);
    }

    /**
     * @notice Get the collection factory address
     * @return The current collection factory address
     */
    function getCollectionFactory() external view returns (address) {
        return LibEmblemVaultStorage.vaultStorage().vaultFactory;
    }
}
