// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/factories/VaultCollectionFactory.sol";
import "../src/beacon/VaultBeacon.sol";
import "../src/facets/EmblemVaultCollectionFacet.sol";

/**
 * @title UpdateCollectionsAndURIs
 * @notice Script to deploy new factory, transfer collection ownership, and update URIs
 * @dev Run with:
 * forge script script/UpdateCollectionsAndURIs.s.sol:UpdateCollectionsAndURIs --rpc-url bsc_testnet --broadcast -vvvv
 */
contract UpdateCollectionsAndURIs is Script {
    function run() external {
        // Get deployment private key
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // Get contract addresses from environment
        address diamondAddress = vm.envAddress("DIAMOND_ADDRESS");
        address oldFactoryAddress = vm.envAddress("COLLECTION_FACTORY_ADDRESS");
        address erc721Collection = vm.envAddress("ERC721_COLLECTION");
        address erc1155Collection = vm.envAddress("ERC1155_COLLECTION");

        // Get beacon addresses from old factory
        VaultCollectionFactory oldFactory = VaultCollectionFactory(oldFactoryAddress);
        address erc721Beacon = oldFactory.erc721Beacon();
        address erc1155Beacon = oldFactory.erc1155Beacon();

        console.log("Updating Collections and URIs");
        console.log("Deployer:", deployer);
        console.log("Diamond:", diamondAddress);
        console.log("Old Factory:", oldFactoryAddress);
        console.log("ERC721 Collection:", erc721Collection);
        console.log("ERC1155 Collection:", erc1155Collection);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy new factory with same beacons
        VaultCollectionFactory newFactory = new VaultCollectionFactory(erc721Beacon, erc1155Beacon);
        console.log("New Factory deployed at:", address(newFactory));

        // Set new factory in diamond
        EmblemVaultCollectionFacet(diamondAddress).setCollectionFactory(address(newFactory));
        console.log("New factory set in diamond");

        // Transfer collection ownership to diamond
        newFactory.transferCollectionOwnership(erc721Collection, diamondAddress);
        console.log("ERC721 collection ownership transferred to diamond");

        newFactory.transferCollectionOwnership(erc1155Collection, diamondAddress);
        console.log("ERC1155 collection ownership transferred to diamond");

        // Update URIs through diamond
        EmblemVaultCollectionFacet collectionFacet = EmblemVaultCollectionFacet(diamondAddress);

        collectionFacet.setCollectionBaseURI(
            erc721Collection, "https://api.emblem.finance/erc721/metadata/"
        );
        console.log("ERC721 base URI updated");

        collectionFacet.setCollectionURI(
            erc1155Collection, "https://api.emblem.finance/erc1155/metadata/{id}.json"
        );
        console.log("ERC1155 URI updated");

        vm.stopBroadcast();

        console.log("\nUpdate Complete");
        console.log("--------------------------------");
        console.log("New Factory:", address(newFactory));
        console.log("ERC721 Collection:", erc721Collection);
        console.log("ERC721 Base URI: https://api.emblem.finance/erc721/metadata/");
        console.log("ERC1155 Collection:", erc1155Collection);
        console.log("ERC1155 URI: https://api.emblem.finance/erc1155/metadata/{id}.json");
    }
}
