// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/facets/EmblemVaultCollectionFacet.sol";
import "../src/implementations/ERC721VaultImplementation.sol";

/**
 * @title CreatePriorityCollections
 * @notice Script to create priority vault collections for each chain deployment
 * @dev Example commands:
 *
 * Abstract Mainnet:
 * forge script script/CreatePriorityCollections.s.sol:CreatePriorityCollections --rpc-url https://api.mainnet.abs.xyz --broadcast -vvvv
 *
 * Base:
 * forge script script/CreatePriorityCollections.s.sol:CreatePriorityCollections --rpc-url https://mainnet.base.org --broadcast -vvvv
 *
 * Merlin:
 * forge script script/CreatePriorityCollections.s.sol:CreatePriorityCollections --rpc-url https://rpc.merlinchain.io --broadcast -vvvv
 *
 * Arbitrum:
 * forge script script/CreatePriorityCollections.s.sol:CreatePriorityCollections --rpc-url https://arb1.arbitrum.io/rpc --broadcast -vvvv
 *
 * Apechain:
 * forge script script/CreatePriorityCollections.s.sol:CreatePriorityCollections --rpc-url https://apechain.calderachain.xyz/http --broadcast -vvvv
 *
 * For testnets, use the corresponding testnet RPC URLs.
 *
 * Chain RPC URLs:
 * - Abstract Mainnet: https://api.mainnet.abs.xyz (Chain ID: 2741)
 * - Base: https://mainnet.base.org (Chain ID: 8453)
 * - Merlin: https://rpc.merlinchain.io (Chain ID: 4200)
 * - Arbitrum: https://arb1.arbitrum.io/rpc (Chain ID: 42161)
 * - Apechain: https://apechain.calderachain.xyz/http (Chain ID: 33139)
 *
 * Testnets:
 * - Abstract Testnet: https://api.testnet.abs.xyz (Chain ID: 11124)
 * - Base Sepolia: https://sepolia.base.org (Chain ID: 84532)
 * - Merlin Testnet: https://testnet-rpc.merlinchain.io (Chain ID: 686868)
 * - Arbitrum Sepolia: https://sepolia-rollup.arbitrum.io/rpc (Chain ID: 421614)
 * - Apechain Curtis: https://curtis.rpc.caldera.xyz/http (Chain ID: 33111)
 */
