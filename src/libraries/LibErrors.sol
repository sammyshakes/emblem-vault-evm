// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title LibErrors
/// @notice Library for centralized error definitions
/// @dev Contains all custom errors used across the system
library LibErrors {
    // ============ Diamond Errors ============

    /// @notice Function does not exist in any facet
    error FunctionNotFound(bytes4 selector);

    /// @notice Initialization failed during diamond cut
    error DiamondInitFailed(address initContract, bytes initData);

    /// @notice Invalid facet cut action provided
    error InvalidFacetCutAction(uint8 action);

    /// @notice Function already exists and cannot be added again
    error FunctionAlreadyExists(bytes4 selector);

    /// @notice Function doesn't exist and cannot be replaced/removed
    error FunctionDoesNotExist(bytes4 selector);

    /// @notice Cannot replace function with same function
    error CannotReplaceSameFunction(bytes4 selector);

    /// @notice Invalid initialization parameters
    error InvalidInitialization();

    /// @notice Initialization contract has no code
    error InitializationContractEmpty(address initContract);

    /// @notice Delegate call failed
    error DelegateCallFailed();

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

    /// @notice Invalid implementation contract
    error InvalidImplementation();

    // ============ Collection Errors ============

    /// @notice Invalid collection type provided
    error InvalidCollectionType(uint8 collectionType);

    /// @notice Invalid operation for collection type
    error InvalidCollectionOperation(address collection);

    /// @notice Not the owner of the collection
    error NotCollectionOwner(address collection, address caller);

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

    // ============ Unvault Errors ============

    /// @notice Unvaulter contract not set
    error UnvaulterNotSet();

    /// @notice Token already unvaulted
    error AlreadyUnvaulted(address collection, uint256 tokenId);

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

    /// @notice Eth transfer failed
    error ETHTransferFailed();

    /// @notice Array length mismatch
    error LengthMismatch(uint256 length1, uint256 length2);

    /// @notice Batch size exceeds limit
    error BatchSizeExceeded(uint256 size, uint256 limit);

    /// @notice Recipient address does not match sender
    error InvalidRecipient();

    /// @notice Number of serial numbers does not match amount
    error InvalidSerialNumbersCount();

    // ============ Initialization Errors ============

    /// @notice Already initialized
    error AlreadyInitialized();

    /// @notice Initialization failed
    error InitializationFailed();

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

    /// @notice Check for insufficient payment
    function revertIfInsufficientETH(uint256 provided, uint256 expected) internal pure {
        if (provided < expected) revert IncorrectPayment(provided, expected);
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

    /// @notice Check for collection ownership
    function revertIfNotCollectionOwner(address collection, address caller, address owner)
        internal
        pure
    {
        if (caller != owner) revert NotCollectionOwner(collection, caller);
    }

    /// @notice Check for contract ownership
    function revertIfNotContractOwner(address caller, address owner) internal pure {
        if (caller != owner) revert Unauthorized(caller);
    }

    /// @notice Check for function existence
    function revertIfFunctionNotFound(bytes4 selector, address facet) internal pure {
        if (facet == address(0)) revert FunctionNotFound(selector);
    }

    /// @notice Check for initialization contract
    function revertIfInitializationInvalid(address initContract, bytes memory initData)
        internal
        pure
    {
        if (initContract == address(0) && initData.length > 0) revert InvalidInitialization();
        if (initContract != address(0) && initData.length == 0) revert InvalidInitialization();
    }

    /// @notice Check for length mismatch
    function revertIfLengthMismatch(uint256 length1, uint256 length2) internal pure {
        if (length1 != length2) revert LengthMismatch(length1, length2);
    }

    /// @notice Check for batch size limit
    function revertIfBatchSizeExceeded(uint256 size, uint256 limit) internal pure {
        if (size > limit) revert BatchSizeExceeded(size, limit);
    }

    /// @notice Check if recipient matches sender
    function revertIfInvalidRecipient(address recipient, address sender) internal pure {
        if (recipient != sender) revert InvalidRecipient();
    }
}
