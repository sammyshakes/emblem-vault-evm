// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {EmblemVaultDiamond} from "../src/EmblemVaultDiamond.sol";
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

        EmblemVaultClaimFacet claimFacet = new EmblemVaultClaimFacet();
        emit Deployed("EmblemVaultClaimFacet", address(claimFacet));

        EmblemVaultMintFacet mintFacet = new EmblemVaultMintFacet();
        emit Deployed("EmblemVaultMintFacet", address(mintFacet));

        EmblemVaultCallbackFacet callbackFacet = new EmblemVaultCallbackFacet();
        emit Deployed("EmblemVaultCallbackFacet", address(callbackFacet));

        EmblemVaultCollectionFacet collectionFacet = new EmblemVaultCollectionFacet();
        emit Deployed("EmblemVaultCollectionFacet", address(collectionFacet));

        EmblemVaultInitFacet initFacet = new EmblemVaultInitFacet();
        emit Deployed("EmblemVaultInitFacet", address(initFacet));

        // 2. Deploy Diamond
        EmblemVaultDiamond diamond = new EmblemVaultDiamond(deployer, address(diamondCutFacet));
        emit Deployed("EmblemVaultDiamond", address(diamond));

        // 3. Build cut struct for adding facets
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](8);

        // DiamondLoupeFacet
        bytes4[] memory loupeSelectors = new bytes4[](5);
        loupeSelectors[0] = DiamondLoupeFacet.facets.selector;
        loupeSelectors[1] = DiamondLoupeFacet.facetFunctionSelectors.selector;
        loupeSelectors[2] = DiamondLoupeFacet.facetAddresses.selector;
        loupeSelectors[3] = DiamondLoupeFacet.getFacetAddress.selector;
        loupeSelectors[4] = DiamondLoupeFacet.supportsInterface.selector;
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
        bytes4[] memory vaultCoreSelectors = new bytes4[](13);
        vaultCoreSelectors[0] = EmblemVaultCoreFacet.lockVault.selector;
        vaultCoreSelectors[1] = EmblemVaultCoreFacet.unlockVault.selector;
        vaultCoreSelectors[2] = EmblemVaultCoreFacet.isVaultLocked.selector;
        vaultCoreSelectors[3] = EmblemVaultCoreFacet.addWitness.selector;
        vaultCoreSelectors[4] = EmblemVaultCoreFacet.removeWitness.selector;
        vaultCoreSelectors[5] = EmblemVaultCoreFacet.setRecipientAddress.selector;
        vaultCoreSelectors[6] = EmblemVaultCoreFacet.setQuoteContract.selector;
        vaultCoreSelectors[7] = EmblemVaultCoreFacet.setMetadataBaseUri.selector;
        vaultCoreSelectors[8] = EmblemVaultCoreFacet.registerContract.selector;
        vaultCoreSelectors[9] = EmblemVaultCoreFacet.unregisterContract.selector;
        vaultCoreSelectors[10] = EmblemVaultCoreFacet.getRegisteredContractsOfType.selector;
        vaultCoreSelectors[11] = EmblemVaultCoreFacet.isRegistered.selector;
        vaultCoreSelectors[12] = EmblemVaultCoreFacet.version.selector;
        cut[2] = IDiamondCut.FacetCut({
            facetAddress: address(vaultCoreFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: vaultCoreSelectors
        });

        // ClaimFacet
        bytes4[] memory claimSelectors = new bytes4[](2);
        claimSelectors[0] = EmblemVaultClaimFacet.claim.selector;
        claimSelectors[1] = EmblemVaultClaimFacet.claimWithSignedPrice.selector;
        cut[3] = IDiamondCut.FacetCut({
            facetAddress: address(claimFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: claimSelectors
        });

        // MintFacet
        bytes4[] memory mintSelectors = new bytes4[](2);
        mintSelectors[0] = EmblemVaultMintFacet.buyWithSignedPrice.selector;
        mintSelectors[1] = EmblemVaultMintFacet.buyWithQuote.selector;
        cut[4] = IDiamondCut.FacetCut({
            facetAddress: address(mintFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: mintSelectors
        });

        // CallbackFacet
        bytes4[] memory callbackSelectors = new bytes4[](6);
        callbackSelectors[0] = EmblemVaultCallbackFacet.executeCallbacks.selector;
        callbackSelectors[1] = EmblemVaultCallbackFacet.registerCallback.selector;
        callbackSelectors[2] = EmblemVaultCallbackFacet.registerWildcardCallback.selector;
        callbackSelectors[3] = EmblemVaultCallbackFacet.hasCallback.selector;
        callbackSelectors[4] = EmblemVaultCallbackFacet.unregisterCallback.selector;
        callbackSelectors[5] = EmblemVaultCallbackFacet.toggleAllowCallbacks.selector;
        cut[5] = IDiamondCut.FacetCut({
            facetAddress: address(callbackFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: callbackSelectors
        });

        // CollectionFacet
        bytes4[] memory collectionSelectors = new bytes4[](8);
        collectionSelectors[0] = EmblemVaultCollectionFacet.setCollectionFactory.selector;
        collectionSelectors[1] = EmblemVaultCollectionFacet.createVaultCollection.selector;
        collectionSelectors[2] = EmblemVaultCollectionFacet.upgradeCollectionImplementation.selector;
        collectionSelectors[3] = EmblemVaultCollectionFacet.getCollectionImplementation.selector;
        collectionSelectors[4] = EmblemVaultCollectionFacet.getCollectionBeacon.selector;
        collectionSelectors[5] = EmblemVaultCollectionFacet.isCollection.selector;
        collectionSelectors[6] = EmblemVaultCollectionFacet.getCollectionFactory.selector;
        cut[6] = IDiamondCut.FacetCut({
            facetAddress: address(collectionFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: collectionSelectors
        });

        // InitializationFacet
        bytes4[] memory initSelectors = new bytes4[](4);
        initSelectors[0] = EmblemVaultInitFacet.initialize.selector;
        initSelectors[1] = EmblemVaultInitFacet.isInitialized.selector;
        initSelectors[2] = EmblemVaultInitFacet.getInterfaceIds.selector;
        initSelectors[3] = EmblemVaultInitFacet.getConfiguration.selector;
        cut[7] = IDiamondCut.FacetCut({
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
        console.log("ClaimFacet:", address(claimFacet));
        console.log("MintFacet:", address(mintFacet));
        console.log("CallbackFacet:", address(callbackFacet));
        console.log("CollectionFacet:", address(collectionFacet));
        console.log("InitFacet:", address(initFacet));
    }
}
