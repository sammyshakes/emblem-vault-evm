// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

// Core contracts
import {EmblemVaultDiamond} from "../src/EmblemVaultDiamond.sol";
import {DiamondCutFacet} from "../src/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../src/facets/DiamondLoupeFacet.sol";
import {OwnershipFacet} from "../src/facets/OwnershipFacet.sol";
import {EmblemVaultCoreFacet} from "../src/facets/EmblemVaultCoreFacet.sol";
import {EmblemVaultClaimFacet} from "../src/facets/EmblemVaultClaimFacet.sol";
import {EmblemVaultCollectionFacet} from "../src/facets/EmblemVaultCollectionFacet.sol";
import {EmblemVaultInitFacet} from "../src/facets/EmblemVaultInitFacet.sol";
import {EmblemVaultMintFacet} from "../src/facets/EmblemVaultMintFacet.sol";
import {EmblemVaultMintFacetOptimized} from "../src/facets/EmblemVaultMintFacetOptimized.sol";

// Implementations
import {ERC721VaultImplementation} from "../src/implementations/ERC721VaultImplementation.sol";
import {ERC721VaultImplementationOptimized} from
    "../src/implementations/ERC721VaultImplementationOptimized.sol";
import {VaultBeacon} from "../src/beacon/VaultBeacon.sol";
import {VaultProxy} from "../src/beacon/VaultProxy.sol";

// Libraries
import {LibEmblemVaultStorage} from "../src/libraries/LibEmblemVaultStorage.sol";
import {LibSignature} from "../src/libraries/LibSignature.sol";
import {LibDiamond} from "../src/libraries/LibDiamond.sol";

// Interfaces
import {IMintVaultQuote} from "../src/interfaces/IMintVaultQuote.sol";
import {IVaultCollectionFactory} from "../src/interfaces/IVaultCollectionFactory.sol";
import {IERC721A} from "../src/interfaces/IERC721A.sol";
import {IERC1155} from "../src/interfaces/IERC1155.sol";
import {IDiamondCut} from "../src/interfaces/IDiamondCut.sol";

contract MockQuoteContract is IMintVaultQuote {
    function initialize() external {}
    function setPair(address) external {}
    function setUsdPrice(uint256) external {}
    function addDiscountToken(address, uint256, uint256) external {}
    function updateDiscountToken(uint256, address, uint256, uint256) external {}
    function removeDiscountToken(uint256) external {}
    function addMintPass(address, uint256, uint256) external {}
    function updateMintPass(uint256, address, uint256, uint256) external {}
    function removeMintPass(uint256) external {}

    function getUsdPriceInEth(uint256) external pure returns (uint256) {
        return 0;
    }

    function getReserves() external pure returns (uint112, uint112) {
        return (0, 0);
    }

    function quoteExternalPrice(address, uint256 basePrice) external pure returns (uint256) {
        return basePrice * 2; // Simple multiplier for testing
    }

    function quoteStoredPrice(address) external pure returns (uint256) {
        return 0;
    }
}

contract MockVaultFactory {
    mapping(address => bool) public collections;

    function setCollection(address collection, bool isValid) external {
        collections[collection] = isValid;
    }

    function isCollection(address collection) external view returns (bool) {
        return collections[collection];
    }
}

