// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/console.sol";
import {EmblemVaultMintFacet} from "../../src/facets/EmblemVaultMintFacet.sol";
import {EmblemVaultClaimFacet} from "../../src/facets/EmblemVaultClaimFacet.sol";
import {LibEmblemVaultStorage} from "../../src/libraries/LibEmblemVaultStorage.sol";

contract ReentrantReceiver {
    EmblemVaultMintFacet public mintFacet;
    EmblemVaultClaimFacet public claimFacet;
    bytes public signature;
    uint256 public reentryCount;

    constructor(address _diamond) {
        mintFacet = EmblemVaultMintFacet(_diamond);
        claimFacet = EmblemVaultClaimFacet(_diamond);
    }

    // Track which operation to reenter with
    bool public useClaimReentrancy;
    uint256 public storedTokenId;
    uint256 public storedNonce;
    uint256 public storedPrice;
    address public storedNftAddress;

    function setSignature(bytes memory _signature) external {
        signature = _signature;
    }

    function setReentryParams(
        bool _useClaimReentrancy,
        address _nftAddress,
        uint256 _tokenId,
        uint256 _nonce,
        uint256 _price
    ) public {
        useClaimReentrancy = _useClaimReentrancy;
        storedNftAddress = _nftAddress;
        storedTokenId = _tokenId;
        storedNonce = _nonce;
        storedPrice = _price;
    }

    function attemptReentrantMint(address nftAddress, uint256 price, uint256 tokenId, uint256 nonce)
        external
        payable
    {
        console.log("ReentrantReceiver: Starting reentrant mint attempt");
        setReentryParams(false, nftAddress, tokenId, nonce, price);
        console.log("ReentrantReceiver: Params set, calling buyWithSignedPrice");
        mintFacet.buyWithSignedPrice{value: msg.value}(
            nftAddress, address(0), price, address(this), tokenId, nonce, signature, "", 1
        );
        console.log("ReentrantReceiver: buyWithSignedPrice completed");
    }

    function attemptReentrantClaim(
        address nftAddress,
        uint256 tokenId,
        uint256 nonce,
        uint256 price
    ) external payable {
        console.log("ReentrantReceiver: Starting reentrant claim attempt");
        setReentryParams(true, nftAddress, tokenId, nonce, price);
        console.log("ReentrantReceiver: Params set, calling claimWithSignedPrice");
        claimFacet.claimWithSignedPrice{value: msg.value}(
            nftAddress, tokenId, nonce, address(0), price, signature
        );
        console.log("ReentrantReceiver: claimWithSignedPrice completed");
    }

    receive() external payable {
        // Only attempt reentrancy once
        if (reentryCount == 0) {
            console.log("ReentrantReceiver: Attempting reentrant call");
            console.log("Current reentryCount:", reentryCount);

            // Check reentrancy guard before reentrant call
            LibEmblemVaultStorage.ReentrancyGuard storage guard =
                LibEmblemVaultStorage.reentrancyGuard();
            console.log("ReentrantReceiver: Guard value before reentrant call:", guard.entered);

            reentryCount++;

            // Try to reenter with same parameters during ETH transfer
            if (useClaimReentrancy) {
                console.log("ReentrantReceiver: Attempting reentrant claim");
                // Try to claim with same nonce before it's marked as used
                claimFacet.claimWithSignedPrice{value: msg.value}(
                    storedNftAddress, storedTokenId, storedNonce, address(0), storedPrice, signature
                );
            } else {
                console.log("ReentrantReceiver: Attempting reentrant mint");
                // Try to mint with same nonce before it's marked as used
                mintFacet.buyWithSignedPrice{value: msg.value}(
                    storedNftAddress,
                    address(0),
                    storedPrice,
                    address(this),
                    storedTokenId,
                    storedNonce,
                    signature,
                    "",
                    1
                );
            }

            // Check reentrancy guard after reentrant call
            console.log("ReentrantReceiver: Guard value after reentrant call:", guard.entered);
            console.log("ReentrantReceiver: Reentrant call completed");
        } else {
            console.log("ReentrantReceiver: Skipping reentrant call, reentryCount:", reentryCount);
        }
    }
}
