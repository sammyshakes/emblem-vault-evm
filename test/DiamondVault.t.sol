// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {EmblemVaultDiamond} from "../src/EmblemVaultDiamond.sol";
import {ERC721AUpgradeable} from "ERC721A-Upgradeable/ERC721AUpgradeable.sol";
import {IDiamondCut} from "../src/interfaces/IDiamondCut.sol";
import {DiamondCutFacet} from "../src/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../src/facets/DiamondLoupeFacet.sol";
import {OwnershipFacet} from "../src/facets/OwnershipFacet.sol";
import {EmblemVaultCoreFacet} from "../src/facets/EmblemVaultCoreFacet.sol";
import {EmblemVaultClaimFacet} from "../src/facets/EmblemVaultClaimFacet.sol";
import {EmblemVaultMintFacet} from "../src/facets/EmblemVaultMintFacet.sol";
import {EmblemVaultCollectionFacet} from "../src/facets/EmblemVaultCollectionFacet.sol";
import {EmblemVaultInitFacet} from "../src/facets/EmblemVaultInitFacet.sol";
import {VaultBeacon, ERC721VaultBeacon, ERC1155VaultBeacon} from "../src/beacon/VaultBeacon.sol";
import {VaultProxy, ERC721VaultProxy, ERC1155VaultProxy} from "../src/beacon/VaultProxy.sol";
import {
    IVaultProxy, IERC721VaultProxy, IERC1155VaultProxy
} from "../src/interfaces/IVaultProxy.sol";
import {IERC721AVault} from "../src/interfaces/IERC721AVault.sol";
import {ERC721VaultImplementation} from "../src/implementations/ERC721VaultImplementation.sol";
import {ERC1155VaultImplementation} from "../src/implementations/ERC1155VaultImplementation.sol";
import {VaultCollectionFactory} from "../src/factories/VaultCollectionFactory.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {LibErrors} from "../src/libraries/LibErrors.sol";
import "./mocks/MockERC20.sol";
import "./mocks/MockClaimer.sol";

contract MockQuoteContract {
    function quoteExternalPrice(address, uint256 price) external pure returns (uint256) {
        return price * 2; // Simple mock that doubles the price
    }
}

