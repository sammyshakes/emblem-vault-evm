# Arbitrum Sepolia Testnet Deployment Report

## Deployment Command

```bash
forge script DeployDiamondSystem -vvvv --verify --rpc-url arbitrum_testnet --broadcast --slow
```

## Deployed Contracts

### Core Diamond System

- Diamond: [`0xdf6a773182717cE03f675e414cEc5B7Cd7B78818`](https://sepolia.arbiscan.io/address/0xdf6a773182717cE03f675e414cEc5B7Cd7B78818) ✅
- DiamondCutFacet: [`0x76060779BF7164B40A63588C01d0E632B213A726`](https://sepolia.arbiscan.io/address/0x76060779BF7164B40A63588C01d0E632B213A726) ✅
- DiamondLoupeFacet: [`0xc7382E75145d548AE8cfC2ee2CA00C8Db8dFDcE0`](https://sepolia.arbiscan.io/address/0xc7382E75145d548AE8cfC2ee2CA00C8Db8dFDcE0) ✅
- OwnershipFacet: [`0xb1E84323091755162bAe7142B4126A3334B140db`](https://sepolia.arbiscan.io/address/0xb1E84323091755162bAe7142B4126A3334B140db) ✅

### Vault Facets

- VaultCoreFacet: [`0xEB29df0b1E446E29845571cF3Abdd8c27444A1b7`](https://sepolia.arbiscan.io/address/0xEB29df0b1E446E29845571cF3Abdd8c27444A1b7) ✅
- UnvaultFacet: [`0x360A89688b2672A70E298cab74EA48883340fFF6`](https://sepolia.arbiscan.io/address/0x360A89688b2672A70E298cab74EA48883340fFF6) ✅
- MintFacet: [`0x7726fADB63a4148A54Ab9b47979A4C49f028ACC7`](https://sepolia.arbiscan.io/address/0x7726fADB63a4148A54Ab9b47979A4C49f028ACC7) ✅
- CollectionFacet: [`0x5672f3B4cE39126D6FF8080Ac2377f6a2413C6bB`](https://sepolia.arbiscan.io/address/0x5672f3B4cE39126D6FF8080Ac2377f6a2413C6bB) ✅
- InitFacet: [`0x4ac5cB5eE407EDDAB39F01981e329C3ACC7e43C1`](https://sepolia.arbiscan.io/address/0x4ac5cB5eE407EDDAB39F01981e329C3ACC7e43C1) ✅

## Gas Summary

- Total Gas Used: 9,777,621
- Average Gas Price: 0.1 gwei
- Total Cost: 0.0009777621 ETH

## Transaction Hashes

1. DiamondCutFacet: `0xe3973de35e0a717330d386a6b7afca65da867b8ca62ce2ee4ec0e961006428aa`
2. DiamondLoupeFacet: `0x356d0a6d7dbeb26120dae662fcb19c13c0cd3a0156b18c79c291189e03384fe5`
3. OwnershipFacet: `0xf22c88a7b9455f536365736b71b6c3856b2982653748f21c367621c548f5488f`
4. VaultCoreFacet: `0xb181b2d74d2b73e1ff02d421815de7f31bbf9a3c459728781f6d0fbc18bd9b73`
5. UnvaultFacet: `0x107c5f0e074ed4b76d08cb1d90d820a3dc0475c528f7df380d6878e63ef8d758`
6. MintFacet: `0x2305d49271d1842461496878316bdaf8933b0e891c3b64be7229f5e6a20913e7`
7. CollectionFacet: `0xe584057f1d1498dcfcf4796f814db5ffa93487f1c7ace47d82d11dbd3c1d8cf7`
8. InitFacet: `0x027d5070aa188bfc5966512aa1eee13a916c0d31c2a94e14ec56aa51a007fc58`
9. Diamond: `0x4290a80e4140fa3230bc0d2aca9224b77ec39c8dc0d964c1ecb1fc2b24275789`
10. Diamond Cut: `0xe19ea9d2bbb285d61ed00c32d5ab0ccb81144fd13ff3bd8f2b9498b06262ed85`
11. Diamond Initialize: `0x53f7eadebfe2f669cd99fa6b7be07e00b45af3100cb2a4fa8a53672266c6b399`

## Initialization Details

- Owner: `0xa99526E4Dc81b85C1d248Ca974Eadce81837eCF1`
- Metadata Base URI: `https://v2.emblemvault.io/meta/`
- Bypass State: Disabled
- Unvaulting: Enabled
- Supported Interfaces: ERC1155, ERC20, ERC721A

## Vault Implementation Addresses

### ERC721 Implementation

- Address: [`0xCD87972d278D7Ce7A2B83415aF963671cc0b82bA`](https://sepolia.arbiscan.io/address/0xCD87972d278D7Ce7A2B83415aF963671cc0b82bA) ✅

### ERC1155 Implementation

- Address: [`0x3b6f613f16C5b3C696Ba1826bd2d3583258cA76c`](https://sepolia.arbiscan.io/address/0x3b6f613f16C5b3C696Ba1826bd2d3583258cA76c) ✅

## Beacon System Addresses

### Beacons

- ERC721 Beacon: [`0xd2De6b8CBF23CfF0E62e18c9AeFdA12ED0c0cB2D`](https://sepolia.arbiscan.io/address/0xd2De6b8CBF23CfF0E62e18c9AeFdA12ED0c0cB2D) ✅
- ERC1155 Beacon: [`0xF04a4B0CE209aF4017648Fa93D2bB348eCb116d6`](https://sepolia.arbiscan.io/address/0xF04a4B0CE209aF4017648Fa93D2bB348eCb116d6) ✅

### Factory

- Collection Factory: [`0xC59c4B6EA71a610BC7eDF05CBc66bfc2a86A3005`](https://sepolia.arbiscan.io/address/0xC59c4B6EA71a610BC7eDF05CBc66bfc2a86A3005) ✅

## System Connections

- Factory connected to Diamond: `0xdf6a773182717cE03f675e414cEc5B7Cd7B78818`
- Factory set in Diamond's CollectionFacet
- Beacons using verified implementations

## Contract Verification Status

All contracts have been verified on Arbitrum Sepolia Explorer:

- DiamondCutFacet ✅
- DiamondLoupeFacet ✅
- OwnershipFacet ✅
- VaultCoreFacet ✅
- UnvaultFacet ✅
- MintFacet ✅
- CollectionFacet ✅
- InitFacet ✅
- Diamond ✅
- ERC721 Implementation ✅
- ERC1155 Implementation ✅
- ERC721 Beacon ✅
- ERC1155 Beacon ✅
- Collection Factory ✅
