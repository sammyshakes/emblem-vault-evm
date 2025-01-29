# Apechain Curtis Testnet Deployment Report

Network: Apechain Curtis Testnet
Chain ID: 33111
RPC URL: https://curtis.rpc.caldera.xyz/http
Explorer: https://curtis.explorer.caldera.xyz/

## Diamond System Deployment

Deployment Date: January 27, 2025

### Core Contracts

1. Diamond Contract
   - Address: `0xc7241F821DbA320Ebe611c65bdc17f71d5907f12`
   - Transaction: https://curtis.explorer.caldera.xyz/tx/0xf7223cad1a74df73b9552b2effdbe8a2f960b7050806581dbfc22fe6181658be
   - Verified: ✅

### Facets

1. DiamondCutFacet

   - Address: `0xB35a45aa3040297c6Cbb04EcB5123974EfEDD1aB`
   - Transaction: https://curtis.explorer.caldera.xyz/tx/0x9b05404f9aade266304efd4dda4c99a1d7a5912a097a0d1d69d8335b753f299f
   - Verified: ✅

2. DiamondLoupeFacet

   - Address: `0xCa9892288E1157c3FeDAC180149866691a37458C`
   - Transaction: https://curtis.explorer.caldera.xyz/tx/0x355125596a88ac5b8b0d8cfd0d615cc2d7b90d0cc47edfa08e6602e55ce6c71f
   - Verification Failed

3. OwnershipFacet

   - Address: `0xeEa4194F3f12D31D2CC7260ddbe41296339968ff`
   - Transaction: https://curtis.explorer.caldera.xyz/tx/0x826caf914093b90dbfa32217e7e8034ac9eea680db5ed3f630be542ef34fcfc6
   - Verification Failed

4. VaultCoreFacet

   - Address: `0x191eE872C022F34BBF5da245EbB8674175c9f83E`
   - Transaction: https://curtis.explorer.caldera.xyz/tx/0x9b378c1d5c4fdd27b32da97521fc664d00083846ad5816991066f30f4dd9174d
   - Verification Failed

5. UnvaultFacet

   - Address: `0xD85B74a55D06634561553795d0eDea5ca523ca58`
   - Transaction: https://curtis.explorer.caldera.xyz/tx/0x71d691dd8d5d511ead1a69ea920c16647a8f89767734b0bc0536c793335ae303
   - Verified: ✅

6. MintFacet

   - Address: `0x7D6cd100e6Fd4Eb456b7837493790Cc34ff072e4`
   - Transaction: https://curtis.explorer.caldera.xyz/tx/0x636408a9dc8314e15dfb3320367b2d4c2228a2399bca358b4080f606d3b71020
   - Verification Failed

7. CollectionFacet

   - Address: `0x2E428D2fe37Aa70f8d19139fB25C1e3f0d56058b`
   - Transaction: https://curtis.explorer.caldera.xyz/tx/0x1225102ac707f6fcbbfe2e1c32d6086c6331707cf0e9f8a7a74078966cac6156
   - Verified: ✅

8. InitFacet
   - Address: `0x038A0b83F013106f8436191Ad7BeADd8Ec59347C`
   - Transaction: https://curtis.explorer.caldera.xyz/tx/0x8b7987955f4fdc495221b7852a7b592281c6aa45319ccf32a9c9119d930eae69
   - Verified: ✅

### Diamond Initialization

- Transaction: https://curtis.explorer.caldera.xyz/tx/0x1e344ec86651c74977b7358d5b1fc6e60381e79334de1cb03c85edfcb59ec540

### Gas Usage Summary

Total Gas Used: 9,758,108
Average Gas Price: 0.01 gwei
Total Cost: 0.00009758108 ETH

### Deployment Notes

- All core functionality deployed successfully
- Some contract verifications failed but contracts are operational
- Diamond initialized with default configuration

## Vault Implementations Deployment

Deployment Date: January 27, 2025

1. ERC721A Implementation

   - Address: `0x9EDB3D6D15F7a18832981115F8889b5d1C91aB28`
   - Transaction: https://curtis.explorer.caldera.xyz/tx/0x8391a47d31cbd83b8837c90444a6f38078ae6660a67b02bc593fb36affccdc5b
   - Verification Failed

2. ERC1155 Implementation
   - Address: `0x499374687048E68Dc7aE35966B4e0FBa5e17C77B`
   - Transaction: https://curtis.explorer.caldera.xyz/tx/0x794a61e8e2664c5a0a3c45a7ae011a6ab16e8c97d1eaa6f9848512cd68fc6ce8
   - Verified: ✅

### Gas Usage

Total Gas Used: 4,807,526
Average Gas Price: 0.01 gwei
Total Cost: 0.00004807526 ETH

## Beacon System Deployment

Deployment Date: January 27, 2025

1. ERC721 Beacon

   - Address: `0x49cb84d93C8A80f0Ee639002D318f043B53a6FcA`
   - Transaction: https://curtis.explorer.caldera.xyz/tx/0x11120633ab270a5546d3a0097d9ce40e530d307175b7b540b15a1ce5f70a0ca0
   - Verification Failed
   - Implementation: 0x9EDB3D6D15F7a18832981115F8889b5d1C91aB28

2. ERC1155 Beacon

   - Address: `0x704BC33f34fb696405BB4074a770D284097AfC75`
   - Transaction: https://curtis.explorer.caldera.xyz/tx/0xee2e062af977f58657231884b7ee58d9cb81e1ae79b23f0b9687bf8e707a0a74
   - Verified: ✅
   - Implementation: 0x499374687048E68Dc7aE35966B4e0FBa5e17C77B

3. Collection Factory
   - Address: `0x8aAa7EA37638C1C4466804434bE2e4dA02774AcC`
   - Transaction: https://curtis.explorer.caldera.xyz/tx/0xc015f3e7d19119ba6d7fead5bfb7fa4c157e609815831e0df61e73f93f8ac847
   - Verified: ✅
   - Factory Set in Diamond: https://curtis.explorer.caldera.xyz/tx/0x55df0e2d6d368b80bdd993786b5609e76010f69541910c785c8711d91543cfbe

### Gas Usage

Total Gas Used: 1,733,274
Average Gas Price: 0.01 gwei
Total Cost: 0.00001733274 ETH

### System Components Status

- [x] Diamond Contract
- [x] ERC721A Implementation
- [x] ERC1155 Implementation
- [x] Beacon Contract
- [x] Factory Contract

## Next Steps

- Create and Configure Collections
- Deploy Priority Collections:
  1. Rare Pepe (ERC1155)
  2. Spells of Genesis (ERC1155)
  3. Fake Rares (ERC1155)
  4. EmBells (ERC721A)
  5. Emblem Open (ERC721A)

## Issues and Resolutions

- Some contract verifications failed, but this is a known issue with the explorer's verification system
- All contracts are deployed and functional despite verification status
