// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

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
            if (IIsSerialized(params.nftAddress).isOverloadSerial()) {
                IERC1155(params.nftAddress).mintWithSerial(
                    params.to, params.tokenId, params.amount, params.serialNumber
                );
            } else {
                IERC1155(params.nftAddress).mint(params.to, params.tokenId, params.amount);
            }
        } else if (isERC721A) {
            IERC721AVault(params.nftAddress).mint(params.to, params.tokenId);
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

    function batchMint(address to, uint256[] calldata externalTokenIds) external {
        IERC721AVault(address(this)).batchMint(to, externalTokenIds);
    }

    function batchMintWithData(address to, uint256[] calldata externalTokenIds, bytes calldata data)
        external
    {
        IERC721AVault(address(this)).batchMintWithData(to, externalTokenIds, data);
    }

    function batchBuyWithSignedPrice(
        address _nftAddress,
        address _payment,
        uint256[] calldata _prices,
        address _to,
        uint256[] calldata _tokenIds,
        uint256[] calldata _nonces,
        bytes[] calldata _signatures,
        uint256[] calldata _amounts
    ) external payable onlyValidCollection(_nftAddress) {
        LibEmblemVaultStorage.nonReentrantBefore();

        require(_tokenIds.length == _prices.length, "Length mismatch");
        require(_tokenIds.length == _nonces.length, "Length mismatch");
        require(_tokenIds.length == _signatures.length, "Length mismatch");
        require(_tokenIds.length == _amounts.length, "Length mismatch");

        uint256 totalPrice;
        for (uint256 i = 0; i < _prices.length; i++) {
            totalPrice += _prices[i] * _amounts[i];
        }

        LibEmblemVaultStorage.VaultStorage storage vs = LibEmblemVaultStorage.vaultStorage();

        if (_payment == address(0)) {
            require(msg.value >= totalPrice, "Insufficient ETH");
            (bool success,) = vs.recipientAddress.call{value: msg.value}("");
            require(success, "ETH transfer failed");
        } else {
            IERC20(_payment).safeTransferFrom(msg.sender, vs.recipientAddress, totalPrice);
        }

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            LibEmblemVaultStorage.enforceNotUsedNonce(_nonces[i]);

            address signer = LibSignature.verifyStandardSignature(
                _nftAddress,
                _payment,
                _prices[i],
                _to,
                _tokenIds[i],
                _nonces[i],
                _amounts[i],
                _signatures[i]
            );

            LibErrors.revertIfNotWitness(signer, vs.witnesses[signer]);
            LibEmblemVaultStorage.setUsedNonce(_nonces[i]);
        }

        IERC721AVault(_nftAddress).batchMint(_to, _tokenIds);

        LibEmblemVaultStorage.nonReentrantAfter();
    }
}
