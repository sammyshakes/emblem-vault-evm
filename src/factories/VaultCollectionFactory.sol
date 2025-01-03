// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../beacon/VaultBeacon.sol";
import "../beacon/VaultProxy.sol";
import "../interfaces/IVaultBeacon.sol";
import "../interfaces/IVaultProxy.sol";
import "../interfaces/IVaultCollectionFactory.sol";
import "../libraries/LibCollectionTypes.sol";
import "../libraries/LibErrors.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title VaultCollectionFactory
 * @dev Uses Factory owner address as collection owner
 * @notice Factory contract for deploying vault collection contracts using the beacon pattern
 * @dev Creates ERC721 and ERC1155 collection contracts that can mint individual vaults as tokens.
 *      Each collection is a token contract that can mint multiple vault tokens, making it a
 *      parent container for individual vaults. The factory manages these collection contracts
 *      through the beacon proxy pattern for upgradeability.
 */
contract VaultCollectionFactory is IVaultCollectionFactory, Ownable(msg.sender) {
    using LibCollectionTypes for uint8;

    // State variables
    address public immutable diamond;
    address public erc721Beacon;
    address public erc1155Beacon;

    /**
     * @notice Constructor
     * @param _erc721Beacon Address of the ERC721 collection beacon
     * @param _erc1155Beacon Address of the ERC1155 collection beacon
     * @param _diamond Address of the Diamond that will own all collections
     */
    constructor(address _erc721Beacon, address _erc1155Beacon, address _diamond) {
        LibErrors.revertIfZeroAddress(_erc721Beacon);
        LibErrors.revertIfZeroAddress(_erc1155Beacon);
        LibErrors.revertIfZeroAddress(_diamond);
        diamond = _diamond;
        erc721Beacon = _erc721Beacon;
        erc1155Beacon = _erc1155Beacon;
    }

    /**
     * @notice Create a new ERC721 vault collection contract
     * @param name The name of the collection
     * @param symbol The symbol of the collection
     * @return collection The address of the new collection contract that can mint individual vaults
     */
    function createERC721Collection(string memory name, string memory symbol)
        external
        returns (address collection)
    {
        // Only Diamond can create collections
        if (msg.sender != diamond) revert LibErrors.Unauthorized(msg.sender);

        // Deploy proxy
        collection = address(new ERC721VaultProxy(erc721Beacon));

        // Initialize collection contract with Diamond address
        try IERC721VaultProxy(collection).initialize(name, symbol, diamond) {
            // Transfer ownership to factory owner
            try Ownable(collection).transferOwnership(owner()) {
                emit CollectionOwnershipTransferred(collection, owner());
                emit ERC721CollectionCreated(collection, name, symbol);
            } catch {
                revert LibErrors.TransferFailed();
            }
        } catch {
            revert LibErrors.InitializationFailed();
        }
    }

    /**
     * @notice Create a new ERC1155 vault collection contract
     * @param uri The base URI for the collection's metadata
     * @return collection The address of the new collection contract that can mint individual vaults
     */
    function createERC1155Collection(string memory uri) external returns (address collection) {
        // Only Diamond can create collections
        if (msg.sender != diamond) revert LibErrors.Unauthorized(msg.sender);

        // Deploy proxy
        collection = address(new ERC1155VaultProxy(erc1155Beacon));

        // Initialize collection contract with Diamond address
        try IERC1155VaultProxy(collection).initialize(uri, diamond) {
            // Transfer ownership to factory owner
            try Ownable(collection).transferOwnership(owner()) {
                emit CollectionOwnershipTransferred(collection, owner());
                emit ERC1155CollectionCreated(collection, uri);
            } catch {
                revert LibErrors.TransferFailed();
            }
        } catch {
            revert LibErrors.InitializationFailed();
        }
    }

    /**
     * @notice Update the beacon for a collection type
     * @param collectionType The type of collection (1 for ERC721, 2 for ERC1155)
     * @param newImplementation The address of the new implementation
     */
    function updateBeacon(uint8 collectionType, address newImplementation) external {
        // Only Diamond can update beacons
        if (msg.sender != diamond) revert LibErrors.Unauthorized(msg.sender);
        LibErrors.revertIfZeroAddress(newImplementation);

        if (!collectionType.isValidCollectionType()) {
            revert LibErrors.InvalidCollectionType(collectionType);
        }

        address beacon = collectionType.isERC721Type() ? erc721Beacon : erc1155Beacon;
        IVaultBeacon(beacon).upgrade(newImplementation);

        emit BeaconUpdated(collectionType, beacon, beacon);
    }

    /**
     * @notice Get the beacon address for a collection type
     * @param collectionType The type of collection (1 for ERC721, 2 for ERC1155)
     * @return The beacon address
     */
    function getBeacon(uint8 collectionType) external view returns (address) {
        if (!collectionType.isValidCollectionType()) {
            revert LibErrors.InvalidCollectionType(collectionType);
        }

        return collectionType.isERC721Type() ? erc721Beacon : erc1155Beacon;
    }

    /**
     * @notice Get the implementation address for a collection type
     * @param collectionType The type of collection (1 for ERC721, 2 for ERC1155)
     * @return The implementation address
     */
    function getImplementation(uint8 collectionType) external view returns (address) {
        if (!collectionType.isValidCollectionType()) {
            revert LibErrors.InvalidCollectionType(collectionType);
        }

        address beacon = collectionType.isERC721Type() ? erc721Beacon : erc1155Beacon;
        return IVaultBeacon(beacon).implementation();
    }

    /**
     * @notice Get the type of a collection
     * @param collection The collection address
     * @return The collection type (1 for ERC721, 2 for ERC1155)
     */
    function getCollectionType(address collection) external view returns (uint8) {
        if (!isCollection(collection)) revert LibErrors.InvalidCollection(collection);

        address beaconAddress = IVaultProxy(collection).beacon();
        if (beaconAddress == erc721Beacon) {
            return LibCollectionTypes.ERC721_TYPE;
        } else {
            return LibCollectionTypes.ERC1155_TYPE;
        }
    }

    /**
     * @notice Check if an address is a vault collection contract created by this factory
     * @param collection The address to check
     * @return bool True if the address is a vault collection contract
     */
    function isCollection(address collection) public view returns (bool) {
        if (collection.code.length == 0) return false;

        try IVaultProxy(collection).beacon() returns (address beaconAddress) {
            return beaconAddress == erc721Beacon || beaconAddress == erc1155Beacon;
        } catch {
            return false;
        }
    }
}
