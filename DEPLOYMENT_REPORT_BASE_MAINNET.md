# Base Mainnet Deployment Report

## Deployment Commands

```bash
# 1. Deploy Diamond System
forge script DeployDiamondSystem -vvvv --rpc-url base_mainnet --broadcast --verify --slow

# 2. Deploy Vault Implementations
forge script DeployVaultImplementations -vvvv --rpc-url base_mainnet --broadcast --verify --slow

# 3. Deploy Beacon and Factory
forge script DeployBeaconAndFactory -vvvv --rpc-url base_mainnet --broadcast --verify --slow

# 4. Create Priority Collections
forge script CreatePriorityCollections -vvvv --rpc-url base_mainnet --broadcast --verify --slow
```

## Deployed Contracts

### Core Diamond System

- Diamond: `0x12F084DE536F41bcd29Dfc7632Db0261CEC72C60`
- DiamondCutFacet: `0x4774d3b39993a6Bf414DF7bA3AF12d229d73fe39`
- DiamondLoupeFacet: `0x50197F900Fed0E25Ccfc7Cc0c38354B2193572aB`
- OwnershipFacet: `0x9f8c10D32B4db3BEceEA1Fe0B3b91F43ab26d733`

### Vault Facets

- VaultCoreFacet: `0x07bD2bAA3377098a2F3b4C309914C943b549b0e4`
- UnvaultFacet: `0xF91fCd071DF35C7a5ee1Ee156669e508eC03A16A`
- MintFacet: `0x6b68035c5512580fBfBE72A3A5B21186D2E120e5`
- CollectionFacet: `0xA1d16625A674EFb4259DFC0e04289b3512609185`
- InitFacet: `0x11B8d84b94B27dc14f19a519a647fb1BAF79043f`

## Gas Summary

- Total Gas Used: 9,771,309
- Average Gas Price: 0.002040347 gwei
- Total Cost: 0.00001993545172422 ETH

## Transaction Hashes

### Diamond System Deployment

1. DiamondCutFacet: `0x1d2e177c45765ecab25e6a54fcb899545a51e1c27c56edbab545e6353c762113`
2. DiamondLoupeFacet: `0x13c1ea05620b8d212b6a95c990a407270f2293218fe4a772b05eca281498a391`
3. OwnershipFacet: `0xfd7ecadb723d4c8ea6faa08ebbf2ee2efa08cd21cf9565fab314c5ba623c2ae4`
4. VaultCoreFacet: `0x955d3b42f245bf5d24cba9a69eb8a4c87b5713ac206f584b1042a85acf8b5eb6`
5. UnvaultFacet: `0x7bb9c8529f0fdc2ddbdcb0a27eda561e2266abc1565a1be58288ad1edfbbb54a`
6. MintFacet: `0x26920bb99d471967e33874997fd65b32791b8406b69b48c2b08c1c24183103af`
7. CollectionFacet: `0xf7e7d05464ff49f250c263c4afdae17cdee8248e8a724c8efdd592caeb5c83d9`
8. InitFacet: `0x01d3f4376889e0eca9d2aea62932ae4f0306de46b419630b1c0517d12010abbd`
9. Diamond: `0x027458cc0c9bb1171d1d2614f701cc7f40a7b9d67afb3ea702211a0c43a6e991`
10. Diamond Cut: `0x9284eb1ff7031de0952311eb1e28981d31e8b578bf86d4c328aeec39ef203b4c`
11. Diamond Initialize: `0xdd100107961a7146e5266a99b982f0539a8cd4ecb00e002c42a1a1d293a1ab0e`

## Vault Implementation Addresses

### ERC721 Implementation

