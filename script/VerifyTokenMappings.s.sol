// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/interfaces/IERC721AVault.sol";
import "../src/interfaces/IERC721.sol";

contract VerifyTokenMappings is Script {
    function run() external view {
        address collection = 0x403CDaaC0fcdf23B56A399Ca3B97B44636c1Dd22;
        uint256 externalTokenId = 10_000;

        console.log("=== TOKEN MAPPING VERIFICATION ===");
        console.log("Collection:", collection);
        console.log("External Token ID:", externalTokenId);

        IERC721AVault vault = IERC721AVault(collection);

        try vault.getInternalTokenId(externalTokenId) returns (uint256 internalTokenId) {
            console.log("SUCCESS: Internal Token ID:", internalTokenId);

            // Check if internal token exists
            IERC721 erc721 = IERC721(collection);
            try erc721.ownerOf(internalTokenId) returns (address owner) {
                console.log("SUCCESS: Token exists, owner:", owner);
            } catch {
                console.log("ERROR: Internal token does not exist or was burned");
            }

            // Test reverse mapping
            try vault.getExternalTokenId(internalTokenId) returns (uint256 reversedExternalId) {
                console.log("SUCCESS: Reverse mapping successful, External ID:", reversedExternalId);
                if (reversedExternalId == externalTokenId) {
                    console.log("SUCCESS: Mappings are consistent");
                } else {
                    console.log("ERROR: Mapping inconsistency detected!");
                }
            } catch {
                console.log("ERROR: Reverse mapping failed");
            }
        } catch {
            console.log("ERROR: External Token ID not found or mapping broken");

            // Check if external token was never minted or mapping was deleted
            try vault.getExternalTokenId(9) returns (uint256 externalId) {
                console.log("Internal Token ID 9 maps to External ID:", externalId);
            } catch {
                console.log("Internal Token ID 9 has no mapping");
            }
        }

        // Test direct ownerOf with external ID (this should fail)
        IERC721 erc721 = IERC721(collection);
        try erc721.ownerOf(externalTokenId) {
            console.log("WARNING: ownerOf(externalTokenId) succeeded - this shouldn't happen");
        } catch {
            console.log(
                "SUCCESS: ownerOf(externalTokenId) failed as expected - use internal token ID"
            );
        }
    }
}
