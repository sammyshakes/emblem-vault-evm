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

    modifier onlyValidCollection(address collection) {
        LibEmblemVaultStorage.VaultStorage storage vs = LibEmblemVaultStorage.vaultStorage();
        LibErrors.revertIfFactoryNotSet(vs.vaultFactory);
        LibErrors.revertIfInvalidCollection(
            collection, IVaultCollectionFactory(vs.vaultFactory).isCollection(collection)
        );
        _;
    }

    /// @notice Sets the claimer contract address
    /// @dev Only callable by the contract owner. Updates the contract used for handling claims
    /// @param _claimer The address of the new claimer contract
    /// @dev Reverts if the provided address is zero
    function setClaimerContract(address _claimer) external {
        LibDiamond.enforceIsContractOwner();
        LibErrors.revertIfZeroAddress(_claimer);

        LibEmblemVaultStorage.VaultStorage storage vs = LibEmblemVaultStorage.vaultStorage();
        address oldClaimer = vs.claimerContract;
        LibEmblemVaultStorage.setClaimerContract(_claimer);

        emit ClaimerContractUpdated(oldClaimer, _claimer);
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

        // Unlock vault because server signed it
        LibEmblemVaultStorage.unlockVault(_nftAddress, _tokenId);

        (bool success, uint256 serialNumber, bytes memory data) =
            burnRouter(_nftAddress, _tokenId, true);
        if (!success) revert LibErrors.BurnFailed(_nftAddress, _tokenId);

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
        LibEmblemVaultStorage.VaultStorage storage vs = LibEmblemVaultStorage.vaultStorage();
        if (vs.claimerContract == address(0)) revert LibErrors.ClaimerNotSet();

        IClaimed claimer = IClaimed(vs.claimerContract);
        bytes32[] memory proof;

        if (LibInterfaceIds.isERC1155(_nftAddress)) {
            IIsSerialized serialized = IIsSerialized(_nftAddress);
            serialNumber = serialized.getFirstSerialByOwner(address(this), tokenId);

            if (serialized.getTokenIdForSerialNumber(serialNumber) != tokenId) {
                revert LibErrors.InvalidTokenId(tokenId);
            }
            if (serialized.getOwnerOfSerial(serialNumber) != address(this)) {
                revert LibErrors.NotVaultOwner(_nftAddress, tokenId, address(this));
            }
            if (claimer.isClaimed(_nftAddress, serialNumber, proof)) {
                revert LibErrors.AlreadyClaimed(_nftAddress, serialNumber);
            }

            IERC1155(_nftAddress).burn(address(this), tokenId, 1);
            if (shouldClaim) {
                claimer.claim(_nftAddress, serialNumber, msg.sender);
            }
            data = "";
        } else {
            if (LibInterfaceIds.isERC721A(_nftAddress)) {
                IERC721AVault token = IERC721AVault(_nftAddress);
                uint256 internalTokenId = token.getInternalTokenId(tokenId);

                if (claimer.isClaimed(_nftAddress, internalTokenId, proof)) {
                    revert LibErrors.AlreadyClaimed(_nftAddress, internalTokenId);
                }
                if (token.ownerOf(internalTokenId) != address(this)) {
                    revert LibErrors.NotVaultOwner(_nftAddress, internalTokenId, address(this));
                }

                token.burn(internalTokenId);
                data = "";
                serialNumber = internalTokenId;
            } else {
                if (claimer.isClaimed(_nftAddress, tokenId, proof)) {
                    revert LibErrors.AlreadyClaimed(_nftAddress, tokenId);
                }
                IERC721 token = IERC721(_nftAddress);
                if (token.ownerOf(tokenId) != address(this)) {
                    revert LibErrors.NotVaultOwner(_nftAddress, tokenId, address(this));
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

    /// @notice Returns the version of this facet
    /// @return version The version string
    function version() external pure returns (string memory) {
        return "1";
    }
}
