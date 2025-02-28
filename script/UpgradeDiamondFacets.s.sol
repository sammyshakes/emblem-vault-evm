// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {IDiamondCut} from "../src/interfaces/IDiamondCut.sol";
import {DiamondCutFacet} from "../src/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../src/facets/DiamondLoupeFacet.sol";
import {OwnershipFacet} from "../src/facets/OwnershipFacet.sol";
import {EmblemVaultCoreFacet} from "../src/facets/EmblemVaultCoreFacet.sol";
import {EmblemVaultUnvaultFacet} from "../src/facets/EmblemVaultUnvaultFacet.sol";
import {EmblemVaultMintFacet} from "../src/facets/EmblemVaultMintFacet.sol";
import {EmblemVaultCollectionFacet} from "../src/facets/EmblemVaultCollectionFacet.sol";
import {EmblemVaultInitFacet} from "../src/facets/EmblemVaultInitFacet.sol";

contract UpgradeDiamondFacets is Script {
    event FacetUpgraded(string name, address addr);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address diamond = vm.envAddress("DIAMOND_ADDRESS");
        string memory facetsToUpgrade = vm.envString("FACETS_TO_UPGRADE");

        console.log("Upgrading Diamond Facets for diamond at:", diamond);
        console.log("Facets to upgrade:", facetsToUpgrade);

        vm.startBroadcast(deployerPrivateKey);

        // Parse facets to upgrade
        string[] memory facetNames = _split(facetsToUpgrade, ",");

        // Calculate exact number of cuts needed
        uint256 totalCuts = 0;
        for (uint256 i = 0; i < facetNames.length; i++) {
            string memory facetName = facetNames[i];
            if (_strEquals(facetName, "MintFacet")) {
                totalCuts += 2; // Remove old + Add new
            } else if (_strEquals(facetName, "UnvaultFacet")) {
                totalCuts += 1; // Replace (no function signature changes)
            } else if (_strEquals(facetName, "CoreFacet")) {
                totalCuts += 1; // Replace (no function signature changes)
            }
        }

        console.log("Total cuts needed:", totalCuts);
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](totalCuts);
        uint256 cutIndex = 0;

        // Deploy and prepare upgrades for each facet
        for (uint256 i = 0; i < facetNames.length; i++) {
            string memory facetName = facetNames[i];
            console.log("Processing facet:", facetName);

            if (_strEquals(facetName, "MintFacet")) {
                EmblemVaultMintFacet newFacet = new EmblemVaultMintFacet();

                // First remove old functions with bytes parameter
                bytes4[] memory oldSelectors = new bytes4[](2);
                // Use hardcoded selectors for the old functions that we calculated with cast sig
                oldSelectors[0] = 0xebc7fd7c; // buyWithSignedPrice with bytes parameter
                oldSelectors[1] = 0xa016e28e; // batchBuyWithSignedPrice with bytes[] parameter
                cut[cutIndex++] = IDiamondCut.FacetCut({
                    facetAddress: address(0),
                    action: IDiamondCut.FacetCutAction.Remove,
                    functionSelectors: oldSelectors
                });

                // Then add new functions with uint256[] parameter
                bytes4[] memory newSelectors = new bytes4[](2);
                // Use the selectors from the contract for the new functions, like in the deploy script
                newSelectors[0] = EmblemVaultMintFacet.buyWithSignedPrice.selector;
                newSelectors[1] = EmblemVaultMintFacet.batchBuyWithSignedPrice.selector;
                cut[cutIndex++] = _createAddCut(address(newFacet), newSelectors);

                emit FacetUpgraded("MintFacet", address(newFacet));
            } else if (_strEquals(facetName, "UnvaultFacet")) {
                EmblemVaultUnvaultFacet newFacet = new EmblemVaultUnvaultFacet();

                // Replace all functions (no signature changes)
                bytes4[] memory selectors = new bytes4[](9);
                selectors[0] = EmblemVaultUnvaultFacet.unvault.selector;
                selectors[1] = EmblemVaultUnvaultFacet.unvaultWithSignedPrice.selector;
                selectors[2] = EmblemVaultUnvaultFacet.setUnvaultingEnabled.selector;
                selectors[3] = EmblemVaultUnvaultFacet.setBurnAddress.selector;
                selectors[4] = EmblemVaultUnvaultFacet.isTokenUnvaulted.selector;
                selectors[5] = EmblemVaultUnvaultFacet.getTokenUnvaulter.selector;
                selectors[6] = EmblemVaultUnvaultFacet.getCollectionUnvaultCount.selector;
                selectors[7] = EmblemVaultUnvaultFacet.getUnvaultVersion.selector;
                selectors[8] = EmblemVaultUnvaultFacet.batchUnvaultWithSignedPrice.selector;
                cut[cutIndex++] = _createReplaceCut(address(newFacet), selectors);

                emit FacetUpgraded("UnvaultFacet", address(newFacet));
            } else if (_strEquals(facetName, "CoreFacet")) {
                EmblemVaultCoreFacet newFacet = new EmblemVaultCoreFacet();

                // Replace all functions (no signature changes)
                bytes4[] memory selectors = new bytes4[](12);
                selectors[0] = EmblemVaultCoreFacet.lockVault.selector;
                selectors[1] = EmblemVaultCoreFacet.unlockVault.selector;
                selectors[2] = EmblemVaultCoreFacet.isVaultLocked.selector;
                selectors[3] = EmblemVaultCoreFacet.addWitness.selector;
                selectors[4] = EmblemVaultCoreFacet.removeWitness.selector;
                selectors[5] = EmblemVaultCoreFacet.setRecipientAddress.selector;
                selectors[6] = EmblemVaultCoreFacet.setMetadataBaseUri.selector;
                selectors[7] = EmblemVaultCoreFacet.isWitness.selector;
                selectors[8] = EmblemVaultCoreFacet.getWitnessCount.selector;
                selectors[9] = EmblemVaultCoreFacet.getCoreVersion.selector;
                selectors[10] = EmblemVaultCoreFacet.setVaultFactory.selector;
                selectors[11] = EmblemVaultCoreFacet.getVaultFactory.selector;
                cut[cutIndex++] = _createReplaceCut(address(newFacet), selectors);

                emit FacetUpgraded("CoreFacet", address(newFacet));
            }
        }

        // Create final cuts array with exact size
        IDiamondCut.FacetCut[] memory finalCuts = new IDiamondCut.FacetCut[](cutIndex);
        for (uint256 i = 0; i < cutIndex; i++) {
            finalCuts[i] = cut[i];
        }

        // Perform diamond cut to upgrade facets
        IDiamondCut(diamond).diamondCut(finalCuts, address(0), "");

        vm.stopBroadcast();

        // Log upgrade summary
        console.log("\nDiamond Facets Upgrade Summary:");
        console.log("--------------------------------");
        console.log("Diamond:", diamond);
        console.log("Facets upgraded:", facetsToUpgrade);
    }

    function _createReplaceCut(address facet, bytes4[] memory selectors)
        internal
        pure
        returns (IDiamondCut.FacetCut memory)
    {
        return IDiamondCut.FacetCut({
            facetAddress: facet,
            action: IDiamondCut.FacetCutAction.Replace,
            functionSelectors: selectors
        });
    }

    function _createAddCut(address facet, bytes4[] memory selectors)
        internal
        pure
        returns (IDiamondCut.FacetCut memory)
    {
        return IDiamondCut.FacetCut({
            facetAddress: facet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: selectors
        });
    }

    function _split(string memory str, string memory delimiter)
        internal
        pure
        returns (string[] memory)
    {
        require(bytes(str).length > 0, "Empty input string");
        require(bytes(delimiter).length == 1, "Delimiter must be single character");

        uint256 count = 1;
        for (uint256 i = 0; i < bytes(str).length; i++) {
            if (bytes(str)[i] == bytes(delimiter)[0]) count++;
        }

        string[] memory parts = new string[](count);
        uint256 partIndex = 0;
        uint256 start = 0;

        for (uint256 i = 0; i < bytes(str).length; i++) {
            if (bytes(str)[i] == bytes(delimiter)[0]) {
                parts[partIndex++] = _substring(str, start, i);
                start = i + 1;
            }
        }
        parts[partIndex] = _substring(str, start, bytes(str).length);

        console.log("Split %s into %d parts:", str, count);
        for (uint256 i = 0; i < parts.length; i++) {
            console.log("- Part %d: %s", i, parts[i]);
        }

        return parts;
    }

    function _substring(string memory str, uint256 startIndex, uint256 endIndex)
        internal
        pure
        returns (string memory)
    {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    function _strEquals(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}
