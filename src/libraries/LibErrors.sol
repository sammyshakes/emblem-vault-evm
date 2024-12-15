// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title LibErrors
/// @notice Library for centralized error definitions
/// @dev Contains all custom errors used across the system
library LibErrors {
    // ============ Common Errors ============

    /// @notice Zero address provided where a non-zero address is required
    error ZeroAddress();

    /// @notice Operation attempted by non-owner
    error Unauthorized(address caller);

    /// @notice Invalid collection address provided
    error InvalidCollection(address collection);

    /// @notice Factory not set in storage
    error FactoryNotSet();

    /// @notice Transfer operation failed
    error TransferFailed();

    // ============ Vault State Errors ============

    /// @notice Vault is already locked
    error VaultAlreadyLocked(address collection, uint256 tokenId);

    /// @notice Vault is not locked
    error VaultNotLocked(address collection, uint256 tokenId);

    /// @notice Vault owner check failed
    error NotVaultOwner(address collection, uint256 tokenId, address caller);

    // ============ Witness Errors ============

    /// @notice Witness already exists
    error WitnessAlreadyExists(address witness);

    /// @notice Witness does not exist
    error WitnessDoesNotExist(address witness);

    /// @notice No witnesses remaining
    error NoWitnessesRemaining();

    /// @notice Not a witness
    error NotWitness(address caller);

    // ============ Signature Errors ============

    /// @notice Invalid signature provided
    error InvalidSignature();

    /// @notice Nonce already used
    error NonceAlreadyUsed(uint256 nonce);

    // ============ Claim Errors ============

    /// @notice Claimer contract not set
    error ClaimerNotSet();

    /// @notice Token already claimed
    error AlreadyClaimed(address collection, uint256 tokenId);

    /// @notice Burn operation failed
    error BurnFailed(address collection, uint256 tokenId);

    // ============ Mint Errors ============

    /// @notice Mint operation failed
    error MintFailed(address collection, uint256 tokenId);

    /// @notice Invalid amount provided
    error InvalidAmount(uint256 amount);

    /// @notice Price out of acceptable range
    error PriceOutOfRange(uint256 provided, uint256 expected, uint256 tolerance);

    /// @notice Invalid token ID
    error InvalidTokenId(uint256 tokenId);

    /// @notice Incorrect payment amount
    error IncorrectPayment(uint256 provided, uint256 expected);

    // ============ Initialization Errors ============

    /// @notice Already initialized
    error AlreadyInitialized();

    /// @notice Initialization failed
    error InitializationFailed();

    // ============ Bypass Errors ============

    /// @notice Invalid bypass rule
    error InvalidBypassRule();

    // ============ Helper Functions ============

    /// @notice Check for zero address
    function revertIfZeroAddress(address addr) internal pure {
        if (addr == address(0)) revert ZeroAddress();
    }

    /// @notice Check for valid collection
    function revertIfInvalidCollection(address collection, bool isValid) internal pure {
        if (!isValid) revert InvalidCollection(collection);
    }

    /// @notice Check for factory
    function revertIfFactoryNotSet(address factory) internal pure {
        if (factory == address(0)) revert FactoryNotSet();
    }

    /// @notice Check for vault lock state
    function revertIfAlreadyLocked(address collection, uint256 tokenId, bool isLocked)
        internal
        pure
    {
        if (isLocked) revert VaultAlreadyLocked(collection, tokenId);
    }

    /// @notice Check for vault unlock state
    function revertIfNotLocked(address collection, uint256 tokenId, bool isLocked) internal pure {
        if (!isLocked) revert VaultNotLocked(collection, tokenId);
    }

    /// @notice Check for witness status
    function revertIfNotWitness(address caller, bool isWitness) internal pure {
        if (!isWitness) revert NotWitness(caller);
    }

    /// @notice Check for correct payment
    function revertIfIncorrectPayment(uint256 provided, uint256 expected) internal pure {
        if (provided != expected) revert IncorrectPayment(provided, expected);
    }

    /// @notice Check for price range
    function revertIfPriceOutOfRange(uint256 provided, uint256 expected, uint256 tolerance)
        internal
        pure
    {
        if (provided < expected - tolerance || provided > expected + tolerance) {
            revert PriceOutOfRange(provided, expected, tolerance);
        }
    }

    /// @notice Check for vault ownership
    function revertIfNotVaultOwner(
        address collection,
        uint256 tokenId,
        address caller,
        address owner
    ) internal pure {
        if (caller != owner) revert NotVaultOwner(collection, tokenId, caller);
    }
}
