// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title EmblemVaultMintFacet
/// @notice Facet contract for handling NFT minting operations in the Emblem Vault system
/// @dev This facet provides functionality for minting NFTs through various methods including
/// signed price purchases, quote-based purchases, and batch minting. It supports both ERC721A
/// and ERC1155 token standards.

// ========== External Libraries ==========
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// ========== Internal Libraries ==========
import "../libraries/LibDiamond.sol";
import "../libraries/LibEmblemVaultStorage.sol";
import "../libraries/LibSignature.sol";
import "../libraries/LibInterfaceIds.sol";
import "../libraries/LibErrors.sol";

// ========== Interfaces ==========
import "../interfaces/IERC1155.sol";
import "../interfaces/IERC20Token.sol";
import "../interfaces/IMintVaultQuote.sol";
import "../interfaces/IIsSerialized.sol";
import "../interfaces/IERC721AVault.sol";
import "../interfaces/IVaultCollectionFactory.sol";

contract EmblemVaultMintFacet {
    using LibEmblemVaultStorage for LibEmblemVaultStorage.VaultStorage;
    using SafeERC20 for IERC20;

    // Constants for gas optimization
    uint256 private constant PRICE_TOLERANCE_BPS = 200; // 2%

    /// @notice Emitted when a token is successfully minted
    /// @param nftAddress The address of the NFT contract
    /// @param to The address receiving the minted token
    /// @param tokenId The ID of the minted token
    /// @param amount The amount of tokens minted (for ERC1155)
    /// @param price The price paid for the mint
    /// @param paymentToken The token used for payment (address(0) for ETH)
    /// @param data Additional data associated with the mint
    event TokenMinted(
        address indexed nftAddress,
        address indexed to,
        uint256 indexed tokenId,
        uint256 amount,
        uint256 price,
        address paymentToken,
        bytes data
    );

    /// @notice Parameters required for minting operations
    /// @dev This struct encapsulates all necessary data for both standard and quote-based mints
    struct MintParams {
        address nftAddress; // Address of the NFT contract
        address payment; // Payment token address (address(0) for ETH)
        uint256 price; // Price per token
        address to; // Recipient address
        uint256 externalTokenId; // External token ID
        uint256 nonce; // Unique nonce for the transaction
        bytes signature; // Signature for verification
        bytes serialNumber; // Serial number for ERC1155 tokens
        uint256 amount; // Number of tokens to mint
        bool isQuote; // Flag indicating if this is a quote-based mint
    }

    /// @notice Modifier to ensure the collection is valid
    /// @dev Reverts if the collection is not registered with the vault factory
    /// @param collection The address of the collection to validate
    modifier onlyValidCollection(address collection) {
        LibEmblemVaultStorage.VaultStorage storage vs = LibEmblemVaultStorage.vaultStorage();
        LibErrors.revertIfFactoryNotSet(vs.vaultFactory);
        LibErrors.revertIfInvalidCollection(
            collection, IVaultCollectionFactory(vs.vaultFactory).isCollection(collection)
        );
        _;
    }

    /// @notice Purchase NFTs using a signed price
    /// @dev Allows users to mint NFTs by providing a signed price from an authorized signer
    /// @param _nftAddress Address of the NFT contract
    /// @param _payment Payment token address (address(0) for ETH)
    /// @param _price Price per token
    /// @param _to Recipient address
    /// @param _externalTokenId External token ID
    /// @param _nonce Unique nonce for the transaction
    /// @param _signature Signature for verification
    /// @param _serialNumber Serial number for ERC1155 tokens
    /// @param _amount Number of tokens to mint
    function buyWithSignedPrice(
        address _nftAddress,
        address _payment,
        uint256 _price,
        address _to,
        uint256 _externalTokenId,
        uint256 _nonce,
        bytes calldata _signature,
        bytes calldata _serialNumber,
        uint256 _amount
    ) external payable onlyValidCollection(_nftAddress) {
        LibEmblemVaultStorage.nonReentrantBefore();

        MintParams memory params = MintParams({
            nftAddress: _nftAddress,
            payment: _payment,
            price: _price,
            to: _to,
            externalTokenId: _externalTokenId,
            nonce: _nonce,
            signature: _signature,
            serialNumber: _serialNumber,
            amount: _amount,
            isQuote: false
        });

        _processMint(params);

        LibEmblemVaultStorage.nonReentrantAfter();
    }

    /// @notice Batch purchase NFTs using signed prices
    /// @dev Allows users to mint multiple NFTs in a batch using signed prices
    /// @param _nftAddress Address of the NFT contract
    /// @param _payment Payment token address (address(0) for ETH)
    /// @param _prices Array of prices per token
    /// @param _to Recipient address
    /// @param _externalTokenIds Array of external token IDs to mint
    /// @param _nonces Array of unique nonces for the transactions
    /// @param _signatures Array of signatures for verification
    /// @param _serialNumbers Array of serial numbers for ERC1155 tokens
    /// @param _amounts Array of amounts to mint for each token
    struct BatchPurchase {
        address nftAddress;
        address payment;
        uint256[] prices;
        address to;
        uint256[] externalTokenIds;
        uint256[] nonces;
        bytes[] signatures;
        bytes[] serialNumbers;
        uint256[] amounts;
    }

    function batchBuyWithSignedPrice(BatchPurchase calldata purchase)
        external
        payable
        onlyValidCollection(purchase.nftAddress)
    {
        LibEmblemVaultStorage.nonReentrantBefore();

        LibErrors.revertIfLengthMismatch(purchase.externalTokenIds.length, purchase.prices.length);
        LibErrors.revertIfLengthMismatch(purchase.externalTokenIds.length, purchase.nonces.length);
        LibErrors.revertIfLengthMismatch(
            purchase.externalTokenIds.length, purchase.signatures.length
        );
        LibErrors.revertIfLengthMismatch(purchase.externalTokenIds.length, purchase.amounts.length);
        LibErrors.revertIfLengthMismatch(
            purchase.externalTokenIds.length, purchase.serialNumbers.length
        );

        uint256 totalPrice;
        for (uint256 i = 0; i < purchase.prices.length; i++) {
            totalPrice += purchase.prices[i] * purchase.amounts[i];
        }

        LibEmblemVaultStorage.VaultStorage storage vs = LibEmblemVaultStorage.vaultStorage();

        if (purchase.payment == address(0)) {
            LibErrors.revertIfInsufficientETH(msg.value, totalPrice);
            (bool success,) = vs.recipientAddress.call{value: msg.value}("");
            if (!success) {
                revert LibErrors.ETHTransferFailed();
            }
        } else {
            IERC20(purchase.payment).safeTransferFrom(msg.sender, vs.recipientAddress, totalPrice);
        }

        for (uint256 i = 0; i < purchase.externalTokenIds.length; i++) {
            LibEmblemVaultStorage.enforceNotUsedNonce(purchase.nonces[i]);

            address signer = LibSignature.verifyStandardSignature(
                purchase.nftAddress,
                purchase.payment,
                purchase.prices[i],
                purchase.to,
                purchase.externalTokenIds[i],
                purchase.nonces[i],
                purchase.amounts[i],
                purchase.signatures[i]
            );

            LibErrors.revertIfNotWitness(signer, vs.witnesses[signer]);
            LibEmblemVaultStorage.setUsedNonce(purchase.nonces[i]);
        }

        require(
            _batchMintRouter(
                purchase.nftAddress,
                purchase.to,
                purchase.externalTokenIds,
                purchase.amounts,
                purchase.serialNumbers,
                ""
            ),
            "Batch mint failed"
        );

        LibEmblemVaultStorage.nonReentrantAfter();
    }

    /// @notice Purchase NFTs using a price quote
    /// @dev Allows users to mint NFTs using a price quote from the quote contract
    /// @param _nftAddress Address of the NFT contract
    /// @param _price Price per token
    /// @param _to Recipient address
    /// @param _externalTokenId External token ID
    /// @param _nonce Unique nonce for the transaction
    /// @param _signature Signature for verification
    /// @param _serialNumber Serial number for ERC1155 tokens
    /// @param _amount Number of tokens to mint
    function buyWithQuote(
        address _nftAddress,
        uint256 _price,
        address _to,
        uint256 _externalTokenId,
        uint256 _nonce,
        bytes calldata _signature,
        bytes calldata _serialNumber,
        uint256 _amount
    ) external payable onlyValidCollection(_nftAddress) {
        LibEmblemVaultStorage.nonReentrantBefore();

        LibEmblemVaultStorage.VaultStorage storage vs = LibEmblemVaultStorage.vaultStorage();
        uint256 quote = IMintVaultQuote(vs.quoteContract).quoteExternalPrice(msg.sender, _price);
        uint256 totalPrice;

        unchecked {
            totalPrice = quote * _amount;
            uint256 acceptableRange = (totalPrice * PRICE_TOLERANCE_BPS) / 10_000;
            LibErrors.revertIfPriceOutOfRange(msg.value, totalPrice, acceptableRange);
        }

        MintParams memory params = MintParams({
            nftAddress: _nftAddress,
            payment: address(0),
            price: _price,
            to: _to,
            externalTokenId: _externalTokenId,
            nonce: _nonce,
            signature: _signature,
            serialNumber: _serialNumber,
            amount: _amount,
            isQuote: true
        });

        _processMint(params);

        LibEmblemVaultStorage.nonReentrantAfter();
    }

    function _processMint(MintParams memory params) private {
        LibEmblemVaultStorage.enforceNotUsedNonce(params.nonce);
        LibEmblemVaultStorage.VaultStorage storage vs = LibEmblemVaultStorage.vaultStorage();

        if (params.payment == address(0)) {
            (bool success,) = vs.recipientAddress.call{value: msg.value}("");
            if (!success) {
                revert("Failed to send Ether");
            }
        } else {
            IERC20(params.payment).safeTransferFrom(msg.sender, vs.recipientAddress, params.price);
        }

        address signer = params.isQuote
            ? LibSignature.verifyQuoteSignature(
                params.nftAddress,
                params.price,
                params.to,
                params.externalTokenId,
                params.nonce,
                params.amount,
                params.signature
            )
            : LibSignature.verifyStandardSignature(
                params.nftAddress,
                params.payment,
                params.price,
                params.to,
                params.externalTokenId,
                params.nonce,
                params.amount,
                params.signature
            );

        LibErrors.revertIfNotWitness(signer, vs.witnesses[signer]);

        if (!_mintRouter(params)) {
            revert LibErrors.MintFailed(params.nftAddress, params.externalTokenId);
        }

        LibEmblemVaultStorage.setUsedNonce(params.nonce);

        emit TokenMinted(
            params.nftAddress,
            params.to,
            params.externalTokenId,
            params.amount,
            params.price,
            params.payment,
            params.serialNumber
        );
    }

    function _mintRouter(MintParams memory params) private returns (bool) {
        bool isERC1155 = LibInterfaceIds.isERC1155(params.nftAddress);
        bool isERC721A = !isERC1155 && LibInterfaceIds.isERC721A(params.nftAddress);

        if (isERC1155) {
            if (IIsSerialized(params.nftAddress).isOverloadSerial()) {
                IERC1155(params.nftAddress).mintWithSerial(
                    params.to, params.externalTokenId, params.amount, params.serialNumber
                );
            } else {
                IERC1155(params.nftAddress).mint(params.to, params.externalTokenId, params.amount);
            }
        } else if (isERC721A) {
            IERC721AVault(params.nftAddress).mint(params.to, params.externalTokenId);
        }
        return true;
    }

    function _batchMintRouter(
        address nftAddress,
        address to,
        uint256[] memory externalTokenIds,
        uint256[] memory amounts,
        bytes[] memory serialNumbers,
        bytes memory data
    ) private returns (bool) {
        bool isERC1155 = LibInterfaceIds.isERC1155(nftAddress);
        bool isERC721A = !isERC1155 && LibInterfaceIds.isERC721A(nftAddress);

        if (isERC1155) {
            for (uint256 i = 0; i < externalTokenIds.length; i++) {
                if (IIsSerialized(nftAddress).isOverloadSerial()) {
                    IERC1155(nftAddress).mintWithSerial(
                        to, externalTokenIds[i], amounts[i], serialNumbers[i]
                    );
                } else {
                    IERC1155(nftAddress).mint(to, externalTokenIds[i], amounts[i]);
                }
            }
        } else if (isERC721A) {
            IERC721AVault(nftAddress).batchMintWithData(to, externalTokenIds, data);
        }
        return true;
    }

    /// @notice Batch mint NFTs
    /// @dev Mints multiple NFTs in a single transaction
    /// @param to Recipient address
    /// @param externalTokenIds Array of external token IDs to mint
    function batchMint(address to, uint256[] calldata externalTokenIds) external {
        uint256[] memory amounts = new uint256[](externalTokenIds.length);
        bytes[] memory serialNumbers = new bytes[](externalTokenIds.length);
        for (uint256 i = 0; i < externalTokenIds.length; i++) {
            amounts[i] = 1;
        }
        require(
            _batchMintRouter(address(this), to, externalTokenIds, amounts, serialNumbers, ""),
            "Batch mint failed"
        );
    }

    /// @notice Batch mint NFTs with additional data
    /// @dev Mints multiple NFTs with additional data in a single transaction
    /// @param to Recipient address
    /// @param externalTokenIds Array of external token IDs to mint
    /// @param data Additional data to pass with the mint
    function batchMintWithData(address to, uint256[] calldata externalTokenIds, bytes calldata data)
        external
    {
        uint256[] memory amounts = new uint256[](externalTokenIds.length);
        bytes[] memory serialNumbers = new bytes[](externalTokenIds.length);
        for (uint256 i = 0; i < externalTokenIds.length; i++) {
            amounts[i] = 1;
        }
        require(
            _batchMintRouter(address(this), to, externalTokenIds, amounts, serialNumbers, data),
            "Batch mint failed"
        );
    }

    function _uintToStrOptimized(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }

        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }

        return string(buffer);
    }
}
