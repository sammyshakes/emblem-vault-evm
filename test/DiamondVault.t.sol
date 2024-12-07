// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
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
import {IHandlerCallback} from "../src/interfaces/IHandlerCallback.sol";

contract DiamondVaultTest is Test {
    Diamond diamond;
    DiamondCutFacet diamondCutFacet;
    DiamondLoupeFacet diamondLoupeFacet;
    OwnershipFacet ownershipFacet;
    VaultCoreFacet vaultCoreFacet;
    ClaimFacet claimFacet;
    MintFacet mintFacet;
    CallbackFacet callbackFacet;
    InitializationFacet initFacet;

    address owner = address(this);
    address user1 = address(0x1);
    address user2 = address(0x2);

    function setUp() public {
        // Deploy facets
        diamondCutFacet = new DiamondCutFacet();
        diamondLoupeFacet = new DiamondLoupeFacet();
        ownershipFacet = new OwnershipFacet();
        vaultCoreFacet = new VaultCoreFacet();
        claimFacet = new ClaimFacet();
        mintFacet = new MintFacet();
        callbackFacet = new CallbackFacet();
        initFacet = new InitializationFacet();

        // Deploy Diamond
        diamond = new Diamond(owner, address(diamondCutFacet));

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
        InitializationFacet(address(diamond)).initialize(owner);
    }

    function testInitialization() public {
        assertTrue(InitializationFacet(address(diamond)).isInitialized());
        (string memory baseUri,,,,) = InitializationFacet(address(diamond)).getConfiguration();
        assertEq(baseUri, "https://v2.emblemvault.io/meta/");
    }

    function testOwnership() public {
        assertEq(OwnershipFacet(address(diamond)).owner(), owner);
    }

    function testVaultLocking() public {
        address mockNft = address(0x123);
        uint256 tokenId = 1;

        // Register mock NFT contract
        VaultCoreFacet(address(diamond)).registerContract(mockNft, 1);

        // Lock vault
        VaultCoreFacet(address(diamond)).lockVault(mockNft, tokenId);
        assertTrue(VaultCoreFacet(address(diamond)).isVaultLocked(mockNft, tokenId));

        // Unlock vault
        VaultCoreFacet(address(diamond)).unlockVault(mockNft, tokenId);
        assertFalse(VaultCoreFacet(address(diamond)).isVaultLocked(mockNft, tokenId));
    }

    function testFailLockUnregisteredContract() public {
        address mockNft = address(0x123);
        uint256 tokenId = 1;

        VaultCoreFacet(address(diamond)).lockVault(mockNft, tokenId);
    }

    function testWitnessManagement() public {
        address witness = address(0x456);

        // Add witness
        VaultCoreFacet(address(diamond)).addWitness(witness);

        // Remove witness
        VaultCoreFacet(address(diamond)).removeWitness(witness);
    }

    function testContractRegistration() public {
        address mockContract = address(0x789);
        uint256 contractType = 1;

        // Register contract
        VaultCoreFacet(address(diamond)).registerContract(mockContract, contractType);
        assertTrue(VaultCoreFacet(address(diamond)).isRegistered(mockContract, contractType));

        // Get registered contracts
        address[] memory contracts = VaultCoreFacet(address(diamond)).getRegisteredContractsOfType(contractType);
        assertEq(contracts.length, 1);
        assertEq(contracts[0], mockContract);
    }

    function testDiamondCut() public {
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
