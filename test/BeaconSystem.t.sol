// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/implementations/ERC721VaultImplementation.sol";
import "../src/implementations/ERC1155VaultImplementation.sol";
import "../src/beacon/VaultBeacon.sol";
import "../src/beacon/VaultProxy.sol";
import "../src/factories/VaultCollectionFactory.sol";
import "../src/libraries/LibErrors.sol";

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
    address newOwner = address(0x3);

    // Events to test
    event TokenMinted(
        address indexed to, uint256 indexed tokenId, uint256 indexed externalTokenId, bytes data
    );
    event TokenBurned(
        address indexed from, uint256 indexed tokenId, uint256 indexed externalTokenId, bytes data
    );
    event BaseURIUpdated(string newBaseURI);
    event DetailsUpdated(string name, string symbol);
    event BeaconUpdated(
        uint8 indexed collectionType, address indexed oldBeacon, address indexed newBeacon
    );
    event ImplementationUpgraded(
        address indexed oldImplementation, address indexed newImplementation
    );
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event CollectionOwnershipTransferred(address indexed collection, address indexed newOwner);

    // Create mock diamond address
    address mockDiamond = address(0x1234567890123456789012345678901234567890);

    function setUp() public {
        vm.label(mockDiamond, "MockDiamond");

        // Deploy implementations
        erc721Implementation = new ERC721VaultImplementation();
        erc1155Implementation = new ERC1155VaultImplementation();

        // Deploy beacons pointing to implementations
        erc721Beacon = new VaultBeacon(address(erc721Implementation));
        erc1155Beacon = new VaultBeacon(address(erc1155Implementation));

        // Deploy proxies pointing to beacons
        address erc721Proxy = address(new VaultProxy(address(erc721Beacon)));
        address erc1155Proxy = address(new VaultProxy(address(erc1155Beacon)));

        // Initialize proxies with diamond address
        vm.prank(mockDiamond);
        ERC721VaultImplementation(erc721Proxy).initialize("Test", "TST", mockDiamond);

        vm.prank(mockDiamond);
        ERC1155VaultImplementation(erc1155Proxy).initialize("https://test.uri/", mockDiamond);

        // Deploy beacons
        erc721Beacon = new ERC721VaultBeacon(address(erc721Implementation));
        erc1155Beacon = new ERC1155VaultBeacon(address(erc1155Implementation));

        // Deploy factory with mock diamond using test contract as deployer
        factory =
            new VaultCollectionFactory(address(erc721Beacon), address(erc1155Beacon), mockDiamond);

        // Transfer beacon ownership to factory
        erc721Beacon.transferOwnership(address(factory));
        erc1155Beacon.transferOwnership(address(factory));

        // Setup test accounts
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
    }

    function testInitialSetup() public view {
        assertEq(erc721Beacon.implementation(), address(erc721Implementation));
        assertEq(erc1155Beacon.implementation(), address(erc1155Implementation));
        assertEq(factory.erc721Beacon(), address(erc721Beacon));
        assertEq(factory.erc1155Beacon(), address(erc1155Beacon));
        assertEq(factory.diamond(), mockDiamond);
        assertEq(erc721Beacon.owner(), address(factory));
        assertEq(erc1155Beacon.owner(), address(factory));
    }

    function testCreateERC721Collection() public {
        string memory name = "Test Collection";
        string memory symbol = "TEST";

        // Create collection and verify event
        vm.prank(mockDiamond);
        address collection = factory.createERC721Collection(name, symbol);

        // Verify collection setup
        assertTrue(factory.isCollection(collection));
        assertEq(factory.getCollectionType(collection), 1); // ERC721_TYPE
        assertEq(ERC721VaultImplementation(collection).name(), name);
        assertEq(ERC721VaultImplementation(collection).symbol(), symbol);
        assertEq(OwnableUpgradeable(collection).owner(), address(this));
    }

    function testCreateERC1155Collection() public {
        string memory uri = "https://test.uri/";

        // Create collection and verify event
        vm.prank(mockDiamond);
        address collection = factory.createERC1155Collection(uri);

        // Verify collection setup
        assertTrue(factory.isCollection(collection));
        assertEq(factory.getCollectionType(collection), 2); // ERC1155_TYPE
        assertEq(ERC1155VaultImplementation(collection).uri(0), string(abi.encodePacked(uri, "0")));
        assertEq(OwnableUpgradeable(collection).owner(), address(this));
    }

    function testERC721VaultOperations() public {
        // Create collection
        vm.prank(mockDiamond);
        address collection = factory.createERC721Collection("Test Collection", "TEST");

        // Test minting vault (Diamond is the owner)
        vm.prank(mockDiamond);
        vm.expectEmit(true, true, true, true);
        emit TokenMinted(user1, 1, 1, "");
        ERC721VaultImplementation(collection).mint(user1, 1);
        assertEq(ERC721VaultImplementation(collection).ownerOf(1), user1);

        // Test transfers
        vm.startPrank(user1);
        vm.expectEmit(true, true, true, true);
        emit Transfer(user1, user2, 1);
        ERC721VaultImplementation(collection).transferFrom(user1, user2, 1);
        assertEq(ERC721VaultImplementation(collection).ownerOf(1), user2);
        vm.stopPrank();
    }

    function testERC1155VaultOperations() public {
        // Create collection
        vm.prank(mockDiamond);
        address collection = factory.createERC1155Collection("https://test.uri/");

        // Test minting vaults with serial numbers (Diamond is the owner)
        uint256[] memory serialNumbers = new uint256[](5);
        for (uint256 i = 0; i < 5; i++) {
            serialNumbers[i] = i + 1;
        }
        bytes memory serialData = abi.encode(serialNumbers);

        vm.prank(mockDiamond);
        vm.expectEmit(true, true, true, true);
        emit TransferSingle(mockDiamond, address(0), user1, 1, 5);
        ERC1155VaultImplementation(collection).mintWithSerial(user1, 1, 5, serialData);
        assertEq(ERC1155VaultImplementation(collection).balanceOf(user1, 1), 5);

        // Test transfers
        vm.startPrank(user1);
        vm.expectEmit(true, true, true, true);
        emit TransferSingle(user1, user1, user2, 1, 2);
        ERC1155VaultImplementation(collection).safeTransferFrom(user1, user2, 1, 2, "");
        assertEq(ERC1155VaultImplementation(collection).balanceOf(user1, 1), 3);
        assertEq(ERC1155VaultImplementation(collection).balanceOf(user2, 1), 2);
        vm.stopPrank();
    }

    function testBatchOperations1155() public {
        vm.prank(mockDiamond);
        address collection = factory.createERC1155Collection("https://test.uri/");

        // Test batch minting (Diamond is the owner)
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;
        amounts[0] = 5;
        amounts[1] = 3;

        // Prepare serial numbers for batch mint
        bytes[] memory serialArrays = new bytes[](2);

        uint256[] memory serials1 = new uint256[](5);
        for (uint256 i = 0; i < 5; i++) {
            serials1[i] = 100 + i;
        }
        serialArrays[0] = abi.encode(serials1);

        uint256[] memory serials2 = new uint256[](3);
        for (uint256 i = 0; i < 3; i++) {
            serials2[i] = 200 + i;
        }
        serialArrays[1] = abi.encode(serials2);

        bytes memory batchData = abi.encode(serialArrays);
        vm.prank(mockDiamond);
        ERC1155VaultImplementation(collection).mintBatch(user1, ids, amounts, batchData);

        assertEq(ERC1155VaultImplementation(collection).balanceOf(user1, 1), 5);
        assertEq(ERC1155VaultImplementation(collection).balanceOf(user1, 2), 3);

        // Test batch transfers
        vm.startPrank(user1);
        uint256[] memory transferAmounts = new uint256[](2);
        transferAmounts[0] = 2;
        transferAmounts[1] = 1;

        ERC1155VaultImplementation(collection).safeBatchTransferFrom(
            user1, user2, ids, transferAmounts, ""
        );
        vm.stopPrank();

        assertEq(ERC1155VaultImplementation(collection).balanceOf(user1, 1), 3);
        assertEq(ERC1155VaultImplementation(collection).balanceOf(user1, 2), 2);
        assertEq(ERC1155VaultImplementation(collection).balanceOf(user2, 1), 2);
        assertEq(ERC1155VaultImplementation(collection).balanceOf(user2, 2), 1);
    }

    function testBurnOperations() public {
        // Test ERC721 burn
        vm.prank(mockDiamond);
        address collection721 = factory.createERC721Collection("Test Collection", "TEST");

        vm.prank(mockDiamond);
        ERC721VaultImplementation(collection721).mint(user1, 1);

        vm.prank(user1);
        vm.expectEmit(true, true, true, true);
        emit TokenBurned(user1, 1, 1, "");
        ERC721VaultImplementation(collection721).burn(1);

        vm.expectRevert(); // Should revert when trying to get owner of burned token
        ERC721VaultImplementation(collection721).ownerOf(1);

        // Test ERC1155 burn
        vm.prank(mockDiamond);
        address collection1155 = factory.createERC1155Collection("https://test.uri/");

        // Mint with serial numbers
        uint256[] memory serialNumbers = new uint256[](5);
        for (uint256 i = 0; i < 5; i++) {
            serialNumbers[i] = i + 1;
        }
        bytes memory serialData = abi.encode(serialNumbers);
        vm.prank(mockDiamond);
        ERC1155VaultImplementation(collection1155).mintWithSerial(user1, 1, 5, serialData);

        vm.prank(user1);
        vm.expectEmit(true, true, true, true);
        emit TransferSingle(user1, user1, address(0), 1, 2);
        ERC1155VaultImplementation(collection1155).burn(user1, 1, 2);

        assertEq(ERC1155VaultImplementation(collection1155).balanceOf(user1, 1), 3);
    }

    function testUpgradeERC721Implementation() public {
        // Deploy new implementation
        ERC721VaultImplementation newImplementation = new ERC721VaultImplementation();

        // Create collection before upgrade
        vm.prank(mockDiamond);
        address collection = factory.createERC721Collection("Test Collection", "TEST");

        // Mint vault before upgrade
        vm.prank(mockDiamond);
        ERC721VaultImplementation(collection).mint(user1, 1);

        // Upgrade implementation through factory (this contract is Diamond)
        vm.expectEmit(true, true, true, true);
        emit ImplementationUpgraded(address(erc721Implementation), address(newImplementation));
        vm.prank(mockDiamond);
        factory.updateBeacon(1, address(newImplementation));

        // Verify upgrade
        assertEq(erc721Beacon.implementation(), address(newImplementation));

        // Verify existing state
        assertEq(ERC721VaultImplementation(collection).ownerOf(1), user1);

        // Verify new minting still works
        vm.prank(mockDiamond);
        ERC721VaultImplementation(collection).mint(user2, 2);
        assertEq(ERC721VaultImplementation(collection).ownerOf(2), user2);
    }

    function testUpgradeERC1155Implementation() public {
        // Deploy new implementation
        ERC1155VaultImplementation newImplementation = new ERC1155VaultImplementation();

        // Create collection before upgrade
        vm.prank(mockDiamond);
        address collection = factory.createERC1155Collection("https://test.uri/");

        // Mint vaults before upgrade
        uint256[] memory serialNumbers = new uint256[](5);
        for (uint256 i = 0; i < 5; i++) {
            serialNumbers[i] = 300 + i;
        }
        bytes memory serialData = abi.encode(serialNumbers);
        vm.prank(mockDiamond);
        ERC1155VaultImplementation(collection).mintWithSerial(user1, 1, 5, serialData);

        // Upgrade implementation through factory (this contract is Diamond)
        vm.expectEmit(true, true, true, true);
        emit ImplementationUpgraded(address(erc1155Implementation), address(newImplementation));
        vm.prank(mockDiamond);
        factory.updateBeacon(2, address(newImplementation));

        // Verify upgrade
        assertEq(erc1155Beacon.implementation(), address(newImplementation));

        // Verify existing state
        assertEq(ERC1155VaultImplementation(collection).balanceOf(user1, 1), 5);

        // Verify new minting still works
        uint256[] memory newSerials = new uint256[](3);
        for (uint256 i = 0; i < 3; i++) {
            newSerials[i] = 400 + i;
        }
        bytes memory newSerialData = abi.encode(newSerials);
        vm.prank(mockDiamond);
        ERC1155VaultImplementation(collection).mintWithSerial(user2, 2, 3, newSerialData);
        assertEq(ERC1155VaultImplementation(collection).balanceOf(user2, 2), 3);
    }

    function testRevertUnauthorizedMint721() public {
        vm.prank(mockDiamond);
        address collection = factory.createERC721Collection("Test Collection", "TEST");

        vm.expectRevert(abi.encodeWithSignature("NotDiamond()"));
        vm.prank(user1); // Not the owner
        ERC721VaultImplementation(collection).mint(user1, 1);
    }

    function testRevertUnauthorizedMint1155() public {
        vm.prank(mockDiamond);
        address collection = factory.createERC1155Collection("https://test.uri/");

        uint256[] memory serialNumbers = new uint256[](5);
        for (uint256 i = 0; i < 5; i++) {
            serialNumbers[i] = 500 + i;
        }
        bytes memory serialData = abi.encode(serialNumbers);

        // Attempt to mint from a non-diamond address
        address nonDiamond = address(0x999);
        vm.expectRevert(abi.encodeWithSignature("NotDiamond()"));
        vm.prank(nonDiamond);
        ERC1155VaultImplementation(collection).mintWithSerial(user1, 1, 5, serialData);
    }

    function testRevertUnauthorizedBeaconUpdate() public {
        ERC721VaultImplementation newImplementation = new ERC721VaultImplementation();

        vm.startPrank(user1);
        vm.expectRevert(abi.encodeWithSelector(LibErrors.Unauthorized.selector, user1));
        factory.updateBeacon(1, address(newImplementation));
        vm.stopPrank();
    }

    function testRevertUnauthorizedCollectionCreation() public {
        vm.startPrank(user1);
        vm.expectRevert(abi.encodeWithSelector(LibErrors.Unauthorized.selector, user1));
        factory.createERC721Collection("Test", "TST");
        vm.stopPrank();
    }

    receive() external payable {}
}
