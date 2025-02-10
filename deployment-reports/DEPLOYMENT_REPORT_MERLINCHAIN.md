# MerlinChain Mainnet Deployment Report

## Network Information

- Network Name: MerlinChain
- Chain ID: 4200
- RPC URL: https://merlin.blockpi.network/v1/rpc/public

## Diamond System Addresses

- Diamond Address: `0x12f084de536f41bcd29dfc7632db0261cec72c60`
- Diamond Cut Facet: `0x4774d3b39993a6Bf414DF7bA3AF12d229d73fe39`
- Diamond Loupe Facet: `0x50197f900fed0e25ccfc7cc0c38354b2193572ab`
- Ownership Facet: `0x9f8c10d32b4db3beceea1fe0b3b91f43ab26d733`
- Core Facet: `0x07bd2baa3377098a2f3b4c309914c943b549b0e4`
- Unvault Facet: `0xf91fcd071df35c7a5ee1ee156669e508ec03a16a`
- Mint Facet: `0x6b68035c5512580fbfbe72a3a5b21186d2e120e5`
- Collection Facet: `0xa1d16625a674efb4259dfc0e04289b3512609185`
- Init Facet: `0x11b8d84b94b27dc14f19a519a647fb1baf79043f`

## Implementation Addresses

- ERC721 Implementation: `0x15086dd99d696aa6b0a036424fb6ad4923508a94`
- ERC1155 Implementation: `0xd35a23c5cff0fe663f4357218c2b9b104399b659`

## Beacon System Addresses

- ERC721 Beacon: `0x8977704a454fe2063336324027440d7bc56689aa`
- ERC1155 Beacon: `0x2b05d2ec965e10db70eeee8a62ffc39e399601a6`
- Collection Factory: `0x109de29e0fb4de58a66ce077253e0604d81ad14c`

## Deployment Status

- Initial Diamond System Deployment: ✅ Complete
- Implementation Deployment: ✅ Complete
- Beacon System Deployment: ✅ Complete
- Factory Deployment: ✅ Complete
- Collection Creation: ⏳ Pending

## Verification Status

- Contract verification failed with error: "Too many requests, please try again later."
- Verification needs to be retried using the following commands:

```bash
# Diamond Contract
forge verify-contract --chain-id 4200 --verifier blockscout --verifier-url https://scan.merlinchain.io/api/ 0x12f084de536f41bcd29dfc7632db0261cec72c60 src/EmblemVaultDiamond.sol:EmblemVaultDiamond --constructor-args $(cast abi-encode "constructor(address,address)" 0xa99526e4dc81b85c1d248ca974eadce81837ecf1 0x4774d3b39993a6bf414df7ba3af12d229d73fe39)

# Diamond Cut Facet
forge verify-contract --chain-id 4200 --verifier blockscout --verifier-url https://scan.merlinchain.io/api/ 0x4774d3b39993a6Bf414DF7bA3AF12d229d73fe39 src/facets/DiamondCutFacet.sol:DiamondCutFacet

# Diamond Loupe Facet
forge verify-contract --chain-id 4200 --verifier blockscout --verifier-url https://scan.merlinchain.io/api/ 0x50197f900fed0e25ccfc7cc0c38354b2193572ab src/facets/DiamondLoupeFacet.sol:DiamondLoupeFacet

# Ownership Facet
forge verify-contract --chain-id 4200 --verifier blockscout --verifier-url https://scan.merlinchain.io/api/ 0x9f8c10d32b4db3beceea1fe0b3b91f43ab26d733 src/facets/OwnershipFacet.sol:OwnershipFacet

# Core Facet
forge verify-contract --chain-id 4200 --verifier blockscout --verifier-url https://scan.merlinchain.io/api/ 0x07bd2baa3377098a2f3b4c309914c943b549b0e4 src/facets/EmblemVaultCoreFacet.sol:EmblemVaultCoreFacet

# Unvault Facet
forge verify-contract --chain-id 4200 --verifier blockscout --verifier-url https://scan.merlinchain.io/api/ 0xf91fcd071df35c7a5ee1ee156669e508ec03a16a src/facets/EmblemVaultUnvaultFacet.sol:EmblemVaultUnvaultFacet

# Mint Facet
forge verify-contract --chain-id 4200 --verifier blockscout --verifier-url https://scan.merlinchain.io/api/ 0x6b68035c5512580fbfbe72a3a5b21186d2e120e5 src/facets/EmblemVaultMintFacet.sol:EmblemVaultMintFacet

# Collection Facet
forge verify-contract --chain-id 4200 --verifier blockscout --verifier-url https://scan.merlinchain.io/api/ 0xa1d16625a674efb4259dfc0e04289b3512609185 src/facets/EmblemVaultCollectionFacet.sol:EmblemVaultCollectionFacet

# Init Facet
forge verify-contract --chain-id 4200 --verifier blockscout --verifier-url https://scan.merlinchain.io/api/ 0x11b8d84b94b27dc14f19a519a647fb1baf79043f src/facets/EmblemVaultInitFacet.sol:EmblemVaultInitFacet

# ERC721 Implementation
forge verify-contract --chain-id 4200 --verifier blockscout --verifier-url https://scan.merlinchain.io/api/ 0x15086dd99d696aa6b0a036424fb6ad4923508a94 src/implementations/ERC721VaultImplementation.sol:ERC721VaultImplementation

# ERC1155 Implementation
forge verify-contract --chain-id 4200 --verifier blockscout --verifier-url https://scan.merlinchain.io/api/ 0xd35a23c5cff0fe663f4357218c2b9b104399b659 src/implementations/ERC1155VaultImplementation.sol:ERC1155VaultImplementation

# ERC721 Beacon
forge verify-contract --chain-id 4200 --verifier blockscout --verifier-url https://scan.merlinchain.io/api/ 0x8977704a454fe2063336324027440d7bc56689aa src/beacon/ERC721VaultBeacon.sol:ERC721VaultBeacon --constructor-args $(cast abi-encode "constructor(address)" 0x15086dd99d696aa6b0a036424fb6ad4923508a94)

# ERC1155 Beacon
forge verify-contract --chain-id 4200 --verifier blockscout --verifier-url https://scan.merlinchain.io/api/ 0x2b05d2ec965e10db70eeee8a62ffc39e399601a6 src/beacon/ERC1155VaultBeacon.sol:ERC1155VaultBeacon --constructor-args $(cast abi-encode "constructor(address)" 0xd35a23c5cff0fe663f4357218c2b9b104399b659)

# Collection Factory
forge verify-contract --chain-id 4200 --verifier blockscout --verifier-url https://scan.merlinchain.io/api/ 0x109de29e0fb4de58a66ce077253e0604d81ad14c src/factories/VaultCollectionFactory.sol:VaultCollectionFactory --constructor-args $(cast abi-encode "constructor(address,address,address)" 0x8977704a454fe2063336324027440d7bc56689aa 0x2b05d2ec965e10db70eeee8a62ffc39e399601a6 0x12f084de536f41bcd29dfc7632db0261cec72c60)
```

## Next Steps

1. Retry contract verification with proper rate limiting
   - Add delays between verification attempts (e.g., 30-60 seconds)
   - Verify contracts one at a time
2. Create test collections

## Notes

- Initial deployment of Diamond System completed successfully
- Implementation contracts (ERC721 and ERC1155) deployed successfully
- Beacon System and Factory deployed successfully
- Contract verification needs to be retried due to rate limiting on the Blockscout API
- All facets have been deployed and initialized successfully
