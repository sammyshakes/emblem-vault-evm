// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {IDiamondLoupe} from "../src/interfaces/IDiamondLoupe.sol";

contract InspectDiamondSimple is Script {
    function run() external view {
        address diamond = vm.envAddress("DIAMOND_ADDRESS");
        console.log("Inspecting Diamond at:", diamond);

        // Get all facets and their selectors
        IDiamondLoupe.Facet[] memory facets = IDiamondLoupe(diamond).facets();

        console.log("\nFacets:");
        console.log("-------");
        for (uint256 i = 0; i < facets.length; i++) {
            console.log("Facet %d: %s", i, facets[i].facetAddress);
            console.log("Function Selectors:");
            for (uint256 j = 0; j < facets[i].functionSelectors.length; j++) {
                console.log("  - 0x%x", uint32(bytes4(facets[i].functionSelectors[j])));
            }
            console.log("");
        }

        // Check initialization state using low-level call
        (bool success, bytes memory data) =
            diamond.staticcall(abi.encodeWithSignature("isInitialized()"));
        require(success, "Call failed");
        bool isInitialized = abi.decode(data, (bool));
        console.log("\nDiamond Initialization State:");
        console.log("----------------------------");
        console.log("Is Initialized:", isInitialized);

        // Get configuration using low-level call
        (success, data) = diamond.staticcall(abi.encodeWithSignature("getConfiguration()"));
        require(success, "Call failed");
        (
            string memory baseUri,
            address recipientAddr,
            bool unvaultingEnabled,
            bool byPassable,
            uint256 witnessCount
        ) = abi.decode(data, (string, address, bool, bool, uint256));

        console.log("\nDiamond Configuration:");
        console.log("---------------------");
        console.log("Base URI:", baseUri);
        console.log("Recipient Address:", recipientAddr);
        console.log("Unvaulting Enabled:", unvaultingEnabled);
        console.log("Bypassable:", byPassable);
        console.log("Witness Count:", witnessCount);

        // Search for specific function selectors
        bytes4 oldBuyWithSignedPrice = bytes4(
            keccak256(
                "buyWithSignedPrice(address,address,uint256,address,uint256,uint256,bytes,bytes,uint256)"
            )
        );
        bytes4 newBuyWithSignedPrice = bytes4(
            keccak256(
                "buyWithSignedPrice(address,address,uint256,address,uint256,uint256,bytes,uint256[],uint256)"
            )
        );
        bytes4 oldBatchBuyWithSignedPrice = bytes4(
            keccak256(
                "batchBuyWithSignedPrice((address,address,uint256[],address,uint256[],uint256[],bytes[],bytes[],uint256[]))"
            )
        );
        bytes4 newBatchBuyWithSignedPrice = bytes4(
            keccak256(
                "batchBuyWithSignedPrice((address,address,uint256[],address,uint256[],uint256[],bytes[],uint256[][],uint256[]))"
            )
        );
        bytes4 oldUnvault = bytes4(keccak256("unvault(address,uint256)"));
        bytes4 newUnvault = bytes4(keccak256("unvault(address,uint256)"));
        bytes4 oldUnvaultWithSignedPrice = bytes4(
            keccak256("unvaultWithSignedPrice(address,uint256,uint256,address,uint256,bytes)")
        );
        bytes4 newUnvaultWithSignedPrice = bytes4(
            keccak256("unvaultWithSignedPrice(address,uint256,uint256,address,uint256,bytes)")
        );

        console.log("\nSearching for specific function selectors:");
        console.log("----------------------------------------");
        console.log(
            "Old buyWithSignedPrice (0x%x): %s",
            uint32(oldBuyWithSignedPrice),
            _findFacetForSelector(facets, oldBuyWithSignedPrice)
        );
        console.log(
            "New buyWithSignedPrice (0x%x): %s",
            uint32(newBuyWithSignedPrice),
            _findFacetForSelector(facets, newBuyWithSignedPrice)
        );
        console.log(
            "Old batchBuyWithSignedPrice (0x%x): %s",
            uint32(oldBatchBuyWithSignedPrice),
            _findFacetForSelector(facets, oldBatchBuyWithSignedPrice)
        );
        console.log(
            "New batchBuyWithSignedPrice (0x%x): %s",
            uint32(newBatchBuyWithSignedPrice),
            _findFacetForSelector(facets, newBatchBuyWithSignedPrice)
        );
        console.log(
            "Old unvault (0x%x): %s", uint32(oldUnvault), _findFacetForSelector(facets, oldUnvault)
        );
        console.log(
            "New unvault (0x%x): %s", uint32(newUnvault), _findFacetForSelector(facets, newUnvault)
        );
        console.log(
            "Old unvaultWithSignedPrice (0x%x): %s",
            uint32(oldUnvaultWithSignedPrice),
            _findFacetForSelector(facets, oldUnvaultWithSignedPrice)
        );
        console.log(
            "New unvaultWithSignedPrice (0x%x): %s",
            uint32(newUnvaultWithSignedPrice),
            _findFacetForSelector(facets, newUnvaultWithSignedPrice)
        );
    }

    function _findFacetForSelector(IDiamondLoupe.Facet[] memory facets, bytes4 selector)
        internal
        pure
        returns (string memory)
    {
        for (uint256 i = 0; i < facets.length; i++) {
            for (uint256 j = 0; j < facets[i].functionSelectors.length; j++) {
                if (facets[i].functionSelectors[j] == selector) {
                    return _addressToString(facets[i].facetAddress);
                }
            }
        }
        return "Not found";
    }

    function _addressToString(address addr) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint256(uint160(addr)) / (2 ** (8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = _char(hi);
            s[2 * i + 1] = _char(lo);
        }
        return string(abi.encodePacked("0x", string(s)));
    }

    function _char(bytes1 b) internal pure returns (bytes1) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}