contract DiamondVaultTest is Test {
    // Diamond components
    EmblemVaultDiamond diamond;
    DiamondCutFacet diamondCutFacet;
    DiamondLoupeFacet diamondLoupeFacet;
    OwnershipFacet ownershipFacet;
    EmblemVaultCoreFacet vaultCoreFacet;
    EmblemVaultClaimFacet claimFacet;
    EmblemVaultMintFacet mintFacet;
    EmblemVaultCollectionFacet collectionFacet;
    EmblemVaultInitFacet initFacet;

    // Mock contracts
    MockERC20 paymentToken;
    address nftCollection; // This will be created through the factory
    MockClaimer claimer;
    MockQuoteContract quoteContract;
    VaultCollectionFactory factory;
    ERC721VaultImplementation erc721Implementation;
    ERC1155VaultImplementation erc1155Implementation;
    ERC721VaultBeacon erc721Beacon;
    ERC1155VaultBeacon erc1155Beacon;

    // Test addresses
    address owner = address(this);
    address user1 = address(0x1);
    address user2 = address(0x2);
    uint256 constant witnessPrivateKey =
        0x1234567890123456789012345678901234567890123456789012345678901234;
    address witness;
    address tokenHolder = address(0x4);

    // Events
    event WitnessAdded(address indexed witness, uint256 newCount);
    event WitnessRemoved(address indexed witness, uint256 newCount);
    event VaultLocked(address indexed nftAddress, uint256 indexed tokenId, address indexed owner);
    event VaultUnlocked(address indexed nftAddress, uint256 indexed tokenId, address indexed owner);
    event VaultFactorySet(address indexed oldFactory, address indexed newFactory);
    event RecipientAddressChanged(address indexed oldRecipient, address indexed newRecipient);
    event QuoteContractChanged(address indexed oldQuoteContract, address indexed newQuoteContract);
    event ClaimerContractUpdated(address indexed oldClaimer, address indexed newClaimer);
    event TokenMinted(
        address indexed nftAddress,
        address indexed to,
        uint256 indexed tokenId,
        uint256 amount,
        uint256 price,
        address paymentToken,
        bytes data
    );

    // Custom errors
    error ZeroAddress();
    error WitnessAlreadyExists();
    error WitnessDoesNotExist();
    error NoWitnessesRemaining();
    error NotWitness();
    error InvalidCollection();
    error FactoryNotSet();
    error VaultAlreadyLocked();
    error VaultNotLocked();
    error InvalidSignature();
    error IncorrectPayment();
    error NonceAlreadyUsed();
    error ClaimerNotSet();
    error NotVaultOwner();
    error AlreadyClaimed();

    receive() external payable {}
    fallback() external payable {}

    function setUp() public {
        // Derive witness address from private key
        witness = vm.addr(witnessPrivateKey);

        // Deploy mock contracts
        paymentToken = new MockERC20("Payment Token", "PAY");
        claimer = new MockClaimer();
        quoteContract = new MockQuoteContract();

        // Deploy implementations
        erc721Implementation = new ERC721VaultImplementation();
        erc1155Implementation = new ERC1155VaultImplementation();

        // Deploy beacons
        erc721Beacon = new ERC721VaultBeacon(address(erc721Implementation));
        erc1155Beacon = new ERC1155VaultBeacon(address(erc1155Implementation));

        // Deploy facets first
        diamondCutFacet = new DiamondCutFacet();
        diamondLoupeFacet = new DiamondLoupeFacet();
        ownershipFacet = new OwnershipFacet();
        vaultCoreFacet = new EmblemVaultCoreFacet();
        claimFacet = new EmblemVaultClaimFacet();
        mintFacet = new EmblemVaultMintFacet();
        collectionFacet = new EmblemVaultCollectionFacet();
        initFacet = new EmblemVaultInitFacet();

        // Deploy Diamond with cut facet
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
        vaultCoreSelectors[8] = EmblemVaultCoreFacet.isWitness.selector;
        vaultCoreSelectors[9] = EmblemVaultCoreFacet.getWitnessCount.selector;
        vaultCoreSelectors[10] = EmblemVaultCoreFacet.version.selector;
        vaultCoreSelectors[11] = EmblemVaultCoreFacet.setVaultFactory.selector;
        vaultCoreSelectors[12] = EmblemVaultCoreFacet.getVaultFactory.selector;
        cut[2] = IDiamondCut.FacetCut({
            facetAddress: address(vaultCoreFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: vaultCoreSelectors
        });

        // ClaimFacet
        bytes4[] memory claimSelectors = new bytes4[](3);
        claimSelectors[0] = EmblemVaultClaimFacet.claim.selector;
        claimSelectors[1] = EmblemVaultClaimFacet.claimWithSignedPrice.selector;
        claimSelectors[2] = EmblemVaultClaimFacet.setClaimerContract.selector;
        cut[3] = IDiamondCut.FacetCut({
            facetAddress: address(claimFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: claimSelectors
        });

        // MintFacet
        bytes4[] memory mintSelectors = new bytes4[](3);
        mintSelectors[0] = EmblemVaultMintFacet.buyWithSignedPrice.selector;
        mintSelectors[1] = EmblemVaultMintFacet.buyWithQuote.selector;
        mintSelectors[2] = EmblemVaultMintFacet.batchBuyWithSignedPrice.selector;
        cut[4] = IDiamondCut.FacetCut({
            facetAddress: address(mintFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: mintSelectors
        });

        // CollectionFacet
        bytes4[] memory collectionSelectors = new bytes4[](9);
        collectionSelectors[0] = EmblemVaultCollectionFacet.setCollectionFactory.selector;
        collectionSelectors[1] = EmblemVaultCollectionFacet.createVaultCollection.selector;
        collectionSelectors[2] = EmblemVaultCollectionFacet.upgradeCollectionImplementation.selector;
        collectionSelectors[3] = EmblemVaultCollectionFacet.getCollectionImplementation.selector;
        collectionSelectors[4] = EmblemVaultCollectionFacet.getCollectionBeacon.selector;
        collectionSelectors[5] = EmblemVaultCollectionFacet.isCollection.selector;
        collectionSelectors[6] = EmblemVaultCollectionFacet.getCollectionFactory.selector;
        collectionSelectors[7] = EmblemVaultCollectionFacet.setCollectionBaseURI.selector;
        collectionSelectors[8] = EmblemVaultCollectionFacet.setCollectionURI.selector;
        cut[5] = IDiamondCut.FacetCut({
            facetAddress: address(collectionFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: collectionSelectors
        });

        // InitializationFacet
        bytes4[] memory initSelectors = new bytes4[](5);
        initSelectors[0] = EmblemVaultInitFacet.initialize.selector;
        initSelectors[1] = EmblemVaultInitFacet.isInitialized.selector;
        initSelectors[2] = EmblemVaultInitFacet.getInterfaceIds.selector;
        initSelectors[3] = EmblemVaultInitFacet.getConfiguration.selector;
        initSelectors[4] = EmblemVaultInitFacet.getInitializationDetails.selector;
        cut[6] = IDiamondCut.FacetCut({
            facetAddress: address(initFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: initSelectors
        });

        // Add facets to diamond
        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");

        // Initialize the vault
        EmblemVaultInitFacet(address(diamond)).initialize(owner);

        // Deploy factory with Diamond as controller
        factory = new VaultCollectionFactory(
            address(erc721Beacon), address(erc1155Beacon), address(diamond)
        );

        // Create a test collection through Diamond
        vm.prank(address(diamond));
        nftCollection = factory.createERC721Collection("Test NFT", "NFT");

        // Setup test environment
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
        vm.deal(tokenHolder, 100 ether);
        paymentToken.mint(user1, 1000 ether);
        paymentToken.mint(user2, 1000 ether);

        vm.startPrank(owner);

        // Setup diamond configuration
        // 1. Set recipient address first
        vm.expectEmit(true, true, true, true);
        emit RecipientAddressChanged(address(this), address(this));
        EmblemVaultCoreFacet(address(diamond)).setRecipientAddress(address(this));

        // 2. Set quote contract second
        vm.expectEmit(true, true, true, true);
        emit QuoteContractChanged(address(0), address(quoteContract));
        EmblemVaultCoreFacet(address(diamond)).setQuoteContract(address(quoteContract));

        // 3. Set claimer contract third
        vm.expectEmit(true, true, true, true);
        emit ClaimerContractUpdated(address(0), address(claimer));
        EmblemVaultClaimFacet(address(diamond)).setClaimerContract(address(claimer));

        // 4. Add witness fourth
        vm.expectEmit(true, true, true, true);
        emit WitnessAdded(witness, 2); // owner + witness
        EmblemVaultCoreFacet(address(diamond)).addWitness(witness);

        // 5. Set factory last
        vm.expectEmit(true, true, true, true);
        emit VaultFactorySet(address(0), address(factory));
        EmblemVaultCoreFacet(address(diamond)).setVaultFactory(address(factory));

        vm.stopPrank();

        // Create signature for minting
        bytes memory signature = createSignature(
            nftCollection,
            address(0), // ETH payment
            1 ether,
            tokenHolder,
            1,
            1, // nonce
            1, // amount
            witnessPrivateKey
        );

        // Mint token through diamond
        vm.deal(tokenHolder, 1 ether); // Ensure tokenHolder has enough ETH
        vm.startPrank(tokenHolder);
        EmblemVaultMintFacet(address(diamond)).buyWithSignedPrice{value: 1 ether}(
            nftCollection,
            address(0),
            1 ether,
            tokenHolder,
            1,
            1, // nonce
            signature,
            "", // no serial number
            1 // amount
        );
        vm.stopPrank();
    }

    function testInitialization() public view {
        assertTrue(EmblemVaultInitFacet(address(diamond)).isInitialized());
        (
            string memory baseUri,
            address recipientAddr,
            address quoteAddr,
            address claimerAddr,
            bool byPassable,
            uint256 witnessCount
        ) = EmblemVaultInitFacet(address(diamond)).getConfiguration();

        assertEq(baseUri, "https://v2.emblemvault.io/meta/");
        assertEq(witnessCount, 2); // owner + witness
        assertEq(recipientAddr, address(this));
        assertEq(quoteAddr, address(quoteContract));
        assertEq(claimerAddr, address(claimer));
        assertFalse(byPassable);
        assertEq(EmblemVaultCoreFacet(address(diamond)).getVaultFactory(), address(factory));
    }

    function testOwnership() public view {
        assertEq(OwnershipFacet(address(diamond)).owner(), owner);
    }

    function testRevertLockInvalidCollection() public {
        address invalidCollection = address(0x999);
        vm.expectRevert(InvalidCollection.selector);
        EmblemVaultCoreFacet(address(diamond)).lockVault(invalidCollection, 1);
    }

    function testWitnessManagement() public {
        address newWitness = address(0x456);

        // Add witness
        vm.expectEmit(true, true, true, true);
        emit WitnessAdded(newWitness, 3); // owner + witness + newWitness
        EmblemVaultCoreFacet(address(diamond)).addWitness(newWitness);
        assertEq(EmblemVaultCoreFacet(address(diamond)).getWitnessCount(), 3);

        // Remove witness
        vm.expectEmit(true, true, true, true);
        emit WitnessRemoved(newWitness, 2); // back to owner + witness
        EmblemVaultCoreFacet(address(diamond)).removeWitness(newWitness);
        assertEq(EmblemVaultCoreFacet(address(diamond)).getWitnessCount(), 2);
    }

    function testRevertAddExistingWitness() public {
        vm.expectRevert(WitnessAlreadyExists.selector);
        EmblemVaultCoreFacet(address(diamond)).addWitness(witness);
    }

    function testRevertRemoveNonExistentWitness() public {
        vm.expectRevert(WitnessDoesNotExist.selector);
        EmblemVaultCoreFacet(address(diamond)).removeWitness(address(0x999));
    }

    function testRevertRemoveLastWitness() public {
        // Remove witness (leaving only owner)
        EmblemVaultCoreFacet(address(diamond)).removeWitness(witness);

        // Try to remove owner (last witness)
        vm.expectRevert(NoWitnessesRemaining.selector);
        EmblemVaultCoreFacet(address(diamond)).removeWitness(owner);
    }

    function testBasicClaim() public {
        // First approve and transfer to diamond from tokenHolder
        vm.startPrank(tokenHolder);
        ERC721VaultImplementation(nftCollection).approve(address(diamond), 1);
        ERC721VaultImplementation(nftCollection).transferFrom(tokenHolder, address(diamond), 1);
        vm.stopPrank();

        // Then claim from user1
        vm.startPrank(user1);
        EmblemVaultClaimFacet(address(diamond)).claim(nftCollection, 1);
        vm.stopPrank();

        // Verify token was burned
        vm.expectRevert(abi.encodeWithSignature("OwnerQueryForNonexistentToken()"));
        ERC721VaultImplementation(nftCollection).ownerOf(1);

        // Verify claim was registered
        bytes32[] memory proof;
        assertTrue(claimer.isClaimed(nftCollection, 1, proof));
    }

    function testClaimWithSignedPrice() public {
        uint256 tokenId = 1;
        uint256 price = 1 ether;
        uint256 nonce = 2; // Use new nonce since 1 was used in setup

        // First approve and transfer to diamond from tokenHolder
        vm.startPrank(tokenHolder);
        ERC721VaultImplementation(nftCollection).approve(address(diamond), tokenId);
        ERC721VaultImplementation(nftCollection).transferFrom(
            tokenHolder, address(diamond), tokenId
        );
        vm.stopPrank();

        // Create signature from witness
        bytes memory signature = createSignature(
            nftCollection,
            address(0), // ETH payment
            price,
            user1,
            tokenId,
            nonce,
            1,
            witnessPrivateKey
        );

        // Claim with signed price from user1
        vm.startPrank(user1);
        EmblemVaultClaimFacet(address(diamond)).claimWithSignedPrice{value: price}(
            nftCollection, tokenId, nonce, address(0), price, signature
        );
        vm.stopPrank();

        // Verify token was burned
        vm.expectRevert(abi.encodeWithSignature("OwnerQueryForNonexistentToken()"));
        ERC721VaultImplementation(nftCollection).ownerOf(tokenId);

        // Verify claim was registered
        bytes32[] memory proof;
        assertTrue(claimer.isClaimed(nftCollection, tokenId, proof));
    }

    function testClaimWithSignedPriceERC20() public {
        uint256 tokenId = 1;
        uint256 price = 100 ether;
        uint256 nonce = 2; // Use new nonce since 1 was used in setup

        // First approve and transfer to diamond from tokenHolder
        vm.startPrank(tokenHolder);
        ERC721VaultImplementation(nftCollection).approve(address(diamond), tokenId);
        ERC721VaultImplementation(nftCollection).transferFrom(
            tokenHolder, address(diamond), tokenId
        );
        vm.stopPrank();

        // Create signature from witness
        bytes memory signature = createSignature(
            nftCollection, address(paymentToken), price, user1, tokenId, nonce, 1, witnessPrivateKey
        );

        // Approve payment token
        vm.startPrank(user1);
        paymentToken.approve(address(diamond), price);

        // Claim with signed price
        EmblemVaultClaimFacet(address(diamond)).claimWithSignedPrice(
            nftCollection, tokenId, nonce, address(paymentToken), price, signature
        );
        vm.stopPrank();

        // Verify token was burned
        vm.expectRevert(abi.encodeWithSignature("OwnerQueryForNonexistentToken()"));
        ERC721VaultImplementation(nftCollection).ownerOf(tokenId);

        // Verify claim was registered
        bytes32[] memory proof;
        assertTrue(claimer.isClaimed(nftCollection, tokenId, proof));
    }

    function testBuyWithSignedPrice() public {
        // First verify the mapping for token minted in setup
        uint256 setupTokenId = 1;

        // Verify the token was minted successfully
        uint256 supply = ERC721AUpgradeable(nftCollection).totalSupply();
        assertEq(supply, 1, "Total supply should be 1");

        uint256 balance = ERC721VaultImplementation(nftCollection).balanceOf(tokenHolder);
        assertEq(balance, 1, "TokenHolder balance should be 1");

        // Get the internal token ID (should be 1 since it's the first token)
        uint256 firstTokenId = 1;

        // Verify ownership
        address tokenOwner = ERC721VaultImplementation(nftCollection).ownerOf(firstTokenId);
        assertEq(tokenOwner, tokenHolder, "Token should be owned by tokenHolder");

        // Verify token ID mappings
        uint256 externalId = IERC721AVault(nftCollection).getExternalTokenId(firstTokenId);
        assertEq(externalId, setupTokenId, "External token ID mapping incorrect");

        uint256 internalId = IERC721AVault(nftCollection).getInternalTokenId(setupTokenId);
        assertEq(internalId, firstTokenId, "Internal token ID mapping incorrect");

        // Now test minting a new token
        uint256 tokenId = 1000; // Use a much larger token ID
        uint256 price = 1 ether;
        uint256 nonce = 2; // Use new nonce since 1 was used in setup
        bytes memory serialNumber = new bytes(0);

        // Create signature from witness
        bytes memory signature = createSignature(
            nftCollection,
            address(0), // ETH payment
            price,
            user1,
            tokenId,
            nonce,
            1,
            witnessPrivateKey
        );

        // Buy with signed price from user1
        vm.startPrank(user1);
        EmblemVaultMintFacet(address(diamond)).buyWithSignedPrice{value: price}(
            nftCollection, address(0), price, user1, tokenId, nonce, signature, serialNumber, 1
        );
        vm.stopPrank();

        // Get the sequential internal token ID (should be 2 since we minted one in setup)
        uint256 internalTokenId = 2;

        // Verify ownership of new token
        assertEq(ERC721VaultImplementation(nftCollection).ownerOf(internalTokenId), user1);

        // Verify the mappings for new token
        assertEq(IERC721AVault(nftCollection).getExternalTokenId(internalTokenId), tokenId);
        assertEq(IERC721AVault(nftCollection).getInternalTokenId(tokenId), internalTokenId);
    }

    function testBuyWithSignedPriceERC20() public {
        // First verify the mapping for token minted in setup
        uint256 setupTokenId = 1;
        uint256 setupInternalId = 1;

        // Verify ownership of setup token
        assertEq(ERC721VaultImplementation(nftCollection).ownerOf(setupInternalId), tokenHolder);

        // Verify the mappings for setup token
        assertEq(IERC721AVault(nftCollection).getExternalTokenId(setupInternalId), setupTokenId);
        assertEq(IERC721AVault(nftCollection).getInternalTokenId(setupTokenId), setupInternalId);

        // Now test minting a new token
        uint256 tokenId = 999_999; // Use an even larger token ID
        uint256 price = 100 ether;
        uint256 nonce = 2; // Use new nonce since 1 was used in setup
        bytes memory serialNumber = new bytes(0);

        // Create signature from witness
        bytes memory signature = createSignature(
            nftCollection, address(paymentToken), price, user1, tokenId, nonce, 1, witnessPrivateKey
        );

        // Approve payment token
        vm.startPrank(user1);
        paymentToken.approve(address(diamond), price);

        // Buy with signed price
        EmblemVaultMintFacet(address(diamond)).buyWithSignedPrice(
            nftCollection,
            address(paymentToken),
            price,
            user1,
            tokenId,
            nonce,
            signature,
            serialNumber,
            1
        );
        vm.stopPrank();

        // Get the sequential internal token ID (should be 2 since we minted one in setup)
        uint256 internalTokenId = 2;

        // Verify ownership of new token
        assertEq(ERC721VaultImplementation(nftCollection).ownerOf(internalTokenId), user1);

        // Verify the mappings for new token
        assertEq(IERC721AVault(nftCollection).getExternalTokenId(internalTokenId), tokenId);
        assertEq(IERC721AVault(nftCollection).getInternalTokenId(tokenId), internalTokenId);
    }

    function testBuyWithQuote() public {
        uint256 tokenId = 2;
        uint256 basePrice = 1 ether;
        uint256 quotedPrice = 2 ether; // MockQuoteContract doubles the price
        uint256 nonce = 2; // Use new nonce since 1 was used in setup
        bytes memory serialNumber = new bytes(0);

        // Create signature from witness using the quote signature format
        bytes memory signature = createSignatureQuote(
            nftCollection, basePrice, user1, tokenId, nonce, 1, witnessPrivateKey
        );

        // Buy with quote from user1
        vm.startPrank(user1);
        EmblemVaultMintFacet(address(diamond)).buyWithQuote{value: quotedPrice}(
            nftCollection, basePrice, user1, tokenId, nonce, signature, serialNumber, 1
        );
        vm.stopPrank();

        // Verify token was minted to user1
        assertEq(ERC721VaultImplementation(nftCollection).ownerOf(tokenId), user1);
    }

    function testClaimWithSignedPriceLockedVault() public {
        uint256 tokenId = 1;
        uint256 price = 1 ether;
        uint256 nonce = 2; // Use new nonce since 1 was used in setup

        // First approve and transfer to diamond from tokenHolder
        vm.startPrank(tokenHolder);
        ERC721VaultImplementation(nftCollection).approve(address(diamond), tokenId);
        ERC721VaultImplementation(nftCollection).transferFrom(
            tokenHolder, address(diamond), tokenId
        );
        vm.stopPrank();

        // Lock the vault
        EmblemVaultCoreFacet(address(diamond)).lockVault(nftCollection, tokenId);

        // Create signature from witness with locked acknowledgement
        bytes memory signature = createSignatureWithLock(
            nftCollection, address(0), price, user1, tokenId, nonce, 1, witnessPrivateKey
        );

        // Claim with signed price from user1
        vm.startPrank(user1);
        EmblemVaultClaimFacet(address(diamond)).claimWithSignedPrice{value: price}(
            nftCollection, tokenId, nonce, address(0), price, signature
        );
        vm.stopPrank();

        // Verify token was burned
        vm.expectRevert(abi.encodeWithSignature("OwnerQueryForNonexistentToken()"));
        ERC721VaultImplementation(nftCollection).ownerOf(tokenId);

        // Verify claim was registered
        bytes32[] memory proof;
        assertTrue(claimer.isClaimed(nftCollection, tokenId, proof));
    }

    function testRevertClaimWithInvalidSignature() public {
        uint256 tokenId = 1;
        uint256 price = 1 ether;
        uint256 nonce = 2; // Use new nonce since 1 was used in setup

        // First approve and transfer to diamond from tokenHolder
        vm.startPrank(tokenHolder);
        ERC721VaultImplementation(nftCollection).approve(address(diamond), tokenId);
        ERC721VaultImplementation(nftCollection).transferFrom(
            tokenHolder, address(diamond), tokenId
        );
        vm.stopPrank();

        // Create signature with wrong private key
        bytes memory signature = createSignature(
            nftCollection,
            address(0),
            price,
            user1,
            tokenId,
            nonce,
            1,
            0xBAD // Wrong private key
        );

        // Get the recovered address for the error expectation
        bytes32 hash = keccak256(
            abi.encodePacked(nftCollection, address(0), price, user1, tokenId, nonce, uint256(1))
        );
        bytes32 prefixedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(0xBAD, prefixedHash);
        address recoveredSigner = ecrecover(prefixedHash, v, r, s);

        // Attempt to claim with invalid signature
        vm.startPrank(user1);
        vm.expectRevert(abi.encodeWithSelector(LibErrors.NotWitness.selector, recoveredSigner));
        EmblemVaultClaimFacet(address(diamond)).claimWithSignedPrice{value: price}(
            nftCollection, tokenId, nonce, address(0), price, signature
        );
        vm.stopPrank();
    }

    function testRevertClaimWithWrongPaymentAmount() public {
        uint256 tokenId = 1;
        uint256 price = 1 ether;
        uint256 nonce = 2; // Use new nonce since 1 was used in setup

        // First approve and transfer to diamond from tokenHolder
        vm.startPrank(tokenHolder);
        ERC721VaultImplementation(nftCollection).approve(address(diamond), tokenId);
        ERC721VaultImplementation(nftCollection).transferFrom(
            tokenHolder, address(diamond), tokenId
        );
        vm.stopPrank();

        // Create signature from witness
        bytes memory signature = createSignature(
            nftCollection, address(0), price, user1, tokenId, nonce, 1, witnessPrivateKey
        );

        // Attempt to claim with wrong payment amount
        vm.startPrank(user1);
        vm.expectRevert(
            abi.encodeWithSelector(LibErrors.IncorrectPayment.selector, price / 2, price)
        );
        EmblemVaultClaimFacet(address(diamond)).claimWithSignedPrice{value: price / 2}(
            nftCollection, tokenId, nonce, address(0), price, signature
        );
        vm.stopPrank();
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
            DiamondLoupeFacet(address(diamond)).getFacetAddress(OwnershipFacet.owner.selector),
            address(ownershipFacet)
        );
    }

    function testBatchBuyWithSignedPrice() public {
        // Create test data
        uint256[] memory tokenIds = new uint256[](3);
        tokenIds[0] = 100;
        tokenIds[1] = 101;
        tokenIds[2] = 102;

        uint256[] memory prices = new uint256[](3);
        prices[0] = 1 ether;
        prices[1] = 1.5 ether;
        prices[2] = 2 ether;

        uint256[] memory nonces = new uint256[](3);
        nonces[0] = 2;
        nonces[1] = 3;
        nonces[2] = 4;

        bytes[] memory signatures = new bytes[](3);
        signatures[0] = createSignature(
            nftCollection,
            address(0), // ETH payment
            prices[0],
            user1,
            tokenIds[0],
            nonces[0],
            1,
            witnessPrivateKey
        );
        signatures[1] = createSignature(
            nftCollection,
            address(0),
            prices[1],
            user1,
            tokenIds[1],
            nonces[1],
            1,
            witnessPrivateKey
        );
        signatures[2] = createSignature(
            nftCollection,
            address(0),
            prices[2],
            user1,
            tokenIds[2],
            nonces[2],
            1,
            witnessPrivateKey
        );

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 1;
        amounts[1] = 1;
        amounts[2] = 1;

        // Calculate total price
        uint256 totalPrice = prices[0] + prices[1] + prices[2];

        // Execute batch mint
        vm.startPrank(user1);
        bytes[] memory serialNumbers = new bytes[](3);
        EmblemVaultMintFacet.BatchPurchase memory purchase = EmblemVaultMintFacet.BatchPurchase({
            nftAddress: nftCollection,
            payment: address(0),
            prices: prices,
            to: user1,
            externalTokenIds: tokenIds,
            nonces: nonces,
            signatures: signatures,
            serialNumbers: serialNumbers,
            amounts: amounts
        });
        EmblemVaultMintFacet(address(diamond)).batchBuyWithSignedPrice{value: totalPrice}(purchase);
        vm.stopPrank();

        // Verify tokens were minted correctly
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 internalTokenId = i + 2; // +2 because setup already minted token 1

            // Verify ownership
            assertEq(ERC721VaultImplementation(nftCollection).ownerOf(internalTokenId), user1);

            // Verify token ID mappings
            assertEq(IERC721AVault(nftCollection).getExternalTokenId(internalTokenId), tokenIds[i]);
            assertEq(IERC721AVault(nftCollection).getInternalTokenId(tokenIds[i]), internalTokenId);
        }
    }

    // function testBatchBuyWithQuote() public {
    //     // Create test data
    //     uint256[] memory tokenIds = new uint256[](3);
    //     tokenIds[0] = 100;
    //     tokenIds[1] = 101;
    //     tokenIds[2] = 102;

    //     uint256[] memory basePrices = new uint256[](3);
    //     basePrices[0] = 1 ether;
    //     basePrices[1] = 1.5 ether;
    //     basePrices[2] = 2 ether;

    //     uint256[] memory nonces = new uint256[](3);
    //     nonces[0] = 2;
    //     nonces[1] = 3;
    //     nonces[2] = 4;

    //     bytes[] memory signatures = new bytes[](3);
    //     signatures[0] = createSignatureQuote(
    //         nftCollection, basePrices[0], user1, tokenIds[0], nonces[0], 1, witnessPrivateKey
    //     );
    //     signatures[1] = createSignatureQuote(
    //         nftCollection, basePrices[1], user1, tokenIds[1], nonces[1], 1, witnessPrivateKey
    //     );
    //     signatures[2] = createSignatureQuote(
    //         nftCollection, basePrices[2], user1, tokenIds[2], nonces[2], 1, witnessPrivateKey
    //     );

    //     uint256[] memory amounts = new uint256[](3);
    //     amounts[0] = 1;
    //     amounts[1] = 1;
    //     amounts[2] = 1;

    //     // Calculate total price
    //     uint256 totalPrice = 3.5 ether; // MockQuoteContract doubles the price

    //     // Execute batch mint
    //     vm.startPrank(user1);
    //     EmblemVaultMintFacet(address(diamond)).batchBuyWithQuote{value: totalPrice}(
    //         nftCollection, basePrices, user1, tokenIds, nonces, signatures, amounts
    //     );
    //     vm.stopPrank();

    //     // Verify tokens were minted correctly
    //     for (uint256 i = 0; i < tokenIds.length; i++) {
    //         uint256 internalTokenId = i + 2; // +2 because setup already minted token 1

    //         // Verify ownership
    //         assertEq(ERC721VaultImplementation(nftCollection).ownerOf(internalTokenId), user1);

    //         // Verify token ID
    //         assertEq(IERC721AVault(nftCollection).getExternalTokenId(internalTokenId), tokenIds[i]);
    //         assertEq(IERC721AVault(nftCollection).getInternalTokenId(tokenIds[i]), internalTokenId);
    //     }
    // }

    function testRevertBatchBuyWithInvalidSignature() public {
        // Create test data
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 100;

        uint256[] memory prices = new uint256[](1);
        prices[0] = 1 ether;

        uint256[] memory nonces = new uint256[](1);
        nonces[0] = 2;

        bytes[] memory signatures = new bytes[](1);
        // Create signature with wrong private key
        signatures[0] = createSignature(
            nftCollection,
            address(0),
            prices[0],
            user1,
            tokenIds[0],
            nonces[0],
            1,
            0xBAD // Wrong private key
        );

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;

        // Execute batch mint
        vm.startPrank(user1);
        vm.expectRevert(abi.encodeWithSelector(LibErrors.NotWitness.selector, vm.addr(0xBAD)));
        bytes[] memory serialNumbers = new bytes[](1);
        EmblemVaultMintFacet.BatchPurchase memory purchase = EmblemVaultMintFacet.BatchPurchase({
            nftAddress: nftCollection,
            payment: address(0),
            prices: prices,
            to: user1,
            externalTokenIds: tokenIds,
            nonces: nonces,
            signatures: signatures,
            serialNumbers: serialNumbers,
            amounts: amounts
        });
        EmblemVaultMintFacet(address(diamond)).batchBuyWithSignedPrice{value: prices[0]}(purchase);
        vm.stopPrank();
    }

    function testRevertBatchBuyWithInsufficientPayment() public {
        // Create test data
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 100;

        uint256[] memory prices = new uint256[](1);
        prices[0] = 1 ether;

        uint256[] memory nonces = new uint256[](1);
        nonces[0] = 2;

        bytes[] memory signatures = new bytes[](1);
        signatures[0] = createSignature(
            nftCollection,
            address(0),
            prices[0],
            user1,
            tokenIds[0],
            nonces[0],
            1,
            witnessPrivateKey
        );

        bytes[] memory serialNumbers = new bytes[](1);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;

        // Execute batch mint with insufficient ETH
        vm.startPrank(user1);
        vm.expectRevert(
            abi.encodeWithSelector(LibErrors.IncorrectPayment.selector, prices[0] / 2, prices[0])
        );
        EmblemVaultMintFacet.BatchPurchase memory purchase = EmblemVaultMintFacet.BatchPurchase({
            nftAddress: nftCollection,
            payment: address(0),
            prices: prices,
            to: user1,
            externalTokenIds: tokenIds,
            nonces: nonces,
            signatures: signatures,
            serialNumbers: serialNumbers,
            amounts: amounts
        });
        EmblemVaultMintFacet(address(diamond)).batchBuyWithSignedPrice{value: prices[0] / 2}(
            purchase
        );
        vm.stopPrank();
    }

    // Helper function to create signature for standard purchases
    function createSignature(
        address _nftAddress,
        address _payment,
        uint256 _price,
        address _to,
        uint256 _tokenId,
        uint256 _nonce,
        uint256 _amount,
        uint256 _privateKey
    ) internal pure returns (bytes memory) {
        bytes32 hash = keccak256(
            abi.encodePacked(_nftAddress, _payment, _price, _to, _tokenId, _nonce, _amount)
        );
        bytes32 prefixedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_privateKey, prefixedHash);
        return abi.encodePacked(r, s, v);
    }

    // Helper function to create signature for quotes
    function createSignatureQuote(
        address _nftAddress,
        uint256 _price,
        address _to,
        uint256 _tokenId,
        uint256 _nonce,
        uint256 _amount,
        uint256 _privateKey
    ) internal pure returns (bytes memory) {
        bytes32 hash =
            keccak256(abi.encodePacked(_nftAddress, _price, _to, _tokenId, _nonce, _amount));
        bytes32 prefixedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_privateKey, prefixedHash);
        return abi.encodePacked(r, s, v);
    }

    // Helper function to create signature for locked vaults
    function createSignatureWithLock(
        address _nftAddress,
        address _payment,
        uint256 _price,
        address _to,
        uint256 _tokenId,
        uint256 _nonce,
        uint256 _amount,
        uint256 _privateKey
    ) internal pure returns (bytes memory) {
        bytes32 hash = keccak256(
            abi.encodePacked(_nftAddress, _payment, _price, _to, _tokenId, _nonce, _amount, true)
        );
        bytes32 prefixedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_privateKey, prefixedHash);
        return abi.encodePacked(r, s, v);
    }

    function testVaultLocking() public {
        // Lock vault
        vm.startPrank(owner);
        vm.expectEmit(true, true, true, true);
        emit VaultLocked(nftCollection, 1, owner);
        EmblemVaultCoreFacet(address(diamond)).lockVault(nftCollection, 1);
        assertTrue(EmblemVaultCoreFacet(address(diamond)).isVaultLocked(nftCollection, 1));

        // Unlock vault
        vm.expectEmit(true, true, true, true);
        emit VaultUnlocked(nftCollection, 1, owner);
        EmblemVaultCoreFacet(address(diamond)).unlockVault(nftCollection, 1);
        assertFalse(EmblemVaultCoreFacet(address(diamond)).isVaultLocked(nftCollection, 1));
        vm.stopPrank();
    }
}
