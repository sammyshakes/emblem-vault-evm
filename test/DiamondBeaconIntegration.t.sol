// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {EmblemVaultDiamond} from "../src/EmblemVaultDiamond.sol";
import {IDiamondCut} from "../src/interfaces/IDiamondCut.sol";
import {DiamondCutFacet} from "../src/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../src/facets/DiamondLoupeFacet.sol";
import {OwnershipFacet} from "../src/facets/OwnershipFacet.sol";
import {EmblemVaultCoreFacet} from "../src/facets/EmblemVaultCoreFacet.sol";
import {EmblemVaultMintFacet} from "../src/facets/EmblemVaultMintFacet.sol";
import {EmblemVaultInitFacet} from "../src/facets/EmblemVaultInitFacet.sol";
import {VaultBeacon, ERC721VaultBeacon, ERC1155VaultBeacon} from "../src/beacon/VaultBeacon.sol";
import {VaultProxy, ERC721VaultProxy, ERC1155VaultProxy} from "../src/beacon/VaultProxy.sol";
import {
    IVaultProxy, IERC721VaultProxy, IERC1155VaultProxy
} from "../src/interfaces/IVaultProxy.sol";
import {ERC721VaultImplementation} from "../src/implementations/ERC721VaultImplementation.sol";
import {ERC1155VaultImplementation} from "../src/implementations/ERC1155VaultImplementation.sol";
import {VaultCollectionFactory} from "../src/factories/VaultCollectionFactory.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {LibErrors} from "../src/libraries/LibErrors.sol";

