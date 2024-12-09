// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../beacon/VaultBeacon.sol";
import "../beacon/VaultProxy.sol";
import "../interfaces/IVaultBeacon.sol";
import "../interfaces/IVaultProxy.sol";

/**
 * @title VaultCollectionFactory
 * @notice Factory contract for deploying vault collection contracts using the beacon pattern
 * @dev Creates ERC721 and ERC1155 collection contracts that can mint individual vaults as tokens.
 *      Each collection is a token contract that can mint multiple vault tokens, making it a
 *      parent container for individual vaults. The factory manages these collection contracts
 *      through the beacon proxy pattern for upgradeability.
 */
contract VaultCollectionFactory {
    // Events
    event ERC721CollectionCreated(address indexed collection, string name, string symbol);
    event ERC1155CollectionCreated(address indexed collection, string uri);
    event BeaconUpdated(uint8 indexed collectionType, address indexed oldBeacon, address indexed newBeacon);

    // Custom errors
    error InvalidCollectionType();
    error ZeroAddress();
    error NotOwner();
    error InitializationFailed();

    // State variables
    address public immutable owner;
    address public erc721Beacon;
    address public erc1155Beacon;

    // Constants
    uint8 public constant ERC721_TYPE = 1;
    uint8 public constant ERC1155_TYPE = 2;

    /**
     * @notice Constructor
     * @param _erc721Beacon Address of the ERC721 collection beacon
     * @param _erc1155Beacon Address of the ERC1155 collection beacon
     */
    constructor(address _erc721Beacon, address _erc1155Beacon) {
        if (_erc721Beacon == address(0) || _erc1155Beacon == address(0)) revert ZeroAddress();
        owner = msg.sender;
        erc721Beacon = _erc721Beacon;
        erc1155Beacon = _erc1155Beacon;
    }

    /**
     * @notice Create a new ERC721 vault collection contract
     * @param name The name of the collection
     * @param symbol The symbol of the collection
     * @return collection The address of the new collection contract that can mint individual vaults
     */
    function createERC721Collection(string memory name, string memory symbol) external returns (address collection) {
        // Deploy proxy
        collection = address(new ERC721VaultProxy(erc721Beacon));

        // Initialize collection contract
        try IERC721VaultProxy(collection).initialize(name, symbol) {
            emit ERC721CollectionCreated(collection, name, symbol);
        } catch {
            revert InitializationFailed();
        }
    }

    /**
     * @notice Create a new ERC1155 vault collection contract
     * @param uri The base URI for the collection's metadata
     * @return collection The address of the new collection contract that can mint individual vaults
     */
    function createERC1155Collection(string memory uri) external returns (address collection) {
        // Deploy proxy
        collection = address(new ERC1155VaultProxy(erc1155Beacon));

        // Initialize collection contract
        try IERC1155VaultProxy(collection).initialize(uri) {
            emit ERC1155CollectionCreated(collection, uri);
        } catch {
            revert InitializationFailed();
        }
    }

    /**
     * @notice Update the beacon for a collection type
     * @param collectionType The type of collection (1 for ERC721, 2 for ERC1155)
     * @param newBeacon The address of the new beacon
     */
    function updateBeacon(uint8 collectionType, address newBeacon) external {
        if (msg.sender != owner) revert NotOwner();
        if (newBeacon == address(0)) revert ZeroAddress();

        address oldBeacon;
        if (collectionType == ERC721_TYPE) {
            oldBeacon = erc721Beacon;
            erc721Beacon = newBeacon;
        } else if (collectionType == ERC1155_TYPE) {
            oldBeacon = erc1155Beacon;
            erc1155Beacon = newBeacon;
        } else {
            revert InvalidCollectionType();
        }

        emit BeaconUpdated(collectionType, oldBeacon, newBeacon);
    }

    /**
     * @notice Get the beacon address for a collection type
     * @param collectionType The type of collection (1 for ERC721, 2 for ERC1155)
     * @return The beacon address
     */
    function getBeacon(uint8 collectionType) external view returns (address) {
        if (collectionType == ERC721_TYPE) {
            return erc721Beacon;
        } else if (collectionType == ERC1155_TYPE) {
            return erc1155Beacon;
        } else {
            revert InvalidCollectionType();
        }
    }

    /**
     * @notice Get the implementation address for a collection type
     * @param collectionType The type of collection (1 for ERC721, 2 for ERC1155)
     * @return The implementation address
     */
    function getImplementation(uint8 collectionType) external view returns (address) {
        address beacon = collectionType == ERC721_TYPE ? erc721Beacon : erc1155Beacon;
        if (beacon == address(0)) revert InvalidCollectionType();
        return IVaultBeacon(beacon).implementation();
    }

    /**
     * @notice Check if an address is a vault collection contract created by this factory
     * @param collection The address to check
     * @return bool True if the address is a vault collection contract
     */
    function isCollection(address collection) external view returns (bool) {
        if (collection.code.length == 0) return false;

        try IVaultProxy(collection).beacon() returns (address beaconAddress) {
            return beaconAddress == erc721Beacon || beaconAddress == erc1155Beacon;
        } catch {
            return false;
        }
    }
}
