// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {EmblemVaultDiamond} from "../src/EmblemVaultDiamond.sol";
import {IDiamondCut} from "../src/interfaces/IDiamondCut.sol";
import {DiamondCutFacet} from "../src/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../src/facets/DiamondLoupeFacet.sol";
import {OwnershipFacet} from "../src/facets/OwnershipFacet.sol";
import {EmblemVaultCoreFacet} from "../src/facets/EmblemVaultCoreFacet.sol";
import {EmblemVaultClaimFacet} from "../src/facets/EmblemVaultClaimFacet.sol";
import {EmblemVaultMintFacet} from "../src/facets/EmblemVaultMintFacet.sol";
import {EmblemVaultCallbackFacet} from "../src/facets/EmblemVaultCallbackFacet.sol";
import {EmblemVaultInitFacet} from "../src/facets/EmblemVaultInitFacet.sol";
import {IHandlerCallback} from "../src/interfaces/IHandlerCallback.sol";
import "./mocks/MockERC20.sol";
import "./mocks/MockERC721.sol";
import "./mocks/MockERC1155.sol";
import "./mocks/MockClaimer.sol";

contract MockQuoteContract {
    function quoteExternalPrice(address, uint256 price) external pure returns (uint256) {
        return price * 2; // Simple mock that doubles the price
    }
}

