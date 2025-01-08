// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {EmblemVaultDiamond} from "../src/EmblemVaultDiamond.sol";
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
 * @title DeployDiamondSystem
 * @notice Script to deploy the complete diamond system with all facets
 * @dev Run with `forge script script/DeployDiamondSystem.s.sol:DeployDiamondSystem --rpc-url <your_rpc_url> --broadcast`
 */
contract DeployDiamondSystem is Script {
    // Events for tracking deployments
    event Deployed(string name, address addr);

    function run() external {
        // Get deployment private key
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying Diamond System with deployer:", deployer);

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy all facets
        DiamondCutFacet diamondCutFacet = new DiamondCutFacet();
        emit Deployed("DiamondCutFacet", address(diamondCutFacet));

        DiamondLoupeFacet diamondLoupeFacet = new DiamondLoupeFacet();
        emit Deployed("DiamondLoupeFacet", address(diamondLoupeFacet));

        OwnershipFacet ownershipFacet = new OwnershipFacet();
        emit Deployed("OwnershipFacet", address(ownershipFacet));

        EmblemVaultCoreFacet vaultCoreFacet = new EmblemVaultCoreFacet();
        emit Deployed("EmblemVaultCoreFacet", address(vaultCoreFacet));

        EmblemVaultUnvaultFacet unvaultFacet = new EmblemVaultUnvaultFacet();
        emit Deployed("EmblemVaultUnvaultFacet", address(unvaultFacet));

        EmblemVaultMintFacet mintFacet = new EmblemVaultMintFacet();
        emit Deployed("EmblemVaultMintFacet", address(mintFacet));

        EmblemVaultCollectionFacet collectionFacet = new EmblemVaultCollectionFacet();
        emit Deployed("EmblemVaultCollectionFacet", address(collectionFacet));

        EmblemVaultInitFacet initFacet = new EmblemVaultInitFacet();
        emit Deployed("EmblemVaultInitFacet", address(initFacet));

        // 2. Deploy Diamond
        EmblemVaultDiamond diamond = new EmblemVaultDiamond(deployer, address(diamondCutFacet));
        emit Deployed("EmblemVaultDiamond", address(diamond));

        // 3. Build cut struct for adding facets
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](7);

        // DiamondLoupeFacet
        bytes4[] memory loupeSelectors = new bytes4[](9);
        loupeSelectors[0] = DiamondLoupeFacet.facets.selector;
        loupeSelectors[1] = DiamondLoupeFacet.facetFunctionSelectors.selector;
        loupeSelectors[2] = DiamondLoupeFacet.facetAddresses.selector;
        loupeSelectors[3] = DiamondLoupeFacet.getFacetAddress.selector;
        loupeSelectors[4] = DiamondLoupeFacet.supportsInterface.selector;
        // Add batch function selectors
        loupeSelectors[5] = DiamondLoupeFacet.getFacetAddresses.selector;
        loupeSelectors[6] = DiamondLoupeFacet.batchFacetFunctionSelectors.selector;
        loupeSelectors[7] = DiamondLoupeFacet.supportsInterfaces.selector;
        loupeSelectors[8] = DiamondLoupeFacet.batchFacets.selector;
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(diamondLoupeFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: loupeSelectors
        });

        // OwnershipFacet
        bytes4[] memory ownershipSelectors = new bytes4[](2);
        ownershipSelectors[0] = OwnershipFacet.transferOwnership.selector;
        ownershipSelectors[1] = OwnershipFacet.owner.selector;
        cut[1] = IDiamondCut.FacetCut({
            facetAddress: address(ownershipFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: ownershipSelectors
        });

        // VaultCoreFacet
        bytes4[] memory vaultCoreSelectors = new bytes4[](12);
        vaultCoreSelectors[0] = EmblemVaultCoreFacet.lockVault.selector;
        vaultCoreSelectors[1] = EmblemVaultCoreFacet.unlockVault.selector;
        vaultCoreSelectors[2] = EmblemVaultCoreFacet.isVaultLocked.selector;
        vaultCoreSelectors[3] = EmblemVaultCoreFacet.addWitness.selector;
        vaultCoreSelectors[4] = EmblemVaultCoreFacet.removeWitness.selector;
        vaultCoreSelectors[5] = EmblemVaultCoreFacet.setRecipientAddress.selector;
        vaultCoreSelectors[6] = EmblemVaultCoreFacet.setMetadataBaseUri.selector;
        vaultCoreSelectors[7] = EmblemVaultCoreFacet.isWitness.selector;
        vaultCoreSelectors[8] = EmblemVaultCoreFacet.getWitnessCount.selector;
        vaultCoreSelectors[9] = EmblemVaultCoreFacet.setVaultFactory.selector;
        vaultCoreSelectors[10] = EmblemVaultCoreFacet.getVaultFactory.selector;
        vaultCoreSelectors[11] = EmblemVaultCoreFacet.getCoreVersion.selector;
        cut[2] = IDiamondCut.FacetCut({
            facetAddress: address(vaultCoreFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: vaultCoreSelectors
        });

        // UnvaultFacet
        bytes4[] memory unvaultSelectors = new bytes4[](8);
        unvaultSelectors[0] = EmblemVaultUnvaultFacet.unvault.selector;
        unvaultSelectors[1] = EmblemVaultUnvaultFacet.unvaultWithSignedPrice.selector;
        unvaultSelectors[2] = EmblemVaultUnvaultFacet.setUnvaultingEnabled.selector;
        unvaultSelectors[3] = EmblemVaultUnvaultFacet.setBurnAddress.selector;
        unvaultSelectors[4] = EmblemVaultUnvaultFacet.isTokenUnvaulted.selector;
        unvaultSelectors[5] = EmblemVaultUnvaultFacet.getTokenUnvaulter.selector;
        unvaultSelectors[6] = EmblemVaultUnvaultFacet.getCollectionUnvaultCount.selector;
        unvaultSelectors[7] = EmblemVaultUnvaultFacet.getUnvaultVersion.selector;
        cut[3] = IDiamondCut.FacetCut({
            facetAddress: address(unvaultFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: unvaultSelectors
        });

        // MintFacet
        bytes4[] memory mintSelectors = new bytes4[](3);
        mintSelectors[0] = EmblemVaultMintFacet.buyWithSignedPrice.selector;
        mintSelectors[1] = EmblemVaultMintFacet.batchBuyWithSignedPrice.selector;
        mintSelectors[2] = EmblemVaultMintFacet.getMintVersion.selector;
        cut[4] = IDiamondCut.FacetCut({
            facetAddress: address(mintFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: mintSelectors
        });

        // CollectionFacet
        bytes4[] memory collectionSelectors = new bytes4[](10);
        collectionSelectors[0] = EmblemVaultCollectionFacet.setCollectionFactory.selector;
        collectionSelectors[1] = EmblemVaultCollectionFacet.createVaultCollection.selector;
        collectionSelectors[2] = EmblemVaultCollectionFacet.upgradeCollectionImplementation.selector;
        collectionSelectors[3] = EmblemVaultCollectionFacet.getCollectionImplementation.selector;
        collectionSelectors[4] = EmblemVaultCollectionFacet.getCollectionBeacon.selector;
        collectionSelectors[5] = EmblemVaultCollectionFacet.isCollection.selector;
        collectionSelectors[6] = EmblemVaultCollectionFacet.getCollectionFactory.selector;
        collectionSelectors[7] = EmblemVaultCollectionFacet.setCollectionBaseURI.selector;
        collectionSelectors[8] = EmblemVaultCollectionFacet.setCollectionURI.selector;
        collectionSelectors[9] = EmblemVaultCollectionFacet.getCollectionVersion.selector;
        cut[5] = IDiamondCut.FacetCut({
            facetAddress: address(collectionFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: collectionSelectors
        });

        // InitializationFacet
        bytes4[] memory initSelectors = new bytes4[](6);
        initSelectors[0] = EmblemVaultInitFacet.initialize.selector;
        initSelectors[1] = EmblemVaultInitFacet.isInitialized.selector;
        initSelectors[2] = EmblemVaultInitFacet.getInterfaceIds.selector;
        initSelectors[3] = EmblemVaultInitFacet.getConfiguration.selector;
        initSelectors[4] = EmblemVaultInitFacet.getInitializationDetails.selector;
        initSelectors[5] = EmblemVaultInitFacet.getInitVersion.selector;
        cut[6] = IDiamondCut.FacetCut({
            facetAddress: address(initFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: initSelectors
        });

        // 4. Add facets to diamond
        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");

        // 5. Initialize the diamond
        EmblemVaultInitFacet(address(diamond)).initialize(deployer);

        vm.stopBroadcast();

        // Log deployment summary
        console.log("\nDiamond System Deployment Summary:");
        console.log("--------------------------------");
        console.log("Diamond:", address(diamond));
        console.log("DiamondCutFacet:", address(diamondCutFacet));
        console.log("DiamondLoupeFacet:", address(diamondLoupeFacet));
        console.log("OwnershipFacet:", address(ownershipFacet));
        console.log("VaultCoreFacet:", address(vaultCoreFacet));
        console.log("UnvaultFacet:", address(unvaultFacet));
        console.log("MintFacet:", address(mintFacet));
        console.log("CollectionFacet:", address(collectionFacet));
        console.log("InitFacet:", address(initFacet));
    }
}
