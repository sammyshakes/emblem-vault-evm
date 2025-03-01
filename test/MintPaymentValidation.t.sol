// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./DiamondVault.t.sol";

contract MintPaymentValidationTest is DiamondVaultTest {
    function testCannotOverpayForSingleMint() public {
        // Create signature for minting
        uint256[] memory serialNumbers = new uint256[](0);
        bytes memory signature = createSignature(
            nftCollection,
            address(0), // ETH payment
            1 ether,
            user1,
            2, // tokenId
            2, // nonce
            1, // amount
            witnessPrivateKey,
            serialNumbers,
            0 // timestamp
        );

        // Try to mint with more ETH than required
        vm.startPrank(user1);
        vm.expectRevert(
            abi.encodeWithSelector(LibErrors.IncorrectPayment.selector, 2 ether, 1 ether)
        );
        // Use timestamp 0 for signature verification in tests
        uint256 timestamp = 0;
        EmblemVaultMintFacet(address(diamond)).buyWithSignedPrice{value: 2 ether}(
            nftCollection, address(0), 1 ether, user1, 2, 2, signature, serialNumbers, 1, timestamp
        );
        vm.stopPrank();
    }

    function testCannotOverpayForBatchMint() public {
        // Setup batch parameters
        uint256[] memory prices = new uint256[](2);
        prices[0] = 1 ether;
        prices[1] = 1 ether;

        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 2;
        tokenIds[1] = 3;

        uint256[] memory nonces = new uint256[](2);
        nonces[0] = 2;
        nonces[1] = 3;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 1;

        bytes[] memory signatures = new bytes[](2);
        uint256[][] memory serialNumbers = new uint256[][](2);
        serialNumbers[0] = new uint256[](0);
        serialNumbers[1] = new uint256[](0);

        // Create signatures for each token
        for (uint256 i = 0; i < 2; i++) {
            signatures[i] = createSignature(
                nftCollection,
                address(0),
                prices[i],
                user1,
                tokenIds[i],
                nonces[i],
                amounts[i],
                witnessPrivateKey,
                serialNumbers[i],
                0 // timestamp
            );
        }

        // Create batch params
        // Create an array with a single NFT address repeated for each token
        address[] memory nftAddresses = new address[](2);
        for (uint256 i = 0; i < 2; i++) {
            nftAddresses[i] = nftCollection;
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

        // Try to mint with more ETH than required (total price is 2 ether)
        vm.startPrank(user1);
        vm.expectRevert(
            abi.encodeWithSelector(LibErrors.IncorrectPayment.selector, 3 ether, 2 ether)
        );
        EmblemVaultMintFacet(address(diamond)).batchBuyWithSignedPrice{value: 3 ether}(params);
        vm.stopPrank();
    }

    function testExactPaymentSucceedsForSingleMint() public {
        // Create signature for minting
        uint256[] memory serialNumbers = new uint256[](0);
        bytes memory signature = createSignature(
            nftCollection,
            address(0), // ETH payment
            1 ether,
            user1,
            2, // tokenId
            2, // nonce
            1, // amount
            witnessPrivateKey,
            serialNumbers,
            0 // timestamp
        );

        // Mint with exact ETH amount
        vm.startPrank(user1);
        // Use timestamp 0 for signature verification in tests
        uint256 timestamp = 0;
        EmblemVaultMintFacet(address(diamond)).buyWithSignedPrice{value: 1 ether}(
            nftCollection, address(0), 1 ether, user1, 2, 2, signature, serialNumbers, 1, timestamp
        );
        vm.stopPrank();

        // Verify the mint was successful by checking ownership
        assertEq(IERC721AVault(nftCollection).ownerOf(2), user1);
    }

    function testExactPaymentSucceedsForBatchMint() public {
        // Setup batch parameters
        uint256[] memory prices = new uint256[](2);
        prices[0] = 1 ether;
        prices[1] = 1 ether;

        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 3;
        tokenIds[1] = 4;

        uint256[] memory nonces = new uint256[](2);
        nonces[0] = 3;
        nonces[1] = 4;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 1;

        bytes[] memory signatures = new bytes[](2);
        uint256[][] memory serialNumbers = new uint256[][](2);
        serialNumbers[0] = new uint256[](0);
        serialNumbers[1] = new uint256[](0);

        // Create signatures for each token
        for (uint256 i = 0; i < 2; i++) {
            signatures[i] = createSignature(
                nftCollection,
                address(0),
                prices[i],
                user1,
                tokenIds[i],
                nonces[i],
                amounts[i],
                witnessPrivateKey,
                serialNumbers[i],
                0 // timestamp
            );
        }

        // Create batch params
        // Create an array with a single NFT address repeated for each token
        address[] memory nftAddresses = new address[](2);
        for (uint256 i = 0; i < 2; i++) {
            nftAddresses[i] = nftCollection;
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

        // Mint with exact ETH amount
        vm.startPrank(user1);
        EmblemVaultMintFacet(address(diamond)).batchBuyWithSignedPrice{value: 2 ether}(params);
        vm.stopPrank();

        // Verify the mints were successful by checking ownership
        assertEq(IERC721AVault(nftCollection).ownerOf(2), user1);
        assertEq(IERC721AVault(nftCollection).ownerOf(3), user1);
    }
}
