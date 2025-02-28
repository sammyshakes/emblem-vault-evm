// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./DiamondVault.t.sol";
import {IERC721} from "../src/interfaces/IERC721.sol";
import {IERC1155} from "../src/interfaces/IERC1155.sol";

contract BatchMixedCollectionMintTest is DiamondVaultTest {
    // Additional collections
    address erc1155Collection;

    function setUp() public override {
        // Call the parent setUp first
        super.setUp();

        // Create an ERC1155 collection
        vm.prank(address(diamond));
        erc1155Collection = factory.createERC1155Collection("https://test.uri/");
    }

    function testBatchMintMixedCollections() public {
        vm.startPrank(user1);
        vm.deal(user1, 10 ether);

        // Create parameters for batch minting
        // We'll mint 2 tokens: 1 ERC721 and 1 ERC1155
        uint256 batchSize = 2;

        address[] memory nftAddresses = new address[](batchSize);
        nftAddresses[0] = nftCollection; // ERC721 collection from parent test
        nftAddresses[1] = erc1155Collection;

        uint256[] memory tokenIds = new uint256[](batchSize);
        tokenIds[0] = 2; // ERC721 token ID (ID 1 is already minted in parent setUp)
        tokenIds[1] = 1; // ERC1155 token ID

        uint256[] memory amounts = new uint256[](batchSize);
        amounts[0] = 1; // ERC721 always has amount 1
        amounts[1] = 5; // ERC1155 can have any amount

        uint256[] memory prices = new uint256[](batchSize);
        prices[0] = 0.1 ether;
        prices[1] = 0.1 ether;

        uint256[] memory nonces = new uint256[](batchSize);
        nonces[0] = 2; // Nonce 1 is already used in parent setUp
        nonces[1] = 3;

        // Create serial numbers for ERC1155
        uint256[][] memory serialNumbers = new uint256[][](batchSize);
        serialNumbers[0] = new uint256[](0); // Empty for ERC721
        serialNumbers[1] = new uint256[](5); // 5 serial numbers for ERC1155
        serialNumbers[1][0] = 1;
        serialNumbers[1][1] = 2;
        serialNumbers[1][2] = 3;
        serialNumbers[1][3] = 4;
        serialNumbers[1][4] = 5;

        // Create signatures
        bytes[] memory signatures = new bytes[](batchSize);

        // Sign for ERC721 Collection
        signatures[0] = createSignature(
            nftAddresses[0],
            address(0), // ETH payment
            prices[0],
            user1,
            tokenIds[0],
            nonces[0],
            amounts[0],
            witnessPrivateKey,
            serialNumbers[0]
        );

        // Sign for ERC1155 Collection
        signatures[1] = createSignature(
            nftAddresses[1],
            address(0), // ETH payment
            prices[1],
            user1,
            tokenIds[1],
            nonces[1],
            amounts[1],
            witnessPrivateKey,
            serialNumbers[1]
        );

        // Create batch buy params
        EmblemVaultMintFacet.BatchBuyParams memory params = EmblemVaultMintFacet.BatchBuyParams({
            nftAddresses: nftAddresses,
            payment: address(0), // ETH payment
            prices: prices,
            to: user1,
            tokenIds: tokenIds,
            nonces: nonces,
            signatures: signatures,
            serialNumbers: serialNumbers,
            amounts: amounts
        });

        // Execute batch mint
        uint256 totalPrice = prices[0] + prices[1];
        EmblemVaultMintFacet(address(diamond)).batchBuyWithSignedPrice{value: totalPrice}(params);

        // Verify ERC721 token ownership
        assertEq(IERC721(nftCollection).ownerOf(tokenIds[0]), user1);

        // Verify ERC1155 token balance
        assertEq(IERC1155(erc1155Collection).balanceOf(user1, tokenIds[1]), amounts[1]);

        vm.stopPrank();
    }
}
