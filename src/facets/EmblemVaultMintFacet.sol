/*
███████╗███╗   ███╗██████╗ ██╗     ███████╗███╗   ███╗    ██╗   ██╗ █████╗ ██╗   ██╗██╗  ████████╗
██╔════╝████╗ ████║██╔══██╗██║     ██╔════╝████╗ ████║    ██║   ██║██╔══██╗██║   ██║██║  ╚══██╔══╝
█████╗  ██╔████╔██║██████╔╝██║     █████╗  ██╔████╔██║    ██║   ██║███████║██║   ██║██║     ██║   
██╔══╝  ██║╚██╔╝██║██╔══██╗██║     ██╔══╝  ██║╚██╔╝██║    ╚██╗ ██╔╝██╔══██║██║   ██║██║     ██║   
███████╗██║ ╚═╝ ██║██████╔╝███████╗███████╗██║ ╚═╝ ██║     ╚████╔╝ ██║  ██║╚██████╔╝███████╗██║   
╚══════╝╚═╝     ╚═╝╚═════╝ ╚══════╝╚══════╝╚═╝     ╚═╝      ╚═══╝  ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝   
███╗   ███╗██╗███╗   ██╗████████╗
████╗ ████║██║████╗  ██║╚══██╔══╝
██╔████╔██║██║██╔██╗ ██║   ██║   
██║╚██╔╝██║██║██║╚██╗██║   ██║   
██║ ╚═╝ ██║██║██║ ╚████║   ██║   
╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝   ╚═╝   
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title EmblemVaultMintFacet
/// @notice Facet contract for handling NFT minting operations in the Emblem Vault system
/// @dev This facet provides functionality for minting NFTs through various methods including
/// signed price purchases and batch minting. It supports both ERC721A
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
import "../interfaces/IIsSerialized.sol";
import "../interfaces/IERC721AVault.sol";
import "../interfaces/IVaultCollectionFactory.sol";

contract EmblemVaultMintFacet {
    using LibEmblemVaultStorage for LibEmblemVaultStorage.VaultStorage;
    using SafeERC20 for IERC20;

    /// @notice Get the mint facet version
    /// @return The version string
    function getMintVersion() external pure returns (string memory) {
        return "0.1.0";
    }

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
    /// @dev This struct encapsulates all necessary data for minting operations
    struct MintParams {
        address nftAddress; // Address of the NFT contract
        address payment; // Payment token address (address(0) for ETH)
        uint256 price; // Price per token
        address to; // Recipient address
        uint256 tokenId; // External token ID
        uint256 nonce; // Unique nonce for the transaction
        bytes signature; // Signature for verification
        bytes serialNumber; // Serial number for ERC1155 tokens
        uint256 amount; // Number of tokens to mint
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
    /// @param _tokenId External token ID
    /// @param _nonce Unique nonce for the transaction
    /// @param _signature Signature for verification
    /// @param _serialNumber Serial number for ERC1155 tokens
    /// @param _amount Number of tokens to mint
    function buyWithSignedPrice(
        address _nftAddress,
        address _payment,
        uint256 _price,
        address _to,
        uint256 _tokenId,
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
            tokenId: _tokenId,
            nonce: _nonce,
            signature: _signature,
            serialNumber: _serialNumber,
            amount: _amount
        });

        _processMint(params);

        LibEmblemVaultStorage.nonReentrantAfter();
    }

    /// @notice Batch buy NFTs using signed prices
    /// @dev Allows users to mint multiple NFTs in a batch using signed prices
    /// @param _nftAddress Address of the NFT contract
    /// @param _payment Payment token address (address(0) for ETH)
    /// @param _prices Array of prices per token
    /// @param _to Recipient address
    /// @param _tokenIds Array of token IDs to mint
    /// @param _nonces Array of unique nonces for the transactions
    /// @param _signatures Array of signatures for verification
    /// @param _serialNumbers Array of serial numbers for ERC1155 tokens
    /// @param _amounts Array of amounts to mint for each token
    struct BatchBuyParams {
        address nftAddress;
        address payment;
        uint256[] prices;
        address to;
        uint256[] tokenIds;
        uint256[] nonces;
        bytes[] signatures;
        bytes[] serialNumbers;
        uint256[] amounts;
    }

    function batchBuyWithSignedPrice(BatchBuyParams calldata params)
        external
        payable
        onlyValidCollection(params.nftAddress)
    {
        LibEmblemVaultStorage.nonReentrantBefore();

        LibErrors.revertIfLengthMismatch(params.tokenIds.length, params.prices.length);
        LibErrors.revertIfLengthMismatch(params.tokenIds.length, params.nonces.length);
        LibErrors.revertIfLengthMismatch(params.tokenIds.length, params.signatures.length);
        LibErrors.revertIfLengthMismatch(params.tokenIds.length, params.amounts.length);
        // Calculate total tokens being minted
        uint256 totalTokens;
        for (uint256 i = 0; i < params.amounts.length; i++) {
            totalTokens += params.amounts[i];
        }
        // Verify serial numbers match total tokens
        LibErrors.revertIfLengthMismatch(totalTokens, params.serialNumbers.length);

        uint256 totalPrice;
        for (uint256 i = 0; i < params.prices.length; i++) {
            totalPrice += params.prices[i] * params.amounts[i];
        }

        LibEmblemVaultStorage.VaultStorage storage vs = LibEmblemVaultStorage.vaultStorage();

        if (params.payment == address(0)) {
            LibErrors.revertIfInsufficientETH(msg.value, totalPrice);
            (bool success,) = vs.recipientAddress.call{value: msg.value}("");
            if (!success) {
                revert LibErrors.ETHTransferFailed();
            }
        } else {
            IERC20(params.payment).safeTransferFrom(msg.sender, vs.recipientAddress, totalPrice);
        }

        for (uint256 i = 0; i < params.tokenIds.length; i++) {
            LibEmblemVaultStorage.enforceNotUsedNonce(params.nonces[i]);

            address signer = LibSignature.verifyStandardSignature(
                params.nftAddress,
                params.payment,
                params.prices[i],
                params.to,
                params.tokenIds[i],
                params.nonces[i],
                params.amounts[i],
                params.signatures[i]
            );

            LibErrors.revertIfNotWitness(signer, vs.witnesses[signer]);
            LibEmblemVaultStorage.setUsedNonce(params.nonces[i]);
        }

        require(
            _batchMintRouter(
                params.nftAddress,
                params.to,
                params.tokenIds,
                params.amounts,
                params.serialNumbers,
                ""
            ),
            "Batch mint failed"
        );

        LibEmblemVaultStorage.nonReentrantAfter();
    }

    function _processMint(MintParams memory params) private {
        LibEmblemVaultStorage.enforceNotUsedNonce(params.nonce);
        LibEmblemVaultStorage.VaultStorage storage vs = LibEmblemVaultStorage.vaultStorage();

        if (params.payment == address(0)) {
            LibErrors.revertIfInsufficientETH(msg.value, params.price);
            (bool success,) = vs.recipientAddress.call{value: msg.value}("");
            if (!success) {
                revert("Failed to send Ether");
            }
        } else {
            IERC20(params.payment).safeTransferFrom(msg.sender, vs.recipientAddress, params.price);
        }

        address signer = LibSignature.verifyStandardSignature(
            params.nftAddress,
            params.payment,
            params.price,
            params.to,
            params.tokenId,
            params.nonce,
            params.amount,
            params.signature
        );

        LibErrors.revertIfNotWitness(signer, vs.witnesses[signer]);

        if (!_mintRouter(params)) {
            revert LibErrors.MintFailed(params.nftAddress, params.tokenId);
        }

        LibEmblemVaultStorage.setUsedNonce(params.nonce);

        emit TokenMinted(
            params.nftAddress,
            params.to,
            params.tokenId,
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
            IERC1155(params.nftAddress).mintWithSerial(
                params.to, params.tokenId, params.amount, params.serialNumber
            );
        } else if (isERC721A) {
            IERC721AVault(params.nftAddress).mint(params.to, params.tokenId);
        }
        return true;
    }

    function _batchMintRouter(
        address nftAddress,
        address to,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        bytes[] memory serialNumbers,
        bytes memory data
    ) private returns (bool) {
        bool isERC1155 = LibInterfaceIds.isERC1155(nftAddress);
        bool isERC721A = !isERC1155 && LibInterfaceIds.isERC721A(nftAddress);

        if (isERC1155) {
            for (uint256 i = 0; i < tokenIds.length; i++) {
                IERC1155(nftAddress).mintWithSerial(to, tokenIds[i], amounts[i], serialNumbers[i]);
            }
        } else if (isERC721A) {
            IERC721AVault(nftAddress).batchMintWithData(to, tokenIds, data);
        }
        return true;
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
