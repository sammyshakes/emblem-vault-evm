// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../libraries/LibDiamond.sol";
import "../libraries/LibEmblemVaultStorage.sol";
import "../interfaces/IERC165.sol";
import "../interfaces/IERC721.sol";
import "../interfaces/IERC1155.sol";
import "../interfaces/IERC20Token.sol";
import "../interfaces/IMintVaultQuote.sol";
import "../interfaces/IIsSerialized.sol";
import "../interfaces/IERC721A.sol";
import "../interfaces/IVaultCollectionFactory.sol";

contract EmblemVaultMintFacet {
    using LibEmblemVaultStorage for LibEmblemVaultStorage.VaultStorage;

    event TokenMinted(
        address indexed nftAddress,
        address indexed to,
        uint256 indexed tokenId,
        uint256 amount,
        uint256 price,
        address paymentToken,
        bytes data
    );

    // Custom errors
    error InvalidCollection();
    error FactoryNotSet();
    error InvalidSignature();
    error TransferFailed();
    error MintFailed();
    error InvalidAmount();
    error InvalidNonce();
    error PriceOutOfRange();

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
        if (vs.vaultFactory == address(0)) revert FactoryNotSet();
        if (!IVaultCollectionFactory(vs.vaultFactory).isCollection(collection)) {
            revert InvalidCollection();
        }
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
        uint256 totalPrice = quote * _amount;

        // Calculate the acceptable range for the msg.value (2% tolerance)
        uint256 acceptableRange = totalPrice * 2 / 100;
        if (msg.value < totalPrice - acceptableRange || msg.value > totalPrice + acceptableRange) {
            revert PriceOutOfRange();
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

        if (params.payment == address(0)) {
            payable(vs.recipientAddress).transfer(msg.value);
        } else {
            if (
                !IERC20Token(params.payment).transferFrom(
                    msg.sender, vs.recipientAddress, params.price
                )
            ) {
                revert TransferFailed();
            }
        }

        address signer = params.isQuote
            ? getAddressFromSignatureQuote(
                params.nftAddress,
                params.price,
                params.to,
                params.tokenId,
                params.nonce,
                params.amount,
                params.signature
            )
            : getAddressFromSignature(
                params.nftAddress,
                params.payment,
                params.price,
                params.to,
                params.tokenId,
                params.nonce,
                params.amount,
                params.signature
            );

        LibEmblemVaultStorage.enforceIsWitness(signer);

        if (!_mintRouter(params)) {
            revert MintFailed();
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
        LibEmblemVaultStorage.VaultStorage storage vs = LibEmblemVaultStorage.vaultStorage();

        if (IERC165(params.nftAddress).supportsInterface(vs.INTERFACE_ID_ERC1155)) {
            if (IIsSerialized(params.nftAddress).isOverloadSerial()) {
                IERC1155(params.nftAddress).mintWithSerial(
                    params.to, params.tokenId, params.amount, params.serialNumber
                );
            } else {
                IERC1155(params.nftAddress).mint(params.to, params.tokenId, params.amount);
            }
        } else {
            if (IERC165(params.nftAddress).supportsInterface(vs.INTERFACE_ID_ERC721A)) {
                if (params.serialNumber.length > 0) {
                    IERC721A(params.nftAddress).mintWithData(
                        params.to, params.tokenId, params.serialNumber
                    );
                } else {
                    IERC721A(params.nftAddress).mint(params.to, params.tokenId);
                }
            } else {
                string memory uri =
                    string(abi.encodePacked(vs.metadataBaseUri, uintToStr(params.tokenId)));
                IERC721(params.nftAddress).mint(params.to, params.tokenId, uri, "");
            }
        }
        return true;
    }

    function getAddressFromSignature(
        address _nftAddress,
        address _payment,
        uint256 _price,
        address _to,
        uint256 _tokenId,
        uint256 _nonce,
        uint256 _amount,
        bytes memory _signature
    ) internal pure returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(_nftAddress, _payment, _price, _to, _tokenId, _nonce, _amount)
        );
        return recoverSigner(hash, _signature);
    }

    function getAddressFromSignatureQuote(
        address _nftAddress,
        uint256 _price,
        address _to,
        uint256 _tokenId,
        uint256 _nonce,
        uint256 _amount,
        bytes memory _signature
    ) internal pure returns (address) {
        bytes32 hash =
            keccak256(abi.encodePacked(_nftAddress, _price, _to, _tokenId, _nonce, _amount));
        return recoverSigner(hash, _signature);
    }

    function recoverSigner(bytes32 hash, bytes memory sig) internal pure returns (address) {
        if (sig.length != 65) revert InvalidSignature();

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        if (v < 27) {
            v += 27;
        }

        if (v != 27 && v != 28) revert InvalidSignature();

        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, hash));
        return ecrecover(prefixedHash, v, r, s);
    }

    function uintToStr(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}
