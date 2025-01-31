# Base Sepolia Testnet Deployment Report

## Deployment Command

```bash
forge script DeployDiamondSystem -vvvv --rpc-url base_testnet --broadcast --verify --slow
```

## Deployed Contracts

### Core Diamond System

- Diamond: [`0xA137e2d3DeC0874512C8A71E7Ab176b6FaCB165d`](https://sepolia.basescan.org/address/0xa137e2d3dec0874512c8a71e7ab176b6facb165d) ✅
- DiamondCutFacet: [`0x15086dd99D696AA6b0A036424Fb6Ad4923508a94`](https://sepolia.basescan.org/address/0x15086dd99d696aa6b0a036424fb6ad4923508a94) ✅
- DiamondLoupeFacet: [`0xD35A23C5CFf0fe663F4357218c2B9b104399B659`](https://sepolia.basescan.org/address/0xd35a23c5cff0fe663f4357218c2b9b104399b659) ✅
- OwnershipFacet: [`0x8977704a454fE2063336324027440d7bc56689AA`](https://sepolia.basescan.org/address/0x8977704a454fe2063336324027440d7bc56689aa) ✅

### Vault Facets

- VaultCoreFacet: [`0x2B05d2Ec965E10DB70EEeE8a62FFc39e399601A6`](https://sepolia.basescan.org/address/0x2b05d2ec965e10db70eeee8a62ffc39e399601a6) ✅
- UnvaultFacet: [`0x109De29e0FB4de58A66ce077253E0604D81AD14C`](https://sepolia.basescan.org/address/0x109de29e0fb4de58a66ce077253e0604d81ad14c) ✅
- MintFacet: [`0x62E48d26d032c56B6566d19Ef419737152008e5d`](https://sepolia.basescan.org/address/0x62e48d26d032c56b6566d19ef419737152008e5d) ✅
- CollectionFacet: [`0x9268D229eD40A75B9A2ed44024a765C92626C765`](https://sepolia.basescan.org/address/0x9268d229ed40a75b9a2ed44024a765c92626c765) ✅
- InitFacet: [`0xEE483847aa8E52887A1C5477b8F5b0af28922681`](https://sepolia.basescan.org/address/0xee483847aa8e52887a1c5477b8f5b0af28922681) ✅

## Gas Summary

- Total Gas Used: 9,771,297
- Average Gas Price: 0.0750406 gwei
- Total Cost: 0.00073207240643319 ETH

## Transaction Hashes

1. DiamondCutFacet: `0x13b3e100409a1ee34b743c8332bc059d0af10c5335d41557f841b96e1155ff7e`
2. DiamondLoupeFacet: `0x5d6452b22ebbd777a382fc03ff685d393a3825b0082a9c2efba416d7ca601068`
3. OwnershipFacet: `0xedd80a4fa66001059f8c5b34dccc159ba3f48e1d8b3ff9cc249b5af1229d5aa0`
4. VaultCoreFacet: `0xfd808ff8c87c26542a3ba70023c7a69d72a7bf66eb9a61f38781ae3d3377009a`
5. UnvaultFacet: `0x7eaa8038e9489d867381daa26716acd4d7cf73ee57c2039af78892e79eb451a6`
6. MintFacet: `0xb4296f87a6c80134b6deee31df45da746c953e9fb5426c97beedd3e6edb612ca`
7. CollectionFacet: `0x81d22a33c63b77236ae318fc6f3fd8175fef318337a593ab04849e404f4fc939`
8. InitFacet: `0x84566d04bc83af067a01e97bd1d006b1dcaa6b7105517da2d358e4027c0330fd`
9. Diamond: `0xbe76a39f1eb2a54dd2952647b0dd9d36f1e7feb06a576cfdfd8ca841d4be1b5c`
10. Diamond Cut: `0xf3a2e7aaed468b20949018622a91f6b47ba4deaaac28899d52a66caca663fe40`
11. Diamond Initialize: `0xb56a3dfb0b150af2e60fd0f7052bf9ad22a37d5321b61125bce4b19c1702dfe1`

## Vault Implementation Addresses

### ERC721 Implementation

- Address: [`0x76060779BF7164B40A63588C01d0E632B213A726`](https://sepolia.basescan.org/address/0x76060779bf7164b40a63588c01d0e632b213a726) ✅

### ERC1155 Implementation

- Address: [`0xc7382E75145d548AE8cfC2ee2CA00C8Db8dFDcE0`](https://sepolia.basescan.org/address/0xc7382e75145d548ae8cfc2ee2ca00c8db8dfdce0) ✅

## Beacon System Addresses

### Beacons

- ERC721 Beacon: [`0xb1E84323091755162bAe7142B4126A3334B140db`](https://sepolia.basescan.org/address/0xb1e84323091755162bae7142b4126a3334b140db) ✅
- ERC1155 Beacon: [`0xEB29df0b1E446E29845571cF3Abdd8c27444A1b7`](https://sepolia.basescan.org/address/0xeb29df0b1e446e29845571cf3abdd8c27444a1b7) ✅

### Factory

- Collection Factory: [`0x360A89688b2672A70E298cab74EA48883340fFF6`](https://sepolia.basescan.org/address/0x360a89688b2672a70e298cab74ea48883340fff6) ✅

## System Connections

- Factory connected to Diamond: `0xA137e2d3DeC0874512C8A71E7Ab176b6FaCB165d`
- Factory set in Diamond's CollectionFacet
- Beacons using verified implementations

## Priority Collections

### ERC1155 Collections

- Rare Pepe: [`0x40aCeDfCF6fcCBdBA73F8236fb1A33408a675550`](https://sepolia.basescan.org/address/0x40acedfcf6fccbdba73f8236fb1a33408a675550) ✅

  - URI: `https://v2.emblemvault.io/v3/meta/0x40aCeDfCF6fcCBdBA73F8236fb1A33408a675550/`

- Spells of Genesis: [`0xF28bc496815a024bef5D291cf8B1241117Ac6e32`](https://sepolia.basescan.org/address/0xf28bc496815a024bef5d291cf8b1241117ac6e32) ✅

  - URI: `https://v2.emblemvault.io/v3/meta/0xF28bc496815a024bef5D291cf8B1241117Ac6e32/`

- Fake Rares: [`0xFD372d4020FAE488fE5cB84b3164646fC7718152`](https://sepolia.basescan.org/address/0xfd372d4020fae488fe5cb84b3164646fc7718152) ✅
  - URI: `https://v2.emblemvault.io/v3/meta/0xFD372d4020FAE488fE5cB84b3164646fC7718152/`

### ERC721A Collections

- EmBells: [`0x66C32d2A780b98D400Da5E9Aebb9801b679530A2`](https://sepolia.basescan.org/address/0x66c32d2a780b98d400da5e9aebb9801b679530a2) ✅

  - Base URI: `https://v2.emblemvault.io/v3/meta/0x66C32d2A780b98D400Da5E9Aebb9801b679530A2/`

- Emblem Open: [`0x3d988621D3C36D065d4849AeE7464609FC7cb532`](https://sepolia.basescan.org/address/0x3d988621d3c36d065d4849aee7464609fc7cb532) ✅
  - Base URI: `https://v2.emblemvault.io/v3/meta/0x3d988621D3C36D065d4849AeE7464609FC7cb532/`

## Initialization Details

- Owner: `0xa99526E4Dc81b85C1d248Ca974Eadce81837eCF1`
- Metadata Base URI: `https://v2.emblemvault.io/meta/`
- Bypass State: Disabled
- Unvaulting: Enabled
- Supported Interfaces: ERC1155, ERC20, ERC721A