contract DiamondBeaconIntegrationTest is Test {
    // Diamond components
    EmblemVaultDiamond diamond;
    DiamondCutFacet diamondCutFacet;
    DiamondLoupeFacet diamondLoupeFacet;
    OwnershipFacet ownershipFacet;
    EmblemVaultCoreFacet vaultCoreFacet;
    EmblemVaultMintFacet mintFacet;
    EmblemVaultInitFacet initFacet;

    // Beacon components
    ERC721VaultImplementation erc721Implementation;
    ERC1155VaultImplementation erc1155Implementation;
    ERC721VaultBeacon erc721Beacon;
    ERC1155VaultBeacon erc1155Beacon;
    VaultCollectionFactory factory;

    // Test addresses
    address owner = address(this);
    address user1 = address(0x1);
    address user2 = address(0x2);

    // Events to test
    event VaultLocked(address indexed nftAddress, uint256 indexed tokenId, address indexed owner);
    event VaultUnlocked(address indexed nftAddress, uint256 indexed tokenId, address indexed owner);
    event VaultFactorySet(address indexed oldFactory, address indexed newFactory);
    event BeaconUpdated(
        uint8 indexed collectionType, address indexed oldBeacon, address indexed newBeacon
    );
    event ImplementationUpgraded(
        address indexed oldImplementation, address indexed newImplementation
    );

    function setUp() public {
        // Deploy diamond facets
        diamondCutFacet = new DiamondCutFacet();
        diamondLoupeFacet = new DiamondLoupeFacet();
        ownershipFacet = new OwnershipFacet();
        vaultCoreFacet = new EmblemVaultCoreFacet();
        mintFacet = new EmblemVaultMintFacet();
        initFacet = new EmblemVaultInitFacet();

        // Deploy Diamond
        diamond = new EmblemVaultDiamond(owner, address(diamondCutFacet));

        // Build cut struct for diamond facets
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](5);

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
        vaultCoreSelectors[9] = EmblemVaultCoreFacet.getCoreVersion.selector;
        vaultCoreSelectors[10] = EmblemVaultCoreFacet.setVaultFactory.selector;
        vaultCoreSelectors[11] = EmblemVaultCoreFacet.getVaultFactory.selector;
        cut[2] = IDiamondCut.FacetCut({
            facetAddress: address(vaultCoreFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: vaultCoreSelectors
        });

        // MintFacet
        bytes4[] memory mintSelectors = new bytes4[](1);
        mintSelectors[0] = EmblemVaultMintFacet.buyWithSignedPrice.selector;
        cut[3] = IDiamondCut.FacetCut({
            facetAddress: address(mintFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: mintSelectors
        });

        // InitializationFacet
        bytes4[] memory initSelectors = new bytes4[](5);
        initSelectors[0] = EmblemVaultInitFacet.initialize.selector;
        initSelectors[1] = EmblemVaultInitFacet.isInitialized.selector;
        initSelectors[2] = EmblemVaultInitFacet.getInterfaceIds.selector;
        initSelectors[3] = EmblemVaultInitFacet.getConfiguration.selector;
        initSelectors[4] = EmblemVaultInitFacet.getInitializationDetails.selector;
        cut[4] = IDiamondCut.FacetCut({
            facetAddress: address(initFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: initSelectors
        });

        // Add facets to diamond
        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");

        // Initialize the diamond
        EmblemVaultInitFacet(address(diamond)).initialize(owner);

        // Deploy beacon system
        erc721Implementation = new ERC721VaultImplementation();
        erc1155Implementation = new ERC1155VaultImplementation();

        // Deploy beacons with implementations
        erc721Beacon = new ERC721VaultBeacon(address(erc721Implementation));
        erc1155Beacon = new ERC1155VaultBeacon(address(erc1155Implementation));

        // Deploy factory with Diamond as controller
        factory = new VaultCollectionFactory(
            address(erc721Beacon), address(erc1155Beacon), address(diamond)
        );

        // Transfer beacon ownership to factory
        erc721Beacon.transferOwnership(address(factory));
        erc1155Beacon.transferOwnership(address(factory));

        // Set factory in diamond
        vm.expectEmit(true, true, true, true);
        emit VaultFactorySet(address(0), address(factory));
        EmblemVaultCoreFacet(address(diamond)).setVaultFactory(address(factory));

        // Setup test accounts
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
    }

    function testInitialization() public view {
        assertTrue(EmblemVaultInitFacet(address(diamond)).isInitialized());
        (
            string memory baseUri,
            address recipientAddr,
            bool claimingEnabled,
            bool byPassable,
            uint256 witnessCount
        ) = EmblemVaultInitFacet(address(diamond)).getConfiguration();

        assertEq(baseUri, "https://v2.emblemvault.io/meta/");
        assertEq(witnessCount, 1); // owner is initial witness
        assertEq(recipientAddr, address(this)); // Set to owner during initialization
        assertTrue(claimingEnabled); // Enabled by default in initialization
        assertFalse(byPassable); // Default to false
        assertEq(EmblemVaultCoreFacet(address(diamond)).getVaultFactory(), address(factory));
    }

    function testFactoryManagement() public {
        // Deploy new factory with Diamond as controller
        VaultCollectionFactory newFactory = new VaultCollectionFactory(
            address(erc721Beacon), address(erc1155Beacon), address(diamond)
        );

        // Update factory
        vm.expectEmit(true, true, true, true);
        emit VaultFactorySet(address(factory), address(newFactory));
        EmblemVaultCoreFacet(address(diamond)).setVaultFactory(address(newFactory));

        // Verify update
        assertEq(EmblemVaultCoreFacet(address(diamond)).getVaultFactory(), address(newFactory));
    }

    function testRevertSetZeroFactory() public {
        vm.expectRevert(abi.encodeWithSelector(LibErrors.ZeroAddress.selector));
        EmblemVaultCoreFacet(address(diamond)).setVaultFactory(address(0));
    }

    function testCreateVaultThroughFactory() public {
        // Create ERC721 vault collection through Diamond
        string memory name = "Test Vault";
        string memory symbol = "TVLT";

        vm.prank(address(diamond));
        address vault = factory.createERC721Collection(name, symbol);

        // Verify vault creation
        assertTrue(factory.isCollection(vault));
        assertEq(ERC721VaultImplementation(vault).name(), name);
        assertEq(ERC721VaultImplementation(vault).symbol(), symbol);
        assertEq(OwnableUpgradeable(vault).owner(), factory.owner());
    }

    function testUpgradeVaultImplementation() public {
        // Create initial vault through Diamond
        vm.prank(address(diamond));
        address vault = factory.createERC721Collection("Test Vault", "TVLT");

        // Deploy new implementation
        ERC721VaultImplementation newImplementation = new ERC721VaultImplementation();

        // Upgrade implementation through factory (from Diamond)
        vm.prank(address(diamond));
        factory.updateBeacon(1, address(newImplementation)); // 1 = ERC721_TYPE

        // Verify upgrade
        assertEq(erc721Beacon.implementation(), address(newImplementation));

        // Verify vault still works with new implementation
        vm.prank(address(diamond));
        ERC721VaultImplementation(vault).mint(user1, 1);
        assertEq(ERC721VaultImplementation(vault).ownerOf(1), user1);
    }

    function testFullSystemFlow() public {
        // 1. Create vault collection through Diamond
        vm.prank(address(diamond));
        address vault = factory.createERC721Collection("Test Vault", "TVLT");

        // 2. Mint token through Diamond
        vm.prank(address(diamond));
        ERC721VaultImplementation(vault).mint(user1, 1);

        // 3. Lock vault through diamond
        vm.expectEmit(true, true, true, true);
        emit VaultLocked(vault, 1, address(this));
        EmblemVaultCoreFacet(address(diamond)).lockVault(vault, 1);
        assertTrue(EmblemVaultCoreFacet(address(diamond)).isVaultLocked(vault, 1));

        // Test revert on already locked vault
        vm.expectRevert(abi.encodeWithSelector(LibErrors.VaultAlreadyLocked.selector, vault, 1));
        EmblemVaultCoreFacet(address(diamond)).lockVault(vault, 1);

        // 4. Upgrade implementation through Diamond
        ERC721VaultImplementation newImplementation = new ERC721VaultImplementation();
        vm.prank(address(diamond));
        factory.updateBeacon(1, address(newImplementation)); // 1 = ERC721_TYPE

        // 5. Verify everything still works
        assertTrue(EmblemVaultCoreFacet(address(diamond)).isVaultLocked(vault, 1));
        assertEq(ERC721VaultImplementation(vault).ownerOf(1), user1);

        // 6. Unlock vault and transfer
        vm.expectEmit(true, true, true, true);
        emit VaultUnlocked(vault, 1, address(this));
        EmblemVaultCoreFacet(address(diamond)).unlockVault(vault, 1);

        // Test revert on already unlocked vault
        vm.expectRevert(abi.encodeWithSelector(LibErrors.VaultNotLocked.selector, vault, 1));
        EmblemVaultCoreFacet(address(diamond)).unlockVault(vault, 1);

        vm.startPrank(user1);
        ERC721VaultImplementation(vault).transferFrom(user1, user2, 1);
        vm.stopPrank();
        assertEq(ERC721VaultImplementation(vault).ownerOf(1), user2);
    }

    function testERC1155Integration() public {
        // 1. Create ERC1155 vault collection through Diamond
        string memory uri = "https://test.uri/";
        vm.prank(address(diamond));
        address vault = factory.createERC1155Collection(uri);

        // Supply 5 distinct serial numbers
        uint256[] memory serialNumbers = new uint256[](5);
        for (uint256 i = 0; i < 5; i++) {
            serialNumbers[i] = 100 + i;
        }

        // Now call mintWithSerial
        vm.prank(address(diamond));
        ERC1155VaultImplementation(vault).mintWithSerial(user1, 1, 5, serialNumbers);

        // 3. Verify minting
        assertEq(ERC1155VaultImplementation(vault).balanceOf(user1, 1), 5);

        // 4. Lock vault
        EmblemVaultCoreFacet(address(diamond)).lockVault(vault, 1);
        assertTrue(EmblemVaultCoreFacet(address(diamond)).isVaultLocked(vault, 1));

        // 5. Upgrade implementation through Diamond
        ERC1155VaultImplementation newImplementation = new ERC1155VaultImplementation();
        vm.prank(address(diamond));
        factory.updateBeacon(2, address(newImplementation)); // 2 = ERC1155_TYPE

        // 6. Verify state after upgrade
        assertTrue(EmblemVaultCoreFacet(address(diamond)).isVaultLocked(vault, 1));
        assertEq(ERC1155VaultImplementation(vault).balanceOf(user1, 1), 5);
    }

    function testRevertLockInvalidCollection() public {
        address invalidCollection = address(0x999);
        vm.expectRevert(
            abi.encodeWithSelector(LibErrors.InvalidCollection.selector, address(0x999))
        );
        EmblemVaultCoreFacet(address(diamond)).lockVault(invalidCollection, 1);
    }

    function testRevertWithoutFactory() public {
        // Create new diamond without setting factory
        EmblemVaultDiamond newDiamond = new EmblemVaultDiamond(owner, address(diamondCutFacet));

        // Add core facet to new diamond
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = EmblemVaultCoreFacet.lockVault.selector;
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(vaultCoreFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: selectors
        });
        IDiamondCut(address(newDiamond)).diamondCut(cut, address(0), "");

        // Try to lock vault without setting factory
        vm.expectRevert(abi.encodeWithSelector(LibErrors.FactoryNotSet.selector));
        EmblemVaultCoreFacet(address(newDiamond)).lockVault(address(0x1), 1);
    }

    receive() external payable {}
}
