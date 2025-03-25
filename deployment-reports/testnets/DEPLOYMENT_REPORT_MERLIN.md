# Merlin Testnet Deployment Report

## Deployment Commands

```bash
# Deploy Diamond System
forge script DeployDiamondSystem -vvvv --rpc-url merlin_testnet --verifier blockscout --verifier-url https://scan.merlinchain.io/api/ --legacy --broadcast

# Deploy Vault Implementations
forge script DeployVaultImplementations -vvvv --rpc-url merlin_testnet --verifier blockscout --verifier-url https://scan.merlinchain.io/api/ --legacy --broadcast
```

--verifier-url https://testnet-scan.merlinchain.io/api/

## Deployed Contracts

### Core Diamond System

- Diamond: [`0x12f084de536f41bcd29dfc7632db0261cec72c60`](https://scan.merlinchain.io/address/0x12f084de536f41bcd29dfc7632db0261cec72c60) ✅
- DiamondCutFacet: [`0x4774d3b39993a6Bf414DF7bA3AF12d229d73fe39`](https://scan.merlinchain.io/address/0x4774d3b39993a6Bf414DF7bA3AF12d229d73fe39) ✅
- DiamondLoupeFacet: [`0x50197f900fed0e25ccfc7cc0c38354b2193572ab`](https://scan.merlinchain.io/address/0x50197f900fed0e25ccfc7cc0c38354b2193572ab) ✅
- OwnershipFacet: [`0x9f8c10d32b4db3beceea1fe0b3b91f43ab26d733`](https://scan.merlinchain.io/address/0x9f8c10d32b4db3beceea1fe0b3b91f43ab26d733) ✅

### Vault Facets

- VaultCoreFacet: [`0x07bd2baa3377098a2f3b4c309914c943b549b0e4`](https://scan.merlinchain.io/address/0x07bd2baa3377098a2f3b4c309914c943b549b0e4) ✅
- UnvaultFacet: [`0xf91fcd071df35c7a5ee1ee156669e508ec03a16a`](https://scan.merlinchain.io/address/0xf91fcd071df35c7a5ee1ee156669e508ec03a16a) ✅
- MintFacet: [`0x6b68035c5512580fbfbe72a3a5b21186d2e120e5`](https://scan.merlinchain.io/address/0x6b68035c5512580fbfbe72a3a5b21186d2e120e5) ✅
- CollectionFacet: [`0xa1d16625a674efb4259dfc0e04289b3512609185`](https://scan.merlinchain.io/address/0xa1d16625a674efb4259dfc0e04289b3512609185) ✅
- InitFacet: [`0x11b8d84b94b27dc14f19a519a647fb1baf79043f`](https://scan.merlinchain.io/address/0x11b8d84b94b27dc14f19a519a647fb1baf79043f) ✅

## Transaction Hashes

1. DiamondCutFacet: `0x756a0a2c5a31366b6fb42b4afb8bceb46c79ca389bd9beb61ca85b4b1c91a0d8`
2. DiamondLoupeFacet: `0xf0cc8e4fb3e5e270661da6987fcd3ba21673bd909ec8fd92a036782a54b5cf87`
3. OwnershipFacet: `0x5b29970da95902d3c5388ce17901c7db9f14f7d3aab9ccb677f668f56a3597f3`
4. VaultCoreFacet: `0x9e88b1dc40a4b2783dc103cc1ef2d58b5390ab87b9dd9117d96f0114ea9ae226`
5. UnvaultFacet: `0xebe36bc615217bcf8d2c9e711bedf05849ad33331de1f15de5571f02bc8caa83`
6. MintFacet: `0x327144ae4c7d86d007319fef0d9ae2a0072c5da27829c1a0f1403002e89045d8`
7. CollectionFacet: `0xdcb25341c8b3e0ce49e112902fbaac6f0b35d9adaf7fd0062156cc9ea6dfac06`
8. InitFacet: `0x4ef97e67a55ce01c1e13939ab2ec79bd40971aa36afd2138ed9190e10fc1234e`
9. Diamond: `0xd7f1ade007ccd0e2e5dec4e3c5a993583f582e7227b27cf6d758a525388a238e`
10. Diamond Cut: `0xf996cac1c5fee94563474fd5c632aa4378635eda083104d4c5b359c4a02e1cea`
11. Diamond Initialize: `0x7a6198aa7ee7f7611b6fbee22147694f00ada6438d342d40da1f25c75e951335`

## Vault Implementation Addresses

### ERC721 Implementation

- Address: [`0x15086dd99D696AA6b0A036424Fb6Ad4923508a94`](https://scan.merlinchain.io/address/0x15086dd99D696AA6b0A036424Fb6Ad4923508a94) ✅

### ERC1155 Implementation

- Address: [`0xD35A23C5CFf0fe663F4357218c2B9b104399B659`](https://scan.merlinchain.io/address/0xD35A23C5CFf0fe663F4357218c2B9b104399B659) ✅

## Initialization Details

- Owner: `0xa99526E4Dc81b85C1d248Ca974Eadce81837eCF1`
- Metadata Base URI: `https://v2.emblemvault.io/meta/`
- Bypass State: Disabled
- Unvaulting: Enabled
- Supported Interfaces: ERC1155, ERC20, ERC721A

## Next Steps

The following deployments are pending (waiting for testnet tokens):

1. Deploy Beacon System (ERC721 & ERC1155 Beacons)
2. Deploy Collection Factory
3. Connect Factory to Diamond
4. Deploy Priority Collections
