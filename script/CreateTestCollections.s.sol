// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/facets/EmblemVaultCollectionFacet.sol";
import "../src/implementations/ERC721VaultImplementation.sol";

/**
 * @title CreateTestCollections
 * @notice Script to create test vault collections (ERC721 and ERC1155)
 * @dev Run with `forge script script/CreateTestCollections.s.sol:CreateTestCollections --rpc-url bsc_testnet --broadcast -vvvv`
 */
contract CreateTestCollections is Script {
    // Constants from EmblemVaultCollectionFacet
    uint8 constant ERC721_TYPE = 1;
    uint8 constant ERC1155_TYPE = 2;

    function run() external {
        // Get deployment private key
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        address diamondAddress = vm.envAddress("DIAMOND_ADDRESS");

        console.log("Creating Test Collections with deployer:", deployer);
        console.log("Diamond Address:", diamondAddress);

        EmblemVaultCollectionFacet diamond = EmblemVaultCollectionFacet(diamondAddress);

        vm.startBroadcast(deployerPrivateKey);

        // Create ERC721 Collection
        address erc721Collection =
            diamond.createVaultCollection("Diamond Hands Collection", "DHC", ERC721_TYPE);
        console.log("\nERC721 Collection created at:", erc721Collection);

        // // Create ERC1155 Collection
        // address erc1155Collection = diamond.createVaultCollection(
        //     "Test ERC1155 Vault Collection",
        //     "https://api.emblem.finance/erc1155/metadata/{id}.json",
        //     ERC1155_TYPE
        // );
        // console.log("\nERC1155 Collection created at:", erc1155Collection);

        vm.stopBroadcast();

        // Verify collections were created successfully
        require(diamond.isCollection(erc721Collection), "ERC721 collection not registered");
        // require(diamond.isCollection(erc1155Collection), "ERC1155 collection not registered");

        console.log("\nTest Collections Creation Complete");
        console.log("--------------------------------");
        console.log("ERC721 Collection:", erc721Collection);
        console.log("ERC721 Base URI: https://v2.emblemvault.io/meta/ (default)");
        // console.log("ERC1155 Collection:", erc1155Collection);
        // console.log("ERC1155 URI: https://api.emblem.finance/erc1155/metadata/{id}.json");
    }
}