contract CreatePriorityCollections is Script {
    // Chain IDs
    uint256 constant ABSTRACT_MAINNET = 2741;
    uint256 constant BASE_MAINNET = 8453;
    uint256 constant MERLIN_MAINNET = 4200;
    uint256 constant ARBITRUM_MAINNET = 42_161;
    uint256 constant APECHAIN_MAINNET = 33_139;

    uint256 constant SEPOLIA = 11_155_111;
    uint256 constant ABSTRACT_TESTNET = 11_124;
    uint256 constant BASE_TESTNET = 84_532;
    uint256 constant MERLIN_TESTNET = 686_868;
    uint256 constant ARBITRUM_TESTNET = 421_614;
    uint256 constant APECHAIN_TESTNET = 33_111;

    // Constants from EmblemVaultCollectionFacet
    uint8 constant ERC721_TYPE = 1;
    uint8 constant ERC1155_TYPE = 2;

    // Base URI prefix
    string constant BASE_URI_PREFIX = "https://v2.emblemvault.io/v3/meta/";

    // Helper function to get chain name
    function getChainName(uint256 chainId) internal pure returns (string memory) {
        if (chainId == ABSTRACT_MAINNET) return "Abstract Mainnet";
        if (chainId == BASE_MAINNET) return "Base Mainnet";
        if (chainId == MERLIN_MAINNET) return "Merlin Mainnet";
        if (chainId == ARBITRUM_MAINNET) return "Arbitrum Mainnet";
        if (chainId == APECHAIN_MAINNET) return "Apechain Mainnet";
        if (chainId == ABSTRACT_TESTNET) return "Abstract Testnet";
        if (chainId == BASE_TESTNET) return "Base Sepolia";
        if (chainId == MERLIN_TESTNET) return "Merlin Testnet";
        if (chainId == ARBITRUM_TESTNET) return "Arbitrum Sepolia";
        if (chainId == APECHAIN_TESTNET) return "Apechain Curtis";
        if (chainId == SEPOLIA) return "Ethereum Sepolia";
        return "Unknown Chain";
    }

    // Helper function to validate chain ID
    function isValidChain(uint256 chainId) internal pure returns (bool) {
        return chainId == ABSTRACT_MAINNET || chainId == BASE_MAINNET || chainId == MERLIN_MAINNET
            || chainId == ARBITRUM_MAINNET || chainId == APECHAIN_MAINNET || chainId == ABSTRACT_TESTNET
            || chainId == BASE_TESTNET || chainId == MERLIN_TESTNET || chainId == ARBITRUM_TESTNET
            || chainId == APECHAIN_TESTNET || chainId == SEPOLIA;
    }

    function run() external {
        // Get current chain ID and validate
        uint256 chainId = block.chainid;
        require(isValidChain(chainId), "Unsupported chain ID");

        string memory chainName = getChainName(chainId);
        console.log("\nDeploying to %s (Chain ID: %s)", chainName, chainId);

        // Get deployment private key
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        address diamondAddress = vm.envAddress("DIAMOND_ADDRESS");

        console.log("Creating Priority Collections with deployer:", deployer);
        console.log("Diamond Address:", diamondAddress);

        EmblemVaultCollectionFacet diamond = EmblemVaultCollectionFacet(diamondAddress);

        vm.startBroadcast(deployerPrivateKey);

        // Create ERC1155 Collections
        address rarepepeCollection =
            diamond.createVaultCollection("Rare Pepe", "PEPE", ERC1155_TYPE);
        console.log("\nRare Pepe Collection created at:", rarepepeCollection);

        address sogCollection =
            diamond.createVaultCollection("Spells of Genesis", "SOG", ERC1155_TYPE);
        console.log("\nSpells of Genesis Collection created at:", sogCollection);

        address fakeraresCollection =
            diamond.createVaultCollection("Fake Rares", "FAKE", ERC1155_TYPE);
        console.log("\nFake Rares Collection created at:", fakeraresCollection);

        // Create ERC721A Collections
        address embellsCollection = diamond.createVaultCollection("EmBells", "BELL", ERC721_TYPE);
        console.log("\nEmBells Collection created at:", embellsCollection);

        address openCollection = diamond.createVaultCollection("Emblem Open", "OPEN", ERC721_TYPE);
        console.log("\nEmblem Open Collection created at:", openCollection);

        // Set URIs for all collections with their contract addresses
        string memory rarepepeURI =
            string.concat(BASE_URI_PREFIX, vm.toString(rarepepeCollection), "/");
        string memory sogURI = string.concat(BASE_URI_PREFIX, vm.toString(sogCollection), "/");
        string memory fakeraresURI =
            string.concat(BASE_URI_PREFIX, vm.toString(fakeraresCollection), "/");
        string memory embellsURI =
            string.concat(BASE_URI_PREFIX, vm.toString(embellsCollection), "/");
        string memory openURI = string.concat(BASE_URI_PREFIX, vm.toString(openCollection), "/");

        diamond.setCollectionURI(rarepepeCollection, rarepepeURI);
        diamond.setCollectionURI(sogCollection, sogURI);
        diamond.setCollectionURI(fakeraresCollection, fakeraresURI);
        diamond.setCollectionBaseURI(embellsCollection, embellsURI);
        diamond.setCollectionBaseURI(openCollection, openURI);

        vm.stopBroadcast();

        // Verify collections were created successfully
        require(diamond.isCollection(rarepepeCollection), "Rare Pepe collection not registered");
        require(diamond.isCollection(sogCollection), "Spells of Genesis collection not registered");
        require(diamond.isCollection(fakeraresCollection), "Fake Rares collection not registered");
        require(diamond.isCollection(embellsCollection), "EmBells collection not registered");
        require(diamond.isCollection(openCollection), "Emblem Open collection not registered");

        console.log("\nPriority Collections Creation Complete");
        console.log("--------------------------------");
        console.log("ERC1155 Collections:");
        console.log("1. Rare Pepe:", rarepepeCollection);
        console.log("   URI:", rarepepeURI);
        console.log("2. Spells of Genesis:", sogCollection);
        console.log("   URI:", sogURI);
        console.log("3. Fake Rares:", fakeraresCollection);
        console.log("   URI:", fakeraresURI);
        console.log("\nERC721A Collections:");
        console.log("4. EmBells:", embellsCollection);
        console.log("   Base URI:", embellsURI);
        console.log("5. Emblem Open:", openCollection);
        console.log("   Base URI:", openURI);
    }
}
