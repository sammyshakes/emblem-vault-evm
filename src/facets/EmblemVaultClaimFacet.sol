// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../libraries/LibDiamond.sol";
import "../libraries/LibEmblemVaultStorage.sol";
import "../interfaces/IERC165.sol";
import "../interfaces/IERC721.sol";
import "../interfaces/IERC1155.sol";
import "../interfaces/IERC20Token.sol";
import "../interfaces/IERC721A.sol";
import "../interfaces/IClaimed.sol";
import "../interfaces/IIsSerialized.sol";
import "../interfaces/IVaultCollectionFactory.sol";

/// @title EmblemVaultClaimFacet
/// @notice Facet for handling vault claims and burns
/// @dev Manages the claiming process for vaults with support for various token standards
contract EmblemVaultClaimFacet {
    // Events
    event TokenClaimed(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed claimer,
        uint256 serialNumber,
        bytes data
    );
    event TokenClaimedWithPrice(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed claimer,
        uint256 price,
        uint256 serialNumber,
        bytes data
    );
    event ClaimerContractUpdated(address indexed oldClaimer, address indexed newClaimer);

    // Custom errors
    error InvalidCollection();
    error FactoryNotSet();
    error ZeroAddress();
    error VaultLocked();
    error VaultNotLocked();
    error ClaimerNotSet();
    error BurnFailed();
    error InvalidSignature();
    error TransferFailed();
    error InvalidTokenId();
    error NotVaultOwner();
    error AlreadyClaimed();
    error IncorrectPayment();
    error InvalidNonce();

    modifier onlyValidCollection(address collection) {
        LibEmblemVaultStorage.VaultStorage storage vs = LibEmblemVaultStorage.vaultStorage();
        if (vs.vaultFactory == address(0)) revert FactoryNotSet();
        if (!IVaultCollectionFactory(vs.vaultFactory).isCollection(collection)) {
            revert InvalidCollection();
        }
        _;
    }

    function setClaimerContract(address _claimer) external {
        LibDiamond.enforceIsContractOwner();
        if (_claimer == address(0)) revert ZeroAddress();

        LibEmblemVaultStorage.VaultStorage storage vs = LibEmblemVaultStorage.vaultStorage();
        address oldClaimer = vs.claimerContract;
        LibEmblemVaultStorage.setClaimerContract(_claimer);

        emit ClaimerContractUpdated(oldClaimer, _claimer);
    }

    function claim(address _nftAddress, uint256 tokenId)
        external
        onlyValidCollection(_nftAddress)
    {
        LibEmblemVaultStorage.nonReentrantBefore();

        if (LibEmblemVaultStorage.isVaultLocked(_nftAddress, tokenId)) {
            revert VaultLocked();
        }

        (bool success, uint256 serialNumber, bytes memory data) =
            burnRouter(_nftAddress, tokenId, true);
        if (!success) revert BurnFailed();

        emit TokenClaimed(_nftAddress, tokenId, msg.sender, serialNumber, data);
        LibEmblemVaultStorage.nonReentrantAfter();
    }

    function claimWithSignedPrice(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _nonce,
        address _payment,
        uint256 _price,
        bytes calldata _signature
    ) external payable onlyValidCollection(_nftAddress) {
        LibEmblemVaultStorage.nonReentrantBefore();
        LibEmblemVaultStorage.enforceNotUsedNonce(_nonce);

        address signer;
        if (LibEmblemVaultStorage.isVaultLocked(_nftAddress, _tokenId)) {
            signer = getAddressFromSignatureLocked(
                _nftAddress, _payment, _price, msg.sender, _tokenId, _nonce, 1, _signature
            );
        } else {
            signer = getAddressFromSignature(
                _nftAddress, _payment, _price, msg.sender, _tokenId, _nonce, 1, _signature
            );
        }

        LibEmblemVaultStorage.enforceIsWitness(signer);
        LibEmblemVaultStorage.VaultStorage storage vs = LibEmblemVaultStorage.vaultStorage();

        if (_payment == address(0)) {
            if (msg.value != _price) revert IncorrectPayment();
            payable(vs.recipientAddress).transfer(_price);
        } else {
            if (!IERC20Token(_payment).transferFrom(msg.sender, vs.recipientAddress, _price)) {
                revert TransferFailed();
            }
        }

        // Unlock vault because server signed it
        LibEmblemVaultStorage.unlockVault(_nftAddress, _tokenId);

        (bool success, uint256 serialNumber, bytes memory data) =
            burnRouter(_nftAddress, _tokenId, true);
        if (!success) revert BurnFailed();

        LibEmblemVaultStorage.setUsedNonce(_nonce);
        emit TokenClaimedWithPrice(_nftAddress, _tokenId, msg.sender, _price, serialNumber, data);
        LibEmblemVaultStorage.nonReentrantAfter();
    }

    function burnRouter(address _nftAddress, uint256 tokenId, bool shouldClaim)
        internal
        returns (bool success, uint256 serialNumber, bytes memory data)
    {
        LibEmblemVaultStorage.VaultStorage storage vs = LibEmblemVaultStorage.vaultStorage();
        if (vs.claimerContract == address(0)) revert ClaimerNotSet();

        IClaimed claimer = IClaimed(vs.claimerContract);
        bytes32[] memory proof;

        if (IERC165(_nftAddress).supportsInterface(vs.INTERFACE_ID_ERC1155)) {
            IIsSerialized serialized = IIsSerialized(_nftAddress);
            serialNumber = serialized.getFirstSerialByOwner(address(this), tokenId);

            if (serialized.getTokenIdForSerialNumber(serialNumber) != tokenId) {
                revert InvalidTokenId();
            }
            if (serialized.getOwnerOfSerial(serialNumber) != address(this)) {
                revert NotVaultOwner();
            }
            if (claimer.isClaimed(_nftAddress, serialNumber, proof)) {
                revert AlreadyClaimed();
            }

            IERC1155(_nftAddress).burn(address(this), tokenId, 1);
            if (shouldClaim) {
                claimer.claim(_nftAddress, serialNumber, msg.sender);
            }
            data = "";
        } else {
            if (IERC165(_nftAddress).supportsInterface(vs.INTERFACE_ID_ERC721A)) {
                IERC721A token = IERC721A(_nftAddress);
                uint256 internalTokenId = token.getInternalTokenId(tokenId);

                if (claimer.isClaimed(_nftAddress, internalTokenId, proof)) {
                    revert AlreadyClaimed();
                }
                if (token.ownerOf(internalTokenId) != address(this)) {
                    revert NotVaultOwner();
                }

                token.burnWithData(internalTokenId, "");
                data = "";
                serialNumber = internalTokenId;
            } else {
                if (claimer.isClaimed(_nftAddress, tokenId, proof)) {
                    revert AlreadyClaimed();
                }
                IERC721 token = IERC721(_nftAddress);
                if (token.ownerOf(tokenId) != address(this)) {
                    revert NotVaultOwner();
                }
                token.burn(tokenId);
                serialNumber = tokenId;
                data = "";
            }
            if (shouldClaim) {
                claimer.claim(_nftAddress, tokenId, msg.sender);
            }
        }
        return (true, serialNumber, data);
    }

    function getAddressFromSignature(
        address _nftAddress,
        address _payment,
        uint256 _price,
        address _to,
        uint256 _tokenId,
        uint256 _nonce,
        uint256 _amount,
        bytes calldata signature
    ) internal pure returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(_nftAddress, _payment, _price, _to, _tokenId, _nonce, _amount)
        );
        return recoverSigner(hash, signature);
    }

    function getAddressFromSignatureLocked(
        address _nftAddress,
        address _payment,
        uint256 _price,
        address _to,
        uint256 _tokenId,
        uint256 _nonce,
        uint256 _amount,
        bytes calldata signature
    ) internal pure returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(_nftAddress, _payment, _price, _to, _tokenId, _nonce, _amount, true)
        );
        return recoverSigner(hash, signature);
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
}
