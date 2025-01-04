# Emblem Vault System Mainnet Deployment Report

Ethereum Mainnet Deployment - Chain ID: 1

## Deployment Environment

### Tools & Versions

- Foundry Framework
  - Forge: Used for contract compilation and deployment
  - Cast: Used for contract interaction
- Solidity Version: 0.8.28
- Node Version: Latest LTS

### Scripts Used

- `DeployDiamondSystem.s.sol`: Diamond system deployment
- `DeployVaultImplementations.s.sol`: Implementation contracts deployment
- `DeployBeaconAndFactory.s.sol`: Beacon system and factory deployment

### Deployment Parameters

- Network: Ethereum Mainnet
- Chain ID: 1
- Deployer Address: 0xa99526E4Dc81b85C1d248Ca974Eadce81837eCF1

## Deployment Steps

### Step 1: Diamond System Deployment ✅

1. Dry Run:

```bash
forge script script/DeployDiamondSystem.s.sol:DeployDiamondSystem --rpc-url mainnet
```

2. Actual Deployment:

```bash
forge script script/DeployDiamondSystem.s.sol:DeployDiamondSystem --rpc-url mainnet --broadcast --verify --slow -vvvv
```

After successful deployment, update .env with:

```env
DIAMOND_ADDRESS=0x12F084DE536F41bcd29Dfc7632Db0261CEC72C60
DIAMOND_CUT_FACET=0x4774d3b39993a6Bf414DF7bA3AF12d229d73fe39
DIAMOND_LOUPE_FACET=0x50197F900Fed0E25Ccfc7Cc0c38354B2193572aB
OWNERSHIP_FACET=0x9f8c10D32B4db3BEceEA1Fe0B3b91F43ab26d733
CORE_FACET=0x07bD2bAA3377098a2F3b4C309914C943b549b0e4
CLAIM_FACET=0xF91fCd071DF35C7a5ee1Ee156669e508eC03A16A
MINT_FACET=0x6b68035c5512580fBfBE72A3A5B21186D2E120e5
COLLECTION_FACET=0xA1d16625A674EFb4259DFC0e04289b3512609185
INIT_FACET=0x11B8d84b94B27dc14f19a519a647fb1BAF79043f
```

### Step 2: Vault Implementations Deployment

1. Dry Run:

```bash
forge script script/DeployVaultImplementations.s.sol:DeployVaultImplementations --rpc-url mainnet
```

2. Actual Deployment:

```bash
forge script script/DeployVaultImplementations.s.sol:DeployVaultImplementations --rpc-url mainnet --broadcast --verify --slow -vvvv
```

After successful deployment, update .env with:

```env
ERC721_IMPLEMENTATION=0x15086dd99D696AA6b0A036424Fb6Ad4923508a94
ERC1155_IMPLEMENTATION=0xD35A23C5CFf0fe663F4357218c2B9b104399B659
```

### Step 3: Beacon and Factory Deployment

1. Dry Run:

```bash
forge script script/DeployBeaconAndFactory.s.sol:DeployBeaconAndFactory --rpc-url mainnet
```

2. Actual Deployment:

```bash
forge script script/DeployBeaconAndFactory.s.sol:DeployBeaconAndFactory --rpc-url mainnet --broadcast --verify --slow -vvvv
```

After successful deployment, update .env with:

```env
ERC721_BEACON=
ERC1155_BEACON=
COLLECTION_FACTORY_ADDRESS=
```

## Deployed Contracts

### Diamond System

- Diamond: 0x12F084DE536F41bcd29Dfc7632Db0261CEC72C60

  - Transaction Hash: 0x71d89d8bc52aa3bc434e135536cc40dbef438c7754936a1e1eb04147137ad591
  - Gas Used: 407096
  - Block Number: 21549985
  - Etherscan: https://etherscan.io/address/0x12F084DE536F41bcd29Dfc7632Db0261CEC72C60

- DiamondCutFacet: 0x4774d3b39993a6Bf414DF7bA3AF12d229d73fe39

  - Transaction Hash: 0xade90f813e22d97c8d429ddd0a80f889822713a17a9ea0d363f14c996b393e37
  - Gas Used: 857165
  - Block Number: 21549977
  - Etherscan: https://etherscan.io/address/0x4774d3b39993a6Bf414DF7bA3AF12d229d73fe39

