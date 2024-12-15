// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/EmblemVaultDiamond.sol";
import "../src/facets/DiamondCutFacet.sol";
import "../src/facets/EmblemVaultCollectionFacet.sol";
import "../src/facets/EmblemVaultInitFacet.sol";
import "../src/facets/OwnershipFacet.sol";
import "../src/factories/VaultCollectionFactory.sol";
import "../src/beacon/VaultBeacon.sol";
import "../src/implementations/ERC721VaultImplementation.sol";
import "../src/implementations/ERC1155VaultImplementation.sol";
import "../src/libraries/LibErrors.sol";
import "../src/interfaces/IDiamondCut.sol";

contract DiamondFactoryIntegrationTest is Test {
    // Core contracts
    EmblemVaultDiamond diamond;
    VaultCollectionFactory factory;
    ERC721VaultBeacon erc721Beacon;
    ERC1155VaultBeacon erc1155Beacon;
    ERC721VaultImplementation erc721Implementation;
    ERC1155VaultImplementation erc1155Implementation;
    DiamondCutFacet diamondCutFacet;
    EmblemVaultCollectionFacet collectionFacet;
    EmblemVaultInitFacet initFacet;
    OwnershipFacet ownershipFacet;

    // Test addresses
    address owner = address(this);
    address user1 = address(0x1);
    address user2 = address(0x2);

    // Events
    event VaultCollectionCreated(
        address indexed collection, uint8 indexed collectionType, string name
    );
    event CollectionBaseURIUpdated(address indexed collection, string newBaseURI);
    event CollectionURIUpdated(address indexed collection, string newURI);

    function setUp() public {
        // Deploy implementations and beacons
        erc721Implementation = new ERC721VaultImplementation();
        erc1155Implementation = new ERC1155VaultImplementation();
        erc721Beacon = new ERC721VaultBeacon(address(erc721Implementation));
        erc1155Beacon = new ERC1155VaultBeacon(address(erc1155Implementation));

        // Deploy Diamond facets
        diamondCutFacet = new DiamondCutFacet();
        collectionFacet = new EmblemVaultCollectionFacet();
        initFacet = new EmblemVaultInitFacet();
        ownershipFacet = new OwnershipFacet();

        // Deploy Diamond
        diamond = new EmblemVaultDiamond(owner, address(diamondCutFacet));

        // Build cut struct for diamond facets
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](3);

        // CollectionFacet
        bytes4[] memory collectionSelectors = new bytes4[](3);
        collectionSelectors[0] = EmblemVaultCollectionFacet.setCollectionBaseURI.selector;
        collectionSelectors[1] = EmblemVaultCollectionFacet.setCollectionURI.selector;
        collectionSelectors[2] = EmblemVaultCollectionFacet.setCollectionFactory.selector;
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(collectionFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: collectionSelectors
        });

        // InitFacet
        bytes4[] memory initSelectors = new bytes4[](1);
        initSelectors[0] = EmblemVaultInitFacet.initialize.selector;
        cut[1] = IDiamondCut.FacetCut({
            facetAddress: address(initFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: initSelectors
        });

        // OwnershipFacet
        bytes4[] memory ownershipSelectors = new bytes4[](2);
        ownershipSelectors[0] = OwnershipFacet.transferOwnership.selector;
        ownershipSelectors[1] = OwnershipFacet.owner.selector;
        cut[2] = IDiamondCut.FacetCut({
            facetAddress: address(ownershipFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: ownershipSelectors
        });

        // Add facets to diamond
        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");

        // Initialize the diamond
        EmblemVaultInitFacet(address(diamond)).initialize(owner);

        // Deploy factory with Diamond as controller
        factory = new VaultCollectionFactory(
            address(erc721Beacon), address(erc1155Beacon), address(diamond)
        );

        // Transfer beacon ownership to factory
        erc721Beacon.transferOwnership(address(factory));
        erc1155Beacon.transferOwnership(address(factory));

        // Set factory in diamond
        vm.startPrank(owner);
        EmblemVaultCollectionFacet(address(diamond)).setCollectionFactory(address(factory));
        vm.stopPrank();

        // Setup test accounts
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
    }

    function testFactoryInitialization() public view {
        assertEq(factory.diamond(), address(diamond));
        assertEq(factory.erc721Beacon(), address(erc721Beacon));
        assertEq(factory.erc1155Beacon(), address(erc1155Beacon));
    }

    function testOnlyDiamondCanCreateCollections() public {
        // Try to create collection from non-Diamond address
        vm.startPrank(user1);
        vm.expectRevert(abi.encodeWithSelector(LibErrors.Unauthorized.selector, user1));
        factory.createERC721Collection("Test", "TST");
        vm.stopPrank();

        // Create collection from Diamond address
        vm.startPrank(address(diamond));
        address collection = factory.createERC721Collection("Test", "TST");
        assertTrue(factory.isCollection(collection));
        vm.stopPrank();
    }

    function testOnlyDiamondCanUpdateBeacons() public {
        ERC721VaultImplementation newImpl = new ERC721VaultImplementation();

        // Try to update beacon from non-Diamond address
        vm.startPrank(user1);
        vm.expectRevert(abi.encodeWithSelector(LibErrors.Unauthorized.selector, user1));
        factory.updateBeacon(1, address(newImpl)); // 1 = ERC721_TYPE
        vm.stopPrank();

        // Update beacon from Diamond address
        vm.startPrank(address(diamond));
        factory.updateBeacon(1, address(newImpl));
        assertEq(factory.getImplementation(1), address(newImpl));
        vm.stopPrank();
    }

    function testCollectionURIManagement() public {
        // Create collections
        vm.startPrank(address(diamond));
        address erc721Collection = factory.createERC721Collection("Test721", "TST");
        address erc1155Collection = factory.createERC1155Collection("https://api.test.com/{id}");
        vm.stopPrank();

        // Test ERC721 URI update through Diamond's CollectionFacet
        string memory newBaseURI = "https://new.test.com/";
        vm.startPrank(owner);
        vm.expectEmit(true, true, true, true);
        emit CollectionBaseURIUpdated(erc721Collection, newBaseURI);
        EmblemVaultCollectionFacet(address(diamond)).setCollectionBaseURI(
            erc721Collection, newBaseURI
        );
        vm.stopPrank();

        // Test ERC1155 URI update through Diamond's CollectionFacet
        string memory newURI = "https://new.test.com/{id}";
        vm.startPrank(owner);
        vm.expectEmit(true, true, true, true);
        emit CollectionURIUpdated(erc1155Collection, newURI);
        EmblemVaultCollectionFacet(address(diamond)).setCollectionURI(erc1155Collection, newURI);
        vm.stopPrank();
    }

    function testCollectionOwnership() public {
        vm.startPrank(address(diamond));
        address collection = factory.createERC721Collection("Test", "TST");
        vm.stopPrank();

        // Verify Diamond owns collection
        assertEq(OwnableUpgradeable(collection).owner(), address(diamond));

        // Try to transfer ownership from non-Diamond address
        vm.startPrank(user1);
        vm.expectRevert(
            abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, user1)
        );
        OwnableUpgradeable(collection).transferOwnership(user1);
        vm.stopPrank();

        // Verify ownership unchanged
        assertEq(OwnableUpgradeable(collection).owner(), address(diamond));
    }

    function testCollectionTypeVerification() public {
        vm.startPrank(address(diamond));
        address erc721Collection = factory.createERC721Collection("Test721", "TST");
        address erc1155Collection = factory.createERC1155Collection("https://test.uri/{id}");
        vm.stopPrank();

        assertEq(factory.getCollectionType(erc721Collection), 1); // ERC721_TYPE
        assertEq(factory.getCollectionType(erc1155Collection), 2); // ERC1155_TYPE
    }

    function testRevertInvalidCollectionOperations() public {
        vm.startPrank(address(diamond));
        address erc721Collection = factory.createERC721Collection("Test721", "TST");
        address erc1155Collection = factory.createERC1155Collection("https://test.uri/{id}");
        vm.stopPrank();

        // Try to set ERC1155 URI on ERC721 collection
        vm.startPrank(owner);
        vm.expectRevert(); // Should revert with InvalidCollectionOperation
        EmblemVaultCollectionFacet(address(diamond)).setCollectionURI(
            erc721Collection, "https://test.uri"
        );
        vm.stopPrank();

        // Try to set ERC721 base URI on ERC1155 collection
        vm.startPrank(owner);
        vm.expectRevert(); // Should revert with InvalidCollectionOperation
        EmblemVaultCollectionFacet(address(diamond)).setCollectionBaseURI(
            erc1155Collection, "https://test.uri/"
        );
        vm.stopPrank();
    }

    receive() external payable {}
}
