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

/**
 * @title UpgradeDiamondFacets
 * @notice Script to upgrade specific facets in the diamond system
 * @dev Run with `forge script script/UpgradeDiamondFacets.s.sol:UpgradeDiamondFacets --rpc-url <your_rpc_url> --broadcast`
 *      Set DIAMOND_ADDRESS and FACETS_TO_UPGRADE in .env file
 *      FACETS_TO_UPGRADE should be a comma-separated list of facet names, e.g.:
 *      FACETS_TO_UPGRADE=CoreFacet,MintFacet,UnvaultFacet,InitFacet,CollectionFacet
 */
contract UpgradeDiamondFacets is Script {
    // Events for tracking upgrades
    event FacetUpgraded(string name, address addr);

    function run() external {
        // Get deployment private key and diamond address
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
            if (_strEquals(facetName, "CoreFacet")) {
                totalCuts += 2; // Remove old + Add new
            } else if (_strEquals(facetName, "MintFacet")) {
                totalCuts += 2; // Replace + Add new
            } else if (_strEquals(facetName, "InitFacet")) {
                totalCuts += 2; // Replace existing + Add new
            } else if (_strEquals(facetName, "CollectionFacet")) {
                totalCuts += 2; // Replace existing + Add new
            } else {
                totalCuts += 1; // Replace
            }
        }

        console.log("Total cuts needed:", totalCuts);
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](totalCuts);
        uint256 cutIndex = 0;

        // Deploy and prepare upgrades for each facet
        for (uint256 i = 0; i < facetNames.length; i++) {
            string memory facetName = facetNames[i];
            console.log("Processing facet:", facetName);

            if (_strEquals(facetName, "CoreFacet")) {
                EmblemVaultCoreFacet newFacet = new EmblemVaultCoreFacet();

                // Add new getCoreVersion function
                bytes4[] memory newCoreSelectors = new bytes4[](1);
                newCoreSelectors[0] = EmblemVaultCoreFacet.getCoreVersion.selector;
                require(cutIndex < totalCuts, "Array bounds exceeded");
                cut[cutIndex++] = _createAddCut(address(newFacet), newCoreSelectors);

                // Remove old version function
                bytes4[] memory oldCoreSelectors = _getOldCoreSelectors();
                require(cutIndex < totalCuts, "Array bounds exceeded");
                cut[cutIndex++] = IDiamondCut.FacetCut({
                    facetAddress: address(0),
                    action: IDiamondCut.FacetCutAction.Remove,
                    functionSelectors: oldCoreSelectors
                });

                emit FacetUpgraded("CoreFacet", address(newFacet));
            } else if (_strEquals(facetName, "UnvaultFacet")) {
                EmblemVaultUnvaultFacet newFacet = new EmblemVaultUnvaultFacet();
                bytes4[] memory selectors = _getUnvaultSelectors();
                cut[cutIndex++] = _createAddCut(address(newFacet), selectors);
                emit FacetUpgraded("UnvaultFacet", address(newFacet));
            } else if (_strEquals(facetName, "MintFacet")) {
                EmblemVaultMintFacet newFacet = new EmblemVaultMintFacet();
                // Replace existing functions
                bytes4[] memory existingSelectors = _getExistingMintSelectors();
                cut[cutIndex++] = _createReplaceCut(address(newFacet), existingSelectors);
                // Add new function
                bytes4[] memory newSelectors = _getNewMintSelectors();
                cut[cutIndex++] = _createAddCut(address(newFacet), newSelectors);
                emit FacetUpgraded("MintFacet", address(newFacet));
            } else if (_strEquals(facetName, "CollectionFacet")) {
                EmblemVaultCollectionFacet newFacet = new EmblemVaultCollectionFacet();
                // Replace existing functions
                bytes4[] memory existingSelectors = _getExistingCollectionSelectors();
                cut[cutIndex++] = _createReplaceCut(address(newFacet), existingSelectors);
                // Add new functions
                bytes4[] memory newSelectors = _getNewCollectionSelectors();
                cut[cutIndex++] = _createAddCut(address(newFacet), newSelectors);
                emit FacetUpgraded("CollectionFacet", address(newFacet));
            } else if (_strEquals(facetName, "InitFacet")) {
                EmblemVaultInitFacet newFacet = new EmblemVaultInitFacet();
                // Replace existing functions
                bytes4[] memory existingSelectors = _getExistingInitSelectors();
                cut[cutIndex++] = _createReplaceCut(address(newFacet), existingSelectors);
                // Add new function
                bytes4[] memory newSelectors = _getNewInitSelectors();
                cut[cutIndex++] = _createAddCut(address(newFacet), newSelectors);
                emit FacetUpgraded("InitFacet", address(newFacet));
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

    function _getCoreSelectors() internal pure returns (bytes4[] memory) {
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
        return selectors;
    }

    function _getOldCoreSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = bytes4(keccak256("version()"));
        return selectors;
    }

    function _getUnvaultSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](8);
        selectors[0] = EmblemVaultUnvaultFacet.unvault.selector;
        selectors[1] = EmblemVaultUnvaultFacet.unvaultWithSignedPrice.selector;
        selectors[2] = EmblemVaultUnvaultFacet.setUnvaultingEnabled.selector;
        selectors[3] = EmblemVaultUnvaultFacet.setBurnAddress.selector;
        selectors[4] = EmblemVaultUnvaultFacet.isTokenUnvaulted.selector;
        selectors[5] = EmblemVaultUnvaultFacet.getTokenUnvaulter.selector;
        selectors[6] = EmblemVaultUnvaultFacet.getCollectionUnvaultCount.selector;
        selectors[7] = EmblemVaultUnvaultFacet.getUnvaultVersion.selector;
        return selectors;
    }

    function _getExistingMintSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = EmblemVaultMintFacet.buyWithSignedPrice.selector;
        return selectors;
    }

    function _getNewMintSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = EmblemVaultMintFacet.batchBuyWithSignedPrice.selector;
        selectors[1] = EmblemVaultMintFacet.getMintVersion.selector;
        return selectors;
    }

    function _getExistingCollectionSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](9);
        selectors[0] = EmblemVaultCollectionFacet.setCollectionFactory.selector;
        selectors[1] = EmblemVaultCollectionFacet.createVaultCollection.selector;
        selectors[2] = EmblemVaultCollectionFacet.upgradeCollectionImplementation.selector;
        selectors[3] = EmblemVaultCollectionFacet.getCollectionImplementation.selector;
        selectors[4] = EmblemVaultCollectionFacet.getCollectionBeacon.selector;
        selectors[5] = EmblemVaultCollectionFacet.isCollection.selector;
        selectors[6] = EmblemVaultCollectionFacet.getCollectionFactory.selector;
        selectors[7] = EmblemVaultCollectionFacet.setCollectionBaseURI.selector;
        selectors[8] = EmblemVaultCollectionFacet.setCollectionURI.selector;
        return selectors;
    }

    function _getNewCollectionSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](4);
        selectors[0] = EmblemVaultCollectionFacet.setCollectionOwner.selector;
        selectors[1] = EmblemVaultCollectionFacet.getCollectionOwner.selector;
        selectors[2] = EmblemVaultCollectionFacet.getCollectionVersion.selector;
        selectors[3] = EmblemVaultCollectionFacet.getCollectionType.selector;
        return selectors;
    }

    function _getExistingInitSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](5);
        selectors[0] = EmblemVaultInitFacet.initialize.selector;
        selectors[1] = EmblemVaultInitFacet.isInitialized.selector;
        selectors[2] = EmblemVaultInitFacet.getInterfaceIds.selector;
        selectors[3] = EmblemVaultInitFacet.getConfiguration.selector;
        selectors[4] = EmblemVaultInitFacet.getInitializationDetails.selector;
        return selectors;
    }

    function _getNewInitSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = EmblemVaultInitFacet.getInitVersion.selector;
        return selectors;
    }

    function _split(string memory str, string memory delimiter)
        internal
        pure
        returns (string[] memory)
    {
        // Validate input
        require(bytes(str).length > 0, "Empty input string");
        require(bytes(delimiter).length == 1, "Delimiter must be single character");

        // Count delimiters
        uint256 count = 1;
        for (uint256 i = 0; i < bytes(str).length; i++) {
            if (bytes(str)[i] == bytes(delimiter)[0]) count++;
        }

        string[] memory parts = new string[](count);
        uint256 partIndex = 0;
        uint256 start = 0;

        // Split string
        for (uint256 i = 0; i < bytes(str).length; i++) {
            if (bytes(str)[i] == bytes(delimiter)[0]) {
                parts[partIndex++] = _substring(str, start, i);
                start = i + 1;
            }
        }
        parts[partIndex] = _substring(str, start, bytes(str).length);

        // Log results for debugging
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
