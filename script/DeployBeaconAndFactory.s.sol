// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/beacon/VaultBeacon.sol";
import "../src/factories/VaultCollectionFactory.sol";
import "../src/facets/EmblemVaultCollectionFacet.sol";

/**
 * @title DeployBeaconAndFactory
 * @notice Script to deploy beacons and factory using verified implementations
 * @dev Run with `forge script script/DeployBeaconAndFactory.s.sol:DeployBeaconAndFactory --rpc-url <your_rpc_url> --broadcast --verify`
 */
contract DeployBeaconAndFactory is Script {
    event Deployed(string name, address addr);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        address diamond = vm.envAddress("DIAMOND_ADDRESS");
        address erc721Implementation = vm.envAddress("ERC721_IMPLEMENTATION");
        address erc1155Implementation = vm.envAddress("ERC1155_IMPLEMENTATION");

        console.log("Deploying Beacon System with deployer:", deployer);
        console.log("Using implementations:");
        console.log("- ERC721:", erc721Implementation);
        console.log("- ERC1155:", erc1155Implementation);
        console.log("Diamond address:", diamond);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy Beacons
        VaultBeacon erc721Beacon = new ERC721VaultBeacon(erc721Implementation);
        emit Deployed("ERC721VaultBeacon", address(erc721Beacon));
        console.log("ERC721VaultBeacon deployed at:", address(erc721Beacon));

        VaultBeacon erc1155Beacon = new ERC1155VaultBeacon(erc1155Implementation);
        emit Deployed("ERC1155VaultBeacon", address(erc1155Beacon));
        console.log("ERC1155VaultBeacon deployed at:", address(erc1155Beacon));

        // Deploy Factory
        VaultCollectionFactory factory =
            new VaultCollectionFactory(address(erc721Beacon), address(erc1155Beacon), diamond);
        emit Deployed("VaultCollectionFactory", address(factory));
        console.log("VaultCollectionFactory deployed at:", address(factory));

        // Set factory in Diamond's CollectionFacet
        EmblemVaultCollectionFacet(diamond).setCollectionFactory(address(factory));
        console.log("Factory set in Diamond's CollectionFacet");

        vm.stopBroadcast();

        // Log deployment summary
        console.log("\nBeacon System Deployment Summary:");
        console.log("--------------------------------");
        console.log("ERC721 Beacon:", address(erc721Beacon));
        console.log("ERC1155 Beacon:", address(erc1155Beacon));
        console.log("Collection Factory:", address(factory));
        console.log("\nConnections:");
        console.log("- Factory connected to Diamond:", diamond);
        console.log("- Factory set in Diamond's CollectionFacet");
        console.log("- Beacons using verified implementations");
    }
}
