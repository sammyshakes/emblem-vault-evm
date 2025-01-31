// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {EmblemVaultMintFacet} from "../src/facets/EmblemVaultMintFacet.sol";
import {ERC721VaultImplementation} from "../src/implementations/ERC721VaultImplementation.sol";
import {ERC1155VaultImplementation} from "../src/implementations/ERC1155VaultImplementation.sol";

/**
 * @title TestMintPriorityCollections
 * @notice Script to mint one asset from each priority collection to test functionality
 */
contract TestMintPriorityCollections is Script {
    function run() external {
        // Get deployment private key
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        address diamondAddress = vm.envAddress("DIAMOND_ADDRESS");

        // Get collection addresses
        address pepeCollection = vm.envAddress("PEPE_COLLECTION");
        address sogCollection = vm.envAddress("SOG_COLLECTION");
        address fakeRaresCollection = vm.envAddress("FAKE_RARES_COLLECTION");
        address embellsCollection = vm.envAddress("EMBELLS_COLLECTION");
        address openCollection = vm.envAddress("OPEN_COLLECTION");

        console.log("\nTesting Priority Collections Minting");
        console.log("--------------------------------");
        console.log("Minting to deployer:", deployer);
        console.log("Diamond Address:", diamondAddress);

        EmblemVaultMintFacet diamond = EmblemVaultMintFacet(diamondAddress);

        vm.startBroadcast(deployerPrivateKey);

        // Get witness private key for signing
        uint256 witnessPrivateKey = vm.envUint("PRIVATE_KEY");
        address witness = vm.addr(witnessPrivateKey);

        console.log("\nWitness Address:", witness);
        console.log("Chain ID:", block.chainid);

        // Mint ERC1155 tokens (id 1 for testing)
        console.log("\nMinting ERC1155 Collections:");

        // Generate signatures for each mint
        bytes memory pepeSignature = _generateSignature(
            witnessPrivateKey,
            pepeCollection,
            address(0), // ETH payment
            0, // Free mint
            deployer,
            1000, // tokenId
            1, // nonce
            1 // amount
        );

        bytes memory sogSignature = _generateSignature(
            witnessPrivateKey, sogCollection, address(0), 0, deployer, 1000, 2, 1
        );

        bytes memory fakeRaresSignature = _generateSignature(
            witnessPrivateKey, fakeRaresCollection, address(0), 0, deployer, 1000, 3, 1
        );

        bytes memory embellsSignature = _generateSignature(
            witnessPrivateKey, embellsCollection, address(0), 0, deployer, 1000, 4, 1
        );

        bytes memory openSignature = _generateSignature(
            witnessPrivateKey, openCollection, address(0), 0, deployer, 1000, 5, 1
        );

        // Generate serial numbers for each token
        uint256 pepeSerial = 1_000_001;
        uint256 sogSerial = 2_000_001;
        uint256 fakeRaresSerial = 3_000_001;

        console.log("\n1. Minting Rare Pepe token");
        diamond.buyWithSignedPrice{value: 0}(
            pepeCollection,
            address(0), // ETH payment
            0, // Free mint
            deployer,
            1000, // tokenId
            1, // nonce
            pepeSignature,
            abi.encode(pepeSerial), // Encode single serial number
            1 // amount
        );
        console.log("Minted token 1 to:", deployer);

        console.log("\n2. Minting Spells of Genesis token");
        diamond.buyWithSignedPrice{value: 0}(
            sogCollection, address(0), 0, deployer, 1000, 2, sogSignature, abi.encode(sogSerial), 1
        );
        console.log("Minted token 1 to:", deployer);

        console.log("\n3. Minting Fake Rares token");
        diamond.buyWithSignedPrice{value: 0}(
            fakeRaresCollection,
            address(0),
            0,
            deployer,
            1000,
            3,
            fakeRaresSignature,
            abi.encode(fakeRaresSerial),
            1
        );
        console.log("Minted token 1 to:", deployer);

        // Mint ERC721 tokens (auto-incrementing ids)
        console.log("\nMinting ERC721A Collections:");

        console.log("\n4. Minting EmBells token");
        diamond.buyWithSignedPrice{value: 0}(
            embellsCollection, address(0), 0, deployer, 1000, 4, embellsSignature, "", 1
        );
        console.log("Minted token to:", deployer);

        console.log("\n5. Minting Emblem Open token");
        diamond.buyWithSignedPrice{value: 0}(
            openCollection, address(0), 0, deployer, 1000, 5, openSignature, "", 1
        );
        console.log("Minted token to:", deployer);

        vm.stopBroadcast();

        // Verify balances
        console.log("\nVerifying Balances:");

        // ERC1155 balances
        ERC1155VaultImplementation pepe = ERC1155VaultImplementation(pepeCollection);
        ERC1155VaultImplementation sog = ERC1155VaultImplementation(sogCollection);
        ERC1155VaultImplementation fakeRares = ERC1155VaultImplementation(fakeRaresCollection);

        console.log("\nERC1155 Balances:");
        console.log("Rare Pepe token 1:", pepe.balanceOf(deployer, 1));
        console.log("Spells of Genesis token 1:", sog.balanceOf(deployer, 1));
        console.log("Fake Rares token 1:", fakeRares.balanceOf(deployer, 1));

        // ERC721 balances
        ERC721VaultImplementation embells = ERC721VaultImplementation(embellsCollection);
        ERC721VaultImplementation open = ERC721VaultImplementation(openCollection);

        console.log("\nERC721A Balances:");
        console.log("EmBells total balance:", embells.balanceOf(deployer));
        console.log("Emblem Open total balance:", open.balanceOf(deployer));

        console.log("\nTest Minting Complete");
    }

    /// @notice Helper function to generate signatures for minting
    /// @dev Uses the witness private key to sign mint parameters according to LibSignature
    function _generateSignature(
        uint256 witnessPrivateKey,
        address nftAddress,
        address payment,
        uint256 price,
        address to,
        uint256 tokenId,
        uint256 nonce,
        uint256 amount
    ) internal view returns (bytes memory) {
        // Generate hash exactly as in LibSignature.getStandardSignatureHash
        bytes32 hash = keccak256(
            abi.encodePacked(nftAddress, payment, price, to, tokenId, nonce, amount, block.chainid)
        );

        // Add Ethereum signed message prefix
        bytes32 prefixedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));

        // Sign the hash
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(witnessPrivateKey, prefixedHash);

        console.log("\nSignature Debug for %s:", nftAddress);
        console.log("Parameters:");
        console.log("- NFT Address:", nftAddress);
        console.log("- Payment:", payment);
        console.log("- Price:", price);
        console.log("- To:", to);
        console.log("- Token ID:", tokenId);
        console.log("- Nonce:", nonce);
        console.log("- Amount:", amount);
        console.log("- Chain ID:", block.chainid);
        console.log("\nHashes:");
        console.log("- Raw Hash:", uint256(hash));
        console.log("- Prefixed Hash:", uint256(prefixedHash));
        console.log("\nSignature:");
        console.log("- v:", v);
        console.log("- r:", uint256(r));
        console.log("- s:", uint256(s));
        return abi.encodePacked(r, s, v);
    }
}