contract DiamondVaultTest is Test {
    EmblemVaultDiamond diamond;
    DiamondCutFacet diamondCutFacet;
    DiamondLoupeFacet diamondLoupeFacet;
    OwnershipFacet ownershipFacet;
    EmblemVaultCoreFacet vaultCoreFacet;
    EmblemVaultClaimFacet claimFacet;
    EmblemVaultMintFacet mintFacet;
    EmblemVaultCallbackFacet callbackFacet;
    EmblemVaultInitFacet initFacet;

    // Mock contracts
    MockERC20 paymentToken;
    MockERC721 nftToken;
    MockERC1155 multiToken;
    MockClaimer claimer;
    MockQuoteContract quoteContract;

    // Test addresses
    address owner = address(this);
    address user1 = address(0x1);
    address user2 = address(0x2);
    // Use a proper private key for witness
    uint256 constant witnessPrivateKey = 0x1234567890123456789012345678901234567890123456789012345678901234;
    address witness;

    address tokenHolder = address(0x4);

    // Allow contract to receive ETH
    receive() external payable {}
    fallback() external payable {}

    function setUp() public {
        // Derive witness address from private key
        witness = vm.addr(witnessPrivateKey);

        // Deploy mock contracts
        paymentToken = new MockERC20("Payment Token", "PAY");
        nftToken = new MockERC721("Test NFT", "NFT");
        multiToken = new MockERC1155("https://token.uri/");
        claimer = new MockClaimer();
        quoteContract = new MockQuoteContract();

        // Deploy facets
        diamondCutFacet = new DiamondCutFacet();
        diamondLoupeFacet = new DiamondLoupeFacet();
        ownershipFacet = new OwnershipFacet();
        vaultCoreFacet = new EmblemVaultCoreFacet();
        claimFacet = new EmblemVaultClaimFacet();
        mintFacet = new EmblemVaultMintFacet();
        callbackFacet = new EmblemVaultCallbackFacet();
        initFacet = new EmblemVaultInitFacet();

        // Deploy Diamond
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

        // ClaimFacet
        bytes4[] memory claimSelectors = new bytes4[](2);
        claimSelectors[0] = EmblemVaultClaimFacet.claim.selector;
        claimSelectors[1] = EmblemVaultClaimFacet.claimWithSignedPrice.selector;
        cut[3] = IDiamondCut.FacetCut({
            facetAddress: address(claimFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: claimSelectors
        });

        // MintFacet
        bytes4[] memory mintSelectors = new bytes4[](2);
        mintSelectors[0] = EmblemVaultMintFacet.buyWithSignedPrice.selector;
        mintSelectors[1] = EmblemVaultMintFacet.buyWithQuote.selector;
        cut[4] = IDiamondCut.FacetCut({
            facetAddress: address(mintFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: mintSelectors
        });

        // CallbackFacet
        bytes4[] memory callbackSelectors = new bytes4[](6);
        callbackSelectors[0] = EmblemVaultCallbackFacet.executeCallbacks.selector;
        callbackSelectors[1] = EmblemVaultCallbackFacet.registerCallback.selector;
        callbackSelectors[2] = EmblemVaultCallbackFacet.registerWildcardCallback.selector;
        callbackSelectors[3] = EmblemVaultCallbackFacet.hasCallback.selector;
        callbackSelectors[4] = EmblemVaultCallbackFacet.unregisterCallback.selector;
        callbackSelectors[5] = EmblemVaultCallbackFacet.toggleAllowCallbacks.selector;
        cut[5] = IDiamondCut.FacetCut({
            facetAddress: address(callbackFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: callbackSelectors
        });

        // InitializationFacet
        bytes4[] memory initSelectors = new bytes4[](4);
        initSelectors[0] = EmblemVaultInitFacet.initialize.selector;
        initSelectors[1] = EmblemVaultInitFacet.isInitialized.selector;
        initSelectors[2] = EmblemVaultInitFacet.getInterfaceIds.selector;
        initSelectors[3] = EmblemVaultInitFacet.getConfiguration.selector;
        cut[6] = IDiamondCut.FacetCut({
            facetAddress: address(initFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: initSelectors
        });

        // Add facets to diamond
        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");

        // Initialize the vault
        EmblemVaultInitFacet(address(diamond)).initialize(owner);

        // Setup test environment
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
        paymentToken.mint(user1, 1000 ether);
        paymentToken.mint(user2, 1000 ether);

        // Add witness
        EmblemVaultCoreFacet(address(diamond)).addWitness(witness);

        // Setup mock tokens
        nftToken.mint(tokenHolder, 1, "test uri", "");
        multiToken.mint(tokenHolder, 1, 10);

        // Register mock contracts
        EmblemVaultCoreFacet(address(diamond)).registerContract(address(nftToken), 1);
        EmblemVaultCoreFacet(address(diamond)).registerContract(address(multiToken), 2);
        EmblemVaultCoreFacet(address(diamond)).registerContract(address(claimer), 6);
        EmblemVaultCoreFacet(address(diamond)).setQuoteContract(address(quoteContract));

        // Set recipient address to this contract for testing
        EmblemVaultCoreFacet(address(diamond)).setRecipientAddress(address(this));
    }

    function testInitialization() public view {
        assertTrue(EmblemVaultInitFacet(address(diamond)).isInitialized());
        (string memory baseUri,,,,) = EmblemVaultInitFacet(address(diamond)).getConfiguration();
        assertEq(baseUri, "https://v2.emblemvault.io/meta/");
    }

    function testOwnership() public view {
        assertEq(OwnershipFacet(address(diamond)).owner(), owner);
    }

    function testVaultLocking() public {
        address mockNft = address(nftToken);
        uint256 tokenId = 1;

        // Lock vault
        EmblemVaultCoreFacet(address(diamond)).lockVault(mockNft, tokenId);
        assertTrue(EmblemVaultCoreFacet(address(diamond)).isVaultLocked(mockNft, tokenId));

        // Unlock vault
        EmblemVaultCoreFacet(address(diamond)).unlockVault(mockNft, tokenId);
        assertFalse(EmblemVaultCoreFacet(address(diamond)).isVaultLocked(mockNft, tokenId));
    }

    function testFailLockUnregisteredContract() public {
        address mockNft = address(0x999); // Unregistered contract
        uint256 tokenId = 1;

        EmblemVaultCoreFacet(address(diamond)).lockVault(mockNft, tokenId);
    }

    function testWitnessManagement() public {
        address newWitness = address(0x456);

        // Add witness
        EmblemVaultCoreFacet(address(diamond)).addWitness(newWitness);

        // Remove witness
        EmblemVaultCoreFacet(address(diamond)).removeWitness(newWitness);
    }

    function testContractRegistration() public {
        address mockContract = address(0x789);
        uint256 contractType = 1;

        // Register contract
        EmblemVaultCoreFacet(address(diamond)).registerContract(mockContract, contractType);
        assertTrue(EmblemVaultCoreFacet(address(diamond)).isRegistered(mockContract, contractType));

        // Get registered contracts
        address[] memory contracts = EmblemVaultCoreFacet(address(diamond)).getRegisteredContractsOfType(contractType);
        assertEq(contracts.length, 2); // nftToken + mockContract
        assertEq(contracts[1], mockContract);
    }

    function testBasicClaim() public {
        // Setup
        address mockNft = address(nftToken);
        uint256 tokenId = 1;

        // First approve and transfer to diamond from tokenHolder
        vm.startPrank(tokenHolder);
        nftToken.approve(address(diamond), tokenId);
        nftToken.transferFrom(tokenHolder, address(diamond), tokenId);
        vm.stopPrank();

        // Then claim from user1
        vm.startPrank(user1);
        EmblemVaultClaimFacet(address(diamond)).claim(mockNft, tokenId);
        vm.stopPrank();

        // Verify token was burned
        vm.expectRevert("ERC721: invalid token ID");
        nftToken.ownerOf(tokenId);

        // Verify claim was registered
        bytes32[] memory proof;
        assertTrue(claimer.isClaimed(mockNft, tokenId, proof));
    }

    function testClaimWithSignedPrice() public {
        // Setup
        address mockNft = address(nftToken);
        uint256 tokenId = 1;
        uint256 price = 1 ether;
        uint256 nonce = 1;

        // First approve and transfer to diamond from tokenHolder
        vm.startPrank(tokenHolder);
        nftToken.approve(address(diamond), tokenId);
        nftToken.transferFrom(tokenHolder, address(diamond), tokenId);
        vm.stopPrank();

        // Create signature from witness
        bytes memory signature = createSignature(
            mockNft,
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
            mockNft, tokenId, nonce, address(0), price, signature
        );
        vm.stopPrank();

        // Verify token was burned
        vm.expectRevert("ERC721: invalid token ID");
        nftToken.ownerOf(tokenId);

        // Verify claim was registered
        bytes32[] memory proof;
        assertTrue(claimer.isClaimed(mockNft, tokenId, proof));
    }

    function testClaimWithSignedPriceERC20() public {
        // Setup
        address mockNft = address(nftToken);
        uint256 tokenId = 1;
        uint256 price = 100 ether;
        uint256 nonce = 1;

        // First approve and transfer to diamond from tokenHolder
        vm.startPrank(tokenHolder);
        nftToken.approve(address(diamond), tokenId);
        nftToken.transferFrom(tokenHolder, address(diamond), tokenId);
        vm.stopPrank();

        // Create signature from witness
        bytes memory signature =
            createSignature(mockNft, address(paymentToken), price, user1, tokenId, nonce, 1, witnessPrivateKey);

        // Approve payment token
        vm.startPrank(user1);
        paymentToken.approve(address(diamond), price);

        // Claim with signed price
        EmblemVaultClaimFacet(address(diamond)).claimWithSignedPrice(
            mockNft, tokenId, nonce, address(paymentToken), price, signature
        );
        vm.stopPrank();

        // Verify token was burned
        vm.expectRevert("ERC721: invalid token ID");
        nftToken.ownerOf(tokenId);

        // Verify claim was registered
        bytes32[] memory proof;
        assertTrue(claimer.isClaimed(mockNft, tokenId, proof));
    }

    function testBuyWithSignedPrice() public {
        // Setup
        address mockNft = address(nftToken);
        uint256 tokenId = 2;
        uint256 price = 1 ether;
        uint256 nonce = 1;
        bytes memory serialNumber = new bytes(0);

        // Create signature from witness
        bytes memory signature = createSignature(
            mockNft,
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
            mockNft, address(0), price, user1, tokenId, nonce, signature, serialNumber, 1
        );
        vm.stopPrank();

        // Verify token was minted to user1
        assertEq(nftToken.ownerOf(tokenId), user1);
    }

    function testBuyWithSignedPriceERC20() public {
        // Setup
        address mockNft = address(nftToken);
        uint256 tokenId = 2;
        uint256 price = 100 ether;
        uint256 nonce = 1;
        bytes memory serialNumber = new bytes(0);

        // Create signature from witness
        bytes memory signature =
            createSignature(mockNft, address(paymentToken), price, user1, tokenId, nonce, 1, witnessPrivateKey);

        // Approve payment token
        vm.startPrank(user1);
        paymentToken.approve(address(diamond), price);

        // Buy with signed price
        EmblemVaultMintFacet(address(diamond)).buyWithSignedPrice(
            mockNft, address(paymentToken), price, user1, tokenId, nonce, signature, serialNumber, 1
        );
        vm.stopPrank();

        // Verify token was minted to user1
        assertEq(nftToken.ownerOf(tokenId), user1);
    }

    function testBuyWithQuote() public {
        // Setup
        address mockNft = address(nftToken);
        uint256 tokenId = 2;
        uint256 basePrice = 1 ether;
        uint256 quotedPrice = 2 ether; // MockQuoteContract doubles the price
        uint256 nonce = 1;
        bytes memory serialNumber = new bytes(0);

        // Create signature from witness using the quote signature format
        bytes memory signature = createSignatureQuote(mockNft, basePrice, user1, tokenId, nonce, 1, witnessPrivateKey);

        // Log the hash and signature components for debugging
        bytes32 hash = keccak256(abi.encodePacked(mockNft, basePrice, user1, tokenId, nonce, uint256(1)));
        bytes32 prefixedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(witnessPrivateKey, prefixedHash);
        console.log("Expected signer:", witness);
        console.log("Recovered signer:", ecrecover(prefixedHash, v, r, s));

        // Buy with quote from user1
        vm.startPrank(user1);
        EmblemVaultMintFacet(address(diamond)).buyWithQuote{value: quotedPrice}(
            mockNft, basePrice, user1, tokenId, nonce, signature, serialNumber, 1
        );
        vm.stopPrank();

        // Verify token was minted to user1
        assertEq(nftToken.ownerOf(tokenId), user1);
    }

    function testClaimWithSignedPriceLockedVault() public {
        // Setup
        address mockNft = address(nftToken);
        uint256 tokenId = 1;
        uint256 price = 1 ether;
        uint256 nonce = 1;

        // First approve and transfer to diamond from tokenHolder
        vm.startPrank(tokenHolder);
        nftToken.approve(address(diamond), tokenId);
        nftToken.transferFrom(tokenHolder, address(diamond), tokenId);
        vm.stopPrank();

        // Lock the vault
        EmblemVaultCoreFacet(address(diamond)).lockVault(mockNft, tokenId);

        // Create signature from witness with locked acknowledgement
        bytes memory signature =
            createSignatureWithLock(mockNft, address(0), price, user1, tokenId, nonce, 1, witnessPrivateKey);

        // Claim with signed price from user1
        vm.startPrank(user1);
        EmblemVaultClaimFacet(address(diamond)).claimWithSignedPrice{value: price}(
            mockNft, tokenId, nonce, address(0), price, signature
        );
        vm.stopPrank();

        // Verify token was burned
        vm.expectRevert("ERC721: invalid token ID");
        nftToken.ownerOf(tokenId);

        // Verify claim was registered
        bytes32[] memory proof;
        assertTrue(claimer.isClaimed(mockNft, tokenId, proof));
    }

    function testFailClaimWithInvalidSignature() public {
        // Setup
        address mockNft = address(nftToken);
        uint256 tokenId = 1;
        uint256 price = 1 ether;
        uint256 nonce = 1;

        // First approve and transfer to diamond from tokenHolder
        vm.startPrank(tokenHolder);
        nftToken.approve(address(diamond), tokenId);
        nftToken.transferFrom(tokenHolder, address(diamond), tokenId);
        vm.stopPrank();

        // Create signature with wrong private key
        bytes memory signature = createSignature(
            mockNft,
            address(0),
            price,
            user1,
            tokenId,
            nonce,
            1,
            0xBAD // Wrong private key
        );

        // Attempt to claim with invalid signature
        vm.startPrank(user1);
        EmblemVaultClaimFacet(address(diamond)).claimWithSignedPrice{value: price}(
            mockNft, tokenId, nonce, address(0), price, signature
        );
        vm.stopPrank();
    }

    function testFailClaimWithWrongPaymentAmount() public {
        // Setup
        address mockNft = address(nftToken);
        uint256 tokenId = 1;
        uint256 price = 1 ether;
        uint256 nonce = 1;

        // First approve and transfer to diamond from tokenHolder
        vm.startPrank(tokenHolder);
        nftToken.approve(address(diamond), tokenId);
        nftToken.transferFrom(tokenHolder, address(diamond), tokenId);
        vm.stopPrank();

        // Create signature from witness
        bytes memory signature =
            createSignature(mockNft, address(0), price, user1, tokenId, nonce, 1, witnessPrivateKey);

        // Attempt to claim with wrong payment amount
        vm.startPrank(user1);
        EmblemVaultClaimFacet(address(diamond)).claimWithSignedPrice{value: price / 2}( // Wrong amount
        mockNft, tokenId, nonce, address(0), price, signature);
        vm.stopPrank();
    }

    function testBasicCallback() public {
        address mockNft = address(nftToken);
        uint256 tokenId = 1;
        bytes4 functionSelector = bytes4(keccak256("onMint(address,uint256)"));

        // Register callback
        EmblemVaultCallbackFacet(address(diamond)).registerCallback(
            mockNft, address(this), tokenId, IHandlerCallback.CallbackType.MINT, functionSelector, false
        );

        // Verify callback registration
        assertTrue(
            EmblemVaultCallbackFacet(address(diamond)).hasCallback(
                mockNft, address(this), tokenId, IHandlerCallback.CallbackType.MINT
            )
        );

        // Unregister callback
        EmblemVaultCallbackFacet(address(diamond)).unregisterCallback(
            mockNft, address(this), tokenId, IHandlerCallback.CallbackType.MINT, 0
        );

        // Verify callback unregistration
        assertFalse(
            EmblemVaultCallbackFacet(address(diamond)).hasCallback(
                mockNft, address(this), tokenId, IHandlerCallback.CallbackType.MINT
            )
        );
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
            DiamondLoupeFacet(address(diamond)).getFacetAddress(OwnershipFacet.owner.selector), address(ownershipFacet)
        );
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
        bytes32 hash = keccak256(abi.encodePacked(_nftAddress, _payment, _price, _to, _tokenId, _nonce, _amount));
        console.log("Test hash inputs:");
        console.log("nftAddress:", _nftAddress);
        console.log("payment:", _payment);
        console.log("price:", _price);
        console.log("to:", _to);
        console.log("tokenId:", _tokenId);
        console.log("nonce:", _nonce);
        console.log("amount:", _amount);
        console.log("Test hash:", uint256(hash));
        bytes32 prefixedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_privateKey, prefixedHash);
        console.log("Test recovered signer:", ecrecover(prefixedHash, v, r, s));
        return abi.encodePacked(r, s, v);
    }

    // Helper function to create signature for quotes - matches contract's format
    function createSignatureQuote(
        address _nftAddress,
        uint256 _price,
        address _to,
        uint256 _tokenId,
        uint256 _nonce,
        uint256 _amount,
        uint256 _privateKey
    ) internal pure returns (bytes memory) {
        // Match the exact format used in the contract's getAddressFromSignatureQuote
        bytes32 hash = keccak256(abi.encodePacked(_nftAddress, _price, _to, _tokenId, _nonce, _amount));
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
        // Match the exact format used in the contract's getAddressFromSignatureLocked
        bytes32 hash = keccak256(
            abi.encodePacked(
                _nftAddress,
                _payment,
                _price,
                _to,
                _tokenId,
                _nonce,
                _amount,
                bytes1(0x01) // true as bytes1
            )
        );
        bytes32 prefixedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_privateKey, prefixedHash);
        return abi.encodePacked(r, s, v);
    }
}
