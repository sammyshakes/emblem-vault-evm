/*
███████╗███╗   ███╗██████╗ ██╗     ███████╗███╗   ███╗    ██╗   ██╗ █████╗ ██╗   ██╗██╗  ████████╗
██╔════╝████╗ ████║██╔══██╗██║     ██╔════╝████╗ ████║    ██║   ██║██╔══██╗██║   ██║██║  ╚══██╔══╝
█████╗  ██╔████╔██║██████╔╝██║     █████╗  ██╔████╔██║    ██║   ██║███████║██║   ██║██║     ██║   
██╔══╝  ██║╚██╔╝██║██╔══██╗██║     ██╔══╝  ██║╚██╔╝██║    ╚██╗ ██╔╝██╔══██║██║   ██║██║     ██║   
███████╗██║ ╚═╝ ██║██████╔╝███████╗███████╗██║ ╚═╝ ██║     ╚████╔╝ ██║  ██║╚██████╔╝███████╗██║   
╚══════╝╚═╝     ╚═╝╚═════╝ ╚══════╝╚══════╝╚═╝     ╚═╝      ╚═══╝  ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝   
██╗   ██╗███╗   ██╗██╗   ██╗ █████╗ ██╗   ██╗██╗  ████████╗
██║   ██║████╗  ██║██║   ██║██╔══██╗██║   ██║██║  ╚══██╔══╝
██║   ██║██╔██╗ ██║██║   ██║███████║██║   ██║██║     ██║   
██║   ██║██║╚██╗██║╚██╗ ██╔╝██╔══██║██║   ██║██║     ██║   
╚██████╔╝██║ ╚████║ ╚████╔╝ ██║  ██║╚██████╔╝███████╗██║   
 ╚═════╝ ╚═╝  ╚═══╝  ╚═══╝  ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝
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

/// @title EmblemVaultUnvaultFacet
/// @notice Facet for handling vault unvaulting and burns
/// @dev Manages the unvaulting process for vaults with support for various token standards
contract EmblemVaultUnvaultFacet {
    // Constants for gas optimization
    uint256 public constant MAX_BATCH_SIZE = 45; // Maximum batch size to stay under 4M gas

    /// @notice Get the unvault facet version
    /// @return The version string
    function getUnvaultVersion() external pure returns (string memory) {
        return "0.1.0";
    }

    // Events
    event TokenUnvaulted(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed unvaulter,
        uint256 serialNumber,
        bytes data
    );
    event TokenUnvaultedWithPrice(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed unvaulter,
        uint256 price,
        uint256 serialNumber,
        bytes data
    );
    event UnvaultingEnabled(bool enabled);
    event BurnAddressUpdated(address indexed addr, bool isBurn);

    /// @notice Parameters required for batch unvaulting operations
    /// @dev This struct encapsulates all necessary data for batch unvaulting
    struct BatchUnvaultParams {
        address[] nftAddresses;
        uint256[] tokenIds;
        uint256[] nonces;
        address[] payments;
        uint256[] prices;
        bytes[] signatures;
    }

    modifier onlyValidCollection(address collection) {
        LibEmblemVaultStorage.VaultStorage storage vs = LibEmblemVaultStorage.vaultStorage();
        LibErrors.revertIfFactoryNotSet(vs.vaultFactory);
        LibErrors.revertIfInvalidCollection(
            collection, IVaultCollectionFactory(vs.vaultFactory).isCollection(collection)
        );
        _;
    }

    /// @notice Enable or disable unvaulting
    /// @dev Only callable by the contract owner
    /// @param enabled True to enable unvaulting, false to disable
    function setUnvaultingEnabled(bool enabled) external {
        LibDiamond.enforceIsContractOwner();
        LibEmblemVaultStorage.setUnvaultingEnabled(enabled);
        emit UnvaultingEnabled(enabled);
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

    /// @notice Unvaults a token from a vault
    /// @dev Handles the unvaulting process for both ERC721 and ERC1155 tokens
    /// @param _nftAddress The address of the NFT contract
    /// @param tokenId The ID of the token to unvault
    /// @dev Reverts if:
    /// - The collection is invalid
    /// - The vault is locked
    /// - The burn operation fails
    function unvault(address _nftAddress, uint256 tokenId)
        external
        onlyValidCollection(_nftAddress)
    {
        LibEmblemVaultStorage.nonReentrantBefore();

        if (!LibEmblemVaultStorage.vaultStorage().unvaultingEnabled) {
            revert LibEmblemVaultStorage.UnvaultingDisabled();
        }

        LibErrors.revertIfAlreadyLocked(
            _nftAddress, tokenId, LibEmblemVaultStorage.isVaultLocked(_nftAddress, tokenId)
        );

        (bool success, uint256 serialNumber, bytes memory data) =
            burnRouter(_nftAddress, tokenId, true);
        if (!success) revert LibErrors.BurnFailed(_nftAddress, tokenId);

        emit TokenUnvaulted(_nftAddress, tokenId, msg.sender, serialNumber, data);
        LibEmblemVaultStorage.nonReentrantAfter();
    }

    /// @notice Batch unvault tokens using signed prices
    /// @dev Allows users to unvault multiple tokens in a batch using signed prices
    /// @param params BatchUnvaultParams struct containing:
    /// - nftAddresses: Array of NFT contract addresses
    /// - tokenIds: Array of token IDs to unvault
    /// - nonces: Array of unique nonces for the transactions
    /// - payments: Array of payment token addresses (address(0) for ETH)
    /// - prices: Array of prices to pay for each unvault
    /// - signatures: Array of signatures for verification
    function batchUnvaultWithSignedPrice(BatchUnvaultParams calldata params) external payable {
        LibEmblemVaultStorage.nonReentrantBefore();

        // Check batch size limit
        LibErrors.revertIfBatchSizeExceeded(params.tokenIds.length, MAX_BATCH_SIZE);

        // Validate array lengths
        LibErrors.revertIfLengthMismatch(params.tokenIds.length, params.nftAddresses.length);
        LibErrors.revertIfLengthMismatch(params.tokenIds.length, params.nonces.length);
        LibErrors.revertIfLengthMismatch(params.tokenIds.length, params.payments.length);
        LibErrors.revertIfLengthMismatch(params.tokenIds.length, params.prices.length);
        LibErrors.revertIfLengthMismatch(params.tokenIds.length, params.signatures.length);

        uint256 totalEthValue;
        LibEmblemVaultStorage.VaultStorage storage vs = LibEmblemVaultStorage.vaultStorage();

        for (uint256 i = 0; i < params.tokenIds.length; i++) {
            // Validate collection
            LibErrors.revertIfInvalidCollection(
                params.nftAddresses[i],
                IVaultCollectionFactory(vs.vaultFactory).isCollection(params.nftAddresses[i])
            );

            // Verify nonce and signature
            LibEmblemVaultStorage.enforceNotUsedNonce(params.nonces[i]);

            address signer;
            if (LibEmblemVaultStorage.isVaultLocked(params.nftAddresses[i], params.tokenIds[i])) {
                signer = LibSignature.verifyLockedSignature(
                    params.nftAddresses[i],
                    params.payments[i],
                    params.prices[i],
                    msg.sender,
                    params.tokenIds[i],
                    params.nonces[i],
                    1,
                    params.signatures[i],
                    block.chainid
                );
            } else {
                signer = LibSignature.verifyStandardSignature(
                    params.nftAddresses[i],
                    params.payments[i],
                    params.prices[i],
                    msg.sender,
                    params.tokenIds[i],
                    params.nonces[i],
                    1,
                    params.signatures[i],
                    block.chainid
                );
            }

            LibErrors.revertIfNotWitness(signer, vs.witnesses[signer]);

            // Process payment
            if (params.payments[i] == address(0)) {
                totalEthValue += params.prices[i];
            } else {
                IERC20Token(params.payments[i]).transferFrom(
                    msg.sender, vs.recipientAddress, params.prices[i]
                );
            }

            // Execute unvault
            (bool success, uint256 serialNumber, bytes memory data) =
                burnRouter(params.nftAddresses[i], params.tokenIds[i], true);
            if (!success) revert LibErrors.BurnFailed(params.nftAddresses[i], params.tokenIds[i]);

            // Update state
            LibEmblemVaultStorage.unlockVault(params.nftAddresses[i], params.tokenIds[i]);
            LibEmblemVaultStorage.setUsedNonce(params.nonces[i]);
            emit TokenUnvaultedWithPrice(
                params.nftAddresses[i],
                params.tokenIds[i],
                msg.sender,
                params.prices[i],
                serialNumber,
                data
            );
        }

        // Handle ETH payments
        if (totalEthValue > 0) {
            LibErrors.revertIfIncorrectPayment(msg.value, totalEthValue);
            (bool success,) = vs.recipientAddress.call{value: totalEthValue}("");
            if (!success) revert LibErrors.TransferFailed();
        }

        LibEmblemVaultStorage.nonReentrantAfter();
    }

    /// @notice Unvaults a token using a signed price
    /// @dev Allows unvaulting with price verification through signatures
    /// @param _nftAddress The address of the NFT contract
    /// @param _tokenId The ID of the token to unvault
    /// @param _nonce Unique nonce for the transaction
    /// @param _payment The payment token address (address(0) for ETH)
    /// @param _price The price to pay for the unvault
    /// @param _signature The signature for verification
    /// @dev Reverts if:
    /// - The collection is invalid
    /// - The nonce has been used
    /// - The signature is invalid
    /// - The payment transfer fails
    /// - The burn operation fails
    function unvaultWithSignedPrice(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _nonce,
        address _payment,
        uint256 _price,
        bytes calldata _signature
    ) external payable onlyValidCollection(_nftAddress) {
        LibEmblemVaultStorage.nonReentrantBefore();

        if (!LibEmblemVaultStorage.vaultStorage().unvaultingEnabled) {
            revert LibEmblemVaultStorage.UnvaultingDisabled();
        }

        LibEmblemVaultStorage.enforceNotUsedNonce(_nonce);

        address signer;
        if (LibEmblemVaultStorage.isVaultLocked(_nftAddress, _tokenId)) {
            signer = LibSignature.verifyLockedSignature(
                _nftAddress,
                _payment,
                _price,
                msg.sender,
                _tokenId,
                _nonce,
                1,
                _signature,
                block.chainid
            );
        } else {
            signer = LibSignature.verifyStandardSignature(
                _nftAddress,
                _payment,
                _price,
                msg.sender,
                _tokenId,
                _nonce,
                1,
                _signature,
                block.chainid
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
        emit TokenUnvaultedWithPrice(_nftAddress, _tokenId, msg.sender, _price, serialNumber, data);
        LibEmblemVaultStorage.nonReentrantAfter();
    }

    /// @notice Internal function to handle the burn and unvault process
    /// @dev Routes the burn operation based on token standard (ERC721/ERC1155)
    /// @param _nftAddress The address of the NFT contract
    /// @param tokenId The ID of the token to burn
    /// @param shouldUnvault Whether to trigger the unvault process
    /// @return success Whether the burn was successful
    /// @return serialNumber The serial number of the burned token
    /// @return data Additional data from the burn operation
    /// @dev Reverts if:
    /// - The unvaulter contract is not set
    /// - The token is already unvaulted
    /// - The vault doesn't own the token
    function burnRouter(address _nftAddress, uint256 tokenId, bool shouldUnvault)
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
            if (LibEmblemVaultStorage.isUnvaulted(_nftAddress, serialNumber)) {
                revert LibErrors.AlreadyUnvaulted(_nftAddress, serialNumber);
            }

            IERC1155(_nftAddress).burn(msg.sender, tokenId, 1);
            if (shouldUnvault) {
                LibEmblemVaultStorage.setUnvaulted(_nftAddress, serialNumber, msg.sender);
            }
            data = "";
        } else {
            if (LibInterfaceIds.isERC721A(_nftAddress)) {
                IERC721AVault token = IERC721AVault(_nftAddress);
                uint256 internalTokenId = token.getInternalTokenId(tokenId);

                if (LibEmblemVaultStorage.isUnvaulted(_nftAddress, internalTokenId)) {
                    revert LibErrors.AlreadyUnvaulted(_nftAddress, internalTokenId);
                }
                if (token.ownerOf(internalTokenId) != msg.sender) {
                    revert LibErrors.NotVaultOwner(_nftAddress, internalTokenId, msg.sender);
                }

                token.burn(internalTokenId);
                if (shouldUnvault) {
                    LibEmblemVaultStorage.setUnvaulted(_nftAddress, internalTokenId, msg.sender);
                }
                data = "";
                serialNumber = internalTokenId;
            } else {
                if (LibEmblemVaultStorage.isUnvaulted(_nftAddress, tokenId)) {
                    revert LibErrors.AlreadyUnvaulted(_nftAddress, tokenId);
                }
                IERC721 token = IERC721(_nftAddress);
                if (token.ownerOf(tokenId) != msg.sender) {
                    revert LibErrors.NotVaultOwner(_nftAddress, tokenId, msg.sender);
                }
                token.burn(tokenId);
                if (shouldUnvault) {
                    LibEmblemVaultStorage.setUnvaulted(_nftAddress, tokenId, msg.sender);
                }
                serialNumber = tokenId;
                data = "";
            }
        }
        return (true, serialNumber, data);
    }

    /// @notice Check if a token has been unvaulted
    /// @param nft The NFT contract address
    /// @param id The token ID
    /// @return True if the token has been unvaulted
    function isTokenUnvaulted(address nft, uint256 id) external view returns (bool) {
        return LibEmblemVaultStorage.isUnvaulted(nft, id);
    }

    /// @notice Get the address that unvaulted a token
    /// @param nft The NFT contract address
    /// @param id The token ID
    /// @return The address that unvaulted the token
    function getTokenUnvaulter(address nft, uint256 id) external view returns (address) {
        return LibEmblemVaultStorage.getUnvaulter(nft, id);
    }

    /// @notice Get the total number of unvaults for a collection
    /// @param nft The NFT contract address
    /// @return The total number of unvaults
    function getCollectionUnvaultCount(address nft) external view returns (uint256) {
        return LibEmblemVaultStorage.getUnvaultCount(nft);
    }
}
