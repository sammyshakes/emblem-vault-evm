# Arbitrum One Mainnet Deployment Report

## Deployment Command

```bash
forge script DeployDiamondSystem -vvvv --verify --rpc-url arbitrum_one --broadcast --slow
```

## Deployed Contracts

### Core Diamond System

- Diamond: [`0x5657a10c1AAe46Ae383342d7516290B4FecD9295`](https://arbiscan.io/address/0x5657a10c1AAe46Ae383342d7516290B4FecD9295) ✅
- DiamondCutFacet: [`0x8977704a454fE2063336324027440d7bc56689AA`](https://arbiscan.io/address/0x8977704a454fE2063336324027440d7bc56689AA) ✅
- DiamondLoupeFacet: [`0x2B05d2Ec965E10DB70EEeE8a62FFc39e399601A6`](https://arbiscan.io/address/0x2B05d2Ec965E10DB70EEeE8a62FFc39e399601A6) ✅
- OwnershipFacet: [`0x109De29e0FB4de58A66ce077253E0604D81AD14C`](https://arbiscan.io/address/0x109De29e0FB4de58A66ce077253E0604D81AD14C) ✅

### Vault Facets

- VaultCoreFacet: [`0x62E48d26d032c56B6566d19Ef419737152008e5d`](https://arbiscan.io/address/0x62E48d26d032c56B6566d19Ef419737152008e5d) ✅
- UnvaultFacet: [`0x9268D229eD40A75B9A2ed44024a765C92626C765`](https://arbiscan.io/address/0x9268D229eD40A75B9A2ed44024a765C92626C765) ✅
- MintFacet: [`0xEE483847aa8E52887A1C5477b8F5b0af28922681`](https://arbiscan.io/address/0xEE483847aa8E52887A1C5477b8F5b0af28922681) ✅
- CollectionFacet: [`0xA137e2d3DeC0874512C8A71E7Ab176b6FaCB165d`](https://arbiscan.io/address/0xA137e2d3DeC0874512C8A71E7Ab176b6FaCB165d) ✅
- InitFacet: [`0x79B66cf2f6b90f2Ee837c7eB41163F7725B56B25`](https://arbiscan.io/address/0x79B66cf2f6b90f2Ee837c7eB41163F7725B56B25) ✅

### Vault Implementations

- ERC721VaultImplementation: [`0xb1E84323091755162bAe7142B4126A3334B140db`](https://arbiscan.io/address/0xb1E84323091755162bAe7142B4126A3334B140db)

  - Transaction: `0x26c383ebd527da23d3974cf2d3dae732ccd88920faaca35a682f382048bf1da6`
  - Block: 305759938
  - Gas Used: 2,617,347 gas (0.00002617347 ETH @ 0.01 gwei)

- ERC1155VaultImplementation: [`0xEB29df0b1E446E29845571cF3Abdd8c27444A1b7`](https://arbiscan.io/address/0xEB29df0b1E446E29845571cF3Abdd8c27444A1b7)
  - Transaction: `0x15660f9906c81ba47f50f6073b9339b2c148fd2c832701c4eb13a0a391576da8`
  - Block: 305759943
  - Gas Used: 2,552,649 gas (0.00002552649 ETH @ 0.01 gwei)

### Beacon System

- ERC721VaultBeacon: [`0x360A89688b2672A70E298cab74EA48883340fFF6`](https://arbiscan.io/address/0x360A89688b2672A70E298cab74EA48883340fFF6)

  - Transaction: `0xc58a1c74705baeaa75379d64becf7d01ce38cfc7c697ca01c3831f154c0b6b81`
  - Block: 305760786
  - Gas Used: 296,931 gas (0.00000296931 ETH @ 0.01 gwei)

- ERC1155VaultBeacon: [`0x7726fADB63a4148A54Ab9b47979A4C49f028ACC7`](https://arbiscan.io/address/0x7726fADB63a4148A54Ab9b47979A4C49f028ACC7)

  - Transaction: `0xd9deea6920c6e2226d249c776c50b311cee123278e48ab6551dd9e76319e48d5`
  - Block: 305760790
  - Gas Used: 297,118 gas (0.00000297118 ETH @ 0.01 gwei)

- VaultCollectionFactory: [`0x5672f3B4cE39126D6FF8080Ac2377f6a2413C6bB`](https://arbiscan.io/address/0x5672f3B4cE39126D6FF8080Ac2377f6a2413C6bB)
  - Transaction: `0x423c88e80cd443de6608a59900783f2e07179917e7722e4a62cbddd144ccc804`
  - Block: 305760794
  - Gas Used: 1,220,842 gas (0.00001220842 ETH @ 0.01 gwei)

### Priority Collections

#### ERC1155 Collections

1. Rare Pepe Collection

   - Address: [`0xC4f75736c494b05ee55a66537b60fC3eB2F10E33`](https://arbiscan.io/address/0xC4f75736c494b05ee55a66537b60fC3eB2F10E33)
   - Symbol: PEPE
   - URI: https://v2.emblemvault.io/v3/meta/0xC4f75736c494b05ee55a66537b60fC3eB2F10E33/

2. Spells of Genesis Collection

   - Address: [`0x6372B17cE84Ecf3Ba8f70a420A2ecddf6e52E8aA`](https://arbiscan.io/address/0x6372B17cE84Ecf3Ba8f70a420A2ecddf6e52E8aA)
   - Symbol: SOG
   - URI: https://v2.emblemvault.io/v3/meta/0x6372B17cE84Ecf3Ba8f70a420A2ecddf6e52E8aA/

3. Fake Rares Collection
   - Address: [`0x907CAEE2D12ED9f5f093BF8aCa907a9Ca9d54ec5`](https://arbiscan.io/address/0x907CAEE2D12ED9f5f093BF8aCa907a9Ca9d54ec5)
   - Symbol: FAKE
   - URI: https://v2.emblemvault.io/v3/meta/0x907CAEE2D12ED9f5f093BF8aCa907a9Ca9d54ec5/

#### ERC721A Collections

4. EmBells Collection

   - Address: [`0x01D3e79Fc2518d15EB02Fcd7Dd61Fd003E133ea3`](https://arbiscan.io/address/0x01D3e79Fc2518d15EB02Fcd7Dd61Fd003E133ea3)
   - Symbol: BELL
   - Base URI: https://v2.emblemvault.io/v3/meta/0x01D3e79Fc2518d15EB02Fcd7Dd61Fd003E133ea3/

5. Emblem Open Collection
   - Address: [`0x53f74639688DC71D0071367CEF0daa10DEff77e3`](https://arbiscan.io/address/0x53f74639688DC71D0071367CEF0daa10DEff77e3)
   - Symbol: OPEN
   - Base URI: https://v2.emblemvault.io/v3/meta/0x53f74639688DC71D0071367CEF0daa10DEff77e3/

## Gas Summary

- Average Gas Price: 0.01 gwei
- Total Gas Used: 12,426,885 (successful deployments)
- Total Cost: 0.00012426885 ETH

## Transaction Hashes

1. DiamondCutFacet: `0xee67ab1f2ec2303bc0e31312ac8a4dd73fe19eec40eb42382ded2e6730147d44`
2. DiamondLoupeFacet: `0xcc5a72f87503decbe7964765c9d4b77bbea98aaa6064c4671fd9abdc0ffa557e`
3. OwnershipFacet: `0x8f5668f2e2b27157665bc7af7e11b14fb647beb053d31c6a99516959cf722b75`
4. VaultCoreFacet: `0xb9e66d16cd8ac5e8a9103c208f7d983bece99152d0ff8b5d26c0389521d902be`
5. UnvaultFacet: `0x216b965623bb618040066ccbb19947cbabfbbe5dcf9e62a567f206ec53003653`
6. MintFacet: `0x27e4b539c62ea08c1a6e7a3cc2bd2ffccf3e9546ab5afd90491c0f184a81f8ed`
7. CollectionFacet: `0x2567c36185054d9a59175e6dd8ad5d23c7ce8699ed4362c13ee4a076a13a2066`
8. InitFacet: `0xfec8c9ed981f78149446d593edfca0b1d0a17f1db9cde86c415f1a4a3a84ebde`
9. Diamond: `0xed7306006294bd72270814d7b56d73b987a38c277c1b045c015d984a65366022`
10. ERC721VaultImplementation: `0x26c383ebd527da23d3974cf2d3dae732ccd88920faaca35a682f382048bf1da6`
11. ERC1155VaultImplementation: `0x15660f9906c81ba47f50f6073b9339b2c148fd2c832701c4eb13a0a391576da8`
12. ERC721VaultBeacon: `0xc58a1c74705baeaa75379d64becf7d01ce38cfc7c697ca01c3831f154c0b6b81`
13. ERC1155VaultBeacon: `0xd9deea6920c6e2226d249c776c50b311cee123278e48ab6551dd9e76319e48d5`
14. VaultCollectionFactory: `0x423c88e80cd443de6608a59900783f2e07179917e7722e4a62cbddd144ccc804`

## Initialization Details

- Owner: `0xa99526E4Dc81b85C1d248Ca974Eadce81837eCF1`
- Metadata Base URI: `https://v2.emblemvault.io/meta/`
- Bypass State: Disabled
- Unvaulting: Enabled
- Supported Interfaces: ERC1155, ERC20, ERC721A

## Contract Verification Status

All contracts verified successfully.