contract EmblemVaultMintFacetOptimizedTest is Test {
    EmblemVaultDiamond originalDiamond;
    EmblemVaultDiamond optimizedDiamond;
    DiamondCutFacet diamondCut;
    DiamondLoupeFacet diamondLoupe;
    OwnershipFacet ownership;
    EmblemVaultCoreFacet core;
    EmblemVaultClaimFacet claim;
    EmblemVaultCollectionFacet collection;
    EmblemVaultInitFacet initFacet;
    EmblemVaultMintFacet original;
    EmblemVaultMintFacetOptimized optimized;
    MockQuoteContract quoteContract;
    MockVaultFactory vaultFactory;

    // ERC721 implementations
    ERC721VaultImplementation originalImpl;
    ERC721VaultImplementationOptimized optimizedImpl;
    VaultBeacon originalBeacon;
    VaultBeacon optimizedBeacon;
    VaultProxy originalProxy;
    VaultProxy optimizedProxy;

    address owner = address(this);
    address user = address(0x1);
    address recipient = address(0x2);
    uint256 constant SIGNER_PRIVATE_KEY = 0x1234; // Test private key
    address signer;

    function setUp() public {
        // Set up signer
        signer = vm.addr(SIGNER_PRIVATE_KEY);

        // Deploy mock contracts
        quoteContract = new MockQuoteContract();
        vaultFactory = new MockVaultFactory();

        // Deploy and set up ERC721 implementations
        originalImpl = new ERC721VaultImplementation();
        optimizedImpl = new ERC721VaultImplementationOptimized();

        // Deploy beacons
        originalBeacon = new VaultBeacon(address(originalImpl));
        optimizedBeacon = new VaultBeacon(address(optimizedImpl));

        // Deploy proxies
        originalProxy = new VaultProxy(address(originalBeacon));
        optimizedProxy = new VaultProxy(address(optimizedBeacon));

        // Initialize proxies
        ERC721VaultImplementation(address(originalProxy)).initialize("OriginalVault", "OVLT");
        ERC721VaultImplementationOptimized(address(optimizedProxy)).initialize(
            "OptimizedVault", "OPVLT"
        );

        // Deploy Diamond system facets
        diamondCut = new DiamondCutFacet();
        diamondLoupe = new DiamondLoupeFacet();
        ownership = new OwnershipFacet();
        core = new EmblemVaultCoreFacet();
        claim = new EmblemVaultClaimFacet();
        collection = new EmblemVaultCollectionFacet();
        initFacet = new EmblemVaultInitFacet();

        // Deploy original diamond and facets
        originalDiamond = new EmblemVaultDiamond(owner, address(diamondCut));
        original = new EmblemVaultMintFacet();

        // Deploy optimized diamond and facets
        optimizedDiamond = new EmblemVaultDiamond(owner, address(diamondCut));
        optimized = new EmblemVaultMintFacetOptimized();

        // Setup original diamond
        _setupDiamond(address(originalDiamond), address(original));

        // Setup optimized diamond
        _setupDiamond(address(optimizedDiamond), address(optimized));

        // Setup test accounts
        vm.deal(user, 100 ether);

        // Add signer as witness
        vm.startPrank(owner);
        EmblemVaultCoreFacet(address(originalDiamond)).addWitness(signer);
        EmblemVaultCoreFacet(address(optimizedDiamond)).addWitness(signer);

        // Transfer proxy ownership to diamonds
        ERC721VaultImplementation(address(originalProxy)).transferOwnership(
            address(originalDiamond)
        );
        ERC721VaultImplementationOptimized(address(optimizedProxy)).transferOwnership(
            address(optimizedDiamond)
        );

        // Setup vault factory
        vaultFactory.setCollection(address(originalProxy), true);
        vaultFactory.setCollection(address(optimizedProxy), true);
        vm.stopPrank();
    }

    function _setupDiamond(address diamond, address mintFacet) internal {
        // Build cut struct for adding facets
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](7);

        // DiamondLoupeFacet
        bytes4[] memory loupeSelectors = new bytes4[](4);
        loupeSelectors[0] = DiamondLoupeFacet.facets.selector;
        loupeSelectors[1] = DiamondLoupeFacet.facetFunctionSelectors.selector;
        loupeSelectors[2] = DiamondLoupeFacet.facetAddresses.selector;
        loupeSelectors[3] = DiamondLoupeFacet.supportsInterface.selector;
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(diamondLoupe),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: loupeSelectors
        });

        // OwnershipFacet
        bytes4[] memory ownershipSelectors = new bytes4[](2);
        ownershipSelectors[0] = OwnershipFacet.transferOwnership.selector;
        ownershipSelectors[1] = OwnershipFacet.owner.selector;
        cut[1] = IDiamondCut.FacetCut({
            facetAddress: address(ownership),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: ownershipSelectors
        });

        // CoreFacet
        bytes4[] memory coreSelectors = new bytes4[](13);
        coreSelectors[0] = EmblemVaultCoreFacet.lockVault.selector;
        coreSelectors[1] = EmblemVaultCoreFacet.unlockVault.selector;
        coreSelectors[2] = EmblemVaultCoreFacet.isVaultLocked.selector;
        coreSelectors[3] = EmblemVaultCoreFacet.addWitness.selector;
        coreSelectors[4] = EmblemVaultCoreFacet.removeWitness.selector;
        coreSelectors[5] = EmblemVaultCoreFacet.setRecipientAddress.selector;
        coreSelectors[6] = EmblemVaultCoreFacet.setQuoteContract.selector;
        coreSelectors[7] = EmblemVaultCoreFacet.setMetadataBaseUri.selector;
        coreSelectors[8] = EmblemVaultCoreFacet.isWitness.selector;
        coreSelectors[9] = EmblemVaultCoreFacet.getWitnessCount.selector;
        coreSelectors[10] = EmblemVaultCoreFacet.version.selector;
        coreSelectors[11] = EmblemVaultCoreFacet.setVaultFactory.selector;
        coreSelectors[12] = EmblemVaultCoreFacet.getVaultFactory.selector;
        cut[2] = IDiamondCut.FacetCut({
            facetAddress: address(core),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: coreSelectors
        });

        // ClaimFacet
        bytes4[] memory claimSelectors = new bytes4[](3);
        claimSelectors[0] = EmblemVaultClaimFacet.claim.selector;
        claimSelectors[1] = EmblemVaultClaimFacet.claimWithSignedPrice.selector;
        claimSelectors[2] = EmblemVaultClaimFacet.setClaimerContract.selector;
        cut[3] = IDiamondCut.FacetCut({
            facetAddress: address(claim),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: claimSelectors
        });

        // MintFacet
        bytes4[] memory mintSelectors = new bytes4[](2);
        mintSelectors[0] = EmblemVaultMintFacet.buyWithSignedPrice.selector;
        mintSelectors[1] = EmblemVaultMintFacet.buyWithQuote.selector;
        cut[4] = IDiamondCut.FacetCut({
            facetAddress: mintFacet,
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
            facetAddress: address(collection),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: collectionSelectors
        });

        // InitFacet
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
        IDiamondCut(diamond).diamondCut(cut, address(0), "");

        // Initialize diamond
        bytes memory initData =
            abi.encodeWithSelector(EmblemVaultInitFacet.initialize.selector, owner);
        (bool success,) = diamond.call(initData);
        require(success, "Diamond initialization failed");

        // Set additional configuration through CoreFacet
        vm.startPrank(owner);
        EmblemVaultCoreFacet(diamond).setVaultFactory(address(vaultFactory));
        EmblemVaultCoreFacet(diamond).setQuoteContract(address(quoteContract));
        EmblemVaultCoreFacet(diamond).setRecipientAddress(recipient);
        vm.stopPrank();
    }

    function testGasComparisonBuyWithSignedPrice() public {
        // Generate signature for original implementation
        bytes32 messageHashOriginal = LibSignature.getStandardSignatureHash(
            address(originalProxy), address(0), 1 ether, user, 1, 1, 1
        );
        bytes32 prefixedHashOriginal =
            keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHashOriginal));
        (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(SIGNER_PRIVATE_KEY, prefixedHashOriginal);
        bytes memory signatureOriginal = abi.encodePacked(r1, s1, v1);

        // Generate signature for optimized implementation
        bytes32 messageHashOptimized = LibSignature.getStandardSignatureHash(
            address(optimizedProxy), address(0), 1 ether, user, 2, 2, 1
        );
        bytes32 prefixedHashOptimized =
            keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHashOptimized));
        (uint8 v2, bytes32 r2, bytes32 s2) = vm.sign(SIGNER_PRIVATE_KEY, prefixedHashOptimized);
        bytes memory signatureOptimized = abi.encodePacked(r2, s2, v2);

        vm.startPrank(user);

        // Original implementation
        uint256 gasStartOriginal = gasleft();
        EmblemVaultMintFacet(address(originalDiamond)).buyWithSignedPrice(
            address(originalProxy), address(0), 1 ether, user, 1, 1, signatureOriginal, "", 1
        );
        uint256 gasOriginal = gasStartOriginal - gasleft();

        // Optimized implementation
        uint256 gasStartOptimized = gasleft();
        EmblemVaultMintFacetOptimized(address(optimizedDiamond)).buyWithSignedPrice(
            address(optimizedProxy), address(0), 1 ether, user, 2, 2, signatureOptimized, "", 1
        );
        uint256 gasOptimized = gasStartOptimized - gasleft();

        vm.stopPrank();

        emit log_named_uint("Gas used (original buyWithSignedPrice)", gasOriginal);
        emit log_named_uint("Gas used (optimized buyWithSignedPrice)", gasOptimized);
        assertTrue(gasOptimized < gasOriginal, "Optimized should use less gas");

        // Verify mints
        assertEq(ERC721VaultImplementation(address(originalProxy)).ownerOf(1), user);
        assertEq(ERC721VaultImplementationOptimized(address(optimizedProxy)).ownerOf(1), user);
    }

    function testGasComparisonBuyWithQuote() public {
        // Generate signature for original implementation
        bytes32 messageHashOriginal =
            LibSignature.getQuoteSignatureHash(address(originalProxy), 1 ether, user, 1, 1, 1);
        bytes32 prefixedHashOriginal =
            keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHashOriginal));
        (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(SIGNER_PRIVATE_KEY, prefixedHashOriginal);
        bytes memory signatureOriginal = abi.encodePacked(r1, s1, v1);

        // Generate signature for optimized implementation
        bytes32 messageHashOptimized =
            LibSignature.getQuoteSignatureHash(address(optimizedProxy), 1 ether, user, 2, 2, 1);
        bytes32 prefixedHashOptimized =
            keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHashOptimized));
        (uint8 v2, bytes32 r2, bytes32 s2) = vm.sign(SIGNER_PRIVATE_KEY, prefixedHashOptimized);
        bytes memory signatureOptimized = abi.encodePacked(r2, s2, v2);

        vm.startPrank(user);

        // Original implementation
        uint256 gasStartOriginal = gasleft();
        EmblemVaultMintFacet(address(originalDiamond)).buyWithQuote{value: 2 ether}(
            address(originalProxy), 1 ether, user, 1, 1, signatureOriginal, "", 1
        );
        uint256 gasOriginal = gasStartOriginal - gasleft();

        // Optimized implementation
        uint256 gasStartOptimized = gasleft();
        EmblemVaultMintFacetOptimized(address(optimizedDiamond)).buyWithQuote{value: 2 ether}(
            address(optimizedProxy), 1 ether, user, 2, 2, signatureOptimized, "", 1
        );
        uint256 gasOptimized = gasStartOptimized - gasleft();

        vm.stopPrank();

        emit log_named_uint("Gas used (original buyWithQuote)", gasOriginal);
        emit log_named_uint("Gas used (optimized buyWithQuote)", gasOptimized);
        assertTrue(gasOptimized < gasOriginal, "Optimized should use less gas");

        // Verify mints
        assertEq(ERC721VaultImplementation(address(originalProxy)).ownerOf(1), user);
        assertEq(ERC721VaultImplementationOptimized(address(optimizedProxy)).ownerOf(1), user);
    }
}
