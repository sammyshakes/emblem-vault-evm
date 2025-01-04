// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/facets/EmblemVaultMintFacet.sol";

contract TestMint is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address diamond = vm.envAddress("DIAMOND_ADDRESS");

        // Data from API response
        address nftAddress = vm.parseAddress("0x184ddb67E2EF517f6754F055b56905f2A9b29b6A");
        address payment = vm.parseAddress("0x3d658390460295fb963f54dc0899cfb1c30776df");
        uint256 price = 0x1264db42952cac; // From API _price.hex
        address to = vm.parseAddress("0x16AC7b1598329D95e6C6C6372B12b6E0FB51c96c");
        uint256 tokenId = 1_868_251_361_100_521;
        uint256 nonce = 464_805; // From API _nonce
        bytes memory signature =
            hex"db56b45ddb22211fb59f3bc3e6e4169ce84b315455f269aa7fda57758a4a1fde79a819314a157f3bf5e58a80d49846957c8c7d8a87be678a3c955b702e8db6331b";
        bytes memory serialNumber =
            hex"0000000000000000000000000000000000000000000000000000000000000000";
        uint256 amount = 1;

        vm.startBroadcast(deployerPrivateKey);

        // Call buyWithSignedPrice on the diamond
        // Use payment token from API for signature verification
        EmblemVaultMintFacet(diamond).buyWithSignedPrice{value: price}(
            nftAddress,
            payment, // Use payment token from API
            price,
            to,
            tokenId,
            nonce,
            signature,
            serialNumber,
            amount
        );

        vm.stopBroadcast();
    }
}
