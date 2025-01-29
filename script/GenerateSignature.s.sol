// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/libraries/LibSignature.sol";

contract GenerateSignature is Script {
    function run() external view {
        // Get witness private key from .env
        // uint256 witnessPrivateKey = vm.envUint("WITNESS_PRIVATE_KEY");
        uint256 witnessPrivateKey = vm.envUint("PRIVATE_KEY"); // Use deployer priv key for testing

        // Parameters for signature (these can be modified as needed)
        address nftAddress = vm.envAddress("COLLECTION_ADDRESS");
        address payment = address(0); // Zero address for ETH payment
        uint256 price = 0; // 0.00000000 ETH for testing
        address to = vm.envAddress("RECIPIENT_ADDRESS");
        uint256 tokenId = vm.envUint("TOKEN_ID");
        uint256 nonce = block.timestamp; // Using timestamp as nonce for testing
        uint256 amount = 1;

        // Generate signature hash
        // Include chainId in signature hash for cross-chain replay protection
        uint256 chainId = block.chainid;
        bytes32 hash = keccak256(
            abi.encodePacked(nftAddress, payment, price, to, tokenId, nonce, amount, chainId)
        );

        // Add Ethereum signed message prefix
        bytes32 prefixedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));

        // Sign the hash
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(witnessPrivateKey, prefixedHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        // Get witness address for verification
        address witness = vm.addr(witnessPrivateKey);

        // Print all the information needed for minting
        console.log("\nSignature Generation Parameters:");
        console.log("NFT Collection:", nftAddress);
        console.log("Payment Token:", payment);
        console.log("Price (in wei):", price);
        console.log("Price (in ETH):", price / 1 ether);
        console.log("Recipient:", to);
        console.log("Token ID:", tokenId);
        console.log("Nonce:", nonce);
        console.log("Amount:", amount);

        console.log("\nSignature Details:");
        console.log("Message Hash:", vm.toString(hash));
        console.log("Prefixed Hash:", vm.toString(prefixedHash));
        console.log(
            "Signature:", vm.toString(bytes32(uint256(uint160(uint256(bytes32(signature))))))
        );
        console.log("Witness Address:", witness);

        // Verify the signature
        address recoveredSigner = LibSignature.recoverSigner(hash, signature);
        console.log("\nSignature Verification:");
        console.log("Recovered Signer:", recoveredSigner);
        console.log("Signature Valid:", recoveredSigner == witness);

        // Print frontend-ready parameters
        console.log("\nFrontend Parameters:");
        console.log("{");
        console.log("  nftAddress: '", nftAddress, "',");
        console.log("  payment: '", payment, "',");
        console.log("  price: '", price, "',");
        console.log("  to: '", to, "',");
        console.log("  tokenId: ", tokenId, ",");
        console.log("  nonce: ", nonce, ",");
        console.log("  signature: '", vm.toString(signature), "',");
        console.log("  amount: ", amount, ",");
        console.log("  chainId: ", chainId);
        console.log("}");
    }
}
