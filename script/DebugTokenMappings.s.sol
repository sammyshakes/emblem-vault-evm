// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/interfaces/IERC721AVault.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title DebugTokenMappings
 * @notice Script to debug token ID mappings in vault collections
 * @dev Helps identify the correct token IDs for unvaulting operations
 */
contract DebugTokenMappings is Script {
    function run() external {
        // Replace with your actual collection address
        address collectionAddress = 0x403CDaaC0fcdf23B56A399Ca3B97B44636c1Dd22;

        // Replace with your wallet address
        address userAddress = 0xa99526E4Dc81b85C1d248Ca974Eadce81837eCF1; // <- ADD YOUR ADDRESS HERE

        console.log("=== DEBUGGING TOKEN MAPPINGS ===");
        console.log("Collection:", collectionAddress);
        console.log("User:", userAddress);
        console.log("");

        IERC721 collection = IERC721(collectionAddress);
        IERC721AVault vaultCollection = IERC721AVault(collectionAddress);

        try collection.balanceOf(userAddress) returns (uint256 balance) {
            console.log("User owns", balance, "tokens in this collection");
            console.log("");

            if (balance == 0) {
                console.log("ERROR: User owns no tokens in this collection!");
                return;
            }

            // Try to find tokens owned by user
            console.log("=== SCANNING FOR USER'S TOKENS ===");

            uint256 foundTokens = 0;

            // Check a reasonable range (first 1000 token IDs)
            for (uint256 internalId = 1; internalId <= 1000 && foundTokens < balance; internalId++)
            {
                try collection.ownerOf(internalId) returns (address owner) {
                    if (owner == userAddress) {
                        foundTokens++;
                        console.log("FOUND: Token owned by user:");
                        console.log("  Internal Token ID:", internalId);

                        // Try to get external token ID
                        try vaultCollection.getExternalTokenId(internalId) returns (
                            uint256 externalId
                        ) {
                            console.log("  External Token ID:", externalId);
                            console.log("  -> Use External ID", externalId, "for unvaulting");
                        } catch {
                            console.log("  ERROR: No external token ID mapping found");
                        }

                        console.log("");
                    }
                } catch {
                    // Token doesn't exist or error getting owner
                    continue;
                }
            }

            if (foundTokens == 0) {
                console.log("ERROR: Could not find any tokens in the scanned range (1-1000)");
                console.log("Trying alternative approach...");

                // Alternative: Check specific token IDs that might exist
                console.log("=== CHECKING SPECIFIC TOKEN IDS ===");

                uint256[] memory idsToCheck = new uint256[](20);
                idsToCheck[0] = 1;
                idsToCheck[1] = 2;
                idsToCheck[2] = 3;
                idsToCheck[3] = 4;
                idsToCheck[4] = 5;
                idsToCheck[5] = 6;
                idsToCheck[6] = 7;
                idsToCheck[7] = 8;
                idsToCheck[8] = 9;
                idsToCheck[9] = 10;
                idsToCheck[10] = 11;
                idsToCheck[11] = 12;
                idsToCheck[12] = 13;
                idsToCheck[13] = 14;
                idsToCheck[14] = 15;
                idsToCheck[15] = 20;
                idsToCheck[16] = 50;
                idsToCheck[17] = 100;
                idsToCheck[18] = 500;
                idsToCheck[19] = 1000;

                for (uint256 i = 0; i < idsToCheck.length; i++) {
                    uint256 tokenId = idsToCheck[i];

                    try collection.ownerOf(tokenId) returns (address owner) {
                        console.log("Token ID", tokenId, "exists, owned by:", owner);

                        if (owner == userAddress) {
                            console.log("  SUCCESS: This token is owned by user!");

                            try vaultCollection.getExternalTokenId(tokenId) returns (
                                uint256 externalId
                            ) {
                                console.log("  External Token ID:", externalId);
                                console.log("  -> Use External ID", externalId, "for unvaulting");
                            } catch {
                                console.log("  ERROR: No external token ID mapping");
                            }
                        }
                    } catch {
                        // Token doesn't exist
                        continue;
                    }
                }
            }
        } catch {
            console.log("ERROR: getting balance - collection might not exist or not be ERC721");
        }

        // Test the reverse mapping for token ID 9 specifically
        console.log("=== TESTING TOKEN ID 9 SPECIFICALLY ===");

        try vaultCollection.getInternalTokenId(9) returns (uint256 internalId) {
            console.log("SUCCESS: External token ID 9 maps to internal ID:", internalId);

            try collection.ownerOf(internalId) returns (address owner) {
                console.log("  Internal ID", internalId, "is owned by:", owner);
                if (owner == userAddress) {
                    console.log("  SUCCESS: User owns this token - can unvault with external ID 9");
                } else {
                    console.log("  ERROR: User does not own this token");
                }
            } catch {
                console.log("  ERROR: Internal token ID doesn't exist or error getting owner");
            }
        } catch {
            console.log("ERROR: External token ID 9 has no mapping (TokenMappingNotFound)");
            console.log("This confirms the error you're seeing!");
        }

        console.log("");
        console.log("=== RECOMMENDATIONS ===");
        console.log("1. Use the 'External Token ID' values shown above for unvaulting");
        console.log("2. If no external IDs are found, the tokens might not be properly vaulted");
        console.log("3. Check the minting transaction to see what external ID was used");
        console.log("4. The internal token IDs (1,2,3...) are NOT the same as external IDs");
    }
}
