// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {EmblemVaultDiamond} from "../src/EmblemVaultDiamond.sol";
import {IDiamondCut} from "../src/interfaces/IDiamondCut.sol";
import {DiamondCutFacet} from "../src/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../src/facets/DiamondLoupeFacet.sol";
import {OwnershipFacet} from "../src/facets/OwnershipFacet.sol";
import {EmblemVaultCoreFacet} from "../src/facets/EmblemVaultCoreFacet.sol";
import {EmblemVaultClaimFacet} from "../src/facets/EmblemVaultClaimFacet.sol";
import {EmblemVaultMintFacet} from "../src/facets/EmblemVaultMintFacet.sol";
import {EmblemVaultCallbackFacet} from "../src/facets/EmblemVaultCallbackFacet.sol";
import {EmblemVaultInitFacet} from "../src/facets/EmblemVaultInitFacet.sol";
import {IHandlerCallback} from "../src/interfaces/IHandlerCallback.sol";

contract DiamondVaultTest is Test {
    EmblemVaultDiamond diamond;
    DiamondCutFacet diamondCutFacet;
    DiamondLoupeFacet diamondLoupeFacet;
    OwnershipFacet ownershipFacet;
    EmblemVaultCoreFacet vaultCoreFacet;
    EmblemVaultClaimFacet claimFacet;
    EmblemVaultMintFacet mintFacet;
    EmblemVaultCallbackFacet callbackFacet;
    EmblemVaultInitFacet initFacet;

    address owner = address(this);
    address user1 = address(0x1);
    address user2 = address(0x2);

    function setUp() public {
        // Deploy facets
        diamondCutFacet = new DiamondCutFacet();
        diamondLoupeFacet = new DiamondLoupeFacet();
        ownershipFacet = new OwnershipFacet();
        vaultCoreFacet = new EmblemVaultCoreFacet();
        claimFacet = new EmblemVaultClaimFacet();
        mintFacet = new EmblemVaultMintFacet();
        callbackFacet = new EmblemVaultCallbackFacet();
        initFacet = new EmblemVaultInitFacet();

        // Deploy Diamond
        diamond = new EmblemVaultDiamond(owner, address(diamondCutFacet));

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

        // InitializationFacet
        bytes4[] memory initSelectors = new bytes4[](4);
        initSelectors[0] = EmblemVaultInitFacet.initialize.selector;
        initSelectors[1] = EmblemVaultInitFacet.isInitialized.selector;
        initSelectors[2] = EmblemVaultInitFacet.getInterfaceIds.selector;
        initSelectors[3] = EmblemVaultInitFacet.getConfiguration.selector;
        cut[6] = IDiamondCut.FacetCut({
            facetAddress: address(initFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: initSelectors
        });

        // Add facets to diamond
        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");

        // Initialize the vault
        EmblemVaultInitFacet(address(diamond)).initialize(owner);
    }

    function testInitialization() public view {
        assertTrue(EmblemVaultInitFacet(address(diamond)).isInitialized());
        (string memory baseUri,,,,) = EmblemVaultInitFacet(address(diamond)).getConfiguration();
        assertEq(baseUri, "https://v2.emblemvault.io/meta/");
    }

    function testOwnership() public view {
        assertEq(OwnershipFacet(address(diamond)).owner(), owner);
    }

    function testVaultLocking() public {
        address mockNft = address(0x123);
        uint256 tokenId = 1;

        // Register mock NFT contract
        EmblemVaultCoreFacet(address(diamond)).registerContract(mockNft, 1);

        // Lock vault
        EmblemVaultCoreFacet(address(diamond)).lockVault(mockNft, tokenId);
        assertTrue(EmblemVaultCoreFacet(address(diamond)).isVaultLocked(mockNft, tokenId));

        // Unlock vault
        EmblemVaultCoreFacet(address(diamond)).unlockVault(mockNft, tokenId);
        assertFalse(EmblemVaultCoreFacet(address(diamond)).isVaultLocked(mockNft, tokenId));
    }

    function testFailLockUnregisteredContract() public {
        address mockNft = address(0x123);
        uint256 tokenId = 1;

        EmblemVaultCoreFacet(address(diamond)).lockVault(mockNft, tokenId);
    }

    function testWitnessManagement() public {
        address witness = address(0x456);

        // Add witness
        EmblemVaultCoreFacet(address(diamond)).addWitness(witness);

        // Remove witness
        EmblemVaultCoreFacet(address(diamond)).removeWitness(witness);
    }

    function testContractRegistration() public {
        address mockContract = address(0x789);
        uint256 contractType = 1;

        // Register contract
        EmblemVaultCoreFacet(address(diamond)).registerContract(mockContract, contractType);
        assertTrue(EmblemVaultCoreFacet(address(diamond)).isRegistered(mockContract, contractType));

        // Get registered contracts
        address[] memory contracts = EmblemVaultCoreFacet(address(diamond)).getRegisteredContractsOfType(contractType);
        assertEq(contracts.length, 1);
        assertEq(contracts[0], mockContract);
    }

    function testDiamondCut() public view {
        // Test that all facets were properly added
        address[] memory facetAddresses = DiamondLoupeFacet(address(diamond)).facetAddresses();
        assertEq(facetAddresses.length, 8); // All facets including DiamondCut

        // Verify DiamondCutFacet functions
        assertEq(
            DiamondLoupeFacet(address(diamond)).getFacetAddress(DiamondCutFacet.diamondCut.selector),
            address(diamondCutFacet)
        );

        // Verify DiamondLoupeFacet functions
        assertEq(
            DiamondLoupeFacet(address(diamond)).getFacetAddress(DiamondLoupeFacet.facets.selector),
            address(diamondLoupeFacet)
        );

        // Verify OwnershipFacet functions
        assertEq(
            DiamondLoupeFacet(address(diamond)).getFacetAddress(OwnershipFacet.owner.selector), address(ownershipFacet)
        );
    }
}
