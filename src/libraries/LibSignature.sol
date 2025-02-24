// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title LibSignature
/// @notice Library for signature verification and recovery
/// @dev Centralizes signature verification logic used across facets
library LibSignature {
    // Custom errors
    error InvalidSignature();

    // Half of secp256k1n (the curve order) - used for signature malleability check
    uint256 constant SECP256K1_N_DIV_2 =
        0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0;

    /// @notice Recover signer from a signature
    /// @param hash The hash that was signed
    /// @param signature The signature bytes
    /// @return The address that signed the hash
    function recoverSigner(bytes32 hash, bytes memory signature) internal pure returns (address) {
        if (signature.length != 65) revert InvalidSignature();

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        if (v < 27) {
            v += 27;
        }

        if (v != 27 && v != 28) revert InvalidSignature();

        // Ensure s is in the lower half of secp256k1n to prevent signature malleability
        if (uint256(s) > SECP256K1_N_DIV_2) revert InvalidSignature();

        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, hash));
        return ecrecover(prefixedHash, v, r, s);
    }

    /// @notice Create hash for standard purchase signature
    /// @return Hash to be signed
    function getStandardSignatureHash(
        address nftAddress,
        address payment,
        uint256 price,
        address to,
        uint256 tokenId,
        uint256 nonce,
        uint256 amount,
        uint256[] memory serialNumbers,
        uint256 chainId
    ) internal pure returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                nftAddress,
                payment,
                price,
                to,
                tokenId,
                nonce,
                amount,
                keccak256(abi.encodePacked(serialNumbers)),
                chainId
            )
        );
    }

    /// @notice Create hash for locked vault signature
    /// @return Hash to be signed
    function getLockedSignatureHash(
        address nftAddress,
        address payment,
        uint256 price,
        address to,
        uint256 tokenId,
        uint256 nonce,
        uint256 amount,
        uint256[] memory serialNumbers,
        uint256 chainId
    ) internal pure returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                nftAddress,
                payment,
                price,
                to,
                tokenId,
                nonce,
                amount,
                keccak256(abi.encodePacked(serialNumbers)),
                true,
                chainId
            )
        );
    }

    /// @notice Verify standard purchase signature
    /// @return The recovered signer address
    function verifyStandardSignature(
        address nftAddress,
        address payment,
        uint256 price,
        address to,
        uint256 tokenId,
        uint256 nonce,
        uint256 amount,
        uint256[] memory serialNumbers,
        bytes memory signature,
        uint256 chainId
    ) internal pure returns (address) {
        bytes32 hash = getStandardSignatureHash(
            nftAddress, payment, price, to, tokenId, nonce, amount, serialNumbers, chainId
        );
        return recoverSigner(hash, signature);
    }

    /// @notice Verify locked vault signature
    /// @return The recovered signer address
    function verifyLockedSignature(
        address nftAddress,
        address payment,
        uint256 price,
        address to,
        uint256 tokenId,
        uint256 nonce,
        uint256 amount,
        uint256[] memory serialNumbers,
        bytes memory signature,
        uint256 chainId
    ) internal pure returns (address) {
        bytes32 hash = getLockedSignatureHash(
            nftAddress, payment, price, to, tokenId, nonce, amount, serialNumbers, chainId
        );
        return recoverSigner(hash, signature);
    }
}
