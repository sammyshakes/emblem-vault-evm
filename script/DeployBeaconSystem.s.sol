// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/implementations/ERC721VaultImplementation.sol";
import "../src/implementations/ERC1155VaultImplementation.sol";
import "../src/beacon/VaultBeacon.sol";
import "../src/factories/VaultCollectionFactory.sol";

/**
 * @title DeployBeaconSystem
 * @notice Script to deploy the complete beacon system for vault collections
 * @dev Run with `forge script script/DeployBeaconSystem.s.sol:DeployBeaconSystem --rpc-url <your_rpc_url> --broadcast`
 */
contract DeployBeaconSystem is Script {
    // Events for tracking deployments
    event Deployed(string name, address addr);

    function run() external {
        // Get deployment private key
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying Beacon System with deployer:", deployer);

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy Implementations
        ERC721VaultImplementation erc721Implementation = new ERC721VaultImplementation();
        emit Deployed("ERC721VaultImplementation", address(erc721Implementation));
        console.log("ERC721VaultImplementation deployed at:", address(erc721Implementation));

        ERC1155VaultImplementation erc1155Implementation = new ERC1155VaultImplementation();
        emit Deployed("ERC1155VaultImplementation", address(erc1155Implementation));
        console.log("ERC1155VaultImplementation deployed at:", address(erc1155Implementation));

        // 2. Deploy Beacons
        VaultBeacon erc721Beacon = new ERC721VaultBeacon(address(erc721Implementation));
        emit Deployed("ERC721VaultBeacon", address(erc721Beacon));
        console.log("ERC721VaultBeacon deployed at:", address(erc721Beacon));

        VaultBeacon erc1155Beacon = new ERC1155VaultBeacon(address(erc1155Implementation));
        emit Deployed("ERC1155VaultBeacon", address(erc1155Beacon));
        console.log("ERC1155VaultBeacon deployed at:", address(erc1155Beacon));

        // 3. Deploy Factory
        VaultCollectionFactory factory =
            new VaultCollectionFactory(address(erc721Beacon), address(erc1155Beacon));
        emit Deployed("VaultCollectionFactory", address(factory));
        console.log("VaultCollectionFactory deployed at:", address(factory));

        vm.stopBroadcast();

        // Log deployment summary
        console.log("\nBeacon System Deployment Summary:");
        console.log("--------------------------------");
        console.log("ERC721 Implementation:", address(erc721Implementation));
        console.log("ERC1155 Implementation:", address(erc1155Implementation));
        console.log("ERC721 Beacon:", address(erc721Beacon));
        console.log("ERC1155 Beacon:", address(erc1155Beacon));
        console.log("Collection Factory:", address(factory));
    }
}
