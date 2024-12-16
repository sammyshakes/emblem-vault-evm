// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../libraries/LibDiamond.sol";
import "../libraries/LibEmblemVaultStorage.sol";
import "../libraries/LibSignature.sol";
import "../libraries/LibInterfaceIds.sol";
import "../libraries/LibErrors.sol";
import "../interfaces/IERC721.sol";
import "../interfaces/IERC1155.sol";
import "../interfaces/IERC20Token.sol";
import "../interfaces/IMintVaultQuote.sol";
import "../interfaces/IIsSerialized.sol";
import "../interfaces/IERC721A.sol";
import "../interfaces/IVaultCollectionFactory.sol";

contract EmblemVaultMintFacet {
    using LibEmblemVaultStorage for LibEmblemVaultStorage.VaultStorage;

    // Constants for gas optimization
    uint256 private constant PRICE_TOLERANCE_BPS = 200; // 2%
    bytes16 private constant HEX_DIGITS = "0123456789";

    event TokenMinted(
        address indexed nftAddress,
        address indexed to,
        uint256 indexed tokenId,
        uint256 amount,
        uint256 price,
        address paymentToken,
        bytes data
    );

    struct MintParams {
        address nftAddress;
        address payment;
        uint256 price;
        address to;
        uint256 tokenId;
        uint256 nonce;
        bytes signature;
        bytes serialNumber;
        uint256 amount;
        bool isQuote;
    }

    modifier onlyValidCollection(address collection) {
        LibEmblemVaultStorage.VaultStorage storage vs = LibEmblemVaultStorage.vaultStorage();
        LibErrors.revertIfFactoryNotSet(vs.vaultFactory);
        LibErrors.revertIfInvalidCollection(
            collection, IVaultCollectionFactory(vs.vaultFactory).isCollection(collection)
        );
        _;
    }

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
            amount: _amount,
            isQuote: false
        });

        _processMint(params);

        LibEmblemVaultStorage.nonReentrantAfter();
    }

    function buyWithQuote(
        address _nftAddress,
        uint256 _price,
        address _to,
        uint256 _tokenId,
        uint256 _nonce,
        bytes calldata _signature,
        bytes calldata _serialNumber,
        uint256 _amount
    ) external payable onlyValidCollection(_nftAddress) {
        LibEmblemVaultStorage.nonReentrantBefore();

        // Cache storage reads
        LibEmblemVaultStorage.VaultStorage storage vs = LibEmblemVaultStorage.vaultStorage();
        uint256 quote = IMintVaultQuote(vs.quoteContract).quoteExternalPrice(msg.sender, _price);
        uint256 totalPrice;

        // Unchecked math for gas optimization where overflow is impossible
        unchecked {
            totalPrice = quote * _amount;
            // Calculate acceptable range (2% tolerance)
            uint256 acceptableRange = (totalPrice * PRICE_TOLERANCE_BPS) / 10_000;
            LibErrors.revertIfPriceOutOfRange(msg.value, totalPrice, acceptableRange);
        }

        MintParams memory params = MintParams({
            nftAddress: _nftAddress,
            payment: address(0),
            price: _price, // Use base price for signature verification, not msg.value
            to: _to,
            tokenId: _tokenId,
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

        // Handle payment
        if (params.payment == address(0)) {
            payable(vs.recipientAddress).transfer(msg.value);
        } else {
            if (
                !IERC20Token(params.payment).transferFrom(
                    msg.sender, vs.recipientAddress, params.price
                )
            ) {
                revert LibErrors.TransferFailed();
            }
        }

        // Verify signature
        address signer = params.isQuote
            ? LibSignature.verifyQuoteSignature(
                params.nftAddress,
                params.price,
                params.to,
                params.tokenId,
                params.nonce,
                params.amount,
                params.signature
            )
            : LibSignature.verifyStandardSignature(
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

        // Mint token
        if (!_mintRouter(params, vs)) {
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

    function _mintRouter(MintParams memory params, LibEmblemVaultStorage.VaultStorage storage vs)
        private
        returns (bool)
    {
        // Cache interface check results
        bool isERC1155 = LibInterfaceIds.isERC1155(params.nftAddress);
        bool isERC721A = !isERC1155 && LibInterfaceIds.isERC721A(params.nftAddress);

        if (isERC1155) {
            if (IIsSerialized(params.nftAddress).isOverloadSerial()) {
                IERC1155(params.nftAddress).mintWithSerial(
                    params.to, params.tokenId, params.amount, params.serialNumber
                );
            } else {
                IERC1155(params.nftAddress).mint(params.to, params.tokenId, params.amount);
            }
        } else if (isERC721A) {
            if (params.serialNumber.length > 0) {
                IERC721A(params.nftAddress).mintWithData(
                    params.to, params.tokenId, params.serialNumber
                );
            } else {
                IERC721A(params.nftAddress).mint(params.to, params.tokenId);
            }
        } else {
            string memory uri =
                string(abi.encodePacked(vs.metadataBaseUri, _uintToStrOptimized(params.tokenId)));
            IERC721(params.nftAddress).mint(params.to, params.tokenId, uri, "");
        }
        return true;
    }

    function _uintToStrOptimized(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }

        // Count digits
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        // Create string
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }

        return string(buffer);
    }
}
