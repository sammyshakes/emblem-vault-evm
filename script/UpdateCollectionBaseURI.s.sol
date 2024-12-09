// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/facets/EmblemVaultCollectionFacet.sol";

/**
 * @title UpdateCollectionBaseURI
 * @notice Script to update URIs for vault collections through the diamond
 * @dev Run with:
 * forge script script/UpdateCollectionBaseURI.s.sol:UpdateCollectionBaseURI --rpc-url bsc_testnet --broadcast -vvvv \
 * --sig "run(address,string,uint8)" <collection_address> <new_uri> <collection_type>
 * Collection type: 1 for ERC721, 2 for ERC1155
 */
contract UpdateCollectionBaseURI is Script {
    uint8 constant ERC721_TYPE = 1;
    uint8 constant ERC1155_TYPE = 2;

    function run(address collection, string memory newURI, uint8 collectionType) external {
        // Get deployment private key and diamond address
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        address diamond = vm.envAddress("DIAMOND_ADDRESS");

        console.log("Updating Collection URI");
        console.log("Collection:", collection);
        console.log("New URI:", newURI);
        console.log("Collection Type:", collectionType);
        console.log("Diamond:", diamond);
        console.log("Deployer:", deployer);

        vm.startBroadcast(deployerPrivateKey);

        EmblemVaultCollectionFacet collectionFacet = EmblemVaultCollectionFacet(diamond);

        // Verify collection is registered
        require(collectionFacet.isCollection(collection), "Not a registered collection");

        // Update URI based on collection type
        if (collectionType == ERC721_TYPE) {
            collectionFacet.setCollectionBaseURI(collection, newURI);
            console.log("\nERC721 Base URI updated successfully");
        } else if (collectionType == ERC1155_TYPE) {
            collectionFacet.setCollectionURI(collection, newURI);
            console.log("\nERC1155 URI updated successfully");
        } else {
            revert("Invalid collection type");
        }

        vm.stopBroadcast();

        console.log("\nURI Update Complete");
        console.log("--------------------------------");
        console.log("Collection:", collection);
        console.log("New URI:", newURI);
        if (collectionType == ERC721_TYPE) {
            console.log("Collection Type: ERC721");
        } else {
            console.log("Collection Type: ERC1155");
        }
    }
}
