// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {EmblemVaultDiamond} from "../src/EmblemVaultDiamond.sol";
import {ERC721AUpgradeable} from "ERC721A-Upgradeable/ERC721AUpgradeable.sol";
import {IDiamondCut} from "../src/interfaces/IDiamondCut.sol";
import {DiamondCutFacet} from "../src/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../src/facets/DiamondLoupeFacet.sol";
import {OwnershipFacet} from "../src/facets/OwnershipFacet.sol";
import {EmblemVaultCoreFacet} from "../src/facets/EmblemVaultCoreFacet.sol";
import {EmblemVaultUnvaultFacet} from "../src/facets/EmblemVaultUnvaultFacet.sol";
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
import {LibSignature} from "../src/libraries/LibSignature.sol";
import "./mocks/MockERC20.sol";
import "./mocks/MockClaimer.sol";

contract DiamondVaultTest is Test {
    // Diamond components
    EmblemVaultDiamond diamond;
    DiamondCutFacet diamondCutFacet;
    DiamondLoupeFacet diamondLoupeFacet;
    OwnershipFacet ownershipFacet;
    EmblemVaultCoreFacet vaultCoreFacet;
    EmblemVaultUnvaultFacet unvaultFacet;
    EmblemVaultMintFacet mintFacet;
    EmblemVaultCollectionFacet collectionFacet;
    EmblemVaultInitFacet initFacet;

    // Mock contracts
    MockERC20 paymentToken;
    address nftCollection; // This will be created through the factory
    MockClaimer claimer;
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
    error UnvaulterNotSet();
    error NotVaultOwner();
    error AlreadyUnvaulted();

    receive() external payable {}
    fallback() external payable {}

    function setUp() public virtual {
        // Derive witness address from private key
        witness = vm.addr(witnessPrivateKey);

        // Deploy mock contracts
        paymentToken = new MockERC20("Payment Token", "PAY");
        claimer = new MockClaimer();

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
        unvaultFacet = new EmblemVaultUnvaultFacet();
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

        // UnvaultFacet
        bytes4[] memory unvaultSelectors = new bytes4[](8);
        unvaultSelectors[0] = EmblemVaultUnvaultFacet.unvault.selector;
        unvaultSelectors[1] = EmblemVaultUnvaultFacet.unvaultWithSignedPrice.selector;
        unvaultSelectors[2] = EmblemVaultUnvaultFacet.setUnvaultingEnabled.selector;
        unvaultSelectors[3] = EmblemVaultUnvaultFacet.setBurnAddress.selector;
        unvaultSelectors[4] = EmblemVaultUnvaultFacet.isTokenUnvaulted.selector;
        unvaultSelectors[5] = EmblemVaultUnvaultFacet.getTokenUnvaulter.selector;
        unvaultSelectors[6] = EmblemVaultUnvaultFacet.getCollectionUnvaultCount.selector;
        unvaultSelectors[7] = EmblemVaultUnvaultFacet.getUnvaultVersion.selector;
        cut[3] = IDiamondCut.FacetCut({
            facetAddress: address(unvaultFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: unvaultSelectors
        });

        // MintFacet
        bytes4[] memory mintSelectors = new bytes4[](3);
        mintSelectors[0] = EmblemVaultMintFacet.buyWithSignedPrice.selector;
        mintSelectors[1] = EmblemVaultMintFacet.batchBuyWithSignedPrice.selector;
        mintSelectors[2] = EmblemVaultMintFacet.getMintVersion.selector;
        cut[4] = IDiamondCut.FacetCut({
            facetAddress: address(mintFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: mintSelectors
        });

        // CollectionFacet
        bytes4[] memory collectionSelectors = new bytes4[](13);
        collectionSelectors[0] = EmblemVaultCollectionFacet.setCollectionFactory.selector;
        collectionSelectors[1] = EmblemVaultCollectionFacet.createVaultCollection.selector;
        collectionSelectors[2] = EmblemVaultCollectionFacet.upgradeCollectionImplementation.selector;
        collectionSelectors[3] = EmblemVaultCollectionFacet.getCollectionImplementation.selector;
        collectionSelectors[4] = EmblemVaultCollectionFacet.getCollectionBeacon.selector;
        collectionSelectors[5] = EmblemVaultCollectionFacet.isCollection.selector;
        collectionSelectors[6] = EmblemVaultCollectionFacet.getCollectionFactory.selector;
        collectionSelectors[7] = EmblemVaultCollectionFacet.setCollectionBaseURI.selector;
        collectionSelectors[8] = EmblemVaultCollectionFacet.setCollectionURI.selector;
        collectionSelectors[9] = EmblemVaultCollectionFacet.getCollectionVersion.selector;
        collectionSelectors[10] = EmblemVaultCollectionFacet.setCollectionOwner.selector;
        collectionSelectors[11] = EmblemVaultCollectionFacet.getCollectionOwner.selector;
        collectionSelectors[12] = EmblemVaultCollectionFacet.getCollectionType.selector;
        cut[5] = IDiamondCut.FacetCut({
            facetAddress: address(collectionFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: collectionSelectors
        });

        // InitializationFacet
        bytes4[] memory initSelectors = new bytes4[](6);
        initSelectors[0] = EmblemVaultInitFacet.initialize.selector;
        initSelectors[1] = EmblemVaultInitFacet.isInitialized.selector;
        initSelectors[2] = EmblemVaultInitFacet.getInterfaceIds.selector;
        initSelectors[3] = EmblemVaultInitFacet.getConfiguration.selector;
        initSelectors[4] = EmblemVaultInitFacet.getInitializationDetails.selector;
        initSelectors[5] = EmblemVaultInitFacet.getInitVersion.selector;
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
        paymentToken.mint(tokenHolder, 1000 ether);

        vm.startPrank(owner);

        // Setup diamond configuration
        // 1. Set recipient address first
        vm.expectEmit(true, true, true, true);
        emit RecipientAddressChanged(address(this), address(this));
        EmblemVaultCoreFacet(address(diamond)).setRecipientAddress(address(this));

        // 2. Add witness (owner is already a witness from initialization)
        vm.expectEmit(true, true, true, true);
        emit WitnessAdded(witness, 2); // owner + witness
        EmblemVaultCoreFacet(address(diamond)).addWitness(witness);

        // Verify witness was added correctly
        require(
            EmblemVaultCoreFacet(address(diamond)).isWitness(witness), "Witness not added correctly"
        );

        // 3. Set factory
        vm.expectEmit(true, true, true, true);
        emit VaultFactorySet(address(0), address(factory));
        EmblemVaultCoreFacet(address(diamond)).setVaultFactory(address(factory));

        vm.stopPrank();

        // Create signature for minting
        bytes32 hash = LibSignature.getStandardSignatureHash(
            nftCollection,
            address(0), // ETH payment
            1 ether,
            tokenHolder,
            1,
            1, // nonce
            1, // amount
            new uint256[](0),
            0, // timestamp
            block.chainid
        );

        // Sign with witness private key
        bytes32 prefixedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(witnessPrivateKey, prefixedHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        // Mint token through diamond
        vm.deal(tokenHolder, 1 ether); // Ensure tokenHolder has enough ETH
        vm.startPrank(tokenHolder);
        // Use timestamp close to current block.timestamp to avoid StaleSignature error
        uint256 timestamp = block.timestamp > 1 ? block.timestamp - 1 : 0;
        console.log("Current block.timestamp:", block.timestamp);
        console.log("Using timestamp:", timestamp);
        EmblemVaultMintFacet(address(diamond)).buyWithSignedPrice{value: 1 ether}(
            nftCollection,
            address(0),
            1 ether,
            tokenHolder,
            1,
            1, // nonce
            signature,
            new uint256[](0), // no serial number
            1, // amount
            timestamp
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
        uint256 _privateKey,
        uint256[] memory _serialNumbers,
        uint256 _timestamp
    ) internal view returns (bytes memory) {
        console.log("chainid: ", block.chainid);

        // Use LibSignature to generate hash with timestamp
        bytes32 hash = LibSignature.getStandardSignatureHash(
            _nftAddress,
            _payment,
            _price,
            _to,
            _tokenId,
            _nonce,
            _amount,
            _serialNumbers,
            _timestamp,
            block.chainid
        );

        // Sign with Ethereum prefix
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
        uint256 _privateKey,
        uint256[] memory _serialNumbers,
        uint256 _timestamp
    ) internal view returns (bytes memory) {
        // Use LibSignature to generate hash with timestamp
        bytes32 hash = LibSignature.getLockedSignatureHash(
            _nftAddress,
            _payment,
            _price,
            _to,
            _tokenId,
            _nonce,
            _amount,
            _serialNumbers,
            _timestamp,
            block.chainid
        );

        // Sign with Ethereum prefix
        bytes32 prefixedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_privateKey, prefixedHash);
        return abi.encodePacked(r, s, v);
    }
}
