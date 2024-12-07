// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../libraries/LibDiamond.sol";
import "../libraries/LibEmblemVaultStorage.sol";
import "../interfaces/IERC165.sol";
import "../interfaces/IERC721.sol";
import "../interfaces/IERC1155.sol";

interface IERC20Token {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

interface IClaimed {
    function isClaimed(address _nftAddress, uint256 tokenId, bytes32[] memory proof) external view returns (bool);
    function claim(address _nftAddress, uint256 tokenId, address claimer) external;
}

interface IIsSerialized {
    function getFirstSerialByOwner(address owner, uint256 tokenId) external view returns (uint256);
    function getTokenIdForSerialNumber(uint256 serialNumber) external view returns (uint256);
    function getOwnerOfSerial(uint256 serialNumber) external view returns (address);
    function isOverloadSerial() external view returns (bool);
}

contract EmblemVaultClaimFacet {
    event TokenClaimed(address indexed nftAddress, uint256 indexed tokenId, address indexed claimer);
    event TokenClaimedWithPrice(
        address indexed nftAddress, uint256 indexed tokenId, address indexed claimer, uint256 price
    );

    function claim(address _nftAddress, uint256 tokenId) external {
        LibEmblemVaultStorage.nonReentrantBefore();
        require(!LibEmblemVaultStorage.isVaultLocked(_nftAddress, tokenId), "EmblemVaultClaimFacet: Vault is locked");
        require(burnRouter(_nftAddress, tokenId, true), "EmblemVaultClaimFacet: Burn failed");
        emit TokenClaimed(_nftAddress, tokenId, msg.sender);
        LibEmblemVaultStorage.nonReentrantAfter();
    }

    function claimWithSignedPrice(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _nonce,
        address _payment,
        uint256 _price,
        bytes calldata _signature
    ) external payable {
        LibEmblemVaultStorage.nonReentrantBefore();
        LibEmblemVaultStorage.enforceNotUsedNonce(_nonce);

        address signer;
        if (LibEmblemVaultStorage.isVaultLocked(_nftAddress, _tokenId)) {
            signer = getAddressFromSignatureLocked(
                _nftAddress, _payment, _price, msg.sender, _tokenId, _nonce, 1, _signature
            );
        } else {
            signer = getAddressFromSignature(_nftAddress, _payment, _price, msg.sender, _tokenId, _nonce, 1, _signature);
        }

        LibEmblemVaultStorage.enforceIsWitness(signer);
        LibEmblemVaultStorage.VaultStorage storage vs = LibEmblemVaultStorage.vaultStorage();

        if (_payment == address(0)) {
            require(msg.value == _price, "EmblemVaultClaimFacet: Incorrect ETH amount sent");
            payable(vs.recipientAddress).transfer(_price);
        } else {
            IERC20Token paymentToken = IERC20Token(_payment);
            require(
                paymentToken.transferFrom(msg.sender, vs.recipientAddress, _price),
                "EmblemVaultClaimFacet: Transfer failed"
            );
        }

        // Unlock vault because server signed it
        LibEmblemVaultStorage.unlockVault(_nftAddress, _tokenId);
        require(burnRouter(_nftAddress, _tokenId, true), "EmblemVaultClaimFacet: Burn failed");

        LibEmblemVaultStorage.setUsedNonce(_nonce);
        emit TokenClaimedWithPrice(_nftAddress, _tokenId, msg.sender, _price);
        LibEmblemVaultStorage.nonReentrantAfter();
    }

    function burnRouter(address _nftAddress, uint256 tokenId, bool shouldClaim) internal returns (bool) {
        LibEmblemVaultStorage.VaultStorage storage vs = LibEmblemVaultStorage.vaultStorage();
        IClaimed claimer = IClaimed(vs.registeredOfType[6][0]);
        bytes32[] memory proof;

        if (IERC165(_nftAddress).supportsInterface(vs.INTERFACE_ID_ERC1155)) {
            IIsSerialized serialized = IIsSerialized(_nftAddress);
            uint256 serialNumber = serialized.getFirstSerialByOwner(address(this), tokenId);
            require(
                serialized.getTokenIdForSerialNumber(serialNumber) == tokenId,
                "EmblemVaultClaimFacet: Invalid tokenId serialnumber combination"
            );
            require(
                serialized.getOwnerOfSerial(serialNumber) == address(this), "EmblemVaultClaimFacet: Not owned by vault"
            );
            require(!claimer.isClaimed(_nftAddress, serialNumber, proof), "EmblemVaultClaimFacet: Already Claimed");
            IERC1155(_nftAddress).burn(address(this), tokenId, 1);
            if (shouldClaim) {
                claimer.claim(_nftAddress, serialNumber, msg.sender);
            }
        } else {
            if (IERC165(_nftAddress).supportsInterface(vs.INTERFACE_ID_ERC721A)) {
                IERC721A token = IERC721A(_nftAddress);
                uint256 internalTokenId = token.getInternalTokenId(tokenId);
                require(
                    !claimer.isClaimed(_nftAddress, internalTokenId, proof), "EmblemVaultClaimFacet: Already Claimed"
                );
                require(token.ownerOf(internalTokenId) == address(this), "EmblemVaultClaimFacet: Not owned by vault");
                token.burn(internalTokenId);
            } else {
                require(!claimer.isClaimed(_nftAddress, tokenId, proof), "EmblemVaultClaimFacet: Already Claimed");
                IERC721 token = IERC721(_nftAddress);
                require(token.ownerOf(tokenId) == address(this), "EmblemVaultClaimFacet: Not owned by vault");
                token.burn(tokenId);
            }
            if (shouldClaim) {
                claimer.claim(_nftAddress, tokenId, msg.sender);
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
        bytes calldata signature
    ) internal pure returns (address) {
        bytes32 hash = keccak256(abi.encodePacked(_nftAddress, _payment, _price, _to, _tokenId, _nonce, _amount));
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
        bytes32 hash = keccak256(abi.encodePacked(_nftAddress, _payment, _price, _to, _tokenId, _nonce, _amount, true));
        return recoverSigner(hash, signature);
    }

    function recoverSigner(bytes32 hash, bytes memory sig) internal pure returns (address) {
        require(sig.length == 65, "EmblemVaultClaimFacet: Invalid signature length");

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

        require(v == 27 || v == 28, "EmblemVaultClaimFacet: Invalid signature version");

        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, hash));
        return ecrecover(prefixedHash, v, r, s);
    }
}

interface IERC721A {
    function getInternalTokenId(uint256 tokenId) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function burn(uint256 tokenId) external;
}
