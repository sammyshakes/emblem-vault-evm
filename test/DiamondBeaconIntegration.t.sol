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
import {IHandlerCallback} from "../src/interfaces/IHandlerCallback.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// Mock handler callback implementation
contract MockHandlerCallback is IHandlerCallback {
    function executeCallbacks(address from, address to, uint256 tokenId, CallbackType callbackType)
        external
        override
    {}
}

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
    MockHandlerCallback mockHandler;

    // Test addresses
    address owner = address(this);
    address user1 = address(0x1);
    address user2 = address(0x2);

    // Contract types
    uint256 constant HANDLER_TYPE = 3; // Type 3 is for handler/factory
    uint256 constant ERC721_TYPE = 1;
    uint256 constant ERC1155_TYPE = 2;

    function setUp() public {
        // Deploy mock handler
        mockHandler = new MockHandlerCallback();

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

        // MintFacet
        bytes4[] memory mintSelectors = new bytes4[](2);
        mintSelectors[0] = EmblemVaultMintFacet.buyWithSignedPrice.selector;
        mintSelectors[1] = EmblemVaultMintFacet.buyWithQuote.selector;
        cut[3] = IDiamondCut.FacetCut({
            facetAddress: address(mintFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: mintSelectors
        });

        // InitializationFacet
        bytes4[] memory initSelectors = new bytes4[](4);
        initSelectors[0] = EmblemVaultInitFacet.initialize.selector;
        initSelectors[1] = EmblemVaultInitFacet.isInitialized.selector;
        initSelectors[2] = EmblemVaultInitFacet.getInterfaceIds.selector;
        initSelectors[3] = EmblemVaultInitFacet.getConfiguration.selector;
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

        // Deploy beacons with uninitialized implementations
        erc721Beacon = new ERC721VaultBeacon(address(erc721Implementation));
        erc1155Beacon = new ERC1155VaultBeacon(address(erc1155Implementation));

        // Deploy factory (this test contract will be the owner)
        factory = new VaultCollectionFactory(address(erc721Beacon), address(erc1155Beacon));

        // Transfer beacon ownership to factory
        erc721Beacon.transferOwnership(address(factory));
        erc1155Beacon.transferOwnership(address(factory));

        // Register factory with diamond as handler (type 3)
        EmblemVaultCoreFacet(address(diamond)).registerContract(address(mockHandler), HANDLER_TYPE);

        // Setup test accounts
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
    }

    function _setupVault(address vault) internal {
        // Register vault with diamond
        EmblemVaultCoreFacet(address(diamond)).registerContract(vault, ERC721_TYPE);

        // Register mock handler in the vault
        vm.startPrank(OwnableUpgradeable(vault).owner());
        ERC721VaultImplementation(vault).registerContract(HANDLER_TYPE, address(mockHandler));
        vm.stopPrank();

        // Transfer ownership to factory
        vm.startPrank(OwnableUpgradeable(vault).owner());
        OwnableUpgradeable(vault).transferOwnership(address(factory));
        vm.stopPrank();
    }

    function _setupVault1155(address vault) internal {
        // Register vault with diamond
        EmblemVaultCoreFacet(address(diamond)).registerContract(vault, ERC1155_TYPE);

        // Register mock handler in the vault
        vm.startPrank(OwnableUpgradeable(vault).owner());
        ERC1155VaultImplementation(vault).registerContract(HANDLER_TYPE, address(mockHandler));
        vm.stopPrank();

        // Transfer ownership to factory
        vm.startPrank(OwnableUpgradeable(vault).owner());
        OwnableUpgradeable(vault).transferOwnership(address(factory));
        vm.stopPrank();
    }

    function testCreateVaultThroughDiamond() public {
        // Create ERC721 vault collection through diamond
        string memory name = "Test Vault";
        string memory symbol = "TVLT";

        address vault = factory.createERC721Collection(name, symbol);
        _setupVault(vault);

        // Verify vault creation and registration
        assertTrue(EmblemVaultCoreFacet(address(diamond)).isRegistered(vault, ERC721_TYPE));
        assertEq(ERC721VaultImplementation(vault).name(), name);
        assertEq(ERC721VaultImplementation(vault).symbol(), symbol);
        assertEq(OwnableUpgradeable(vault).owner(), address(factory));

        // Verify mock handler is registered
        address[] memory registeredHandlers =
            EmblemVaultCoreFacet(address(diamond)).getRegisteredContractsOfType(HANDLER_TYPE);
        assertEq(registeredHandlers.length, 1);
        assertEq(registeredHandlers[0], address(mockHandler));

        // Verify beacon ownership
        assertEq(erc721Beacon.owner(), address(factory));
        assertEq(erc1155Beacon.owner(), address(factory));
    }

    function testUpgradeVaultImplementation() public {
        // Create initial vault
        address vault = factory.createERC721Collection("Test Vault", "TVLT");
        _setupVault(vault);

        // Deploy new implementation
        ERC721VaultImplementation newImplementation = new ERC721VaultImplementation();

        // Upgrade implementation through beacon
        vm.startPrank(address(factory));
        erc721Beacon.upgrade(address(newImplementation));
        vm.stopPrank();

        // Verify upgrade
        assertEq(erc721Beacon.implementation(), address(newImplementation));

        // Verify vault still works with new implementation
        vm.startPrank(address(factory));
        ERC721VaultImplementation(vault).mint(user1, 1);
        vm.stopPrank();
        assertEq(ERC721VaultImplementation(vault).ownerOf(1), user1);
    }

    function testFullSystemFlow() public {
        // 1. Create vault collection
        address vault = factory.createERC721Collection("Test Vault", "TVLT");
        _setupVault(vault);

        // 2. Mint token through factory (simulating diamond mint)
        vm.startPrank(address(factory));
        ERC721VaultImplementation(vault).mint(user1, 1);
        vm.stopPrank();

        // 3. Lock vault through diamond
        EmblemVaultCoreFacet(address(diamond)).lockVault(vault, 1);
        assertTrue(EmblemVaultCoreFacet(address(diamond)).isVaultLocked(vault, 1));

        // 4. Upgrade implementation
        ERC721VaultImplementation newImplementation = new ERC721VaultImplementation();
        vm.startPrank(address(factory));
        erc721Beacon.upgrade(address(newImplementation));
        vm.stopPrank();

        // 5. Verify everything still works
        assertTrue(EmblemVaultCoreFacet(address(diamond)).isVaultLocked(vault, 1));
        assertEq(ERC721VaultImplementation(vault).ownerOf(1), user1);

        // 6. Unlock vault and transfer
        EmblemVaultCoreFacet(address(diamond)).unlockVault(vault, 1);

        vm.startPrank(user1);
        ERC721VaultImplementation(vault).transferFrom(user1, user2, 1);
        vm.stopPrank();
        assertEq(ERC721VaultImplementation(vault).ownerOf(1), user2);
    }

    function testERC1155Integration() public {
        // 1. Create ERC1155 vault collection
        string memory uri = "https://test.uri/";
        address vault = factory.createERC1155Collection(uri);
        _setupVault1155(vault);

        // 2. Mint tokens through factory
        vm.startPrank(address(factory));
        ERC1155VaultImplementation(vault).mint(user1, 1, 5, "");
        vm.stopPrank();

        // 3. Verify minting
        assertEq(ERC1155VaultImplementation(vault).balanceOf(user1, 1), 5);

        // 4. Lock vault
        EmblemVaultCoreFacet(address(diamond)).lockVault(vault, 1);
        assertTrue(EmblemVaultCoreFacet(address(diamond)).isVaultLocked(vault, 1));

        // 5. Upgrade implementation
        ERC1155VaultImplementation newImplementation = new ERC1155VaultImplementation();
        vm.startPrank(address(factory));
        erc1155Beacon.upgrade(address(newImplementation));
        vm.stopPrank();

        // 6. Verify state after upgrade
        assertTrue(EmblemVaultCoreFacet(address(diamond)).isVaultLocked(vault, 1));
        assertEq(ERC1155VaultImplementation(vault).balanceOf(user1, 1), 5);
    }

    receive() external payable {}
}
