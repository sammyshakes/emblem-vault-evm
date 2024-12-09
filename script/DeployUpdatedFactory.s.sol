// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/factories/VaultCollectionFactory.sol";

/**
 * @title DeployUpdatedFactory
 * @notice Script to deploy updated factory using existing beacons
 * @dev Run with `forge script script/DeployUpdatedFactory.s.sol:DeployUpdatedFactory --rpc-url bsc_testnet --broadcast -vvvv`
 */
contract DeployUpdatedFactory is Script {
    function run() external {
        // Get deployment private key
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // Get old factory address
        address oldFactory = vm.envAddress("COLLECTION_FACTORY_ADDRESS");

        console.log("Deploying Updated Factory with deployer:", deployer);
        console.log("Old Factory:", oldFactory);

        // Get beacon addresses from old factory
        VaultCollectionFactory factory = VaultCollectionFactory(oldFactory);
        address erc721Beacon = factory.erc721Beacon();
        address erc1155Beacon = factory.erc1155Beacon();

        console.log("Using existing beacons:");
        console.log("ERC721 Beacon:", erc721Beacon);
        console.log("ERC1155 Beacon:", erc1155Beacon);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy new factory with existing beacons
        VaultCollectionFactory newFactory = new VaultCollectionFactory(erc721Beacon, erc1155Beacon);
        console.log("\nNew factory deployed at:", address(newFactory));

        vm.stopBroadcast();

        console.log("\nFactory Deployment Summary:");
        console.log("--------------------------------");
        console.log("Old Factory:", oldFactory);
        console.log("New Factory:", address(newFactory));
        console.log("ERC721 Beacon:", erc721Beacon);
        console.log("ERC1155 Beacon:", erc1155Beacon);
    }
}
