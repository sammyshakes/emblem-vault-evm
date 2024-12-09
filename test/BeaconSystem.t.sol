// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/implementations/ERC721VaultImplementation.sol";
import "../src/implementations/ERC1155VaultImplementation.sol";
import "../src/beacon/VaultBeacon.sol";
import "../src/beacon/VaultProxy.sol";
import "../src/factories/VaultCollectionFactory.sol";

contract BeaconSystemTest is Test {
    // Core contracts
    ERC721VaultImplementation public erc721Implementation;
    ERC1155VaultImplementation public erc1155Implementation;
    VaultBeacon public erc721Beacon;
    VaultBeacon public erc1155Beacon;
    VaultCollectionFactory public factory;

    // Test addresses
    address owner = address(this);
    address user1 = address(0x1);
    address user2 = address(0x2);

    // Events to test
    event ERC721CollectionCreated(address indexed collection, string name, string symbol);
    event ERC1155CollectionCreated(address indexed collection, string uri);
    event BeaconUpdated(uint8 indexed collectionType, address indexed oldBeacon, address indexed newBeacon);
    event ImplementationUpgraded(address indexed oldImplementation, address indexed newImplementation);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    function setUp() public {
        // Deploy implementations
        erc721Implementation = new ERC721VaultImplementation();
        erc1155Implementation = new ERC1155VaultImplementation();

        // Deploy beacons
        erc721Beacon = new ERC721VaultBeacon(address(erc721Implementation));
        erc1155Beacon = new ERC1155VaultBeacon(address(erc1155Implementation));

        // Deploy factory with owner as this contract
        factory = new VaultCollectionFactory(address(erc721Beacon), address(erc1155Beacon));

        // Setup test accounts
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
    }

    function testInitialSetup() public view {
        assertEq(erc721Beacon.implementation(), address(erc721Implementation));
        assertEq(erc1155Beacon.implementation(), address(erc1155Implementation));
        assertEq(factory.erc721Beacon(), address(erc721Beacon));
        assertEq(factory.erc1155Beacon(), address(erc1155Beacon));
    }

    function testCreateERC721Collection() public {
        string memory name = "Test Collection";
        string memory symbol = "TEST";

        // Create collection and capture its address
        address collection = factory.createERC721Collection(name, symbol);

        // Verify collection setup
        assertTrue(factory.isCollection(collection));
        assertEq(ERC721VaultImplementation(collection).name(), name);
        assertEq(ERC721VaultImplementation(collection).symbol(), symbol);
    }

    function testCreateERC1155Collection() public {
        string memory uri = "https://test.uri/";

        // Create collection and capture its address
        address collection = factory.createERC1155Collection(uri);

        // Verify collection setup
        assertTrue(factory.isCollection(collection));
        assertEq(ERC1155VaultImplementation(collection).uri(0), uri);
    }

    function testERC721VaultOperations() public {
        // Create collection
        address collection = factory.createERC721Collection("Test Collection", "TEST");

        // Test minting vault (factory is the owner)
        vm.prank(address(factory));
        ERC721VaultImplementation(collection).mint(user1, 1);
        assertEq(ERC721VaultImplementation(collection).ownerOf(1), user1);

        // Test transfers
        vm.startPrank(user1);
        ERC721VaultImplementation(collection).transferFrom(user1, user2, 1);
        assertEq(ERC721VaultImplementation(collection).ownerOf(1), user2);
        vm.stopPrank();

        // Test serial number tracking
        uint256 serial = ERC721VaultImplementation(collection).getFirstSerialByOwner(user2, 1);
        assertTrue(serial > 0);
        assertEq(ERC721VaultImplementation(collection).getOwnerOfSerial(serial), user2);
    }

    function testERC1155VaultOperations() public {
        // Create collection
        address collection = factory.createERC1155Collection("https://test.uri/");

        // Test minting vaults (factory is the owner)
        vm.prank(address(factory));
        ERC1155VaultImplementation(collection).mint(user1, 1, 5, "");
        assertEq(ERC1155VaultImplementation(collection).balanceOf(user1, 1), 5);

        // Test transfers
        vm.startPrank(user1);
        ERC1155VaultImplementation(collection).safeTransferFrom(user1, user2, 1, 2, "");
        assertEq(ERC1155VaultImplementation(collection).balanceOf(user1, 1), 3);
        assertEq(ERC1155VaultImplementation(collection).balanceOf(user2, 1), 2);
        vm.stopPrank();

        // Test serial number tracking
        uint256 serial = ERC1155VaultImplementation(collection).getFirstSerialByOwner(user2, 1);
        assertTrue(serial > 0);
        assertEq(ERC1155VaultImplementation(collection).getOwnerOfSerial(serial), user2);
    }

    function testBatchOperations1155() public {
        address collection = factory.createERC1155Collection("https://test.uri/");

        // Test batch minting (factory is the owner)
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;
        amounts[0] = 5;
        amounts[1] = 3;

        vm.prank(address(factory));
        ERC1155VaultImplementation(collection).mintBatch(user1, ids, amounts, "");

        assertEq(ERC1155VaultImplementation(collection).balanceOf(user1, 1), 5);
        assertEq(ERC1155VaultImplementation(collection).balanceOf(user1, 2), 3);

        // Test batch transfers
        vm.startPrank(user1);
        uint256[] memory transferAmounts = new uint256[](2);
        transferAmounts[0] = 2;
        transferAmounts[1] = 1;

        ERC1155VaultImplementation(collection).safeBatchTransferFrom(user1, user2, ids, transferAmounts, "");
        vm.stopPrank();

        assertEq(ERC1155VaultImplementation(collection).balanceOf(user1, 1), 3);
        assertEq(ERC1155VaultImplementation(collection).balanceOf(user1, 2), 2);
        assertEq(ERC1155VaultImplementation(collection).balanceOf(user2, 1), 2);
        assertEq(ERC1155VaultImplementation(collection).balanceOf(user2, 2), 1);
    }

    function testBurnOperations() public {
        // Test ERC721 burn
        address collection721 = factory.createERC721Collection("Test Collection", "TEST");

        vm.prank(address(factory));
        ERC721VaultImplementation(collection721).mint(user1, 1);

        vm.prank(user1);
        ERC721VaultImplementation(collection721).burn(1);

        vm.expectRevert(); // Should revert when trying to get owner of burned token
        ERC721VaultImplementation(collection721).ownerOf(1);

        // Test ERC1155 burn
        address collection1155 = factory.createERC1155Collection("https://test.uri/");

        vm.prank(address(factory));
        ERC1155VaultImplementation(collection1155).mint(user1, 1, 5, "");

        vm.prank(user1);
        ERC1155VaultImplementation(collection1155).burn(user1, 1, 2);

        assertEq(ERC1155VaultImplementation(collection1155).balanceOf(user1, 1), 3);
    }

    function testUpgradeERC721Implementation() public {
        // Deploy new implementation
        ERC721VaultImplementation newImplementation = new ERC721VaultImplementation();

        // Create collection before upgrade
        address collection = factory.createERC721Collection("Test Collection", "TEST");

        // Mint vault before upgrade
        vm.prank(address(factory));
        ERC721VaultImplementation(collection).mint(user1, 1);

        // Upgrade implementation (beacon owner is this contract)
        erc721Beacon.upgrade(address(newImplementation));

        // Verify upgrade
        assertEq(erc721Beacon.implementation(), address(newImplementation));

        // Verify existing state
        assertEq(ERC721VaultImplementation(collection).ownerOf(1), user1);

        // Verify new minting still works
        vm.prank(address(factory));
        ERC721VaultImplementation(collection).mint(user2, 2);
        assertEq(ERC721VaultImplementation(collection).ownerOf(2), user2);
    }

    function testUpgradeERC1155Implementation() public {
        // Deploy new implementation
        ERC1155VaultImplementation newImplementation = new ERC1155VaultImplementation();

        // Create collection before upgrade
        address collection = factory.createERC1155Collection("https://test.uri/");

        // Mint vaults before upgrade
        vm.prank(address(factory));
        ERC1155VaultImplementation(collection).mint(user1, 1, 5, "");

        // Upgrade implementation (beacon owner is this contract)
        erc1155Beacon.upgrade(address(newImplementation));

        // Verify upgrade
        assertEq(erc1155Beacon.implementation(), address(newImplementation));

        // Verify existing state
        assertEq(ERC1155VaultImplementation(collection).balanceOf(user1, 1), 5);

        // Verify new minting still works
        vm.prank(address(factory));
        ERC1155VaultImplementation(collection).mint(user2, 2, 3, "");
        assertEq(ERC1155VaultImplementation(collection).balanceOf(user2, 2), 3);
    }

    function testFailUnauthorizedMint721() public {
        address collection = factory.createERC721Collection("Test Collection", "TEST");

        vm.prank(user1); // Not the owner
        ERC721VaultImplementation(collection).mint(user1, 1);
    }

    function testFailUnauthorizedMint1155() public {
        address collection = factory.createERC1155Collection("https://test.uri/");

        vm.prank(user1); // Not the owner
        ERC1155VaultImplementation(collection).mint(user1, 1, 5, "");
    }

    receive() external payable {}
}
