// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {IDiamondCut} from "../src/interfaces/IDiamondCut.sol";
import {DiamondCutFacet} from "../src/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../src/facets/DiamondLoupeFacet.sol";
import {OwnershipFacet} from "../src/facets/OwnershipFacet.sol";
import {EmblemVaultCoreFacet} from "../src/facets/EmblemVaultCoreFacet.sol";
import {EmblemVaultClaimFacet} from "../src/facets/EmblemVaultClaimFacet.sol";
import {EmblemVaultMintFacet} from "../src/facets/EmblemVaultMintFacet.sol";
import {EmblemVaultCallbackFacet} from "../src/facets/EmblemVaultCallbackFacet.sol";
import {EmblemVaultCollectionFacet} from "../src/facets/EmblemVaultCollectionFacet.sol";
import {EmblemVaultInitFacet} from "../src/facets/EmblemVaultInitFacet.sol";

/**
 * @title UpgradeDiamondFacets
 * @notice Script to upgrade specific facets in the diamond system
 * @dev Run with `forge script script/UpgradeDiamondFacets.s.sol:UpgradeDiamondFacets --rpc-url <your_rpc_url> --broadcast`
 *      Set DIAMOND_ADDRESS and FACETS_TO_UPGRADE in .env file
 *      FACETS_TO_UPGRADE should be a comma-separated list of facet names, e.g.:
 *      FACETS_TO_UPGRADE=CoreFacet,MintFacet,ClaimFacet
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
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](facetNames.length);
        uint256 cutIndex = 0;

        // Deploy and prepare upgrades for each facet
        for (uint256 i = 0; i < facetNames.length; i++) {
            string memory facetName = facetNames[i];

            if (_strEquals(facetName, "CoreFacet")) {
                EmblemVaultCoreFacet newFacet = new EmblemVaultCoreFacet();
                bytes4[] memory selectors = _getCoreSelectors();
                cut[cutIndex++] = _createFacetCut(address(newFacet), selectors);
                emit FacetUpgraded("CoreFacet", address(newFacet));
            } else if (_strEquals(facetName, "ClaimFacet")) {
                EmblemVaultClaimFacet newFacet = new EmblemVaultClaimFacet();
                bytes4[] memory selectors = _getClaimSelectors();
                cut[cutIndex++] = _createFacetCut(address(newFacet), selectors);
                emit FacetUpgraded("ClaimFacet", address(newFacet));
            } else if (_strEquals(facetName, "MintFacet")) {
                EmblemVaultMintFacet newFacet = new EmblemVaultMintFacet();
                bytes4[] memory selectors = _getMintSelectors();
                cut[cutIndex++] = _createFacetCut(address(newFacet), selectors);
                emit FacetUpgraded("MintFacet", address(newFacet));
            } else if (_strEquals(facetName, "CallbackFacet")) {
                EmblemVaultCallbackFacet newFacet = new EmblemVaultCallbackFacet();
                bytes4[] memory selectors = _getCallbackSelectors();
                cut[cutIndex++] = _createFacetCut(address(newFacet), selectors);
                emit FacetUpgraded("CallbackFacet", address(newFacet));
            } else if (_strEquals(facetName, "CollectionFacet")) {
                EmblemVaultCollectionFacet newFacet = new EmblemVaultCollectionFacet();
                bytes4[] memory selectors = _getCollectionSelectors();
                cut[cutIndex++] = _createFacetCut(address(newFacet), selectors);
                emit FacetUpgraded("CollectionFacet", address(newFacet));
            } else if (_strEquals(facetName, "InitFacet")) {
                EmblemVaultInitFacet newFacet = new EmblemVaultInitFacet();
                bytes4[] memory selectors = _getInitSelectors();
                cut[cutIndex++] = _createFacetCut(address(newFacet), selectors);
                emit FacetUpgraded("InitFacet", address(newFacet));
            }
        }

        // Perform diamond cut to upgrade facets
        IDiamondCut(diamond).diamondCut(cut, address(0), "");

        vm.stopBroadcast();

        // Log upgrade summary
        console.log("\nDiamond Facets Upgrade Summary:");
        console.log("--------------------------------");
        console.log("Diamond:", diamond);
        console.log("Facets upgraded:", facetsToUpgrade);
    }

    function _createFacetCut(address facet, bytes4[] memory selectors)
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

    function _getCoreSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](17);
        selectors[0] = EmblemVaultCoreFacet.lockVault.selector;
        selectors[1] = EmblemVaultCoreFacet.unlockVault.selector;
        selectors[2] = EmblemVaultCoreFacet.isVaultLocked.selector;
        selectors[3] = EmblemVaultCoreFacet.addWitness.selector;
        selectors[4] = EmblemVaultCoreFacet.removeWitness.selector;
        selectors[5] = EmblemVaultCoreFacet.setRecipientAddress.selector;
        selectors[6] = EmblemVaultCoreFacet.setQuoteContract.selector;
        selectors[7] = EmblemVaultCoreFacet.setMetadataBaseUri.selector;
        selectors[8] = EmblemVaultCoreFacet.registerContract.selector;
        selectors[9] = EmblemVaultCoreFacet.unregisterContract.selector;
        selectors[10] = EmblemVaultCoreFacet.toggleAllowCallbacks.selector;
        selectors[11] = EmblemVaultCoreFacet.toggleBypassability.selector;
        selectors[12] = EmblemVaultCoreFacet.addBypassRule.selector;
        selectors[13] = EmblemVaultCoreFacet.removeBypassRule.selector;
        selectors[14] = EmblemVaultCoreFacet.getRegisteredContractsOfType.selector;
        selectors[15] = EmblemVaultCoreFacet.isRegistered.selector;
        selectors[16] = EmblemVaultCoreFacet.version.selector;
        return selectors;
    }

    function _getClaimSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = EmblemVaultClaimFacet.claim.selector;
        selectors[1] = EmblemVaultClaimFacet.claimWithSignedPrice.selector;
        return selectors;
    }

    function _getMintSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = EmblemVaultMintFacet.buyWithSignedPrice.selector;
        selectors[1] = EmblemVaultMintFacet.buyWithQuote.selector;
        return selectors;
    }

    function _getCallbackSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](6);
        selectors[0] = EmblemVaultCallbackFacet.executeCallbacks.selector;
        selectors[1] = EmblemVaultCallbackFacet.registerCallback.selector;
        selectors[2] = EmblemVaultCallbackFacet.registerWildcardCallback.selector;
        selectors[3] = EmblemVaultCallbackFacet.hasCallback.selector;
        selectors[4] = EmblemVaultCallbackFacet.unregisterCallback.selector;
        selectors[5] = EmblemVaultCallbackFacet.toggleAllowCallbacks.selector;
        return selectors;
    }

    function _getCollectionSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](7);
        selectors[0] = EmblemVaultCollectionFacet.setCollectionFactory.selector;
        selectors[1] = EmblemVaultCollectionFacet.createVaultCollection.selector;
        selectors[2] = EmblemVaultCollectionFacet.upgradeCollectionImplementation.selector;
        selectors[3] = EmblemVaultCollectionFacet.getCollectionImplementation.selector;
        selectors[4] = EmblemVaultCollectionFacet.getCollectionBeacon.selector;
        selectors[5] = EmblemVaultCollectionFacet.isCollection.selector;
        selectors[6] = EmblemVaultCollectionFacet.getCollectionFactory.selector;
        return selectors;
    }

    function _getInitSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](5);
        selectors[0] = EmblemVaultInitFacet.initialize.selector;
        selectors[1] = EmblemVaultInitFacet.isInitialized.selector;
        selectors[2] = EmblemVaultInitFacet.getInterfaceIds.selector;
        selectors[3] = EmblemVaultInitFacet.getConfiguration.selector;
        selectors[4] = EmblemVaultInitFacet.version.selector;
        return selectors;
    }

    function _split(string memory str, string memory delimiter) internal pure returns (string[] memory) {
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
