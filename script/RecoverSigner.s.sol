// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/libraries/LibSignature.sol";

contract RecoverSigner is Script {
    function run() external pure {
        // Use exact same parameters as TestMint.s.sol
        address nftAddress = vm.parseAddress("0x12a84432093C56D9235C7cd390Bb6A7adDA78301");
        address payment = address(0); // Zero address for ETH payment
        uint256 price = 0x1329c5a30bdfb7;
        address to = vm.parseAddress("0x16AC7b1598329D95e6C6C6372B12b6E0FB51c96c");
        uint256 tokenId = 1_868_251_361_100_521;
        uint256 nonce = 513_701;
        uint256 amount = 1;
        bytes memory signature =
            hex"2876fe7a97343fb557d934fe9701866ea7db3bfca69cc0594fe4ac2db0b5de002d2ccf71adc115ae3e06ca33a25f08688e6a7f035e3a369bb4aa1b7ea0792ba41b";

        // Get hash that was actually used in mint
        bytes32 hash = LibSignature.getStandardSignatureHash(
            nftAddress, payment, price, to, tokenId, nonce, amount
        );
        address signer = LibSignature.recoverSigner(hash, signature);

        console.log("\nTest Collection Parameters (used in mint):");
        console.log("NFT Address:", nftAddress);
        console.log("Payment Token:", payment);
        console.log("Message Hash:", vm.toString(hash));
        console.log("Recovered signer:", signer);

        // Try with original parameters from gist
        address originalNftAddress = vm.parseAddress("0x184ddb67E2EF517f6754F055b56905f2A9b29b6A");
        address originalPayment = vm.parseAddress("0x3d658390460295fb963f54dc0899cfb1c30776df");
        bytes32 originalHash = LibSignature.getStandardSignatureHash(
            originalNftAddress, originalPayment, price, to, tokenId, nonce, amount
        );
        address originalSigner = LibSignature.recoverSigner(originalHash, signature);

        console.log("\nOriginal Parameters (from gist API):");
        console.log("NFT Address:", originalNftAddress);
        console.log("Payment Token:", originalPayment);
        console.log("Message Hash:", vm.toString(originalHash));
        console.log("Recovered signer:", originalSigner);

        // Try with gist's direct signature
        string memory message = "Curated Minting: 1868251361100521";
        bytes memory gistSignature =
            hex"672def1d20c1db01cf991a048a7877719eddced6d46215ffb03d505fe6a022cd7358c59c243e862779d9558616f2091447f1f739f41bd4a78672d7cab61ce7071c";

        bytes32 messageHash = keccak256(bytes(message));
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, messageHash));
        address gistSigner = LibSignature.recoverSigner(messageHash, gistSignature);

        console.log("\nGist Direct Signature:");
        console.log("Message:", message);
        console.log("Message Hash:", vm.toString(messageHash));
        console.log("Prefixed Hash:", vm.toString(prefixedHash));
        console.log("Recovered signer:", gistSigner);
    }
}