- DiamondLoupeFacet: 0x50197F900Fed0E25Ccfc7Cc0c38354B2193572aB

  - Transaction Hash: 0x8ccad8a247363bda85e7788db3225f99491c72b2484dec8028de52772312e515
  - Gas Used: 744500
  - Block Number: 21549978
  - Etherscan: https://etherscan.io/address/0x50197F900Fed0E25Ccfc7Cc0c38354B2193572aB

- OwnershipFacet: 0x9f8c10D32B4db3BEceEA1Fe0B3b91F43ab26d733

  - Transaction Hash: 0xe9fdd007a61b74c40cf4b2aac78c62f36325a6f5b9695f8795b79a65e558082d
  - Gas Used: 137493
  - Block Number: 21549979
  - Etherscan: https://etherscan.io/address/0x9f8c10D32B4db3BEceEA1Fe0B3b91F43ab26d733

- VaultCoreFacet: 0x07bD2bAA3377098a2F3b4C309914C943b549b0e4

  - Transaction Hash: 0x4c7b8270d46e0b3bbea1bb178bc01744add72a1cc0c9ca83d25f452c66e1fc2d
  - Gas Used: 941617
  - Block Number: 21549980
  - Etherscan: https://etherscan.io/address/0x07bD2bAA3377098a2F3b4C309914C943b549b0e4

- ClaimFacet: 0xF91fCd071DF35C7a5ee1Ee156669e508eC03A16A

  - Transaction Hash: 0x8bbd84cd13a115601d75a3573ec36db1dcaeb2501371b1c2d8ea1cfbe2b0f55d
  - Gas Used: 1143742
  - Block Number: 21549981
  - Etherscan: https://etherscan.io/address/0xF91fCd071DF35C7a5ee1Ee156669e508eC03A16A

- MintFacet: 0x6b68035c5512580fBfBE72A3A5B21186D2E120e5

  - Transaction Hash: 0x0dd8b3e505a9b3e61a6d92cf44286137fadb6d2c3cae154aa40c55be9ab28466
  - Gas Used: 1298631
  - Block Number: 21549982
  - Etherscan: https://etherscan.io/address/0x6b68035c5512580fBfBE72A3A5B21186D2E120e5

- CollectionFacet: 0xA1d16625A674EFb4259DFC0e04289b3512609185

  - Transaction Hash: 0xb73f067210c35b3f584fc19e9e65d1f57318981a837693bb74325fdab39d0936
  - Gas Used: 890333
  - Block Number: 21549983
  - Etherscan: https://etherscan.io/address/0xA1d16625A674EFb4259DFC0e04289b3512609185

- InitFacet: 0x11B8d84b94B27dc14f19a519a647fb1BAF79043f
  - Transaction Hash: 0xe71c1d6bb637b178fb64469ffcadde2a44691f43d6ec0053fda4d2089c16f360
  - Gas Used: 607635
  - Block Number: 21549984
  - Etherscan: https://etherscan.io/address/0x11B8d84b94B27dc14f19a519a647fb1BAF79043f

### Vault Implementations

- ERC721VaultImplementation: 0x15086dd99D696AA6b0A036424Fb6Ad4923508a94

  - Transaction Hash: 0xcf185f8f53c5639432eb17f454708f2b14735a87c41a31997cfc887e589524b1
  - Gas Used: 2408004
  - Block Number: 21550149
  - Etherscan: https://etherscan.io/address/0x15086dd99d696aa6b0a036424fb6ad4923508a94

- ERC1155VaultImplementation: 0xD35A23C5CFf0fe663F4357218c2B9b104399B659
  - Transaction Hash: 0xae1557f87b9fb29484ffb9fc98ed6afadf28ba1b3511db6fe9ace1ca999be784
  - Gas Used: 2371969
  - Block Number: 21550150
  - Etherscan: https://etherscan.io/address/0xd35a23c5cff0fe663f4357218c2b9b104399b659

### Beacon System

- ERC721VaultBeacon: (To be deployed)

  - Transaction Hash:
  - Gas Used:
  - Block Number:
  - Etherscan:

