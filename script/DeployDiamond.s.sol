// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {Diamond} from "../src/Diamond.sol";
import {IDiamondCut} from "../src/interfaces/IDiamondCut.sol";
import {DiamondCutFacet} from "../src/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../src/facets/DiamondLoupeFacet.sol";
import {OwnershipFacet} from "../src/facets/OwnershipFacet.sol";
import {VaultCoreFacet} from "../src/facets/VaultCoreFacet.sol";
import {ClaimFacet} from "../src/facets/ClaimFacet.sol";
import {MintFacet} from "../src/facets/MintFacet.sol";
import {CallbackFacet} from "../src/facets/CallbackFacet.sol";
import {InitializationFacet} from "../src/facets/InitializationFacet.sol";

contract DeployDiamond is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy facets
        DiamondCutFacet diamondCutFacet = new DiamondCutFacet();
        DiamondLoupeFacet diamondLoupeFacet = new DiamondLoupeFacet();
        OwnershipFacet ownershipFacet = new OwnershipFacet();
        VaultCoreFacet vaultCoreFacet = new VaultCoreFacet();
        ClaimFacet claimFacet = new ClaimFacet();
        MintFacet mintFacet = new MintFacet();
        CallbackFacet callbackFacet = new CallbackFacet();
        InitializationFacet initFacet = new InitializationFacet();

        // Deploy Diamond
        Diamond diamond = new Diamond(msg.sender, address(diamondCutFacet));

        // Build cut struct
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](7);

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
        vaultCoreSelectors[0] = VaultCoreFacet.lockVault.selector;
        vaultCoreSelectors[1] = VaultCoreFacet.unlockVault.selector;
        vaultCoreSelectors[2] = VaultCoreFacet.isVaultLocked.selector;
        vaultCoreSelectors[3] = VaultCoreFacet.addWitness.selector;
        vaultCoreSelectors[4] = VaultCoreFacet.removeWitness.selector;
        vaultCoreSelectors[5] = VaultCoreFacet.setRecipientAddress.selector;
        vaultCoreSelectors[6] = VaultCoreFacet.setQuoteContract.selector;
        vaultCoreSelectors[7] = VaultCoreFacet.setMetadataBaseUri.selector;
        vaultCoreSelectors[8] = VaultCoreFacet.registerContract.selector;
        vaultCoreSelectors[9] = VaultCoreFacet.unregisterContract.selector;
        vaultCoreSelectors[10] = VaultCoreFacet.getRegisteredContractsOfType.selector;
        vaultCoreSelectors[11] = VaultCoreFacet.isRegistered.selector;
        vaultCoreSelectors[12] = VaultCoreFacet.version.selector;
        cut[2] = IDiamondCut.FacetCut({
            facetAddress: address(vaultCoreFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: vaultCoreSelectors
        });

        // ClaimFacet
        bytes4[] memory claimSelectors = new bytes4[](2);
        claimSelectors[0] = ClaimFacet.claim.selector;
        claimSelectors[1] = ClaimFacet.claimWithSignedPrice.selector;
        cut[3] = IDiamondCut.FacetCut({
            facetAddress: address(claimFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: claimSelectors
        });

        // MintFacet
        bytes4[] memory mintSelectors = new bytes4[](2);
        mintSelectors[0] = MintFacet.buyWithSignedPrice.selector;
        mintSelectors[1] = MintFacet.buyWithQuote.selector;
        cut[4] = IDiamondCut.FacetCut({
            facetAddress: address(mintFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: mintSelectors
        });

        // CallbackFacet
        bytes4[] memory callbackSelectors = new bytes4[](6);
        callbackSelectors[0] = CallbackFacet.executeCallbacks.selector;
        callbackSelectors[1] = CallbackFacet.registerCallback.selector;
        callbackSelectors[2] = CallbackFacet.registerWildcardCallback.selector;
        callbackSelectors[3] = CallbackFacet.hasCallback.selector;
        callbackSelectors[4] = CallbackFacet.unregisterCallback.selector;
        callbackSelectors[5] = CallbackFacet.toggleAllowCallbacks.selector;
        cut[5] = IDiamondCut.FacetCut({
            facetAddress: address(callbackFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: callbackSelectors
        });

        // InitializationFacet
        bytes4[] memory initSelectors = new bytes4[](4);
        initSelectors[0] = InitializationFacet.initialize.selector;
        initSelectors[1] = InitializationFacet.isInitialized.selector;
        initSelectors[2] = InitializationFacet.getInterfaceIds.selector;
        initSelectors[3] = InitializationFacet.getConfiguration.selector;
        cut[6] = IDiamondCut.FacetCut({
            facetAddress: address(initFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: initSelectors
        });

        // Add facets to diamond
        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");

        // Initialize the vault
        InitializationFacet(address(diamond)).initialize(msg.sender);

        vm.stopBroadcast();

        console.log("Diamond deployed at:", address(diamond));
        console.log("DiamondCutFacet deployed at:", address(diamondCutFacet));
        console.log("DiamondLoupeFacet deployed at:", address(diamondLoupeFacet));
        console.log("OwnershipFacet deployed at:", address(ownershipFacet));
        console.log("VaultCoreFacet deployed at:", address(vaultCoreFacet));
        console.log("ClaimFacet deployed at:", address(claimFacet));
        console.log("MintFacet deployed at:", address(mintFacet));
        console.log("CallbackFacet deployed at:", address(callbackFacet));
        console.log("InitializationFacet deployed at:", address(initFacet));
    }
}
