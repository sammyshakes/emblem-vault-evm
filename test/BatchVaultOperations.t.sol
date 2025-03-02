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
import {LibErrors} from "../src/libraries/LibErrors.sol";
import {LibSignature} from "../src/libraries/LibSignature.sol";
import {VaultBeacon, ERC721VaultBeacon, ERC1155VaultBeacon} from "../src/beacon/VaultBeacon.sol";
import {ERC721VaultImplementation} from "../src/implementations/ERC721VaultImplementation.sol";
import {ERC1155VaultImplementation} from "../src/implementations/ERC1155VaultImplementation.sol";
import {VaultCollectionFactory} from "../src/factories/VaultCollectionFactory.sol";
import "./mocks/MockERC20.sol";

contract BatchVaultOperationsTest is Test {
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

    // Test components
    MockERC20 paymentToken;
    address nftCollection;
    VaultCollectionFactory factory;
    ERC721VaultImplementation erc721Implementation;
    ERC1155VaultImplementation erc1155Implementation;
    ERC721VaultBeacon erc721Beacon;
    ERC1155VaultBeacon erc1155Beacon;

    // Test addresses
    address owner = address(this);
    address user1 = address(0x1);
    uint256 constant witnessPrivateKey =
        0x1234567890123456789012345678901234567890123456789012345678901234;
    address witness;

    // Match MintFacet's constant (defined in EmblemVaultMintFacet.sol)
    uint256 private constant MAX_BATCH_SIZE = 45;

    // Test batch sizes to analyze (staying within limit)
    uint256[] batchSizes = [1, 5, 10, 20, 40];

    // Storage variables for batch parameters to reduce stack usage
    uint256[] s_prices;
    uint256[] s_tokenIds;
    uint256[] s_nonces;
    bytes[] s_signatures;
    uint256[][] s_serialNumbers;
    uint256[] s_amounts;
    address[] s_nftAddresses;

    // Test for batch size limit
    function testBatchSizeLimitEnforcement() public {
        uint256 basePrice = 0.1 ether;
        uint256 maxSize = MAX_BATCH_SIZE;
        uint256 oversizedBatch = maxSize + 1;

        // Prepare batch parameters
        uint256[] memory prices = new uint256[](oversizedBatch);
        uint256[] memory tokenIds = new uint256[](oversizedBatch);
        uint256[] memory nonces = new uint256[](oversizedBatch);
        bytes[] memory signatures = new bytes[](oversizedBatch);
        uint256[][] memory serialNumbers = new uint256[][](oversizedBatch);
        uint256[] memory amounts = new uint256[](oversizedBatch);

        // Fill arrays with test data
        uint256 totalPrice = 0;
        for (uint256 j = 0; j < oversizedBatch; j++) {
            prices[j] = basePrice;
            tokenIds[j] = j + 1;
            nonces[j] = j + 1;
            amounts[j] = 1;
            signatures[j] = createSignature(
                nftCollection,
                address(0),
                basePrice,
                user1,
                tokenIds[j],
                nonces[j],
                amounts[j],
                witnessPrivateKey
            );
            serialNumbers[j] = new uint256[](0);
            totalPrice += basePrice;
        }

        // Test batch minting with oversized batch
        vm.startPrank(user1);
        vm.expectRevert(
            abi.encodeWithSelector(LibErrors.BatchSizeExceeded.selector, oversizedBatch, maxSize)
        );

        // Create an array with a single NFT address repeated for each token
        address[] memory nftAddresses = new address[](oversizedBatch);
        for (uint256 j = 0; j < oversizedBatch; j++) {
            nftAddresses[j] = nftCollection;
        }

        // Use timestamp 0 for signature verification in tests
        uint256 timestamp = 0;

        EmblemVaultMintFacet.BatchBuyParams memory params = EmblemVaultMintFacet.BatchBuyParams({
            nftAddresses: nftAddresses,
            payment: address(0),
            prices: prices,
            to: user1,
            tokenIds: tokenIds,
            nonces: nonces,
            signatures: signatures,
            serialNumbers: serialNumbers,
            amounts: amounts,
            timestamp: timestamp
        });

        EmblemVaultMintFacet(address(diamond)).batchBuyWithSignedPrice{value: totalPrice}(params);
        vm.stopPrank();
    }

    receive() external payable {}
    fallback() external payable {}

    function setUp() public {
        // Derive witness address
        witness = vm.addr(witnessPrivateKey);

        // Deploy mock contracts
        paymentToken = new MockERC20("Payment Token", "PAY");

        // Deploy implementations
        erc721Implementation = new ERC721VaultImplementation();
        erc1155Implementation = new ERC1155VaultImplementation();

        // Deploy beacons
        erc721Beacon = new ERC721VaultBeacon(address(erc721Implementation));
        erc1155Beacon = new ERC1155VaultBeacon(address(erc1155Implementation));

        // Deploy facets
        diamondCutFacet = new DiamondCutFacet();
        diamondLoupeFacet = new DiamondLoupeFacet();
        ownershipFacet = new OwnershipFacet();
        vaultCoreFacet = new EmblemVaultCoreFacet();
        unvaultFacet = new EmblemVaultUnvaultFacet();
        mintFacet = new EmblemVaultMintFacet();
        collectionFacet = new EmblemVaultCollectionFacet();
        initFacet = new EmblemVaultInitFacet();

        // Deploy Diamond
        diamond = new EmblemVaultDiamond(owner, address(diamondCutFacet));

        // Build cut struct
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](7);

        // Add all facets
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(diamondLoupeFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: getFacetSelectors("DiamondLoupeFacet")
        });

        cut[1] = IDiamondCut.FacetCut({
            facetAddress: address(ownershipFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: getFacetSelectors("OwnershipFacet")
        });

        cut[2] = IDiamondCut.FacetCut({
            facetAddress: address(vaultCoreFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: getFacetSelectors("VaultCoreFacet")
        });

        cut[3] = IDiamondCut.FacetCut({
            facetAddress: address(unvaultFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: getFacetSelectors("UnvaultFacet")
        });

        cut[4] = IDiamondCut.FacetCut({
            facetAddress: address(mintFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: getFacetSelectors("MintFacet")
        });

        cut[5] = IDiamondCut.FacetCut({
            facetAddress: address(collectionFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: getFacetSelectors("CollectionFacet")
        });

        cut[6] = IDiamondCut.FacetCut({
            facetAddress: address(initFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: getFacetSelectors("InitFacet")
        });

        // Add facets to diamond
        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");

        // Initialize diamond
        EmblemVaultInitFacet(address(diamond)).initialize(owner);

        // Configure diamond
        vm.startPrank(owner);
        EmblemVaultCoreFacet(address(diamond)).setRecipientAddress(address(this));
        EmblemVaultCoreFacet(address(diamond)).addWitness(witness);
        vm.stopPrank();

        // Deploy factory
        factory = new VaultCollectionFactory(
            address(erc721Beacon), address(erc1155Beacon), address(diamond)
        );

        // Set factory in diamond through both facets
        vm.startPrank(owner);
        EmblemVaultCoreFacet(address(diamond)).setVaultFactory(address(factory));
        EmblemVaultCollectionFacet(address(diamond)).setCollectionFactory(address(factory));
        vm.stopPrank();

        // Create test collection
        vm.prank(address(diamond));
        nftCollection = factory.createERC721Collection("Test NFT", "NFT");

        // Setup test environment
        vm.deal(user1, 1000 ether);
        paymentToken.mint(user1, 1000 ether);

        // Enable unvaulting
        vm.prank(owner);
        EmblemVaultUnvaultFacet(address(diamond)).setUnvaultingEnabled(true);
    }

    function testBatchMintGasAnalysis() public {
        uint256 basePrice = 0.1 ether;

        for (uint256 i = 0; i < batchSizes.length; i++) {
            uint256 batchSize = batchSizes[i];

            // Prepare batch parameters and get total price
            uint256 totalPrice = prepareBatchParameters(batchSize, basePrice, i);

            // Execute batch mint and measure gas
            uint256 gasBatchUsed = executeBatchMint(batchSize, totalPrice);

            // Log results
            emit log_named_uint(
                string(abi.encodePacked("Gas used for batch size ", vm.toString(batchSize))),
                gasBatchUsed
            );
            emit log_named_uint(
                string(
                    abi.encodePacked("Gas per operation for batch size ", vm.toString(batchSize))
                ),
                gasBatchUsed / batchSize
            );

            // Reset state for next test
            vm.roll(block.number + 1);
        }
    }

    // Helper function to prepare batch parameters
    function prepareBatchParameters(uint256 batchSize, uint256 basePrice, uint256 batchIndex)
        private
        returns (uint256 totalPrice)
    {
        // Initialize arrays in storage
        s_prices = new uint256[](batchSize);
        s_tokenIds = new uint256[](batchSize);
        s_nonces = new uint256[](batchSize);
        s_signatures = new bytes[](batchSize);
        s_serialNumbers = new uint256[][](batchSize);
        s_amounts = new uint256[](batchSize);
        s_nftAddresses = new address[](batchSize);

        // Fill arrays with test data
        totalPrice = 0;
        for (uint256 j = 0; j < batchSize; j++) {
            s_prices[j] = basePrice;
            s_tokenIds[j] = (batchIndex * 1000) + j + 1; // Unique token ID for each operation across all batch sizes
            s_nonces[j] = (batchIndex * 1000) + j + 1; // Unique nonce for each operation across all batch sizes
            s_amounts[j] = 1;
            s_signatures[j] = createSignature(
                nftCollection,
                address(0),
                basePrice,
                user1,
                s_tokenIds[j],
                s_nonces[j],
                s_amounts[j],
                witnessPrivateKey
            );
            s_serialNumbers[j] = new uint256[](0);
            s_nftAddresses[j] = nftCollection;
            totalPrice += basePrice;
        }

        return totalPrice;
    }

    // Helper function to execute batch mint and measure gas
    function executeBatchMint(uint256 batchSize, uint256 totalPrice)
        private
        returns (uint256 gasBatchUsed)
    {
        vm.startPrank(user1);
        uint256 gasBatchStart = gasleft();

        // Use timestamp 0 for signature verification in tests
        uint256 timestamp = 0;

        EmblemVaultMintFacet.BatchBuyParams memory params = EmblemVaultMintFacet.BatchBuyParams({
            nftAddresses: s_nftAddresses,
            payment: address(0),
            prices: s_prices,
            to: user1,
            tokenIds: s_tokenIds,
            nonces: s_nonces,
            signatures: s_signatures,
            serialNumbers: s_serialNumbers,
            amounts: s_amounts,
            timestamp: timestamp
        });

        EmblemVaultMintFacet(address(diamond)).batchBuyWithSignedPrice{value: totalPrice}(params);

        gasBatchUsed = gasBatchStart - gasleft();
        vm.stopPrank();

        return gasBatchUsed;
    }

    // Helper function to create signature
    function createSignature(
        address _nftAddress,
        address _payment,
        uint256 _price,
        address _to,
        uint256 _tokenId,
        uint256 _nonce,
        uint256 _amount,
        uint256 _privateKey
    ) internal view returns (bytes memory) {
        // Create empty array for serialNumbers
        uint256[] memory serialNumbers = new uint256[](0);

        // Use LibSignature to generate hash
        bytes32 hash = LibSignature.getStandardSignatureHash(
            _nftAddress,
            _payment,
            _price,
            _to,
            _tokenId,
            _nonce,
            _amount,
            serialNumbers,
            0, // timestamp
            block.chainid
        );

        // Sign with Ethereum prefix
        bytes32 prefixedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_privateKey, prefixedHash);
        return abi.encodePacked(r, s, v);
    }

    // Helper function to get function selectors for each facet
    function getFacetSelectors(string memory facetName)
        internal
        pure
        returns (bytes4[] memory selectors)
    {
        if (keccak256(bytes(facetName)) == keccak256(bytes("DiamondLoupeFacet"))) {
            selectors = new bytes4[](5);
            selectors[0] = DiamondLoupeFacet.facets.selector;
            selectors[1] = DiamondLoupeFacet.facetFunctionSelectors.selector;
            selectors[2] = DiamondLoupeFacet.facetAddresses.selector;
            selectors[3] = DiamondLoupeFacet.getFacetAddress.selector;
            selectors[4] = DiamondLoupeFacet.supportsInterface.selector;
        } else if (keccak256(bytes(facetName)) == keccak256(bytes("OwnershipFacet"))) {
            selectors = new bytes4[](2);
            selectors[0] = OwnershipFacet.transferOwnership.selector;
            selectors[1] = OwnershipFacet.owner.selector;
        } else if (keccak256(bytes(facetName)) == keccak256(bytes("VaultCoreFacet"))) {
            selectors = new bytes4[](12);
            selectors[0] = EmblemVaultCoreFacet.lockVault.selector;
            selectors[1] = EmblemVaultCoreFacet.unlockVault.selector;
            selectors[2] = EmblemVaultCoreFacet.isVaultLocked.selector;
            selectors[3] = EmblemVaultCoreFacet.addWitness.selector;
            selectors[4] = EmblemVaultCoreFacet.removeWitness.selector;
            selectors[5] = EmblemVaultCoreFacet.setRecipientAddress.selector;
            selectors[6] = EmblemVaultCoreFacet.setMetadataBaseUri.selector;
            selectors[7] = EmblemVaultCoreFacet.isWitness.selector;
            selectors[8] = EmblemVaultCoreFacet.getWitnessCount.selector;
            selectors[9] = EmblemVaultCoreFacet.getCoreVersion.selector;
            selectors[10] = EmblemVaultCoreFacet.setVaultFactory.selector;
            selectors[11] = EmblemVaultCoreFacet.getVaultFactory.selector;
        } else if (keccak256(bytes(facetName)) == keccak256(bytes("UnvaultFacet"))) {
            selectors = new bytes4[](8);
            selectors[0] = EmblemVaultUnvaultFacet.unvault.selector;
            selectors[1] = EmblemVaultUnvaultFacet.unvaultWithSignedPrice.selector;
            selectors[2] = EmblemVaultUnvaultFacet.setUnvaultingEnabled.selector;
            selectors[3] = EmblemVaultUnvaultFacet.setBurnAddress.selector;
            selectors[4] = EmblemVaultUnvaultFacet.isTokenUnvaulted.selector;
            selectors[5] = EmblemVaultUnvaultFacet.getTokenUnvaulter.selector;
            selectors[6] = EmblemVaultUnvaultFacet.getCollectionUnvaultCount.selector;
            selectors[7] = EmblemVaultUnvaultFacet.getUnvaultVersion.selector;
        } else if (keccak256(bytes(facetName)) == keccak256(bytes("MintFacet"))) {
            selectors = new bytes4[](3);
            selectors[0] = EmblemVaultMintFacet.buyWithSignedPrice.selector;
            selectors[1] = EmblemVaultMintFacet.batchBuyWithSignedPrice.selector;
            selectors[2] = EmblemVaultMintFacet.getMintVersion.selector;
        } else if (keccak256(bytes(facetName)) == keccak256(bytes("CollectionFacet"))) {
            selectors = new bytes4[](13);
            selectors[0] = EmblemVaultCollectionFacet.setCollectionFactory.selector;
            selectors[1] = EmblemVaultCollectionFacet.createVaultCollection.selector;
            selectors[2] = EmblemVaultCollectionFacet.upgradeCollectionImplementation.selector;
            selectors[3] = EmblemVaultCollectionFacet.getCollectionImplementation.selector;
            selectors[4] = EmblemVaultCollectionFacet.getCollectionBeacon.selector;
            selectors[5] = EmblemVaultCollectionFacet.isCollection.selector;
            selectors[6] = EmblemVaultCollectionFacet.getCollectionFactory.selector;
            selectors[7] = EmblemVaultCollectionFacet.setCollectionBaseURI.selector;
            selectors[8] = EmblemVaultCollectionFacet.setCollectionURI.selector;
            selectors[9] = EmblemVaultCollectionFacet.getCollectionVersion.selector;
            selectors[10] = EmblemVaultCollectionFacet.setCollectionOwner.selector;
            selectors[11] = EmblemVaultCollectionFacet.getCollectionOwner.selector;
            selectors[12] = EmblemVaultCollectionFacet.getCollectionType.selector;
        } else if (keccak256(bytes(facetName)) == keccak256(bytes("InitFacet"))) {
            selectors = new bytes4[](6);
            selectors[0] = EmblemVaultInitFacet.initialize.selector;
            selectors[1] = EmblemVaultInitFacet.isInitialized.selector;
            selectors[2] = EmblemVaultInitFacet.getInterfaceIds.selector;
            selectors[3] = EmblemVaultInitFacet.getConfiguration.selector;
            selectors[4] = EmblemVaultInitFacet.getInitializationDetails.selector;
            selectors[5] = EmblemVaultInitFacet.getInitVersion.selector;
        }
    }
}
