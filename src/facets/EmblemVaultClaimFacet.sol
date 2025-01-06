/*
███████╗███╗   ███╗██████╗ ██╗     ███████╗███╗   ███╗    ██╗   ██╗ █████╗ ██╗   ██╗██╗  ████████╗
██╔════╝████╗ ████║██╔══██╗██║     ██╔════╝████╗ ████║    ██║   ██║██╔══██╗██║   ██║██║  ╚══██╔══╝
█████╗  ██╔████╔██║██████╔╝██║     █████╗  ██╔████╔██║    ██║   ██║███████║██║   ██║██║     ██║   
██╔══╝  ██║╚██╔╝██║██╔══██╗██║     ██╔══╝  ██║╚██╔╝██║    ╚██╗ ██╔╝██╔══██║██║   ██║██║     ██║   
███████╗██║ ╚═╝ ██║██████╔╝███████╗███████╗██║ ╚═╝ ██║     ╚████╔╝ ██║  ██║╚██████╔╝███████╗██║   
╚══════╝╚═╝     ╚═╝╚═════╝ ╚══════╝╚══════╝╚═╝     ╚═╝      ╚═══╝  ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝   
 ██████╗██╗      █████╗ ██╗███╗   ███╗
██╔════╝██║     ██╔══██╗██║████╗ ████║
██║     ██║     ███████║██║██╔████╔██║
██║     ██║     ██╔══██║██║██║╚██╔╝██║
╚██████╗███████╗██║  ██║██║██║ ╚═╝ ██║
 ╚═════╝╚══════╝╚═╝  ╚═╝╚═╝╚═╝     ╚═╝
*/

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
import "../interfaces/IERC721AVault.sol";
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
    event ClaimingEnabled(bool enabled);
    event BurnAddressUpdated(address indexed addr, bool isBurn);

    modifier onlyValidCollection(address collection) {
        LibEmblemVaultStorage.VaultStorage storage vs = LibEmblemVaultStorage.vaultStorage();
        LibErrors.revertIfFactoryNotSet(vs.vaultFactory);
        LibErrors.revertIfInvalidCollection(
            collection, IVaultCollectionFactory(vs.vaultFactory).isCollection(collection)
        );
        _;
    }

    /// @notice Enable or disable claiming
    /// @dev Only callable by the contract owner
    /// @param enabled True to enable claiming, false to disable
    function setClaimingEnabled(bool enabled) external {
        LibDiamond.enforceIsContractOwner();
        LibEmblemVaultStorage.setClaimingEnabled(enabled);
        emit ClaimingEnabled(enabled);
    }

    /// @notice Add or remove a burn address
    /// @dev Only callable by the contract owner
    /// @param addr The address to update
    /// @param isBurn True to mark as burn address, false to unmark
    function setBurnAddress(address addr, bool isBurn) external {
        LibDiamond.enforceIsContractOwner();
        LibEmblemVaultStorage.setBurnAddress(addr, isBurn);
        emit BurnAddressUpdated(addr, isBurn);
    }

    /// @notice Claims a token from a vault
    /// @dev Handles the claiming process for both ERC721 and ERC1155 tokens
    /// @param _nftAddress The address of the NFT contract
    /// @param tokenId The ID of the token to claim
    /// @dev Reverts if:
    /// - The collection is invalid
    /// - The vault is locked
    /// - The burn operation fails
    function claim(address _nftAddress, uint256 tokenId)
        external
        onlyValidCollection(_nftAddress)
    {
        LibEmblemVaultStorage.nonReentrantBefore();

        if (!LibEmblemVaultStorage.vaultStorage().claimingEnabled) {
            revert LibEmblemVaultStorage.ClaimingDisabled();
        }

        LibErrors.revertIfAlreadyLocked(
            _nftAddress, tokenId, LibEmblemVaultStorage.isVaultLocked(_nftAddress, tokenId)
        );

        (bool success, uint256 serialNumber, bytes memory data) =
            burnRouter(_nftAddress, tokenId, true);
        if (!success) revert LibErrors.BurnFailed(_nftAddress, tokenId);

        emit TokenClaimed(_nftAddress, tokenId, msg.sender, serialNumber, data);
        LibEmblemVaultStorage.nonReentrantAfter();
    }

    /// @notice Claims a token using a signed price
    /// @dev Allows claiming with price verification through signatures
    /// @param _nftAddress The address of the NFT contract
    /// @param _tokenId The ID of the token to claim
    /// @param _nonce Unique nonce for the transaction
    /// @param _payment The payment token address (address(0) for ETH)
    /// @param _price The price to pay for the claim
    /// @param _signature The signature for verification
    /// @dev Reverts if:
    /// - The collection is invalid
    /// - The nonce has been used
    /// - The signature is invalid
    /// - The payment transfer fails
    /// - The burn operation fails
    function claimWithSignedPrice(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _nonce,
        address _payment,
        uint256 _price,
        bytes calldata _signature
    ) external payable onlyValidCollection(_nftAddress) {
        LibEmblemVaultStorage.nonReentrantBefore();

        if (!LibEmblemVaultStorage.vaultStorage().claimingEnabled) {
            revert LibEmblemVaultStorage.ClaimingDisabled();
        }

        LibEmblemVaultStorage.enforceNotUsedNonce(_nonce);

        address signer;
        if (LibEmblemVaultStorage.isVaultLocked(_nftAddress, _tokenId)) {
            signer = LibSignature.verifyLockedSignature(
                _nftAddress, _payment, _price, msg.sender, _tokenId, _nonce, 1, _signature
            );
        } else {
            signer = LibSignature.verifyStandardSignature(
                _nftAddress, _payment, _price, msg.sender, _tokenId, _nonce, 1, _signature
            );
        }

        LibEmblemVaultStorage.VaultStorage storage vs = LibEmblemVaultStorage.vaultStorage();
        LibErrors.revertIfNotWitness(signer, vs.witnesses[signer]);

        if (_payment == address(0)) {
            LibErrors.revertIfIncorrectPayment(msg.value, _price);
            (bool _success,) = vs.recipientAddress.call{value: _price}("");
            if (!_success) revert LibErrors.TransferFailed();
        } else {
            if (!IERC20Token(_payment).transferFrom(msg.sender, vs.recipientAddress, _price)) {
                revert LibErrors.TransferFailed();
            }
        }

        (bool success, uint256 serialNumber, bytes memory data) =
            burnRouter(_nftAddress, _tokenId, true);
        if (!success) revert LibErrors.BurnFailed(_nftAddress, _tokenId);

        // Unlock vault only after successful burn
        LibEmblemVaultStorage.unlockVault(_nftAddress, _tokenId);

        LibEmblemVaultStorage.setUsedNonce(_nonce);
        emit TokenClaimedWithPrice(_nftAddress, _tokenId, msg.sender, _price, serialNumber, data);
        LibEmblemVaultStorage.nonReentrantAfter();
    }

    /// @notice Internal function to handle the burn and claim process
    /// @dev Routes the burn operation based on token standard (ERC721/ERC1155)
    /// @param _nftAddress The address of the NFT contract
    /// @param tokenId The ID of the token to burn
    /// @param shouldClaim Whether to trigger the claim process
    /// @return success Whether the burn was successful
    /// @return serialNumber The serial number of the burned token
    /// @return data Additional data from the burn operation
    /// @dev Reverts if:
    /// - The claimer contract is not set
    /// - The token is already claimed
    /// - The vault doesn't own the token
    function burnRouter(address _nftAddress, uint256 tokenId, bool shouldClaim)
        internal
        returns (bool success, uint256 serialNumber, bytes memory data)
    {
        if (LibInterfaceIds.isERC1155(_nftAddress)) {
            IIsSerialized serialized = IIsSerialized(_nftAddress);
            serialNumber = serialized.getFirstSerialByOwner(msg.sender, tokenId);

            if (serialized.getTokenIdForSerialNumber(serialNumber) != tokenId) {
                revert LibErrors.InvalidTokenId(tokenId);
            }
            if (serialized.getOwnerOfSerial(serialNumber) != msg.sender) {
                revert LibErrors.NotVaultOwner(_nftAddress, tokenId, msg.sender);
            }
            if (LibEmblemVaultStorage.isClaimed(_nftAddress, serialNumber)) {
                revert LibErrors.AlreadyClaimed(_nftAddress, serialNumber);
            }

            IERC1155(_nftAddress).burn(msg.sender, tokenId, 1);
            if (shouldClaim) {
                LibEmblemVaultStorage.setClaimed(_nftAddress, serialNumber, msg.sender);
            }
            data = "";
        } else {
            if (LibInterfaceIds.isERC721A(_nftAddress)) {
                IERC721AVault token = IERC721AVault(_nftAddress);
                uint256 internalTokenId = token.getInternalTokenId(tokenId);

                if (LibEmblemVaultStorage.isClaimed(_nftAddress, internalTokenId)) {
                    revert LibErrors.AlreadyClaimed(_nftAddress, internalTokenId);
                }
                if (token.ownerOf(internalTokenId) != msg.sender) {
                    revert LibErrors.NotVaultOwner(_nftAddress, internalTokenId, msg.sender);
                }

                token.burn(internalTokenId);
                if (shouldClaim) {
                    LibEmblemVaultStorage.setClaimed(_nftAddress, internalTokenId, msg.sender);
                }
                data = "";
                serialNumber = internalTokenId;
            } else {
                if (LibEmblemVaultStorage.isClaimed(_nftAddress, tokenId)) {
                    revert LibErrors.AlreadyClaimed(_nftAddress, tokenId);
                }
                IERC721 token = IERC721(_nftAddress);
                if (token.ownerOf(tokenId) != msg.sender) {
                    revert LibErrors.NotVaultOwner(_nftAddress, tokenId, msg.sender);
                }
                token.burn(tokenId);
                if (shouldClaim) {
                    LibEmblemVaultStorage.setClaimed(_nftAddress, tokenId, msg.sender);
                }
                serialNumber = tokenId;
                data = "";
            }
        }
        return (true, serialNumber, data);
    }

    /// @notice Check if a token has been claimed
    /// @param nft The NFT contract address
    /// @param id The token ID
    /// @return True if the token has been claimed
    function isTokenClaimed(address nft, uint256 id) external view returns (bool) {
        return LibEmblemVaultStorage.isClaimed(nft, id);
    }

    /// @notice Get the address that claimed a token
    /// @param nft The NFT contract address
    /// @param id The token ID
    /// @return The address that claimed the token
    function getTokenClaimer(address nft, uint256 id) external view returns (address) {
        return LibEmblemVaultStorage.getClaimer(nft, id);
    }

    /// @notice Get the total number of claims for a collection
    /// @param nft The NFT contract address
    /// @return The total number of claims
    function getCollectionClaimCount(address nft) external view returns (uint256) {
        return LibEmblemVaultStorage.getClaimCount(nft);
    }
}