- Address: `0x15086dd99D696AA6b0A036424Fb6Ad4923508a94`
- Transaction: `0xf197b7df68c10d73e0ee436acf464ad74e5cab8b459313dbe019ce1b90fd7007`
- Gas Used: 2,435,557
- Gas Price: 0.003420374 gwei
- Cost: 0.000008330515838318 ETH
- Verification: [Verified](https://basescan.org/address/0x15086dd99d696aa6b0a036424fb6ad4923508a94)

### ERC1155 Implementation

- Address: `0xD35A23C5CFf0fe663F4357218c2B9b104399B659`
- Transaction: `0xae3d7143d6485475fe470a8393b215080b58b3058bc533101133e480c66d5515`
- Gas Used: 2,371,969
- Gas Price: 0.003420395 gwei
- Cost: 0.000008113070907755 ETH
- Verification: [Verified](https://basescan.org/address/0xd35a23c5cff0fe663f4357218c2b9b104399b659)

## Beacon System Addresses

### Beacons

- ERC721 Beacon: `0x8977704a454fE2063336324027440d7bc56689AA`

  - Transaction: `0xfd0cd022ec110d270cfb86ad828204c7486812a53a0ff98436af708fc75aafea`
  - Gas Used: 270,218
  - Gas Price: 0.003491356 gwei
  - Cost: 0.000000943427235608 ETH
  - Verification: [Verified](https://basescan.org/address/0x8977704a454fe2063336324027440d7bc56689aa)

- ERC1155 Beacon: `0x2B05d2Ec965E10DB70EEeE8a62FFc39e399601A6`
  - Transaction: `0xcf67d95398fe8d7d6f72fcf1c1021cc1e5692c3a3ee9b861c580ba8b9ea1d3e3`
  - Gas Used: 270,230
  - Gas Price: 0.003491356 gwei
  - Cost: 0.00000094346913188 ETH
  - Verification: [Verified](https://basescan.org/address/0x2b05d2ec965e10db70eeee8a62ffc39e399601a6)

### Factory

- Collection Factory: `0x109De29e0FB4de58A66ce077253E0604D81AD14C`
  - Transaction: `0xe220c7e4c84e6a960f182c9e321f5363794f9d3b9071fb6b8b1a0a17dc18a5cc`
  - Gas Used: 1,140,118
  - Gas Price: 0.003503406 gwei
  - Cost: 0.000003994296241908 ETH
  - Verification: [Verified](https://basescan.org/address/0x109de29e0fb4de58a66ce077253e0604d81ad14c)

## System Connections

- Factory connected to Diamond: ✅ `0x12F084DE536F41bcd29Dfc7632Db0261CEC72C60`
- Factory set in Diamond's CollectionFacet: ✅ Confirmed
- Beacons using verified implementations: ✅ Confirmed

## Priority Collections

### ERC1155 Collections

- Rare Pepe: `0xAfE0130Bad95763A66871e1F2fd73B8e7ee18037`

  - Transaction: `0x3253219e35633bae24eb20a67da520ab4d2ca3846e2d9a436524cd1a8e4ff312`
  - URI: `https://v2.emblemvault.io/v3/meta/0xAfE0130Bad95763A66871e1F2fd73B8e7ee18037/`
  - URI Set: `0x6a206aa7a06f4ade6a57b19e93a71b555504a5d31095c8b46ec2075ad1ce413d`

- Spells of Genesis: `0xAAA86841631DbA89F0841655a679F12b768E2FB8`

  - Transaction: `0x6e9a504e3d894e7328f739ceeec2fd731a9ebd21c6d67e2a45601a6aa9e0e57a`
  - URI: `https://v2.emblemvault.io/v3/meta/0xAAA86841631DbA89F0841655a679F12b768E2FB8/`
  - URI Set: `0x562a17a0c8eba5600bc538d811b4b34e055f5fcc309c3ccec2e8a1ad9d936ca5`

- Fake Rares: `0x6b31E7c15B0db1Fab86F4BE94d5D8cBC27BFF98b`
  - Transaction: `0xd9733c17ae5a0b467bbc293b1291aa3dcce0d0d870aa3bbad1eee94dda7bf511`
  - URI: `https://v2.emblemvault.io/v3/meta/0x6b31E7c15B0db1Fab86F4BE94d5D8cBC27BFF98b/`
  - URI Set: `0x1a0e604836e5574a844657f26f144083efc5097051beab0af54ffbaea88bbd83`

### ERC721A Collections

- EmBells: `0xC9eB32bC9D7162d8Ce3B9b1955cecEdfDda3AfCf`

  - Transaction: `0x637f407ad3bd0e85299b04fe14cba5a229bd14a7f1a0b07a9588b747b69cf020`
  - Base URI: `https://v2.emblemvault.io/v3/meta/0xC9eB32bC9D7162d8Ce3B9b1955cecEdfDda3AfCf/`
  - URI Set: `0xd8fdb65f5a2b223b064e8b333023738a403a14d7c932feb33dafc3a1ff81af31`

- Emblem Open: `0x8CB5Ac17520ba1aeFBccF632576283c7d8CbA816`
  - Transaction: `0x38353f08fecae61cd7b5686b4bc16411702f10d4418bc564b7e9087ebd82b44c`
  - Base URI: `https://v2.emblemvault.io/v3/meta/0x8CB5Ac17520ba1aeFBccF632576283c7d8CbA816/`
  - URI Set: `0x7344c8107b5da807746d1d831db2cb7bfa7971d0c50c2eb469a32b7ff8f05b3a`

## Initialization Details

- Owner: `0xa99526E4Dc81b85C1d248Ca974Eadce81837eCF1`
- Metadata Base URI: `https://v2.emblemvault.io/meta/`
- Bypass State: Disabled
- Unvaulting: Enabled
- Supported Interfaces: ERC1155, ERC20, ERC721A

## Verification Status

All Diamond System contracts have been verified on Base mainnet explorer:

- DiamondCutFacet: [Verified](https://basescan.org/address/0x4774d3b39993a6bf414df7ba3af12d229d73fe39)
- DiamondLoupeFacet: [Verified](https://basescan.org/address/0x50197f900fed0e25ccfc7cc0c38354b2193572ab)
- OwnershipFacet: [Verified](https://basescan.org/address/0x9f8c10d32b4db3beceea1fe0b3b91f43ab26d733)
- VaultCoreFacet: [Verified](https://basescan.org/address/0x07bd2baa3377098a2f3b4c309914c943b549b0e4)
- UnvaultFacet: [Verified](https://basescan.org/address/0xf91fcd071df35c7a5ee1ee156669e508ec03a16a)
- MintFacet: [Verified](https://basescan.org/address/0x6b68035c5512580fbfbe72a3a5b21186d2e120e5)
- CollectionFacet: [Verified](https://basescan.org/address/0xa1d16625a674efb4259dfc0e04289b3512609185)
- InitFacet: [Verified](https://basescan.org/address/0x11b8d84b94b27dc14f19a519a647fb1baf79043f)
- Diamond: [Verified](https://basescan.org/address/0x12f084de536f41bcd29dfc7632db0261cec72c60)