- ERC1155VaultBeacon: (To be deployed)

  - Transaction Hash:
  - Gas Used:
  - Block Number:
  - Etherscan:

- VaultCollectionFactory: (To be deployed)
  - Transaction Hash:
  - Gas Used:
  - Block Number:
  - Etherscan:

## Gas Reports

### Diamond System Deployment

1. DiamondCutFacet Deployment

   - Gas Used: 857,165
   - Gas Price: 6.02808513 gwei
   - Cost: 0.00516706359045645 ETH

2. DiamondLoupeFacet Deployment

   - Gas Used: 744,500
   - Gas Price: 6.017272436 gwei
   - Cost: 0.004479859328602 ETH

3. OwnershipFacet Deployment

   - Gas Used: 137,493
   - Gas Price: 5.981687857 gwei
   - Cost: 0.000822440208522501 ETH

4. VaultCoreFacet Deployment

   - Gas Used: 941,617
   - Gas Price: 5.997912147 gwei
   - Cost: 0.005647736042121699 ETH

5. ClaimFacet Deployment

   - Gas Used: 1,143,742
   - Gas Price: 5.888192552 gwei
   - Cost: 0.006734573125809584 ETH

6. MintFacet Deployment

   - Gas Used: 1,298,631
   - Gas Price: 6.010200379 gwei
   - Cost: 0.007805032528381149 ETH

7. CollectionFacet Deployment

   - Gas Used: 890,333
   - Gas Price: 5.929185877 gwei
   - Cost: 0.005278949849427041 ETH

8. InitFacet Deployment

   - Gas Used: 607,635
   - Gas Price: 6.045857904 gwei
   - Cost: 0.00367367486749704 ETH

9. Diamond Contract Deployment

   - Gas Used: 407,096
   - Gas Price: 5.962061083 gwei
   - Cost: 0.002427131218644968 ETH

10. Diamond Cut Transaction

    - Gas Used: 1,653,708
    - Gas Price: 5.774466256 gwei
    - Cost: 0.009549281043277248 ETH

11. Diamond Initialization
    - Gas Used: 197,360
    - Gas Price: 5.903896011 gwei
    - Cost: 0.00116519291673096 ETH

Total Diamond System:

- Total Gas Used: 8,879,280
- Average Gas Price: 5.95807433 gwei
- Total Cost: 0.05275093471947064 ETH

### Vault Implementations Deployment

1. ERC721VaultImplementation Deployment

   - Gas Used: 2,408,004
   - Gas Price: 6.766090665 gwei
   - Cost: 0.01629277338568266 ETH

2. ERC1155VaultImplementation Deployment
   - Gas Used: 2,371,969
   - Gas Price: 6.938943229 gwei
   - Cost: 0.016458958231947901 ETH

Total Vault Implementations:

- Total Gas Used: 4,779,973
- Average Gas Price: 6.852516947 gwei
- Total Cost: 0.032751731617630561 ETH

### Beacon System Deployment

(To be filled after deployment)

## Security Considerations

1. All contract ownership should be properly set to the deployer
2. Diamond storage slots should be properly initialized
3. Beacon implementations should be initialized with correct version numbers
4. Factory should be properly configured with beacon addresses
5. All facet functions should be accessible through the diamond

## Post-Deployment Verification Steps

1. Verify diamond initialization:

   ```bash
   cast call $DIAMOND_ADDRESS "owner()" --rpc-url mainnet
   ```

2. Verify facet function selectors:

   ```bash
   cast call $DIAMOND_ADDRESS "facets()" --rpc-url mainnet
   ```

3. Verify beacon implementation versions:

   ```bash
   cast call $ERC721_BEACON "implementation()" --rpc-url mainnet
   cast call $ERC1155_BEACON "implementation()" --rpc-url mainnet
   ```

4. Verify factory configuration:
   ```bash
   cast call $COLLECTION_FACTORY_ADDRESS "getBeacon(uint8)" --rpc-url mainnet
   ```

## Notes

- Each step requires updating environment variables before proceeding to the next
- Gas estimates will be updated after each deployment step
- Contract addresses will be updated after each deployment step
- Etherscan verification will be performed automatically with --verify flag
- All transaction hashes and block numbers will be recorded for future reference
