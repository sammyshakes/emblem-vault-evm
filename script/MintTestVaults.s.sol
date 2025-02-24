// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/facets/EmblemVaultMintFacet.sol";
import "../src/libraries/LibSignature.sol";

/**
 * @title MintTestVaults
 * @notice Script to mint test vaults with mock signatures
 * @dev Run with:
 * For empty vault:
 * forge script script/MintTestVaults.s.sol:MintTestVaults --rpc-url fuji -vvvv --broadcast \
 * --sig "mintEmptyVault(address,uint256)" <collection_address> <token_id>
 *
 * For vault with ERC20:
 * forge script script/MintTestVaults.s.sol:MintTestVaults --rpc-url fuji -vvvv --broadcast \
 * --sig "mintERC20Vault(address,uint256,address,uint256)" <collection_address> <token_id> <erc20_token> <amount>
 *
 * For vault with ERC721:
 * forge script script/MintTestVaults.s.sol:MintTestVaults --rpc-url fuji -vvvv --broadcast \
 * --sig "mintERC721Vault(address,uint256,address,uint256)" <collection_address> <token_id> <erc721_token> <nft_id>
 */
contract MintTestVaults is Script {
    // Vault content structure
    struct VaultContent {
        address tokenAddress;
        uint256 tokenId;
        uint256 amount;
        bytes data;
    }

    function mintEmptyVault(address collection, uint256 tokenId) external {
        // Empty vault data (just number of tokens = 0)
        bytes memory vaultData = abi.encode(uint256(0));
        _mintVault(collection, tokenId, vaultData);
    }

    function mintERC20Vault(address collection, uint256 tokenId, address erc20Token, uint256 amount)
        external
    {
        VaultContent[] memory contents = new VaultContent[](1);
        contents[0] = VaultContent({
            tokenAddress: erc20Token,
            tokenId: 0, // Not used for ERC20
            amount: amount,
            data: "" // No additional data for ERC20
        });

        bytes memory vaultData = _encodeVaultContents(contents);
        _mintVault(collection, tokenId, vaultData);
    }

    function mintERC721Vault(
        address collection,
        uint256 tokenId,
        address erc721Token,
        uint256 nftId
    ) external {
        VaultContent[] memory contents = new VaultContent[](1);
        contents[0] = VaultContent({
            tokenAddress: erc721Token,
            tokenId: nftId,
            amount: 1, // Always 1 for ERC721
            data: "" // No additional data for ERC721
        });

        bytes memory vaultData = _encodeVaultContents(contents);
        _mintVault(collection, tokenId, vaultData);
    }

    function mintERC1155Vault(
        address collection,
        uint256 tokenId,
        address erc1155Token,
        uint256 nftId,
        uint256 amount
    ) external {
        VaultContent[] memory contents = new VaultContent[](1);
        contents[0] = VaultContent({
            tokenAddress: erc1155Token,
            tokenId: nftId,
            amount: amount,
            data: "" // No additional data for ERC1155
        });

        bytes memory vaultData = _encodeVaultContents(contents);
        _mintVault(collection, tokenId, vaultData);
    }

    function mintMultiTokenVault(
        address collection,
        uint256 tokenId,
        VaultContent[] calldata contents
    ) external {
        bytes memory vaultData = _encodeVaultContents(contents);
        _mintVault(collection, tokenId, vaultData);
    }

    function _encodeVaultContents(VaultContent[] memory contents)
        internal
        pure
        returns (bytes memory)
    {
        // First encode number of tokens
        bytes memory encoded = abi.encode(contents.length);

        // Then encode each token's data
        for (uint256 i = 0; i < contents.length; i++) {
            encoded = bytes.concat(
                encoded,
                abi.encode(
                    contents[i].tokenAddress,
                    contents[i].tokenId,
                    contents[i].amount,
                    contents[i].data.length
                ),
                contents[i].data
            );
        }

        return encoded;
    }

    function _mintVault(address collection, uint256 tokenId, bytes memory vaultData) internal {
        // Get deployment private key and diamond address
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        address diamond = vm.envAddress("DIAMOND_ADDRESS");

        console.log("\nMinting Vault");
        console.log("Collection:", collection);
        console.log("Token ID:", tokenId);
        console.log("Diamond:", diamond);
        console.log("Minter:", deployer);
        console.log("Vault Data Length:", vaultData.length);

        vm.startBroadcast(deployerPrivateKey);

        // Create mock signature parameters
        uint256 nonce = block.timestamp; // Use timestamp as nonce for testing
        uint256 price = 0; // Free for testing
        address to = deployer; // Mint to deployer
        uint256 amount = 1; // One vault
        uint256[] memory serialNumbers = new uint256[](0); // Empty array for non-ERC1155

        // Create mock signature
        bytes memory signature = _createMockSignature(
            collection,
            address(0), // ETH payment
            price,
            to,
            tokenId,
            nonce,
            amount,
            serialNumbers,
            deployerPrivateKey
        );

        // Mint vault through Diamond
        EmblemVaultMintFacet(diamond).buyWithSignedPrice(
            collection, // NFT address
            address(0), // Payment token (ETH)
            price, // Price
            to, // Recipient
            tokenId, // Token ID
            nonce, // Nonce
            signature, // Signature
            serialNumbers, // Empty serial numbers array
            amount // Amount (1 for ERC721)
        );

        vm.stopBroadcast();

        console.log("\nVault Minting Complete");
        console.log("--------------------------------");
        console.log("Collection:", collection);
        console.log("Token ID:", tokenId);
        console.log("Owner:", to);
        console.log("Vault Data Length:", vaultData.length);
    }

    function _createMockSignature(
        address nftAddress,
        address payment,
        uint256 price,
        address to,
        uint256 tokenId,
        uint256 nonce,
        uint256 amount,
        uint256[] memory serialNumbers,
        uint256 signerKey
    ) internal view returns (bytes memory) {
        // Create message hash using LibSignature
        bytes32 messageHash = LibSignature.getStandardSignatureHash(
            nftAddress, payment, price, to, tokenId, nonce, amount, serialNumbers, block.chainid
        );

        // Sign message hash
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerKey, messageHash);

        // Combine v, r, s into signature
        return abi.encodePacked(r, s, v);
    }
}
