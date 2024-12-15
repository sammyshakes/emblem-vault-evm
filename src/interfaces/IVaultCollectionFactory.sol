// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IVaultCollectionFactory {
    // Events
    event ERC721CollectionCreated(address indexed collection, string name, string symbol);
    event ERC1155CollectionCreated(address indexed collection, string uri);
    event BeaconUpdated(
        uint8 indexed collectionType, address indexed oldBeacon, address indexed newBeacon
    );
    event CollectionOwnershipTransferred(address indexed collection, address indexed newOwner);

    // Functions
    function createERC721Collection(string memory name, string memory symbol)
        external
        returns (address collection);
    function createERC1155Collection(string memory uri) external returns (address collection);
    function transferCollectionOwnership(address collection, address newOwner) external;
    function updateBeacon(uint8 collectionType, address newBeacon) external;
    function getBeacon(uint8 collectionType) external view returns (address);
    function getImplementation(uint8 collectionType) external view returns (address);
    function isCollection(address collection) external view returns (bool);
    function getCollectionType(address collection) external view returns (uint8);
    function erc721Beacon() external view returns (address);
    function erc1155Beacon() external view returns (address);
}
