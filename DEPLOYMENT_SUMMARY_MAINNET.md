# Emblem Vault System Mainnet Deployment Summary

## Diamond System

| Contract          | Address                                    | Etherscan Link                                                                  | Gas Used  | Cost (ETH) |
| ----------------- | ------------------------------------------ | ------------------------------------------------------------------------------- | --------- | ---------- |
| Diamond           | 0x12F084DE536F41bcd29Dfc7632Db0261CEC72C60 | [Link](https://etherscan.io/address/0x12F084DE536F41bcd29Dfc7632Db0261CEC72C60) | 407,096   | 0.002427   |
| DiamondCutFacet   | 0x4774d3b39993a6Bf414DF7bA3AF12d229d73fe39 | [Link](https://etherscan.io/address/0x4774d3b39993a6Bf414DF7bA3AF12d229d73fe39) | 857,165   | 0.005167   |
| DiamondLoupeFacet | 0x50197F900Fed0E25Ccfc7Cc0c38354B2193572aB | [Link](https://etherscan.io/address/0x50197F900Fed0E25Ccfc7Cc0c38354B2193572aB) | 744,500   | 0.004480   |
| OwnershipFacet    | 0x9f8c10D32B4db3BEceEA1Fe0B3b91F43ab26d733 | [Link](https://etherscan.io/address/0x9f8c10D32B4db3BEceEA1Fe0B3b91F43ab26d733) | 137,493   | 0.000822   |
| VaultCoreFacet    | 0x07bD2bAA3377098a2F3b4C309914C943b549b0e4 | [Link](https://etherscan.io/address/0x07bD2bAA3377098a2F3b4C309914C943b549b0e4) | 941,617   | 0.005648   |
| ClaimFacet        | 0xF91fCd071DF35C7a5ee1Ee156669e508eC03A16A | [Link](https://etherscan.io/address/0xF91fCd071DF35C7a5ee1Ee156669e508eC03A16A) | 1,143,742 | 0.006735   |
| MintFacet         | 0x6b68035c5512580fBfBE72A3A5B21186D2E120e5 | [Link](https://etherscan.io/address/0x6b68035c5512580fBfBE72A3A5B21186D2E120e5) | 1,298,631 | 0.007805   |
| CollectionFacet   | 0xA1d16625A674EFb4259DFC0e04289b3512609185 | [Link](https://etherscan.io/address/0xA1d16625A674EFb4259DFC0e04289b3512609185) | 890,333   | 0.005279   |
| InitFacet         | 0x11B8d84b94B27dc14f19a519a647fb1BAF79043f | [Link](https://etherscan.io/address/0x11B8d84b94B27dc14f19a519a647fb1BAF79043f) | 607,635   | 0.003674   |

**Total Diamond System:**

- Gas Used: 8,879,280
- Cost: 0.052751 ETH

## Vault Implementations

| Contract                   | Address                                    | Etherscan Link                                                                  | Gas Used  | Cost (ETH) |
| -------------------------- | ------------------------------------------ | ------------------------------------------------------------------------------- | --------- | ---------- |
| ERC721VaultImplementation  | 0x15086dd99D696AA6b0A036424Fb6Ad4923508a94 | [Link](https://etherscan.io/address/0x15086dd99d696aa6b0a036424fb6ad4923508a94) | 2,408,004 | 0.016293   |
| ERC1155VaultImplementation | 0xD35A23C5CFf0fe663F4357218c2B9b104399B659 | [Link](https://etherscan.io/address/0xd35a23c5cff0fe663f4357218c2b9b104399b659) | 2,371,969 | 0.016459   |

**Total Vault Implementations:**

- Gas Used: 4,779,973
- Cost: 0.032752 ETH

## Beacon System

| Contract               | Address                                    | Etherscan Link                                                                  | Gas Used  | Cost (ETH) |
| ---------------------- | ------------------------------------------ | ------------------------------------------------------------------------------- | --------- | ---------- |
| ERC721VaultBeacon      | 0x8977704a454fE2063336324027440d7bc56689AA | [Link](https://etherscan.io/address/0x8977704a454fe2063336324027440d7bc56689aa) | 270,121   | 0.001647   |
| ERC1155VaultBeacon     | 0x2B05d2Ec965E10DB70EEeE8a62FFc39e399601A6 | [Link](https://etherscan.io/address/0x2b05d2ec965e10db70eeee8a62ffc39e399601a6) | 270,206   | 0.001512   |
| VaultCollectionFactory | 0x109De29e0FB4de58A66ce077253E0604D81AD14C | [Link](https://etherscan.io/address/0x109de29e0fb4de58a66ce077253e0604d81ad14c) | 1,140,118 | 0.006669   |

**Total Beacon System:**

- Gas Used: 1,733,131
- Cost: 0.010160 ETH

## Grand Totals

- **Total Gas Used:** 15,392,384
- **Total Cost:** 0.095663 ETH
