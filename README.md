# Emblem Vault Diamond System

A modular and upgradeable vault system built on the EIP-2535 Diamond Standard, allowing for the creation and management of NFT vaults that can hold various digital assets.

## Features

- **Diamond Architecture**: Upgradeable facets for system functionality
- **Beacon System**: Upgradeable vault implementations
- **Factory Pattern**: Standardized collection deployment
- **Vault Types**: Support for both ERC721 and ERC1155 vaults
- **Asset Support**: Store ERC20, ERC721, and ERC1155 tokens in vaults
- **Witness System**: Secure minting through verified signatures
- **Gas Optimized**: Efficient proxy patterns and storage

## Deployed Contracts (Mainnet)

### Diamond System

**Diamond Address:** `0x12F084DE536F41bcd29Dfc7632Db0261CEC72C60`

#### Core Facets

- **DiamondCutFacet:** `0x4774d3b39993a6Bf414DF7bA3AF12d229d73fe39`
- **DiamondLoupeFacet:** `0x50197F900Fed0E25Ccfc7Cc0c38354B2193572aB`
- **OwnershipFacet:** `0x9f8c10D32B4db3BEceEA1Fe0B3b91F43ab26d733`

#### Functional Facets

- **CoreFacet:** `0xEE483847aa8E52887A1C5477b8F5b0af28922681`
- **MintFacet:** `0xC59c4B6EA71a610BC7eDF05CBc66bfc2a86A3005` 
- **UnvaultFacet:** `0xF04a4B0CE209aF4017648Fa93D2bB348eCb116d6` 
- **InitFacet:** `0x5657a10c1AAe46Ae383342d7516290B4FecD9295`
- **CollectionFacet:** `0x9dDCc1340D0ed0D359e6C4bD1408Ee3542f257B2` 


### Vault Implementations

- **ERC721VaultImplementation:** `0x15086dd99D696AA6b0A036424Fb6Ad4923508a94`
- **ERC1155VaultImplementation:** `0xD35A23C5CFf0fe663F4357218c2B9b104399B659`

### Beacon System

- **ERC721VaultBeacon:** `0x8977704a454fE2063336324027440d7bc56689AA`
- **ERC1155VaultBeacon:** `0x2B05d2Ec965E10DB70EEeE8a62FFc39e399601A6`
- **VaultCollectionFactory:** `0x109De29e0FB4de58A66ce077253E0604D81AD14C`

### Collections

- **Diamond Hands Collection (ERC721A):** `0xAfE0130Bad95763A66871e1F2fd73B8e7ee18037`

## Quick Start

1. Install dependencies:

```bash
forge install
```

2. Set up environment:

```bash
cp .env.example .env
# Edit .env with your configuration
```

3. Deploy system:

```bash
# Deploy Diamond system
forge script script/DeployDiamondSystem.s.sol:DeployDiamondSystem --rpc-url <network> -vvvv --broadcast

# Deploy implementations and beacons
forge script script/DeployVaultImplementations.s.sol:DeployVaultImplementations --rpc-url <network> -vvvv --broadcast
forge script script/DeployBeaconAndFactory.s.sol:DeployBeaconAndFactory --rpc-url <network> -vvvv --broadcast

# Create test collections
forge script script/CreateTestCollections.s.sol:CreateTestCollections --rpc-url <network> -vvvv --broadcast
```

## Scripts

### Deployment

- `DeployDiamondSystem.s.sol` - Deploy complete Diamond system
- `DeployVaultImplementations.s.sol` - Deploy vault implementations
- `DeployBeaconAndFactory.s.sol` - Deploy beacons and factory
- `CreateTestCollections.s.sol` - Create test collections

### Management

- `MintTestVaults.s.sol` - Mint test vaults
- `UpdateCollectionBaseURI.s.sol` - Update collection URIs
- `SetupCollectionFactory.s.sol` - Configure factory in Diamond

### Upgrades

- `UpgradeDiamondFacets.s.sol` - Upgrade Diamond facets
- `UpgradeBeaconImplementations.s.sol` - Upgrade vault implementations
- `DeployUpdatedFactory.s.sol` - Deploy new factory

Key test files:

- `DiamondBeaconIntegration.t.sol` - Integration tests
- `BeaconSystem.t.sol` - Beacon system tests
- `DiamondVault.t.sol` - Vault functionality tests

## Architecture

```
contracts/
├── facets/           # Diamond facets
├── implementations/  # Vault implementations
├── beacon/           # Beacon system
├── factories/        # Collection factory
├── interfaces/       # Contract interfaces
└── libraries/        # Shared libraries
```

## Security

- All contracts use OpenZeppelin libraries
- Diamond storage pattern prevents collisions
- Comprehensive test coverage
- Access control through Diamond owner
- Witness system for minting security

## License

MIT

## Testing

Run the test suite:

```bash
forge test
```

```bash
[⠊] Compiling...
[⠰] Compiling 117 files with Solc 0.8.28
[⠒] Solc 0.8.28 finished in 66.51s
Compiler run successful!

Ran 5 tests for test/DiamondLoupeFacetOptimized.t.sol:DiamondLoupeFacetOptimizedTest
[PASS] testGasComparisonBatchFacets() (gas: 160504)
[PASS] testGasComparisonBatchSelectors() (gas: 151701)
[PASS] testGasComparisonFacets() (gas: 77117)
[PASS] testGasComparisonGetFacetAddresses() (gas: 83528)
[PASS] testGasComparisonSupportsInterfaces() (gas: 57671)
Suite result: ok. 5 passed; 0 failed; 0 skipped; finished in 5.91ms (4.87ms CPU time)

Ran 4 tests for test/DiamondGasComparison.t.sol:DiamondGasComparisonTest
[PASS] testDeploymentGas() (gas: 330555)
[PASS] testDiamondCutGas() (gas: 130741)
[PASS] testFacetCallGas() (gas: 41787)
[PASS] testMultipleCallsGas() (gas: 104720)
Suite result: ok. 4 passed; 0 failed; 0 skipped; finished in 4.47ms (1.28ms CPU time)

Ran 7 tests for test/DiamondFactoryIntegration.t.sol:DiamondFactoryIntegrationTest
[PASS] testCollectionOwnership() (gas: 395244)
[PASS] testCollectionTypeVerification() (gas: 669399)
[PASS] testCollectionURIManagement() (gas: 713164)
[PASS] testFactoryInitialization() (gas: 21994)
[PASS] testOnlyDiamondCanCreateCollections() (gas: 390204)
[PASS] testOnlyDiamondCanUpdateBeacons() (gas: 2275959)
[PASS] testRevertInvalidCollectionOperations() (gas: 704104)
Suite result: ok. 7 passed; 0 failed; 0 skipped; finished in 7.52ms (5.19ms CPU time)

Ran 6 tests for test/DiamondLoupeBatch.t.sol:DiamondLoupeBatchTest
[PASS] testBatchFacetFunctionSelectors() (gas: 236699)
[PASS] testBatchFacets() (gas: 254228)
[PASS] testBatchGetFacetAddresses() (gas: 55039)
[PASS] testBatchSupportsInterfaces() (gas: 34231)
[PASS] testEmptyArrays() (gas: 30370)
[PASS] testGasComparison() (gas: 64900)
Suite result: ok. 6 passed; 0 failed; 0 skipped; finished in 9.15ms (17.45ms CPU time)

Ran 14 tests for test/BeaconVault.t.sol:BeaconVaultTest
[PASS] testInitialSetup() (gas: 42391)
[PASS] testMultipleProxies() (gas: 2875104)
[PASS] testProxyDelegation() (gas: 130560)
[PASS] testRevertDoubleInitialization() (gas: 24127)
[PASS] testRevertProxyWithNonBeaconContract() (gas: 172441)
[PASS] testRevertProxyWithNonContractBeacon() (gas: 172682)
[PASS] testRevertProxyWithZeroBeacon() (gas: 36339)
[PASS] testRevertTransferOwnershipToZeroAddress() (gas: 10812)
[PASS] testRevertTransferOwnershipUnauthorized() (gas: 16864)
[PASS] testRevertUpgradeAfterOwnershipTransfer() (gas: 18998)
[PASS] testRevertUpgradeToZeroAddress() (gas: 10910)
[PASS] testRevertUpgradeUnauthorized() (gas: 14203)
[PASS] testTransferOwnership() (gas: 2294545)
[PASS] testUpgrade() (gas: 2412186)
Suite result: ok. 14 passed; 0 failed; 0 skipped; finished in 8.84ms (6.47ms CPU time)

Ran 9 tests for test/DiamondBeaconIntegration.t.sol:DiamondBeaconIntegrationTest
[PASS] testCreateVaultThroughFactory() (gas: 396292)
[PASS] testERC1155Integration() (gas: 3093688)
[PASS] testFactoryManagement() (gas: 1074773)
[PASS] testFullSystemFlow() (gas: 2812362)
[PASS] testInitialization() (gas: 40021)
[PASS] testRevertLockInvalidCollection() (gas: 24306)
[PASS] testRevertSetZeroFactory() (gas: 15949)
[PASS] testRevertWithoutFactory() (gas: 443900)
[PASS] testUpgradeVaultImplementation() (gas: 2737289)
Suite result: ok. 9 passed; 0 failed; 0 skipped; finished in 8.21ms (5.84ms CPU time)

Ran 13 tests for test/BeaconSystem.t.sol:BeaconSystemTest
[PASS] testBatchOperations1155() (gas: 1330405)
[PASS] testBurnOperations() (gas: 1170376)
[PASS] testCreateERC1155Collection() (gas: 308421)
[PASS] testCreateERC721Collection() (gas: 401620)
[PASS] testERC1155VaultOperations() (gas: 924141)
[PASS] testERC721VaultOperations() (gas: 523294)
[PASS] testInitialSetup() (gas: 44941)
[PASS] testRevertUnauthorizedBeaconUpdate() (gas: 2252134)
[PASS] testRevertUnauthorizedCollectionCreation() (gas: 12987)
[PASS] testRevertUnauthorizedMint1155() (gas: 295916)
[PASS] testRevertUnauthorizedMint721() (gas: 386199)
[PASS] testUpgradeERC1155Implementation() (gas: 3404204)
[PASS] testUpgradeERC721Implementation() (gas: 2843757)
Suite result: ok. 13 passed; 0 failed; 0 skipped; finished in 9.29ms (14.79ms CPU time)

Ran 17 tests for test/DiamondVault.t.sol:DiamondVaultTest
[PASS] testBasicUnvault() (gas: 212060)
[PASS] testBuyWithSignedPrice() (gas: 242317)
[PASS] testBuyWithSignedPriceERC20() (gas: 259892)
[PASS] testFacetVersions() (gas: 43541)
[PASS] testInitialization() (gas: 40178)
[PASS] testOwnership() (gas: 18159)
[PASS] testRevertAddExistingWitness() (gas: 20336)
[PASS] testRevertLockInvalidCollection() (gas: 24460)
[PASS] testRevertRemoveLastWitness() (gas: 32052)
[PASS] testRevertRemoveNonExistentWitness() (gas: 18523)
[PASS] testRevertUnvaultWithInvalidSignature() (gas: 137771)
[PASS] testRevertUnvaultWithWrongPaymentAmount() (gas: 133568)
[PASS] testUnvaultWithSignedPrice() (gas: 266635)
[PASS] testUnvaultWithSignedPriceERC20() (gas: 289662)
[PASS] testUnvaultWithSignedPriceLockedVault() (gas: 275551)
[PASS] testVaultLocking() (gas: 68790)
[PASS] testWitnessManagement() (gas: 45336)
Suite result: ok. 17 passed; 0 failed; 0 skipped; finished in 20.96ms (28.60ms CPU time)

Ran 29 tests for test/UnvaultTracking.t.sol:UnvaultTrackingTest
[PASS] testBasicUnvault() (gas: 211964)
[PASS] testBurnAddressManagement() (gas: 35209)
[PASS] testBurnAddressWithUnvault() (gas: 344222)
[PASS] testBuyWithSignedPrice() (gas: 242238)
[PASS] testBuyWithSignedPriceERC20() (gas: 259880)
[PASS] testDisableUnvaulting() (gas: 260868)
[PASS] testERC1155UnvaultWithSerialNumber() (gas: 595013)
[PASS] testFacetVersions() (gas: 43621)
[PASS] testInitialization() (gas: 40308)
[PASS] testOwnership() (gas: 18341)
[PASS] testPreventDoubleUnvault() (gas: 336925)
[PASS] testRevertAddExistingWitness() (gas: 20323)
[PASS] testRevertLockInvalidCollection() (gas: 24579)
[PASS] testRevertRemoveLastWitness() (gas: 31998)
[PASS] testRevertRemoveNonExistentWitness() (gas: 18576)
[PASS] testRevertSetBurnAddressNotOwner() (gas: 19723)
[PASS] testRevertSetUnvaultingEnabledNotOwner() (gas: 19939)
[PASS] testRevertUnvaultWithInvalidSignature() (gas: 137638)
[PASS] testRevertUnvaultWithWrongPaymentAmount() (gas: 133503)
[PASS] testUnvaultHistory() (gas: 733840)
[PASS] testUnvaultStatusTracking() (gas: 314403)
[PASS] testUnvaultWithLockedVault() (gas: 377084)
[PASS] testUnvaultWithSignedPrice() (gas: 266628)
[PASS] testUnvaultWithSignedPriceERC20() (gas: 289785)
[PASS] testUnvaultWithSignedPriceLockedVault() (gas: 275412)
[PASS] testUnvaultWithSignedPriceWhenDisabled() (gas: 278996)
[PASS] testUnvaultingEnabledByDefault() (gas: 306648)
[PASS] testVaultLocking() (gas: 68623)
[PASS] testWitnessManagement() (gas: 45388)
Suite result: ok. 29 passed; 0 failed; 0 skipped; finished in 20.14ms (64.41ms CPU time)

Ran 14 tests for test/ERC1155VaultImplementation.t.sol:ERC1155VaultImplementationTest
[PASS] testBatchMintWithExternalSerialNumbers() (gas: 658567)
[PASS] testBatchTransferSerialNumbers() (gas: 782745)
[PASS] testComplexBatchMintWithExternalSerials() (gas: 1031243)
[PASS] testComplexTransferScenario() (gas: 642654)
[PASS] testExternalSerialNumberMint() (gas: 413302)
[PASS] testInitialState() (gas: 22593)
[PASS] testRevertDuplicateExternalSerial() (gas: 134525)
[PASS] testRevertInvalidBatchSerialData() (gas: 38066)
[PASS] testRevertInvalidSerialQueries() (gas: 219762)
[PASS] testRevertMismatchedSerialNumbers() (gas: 20194)
[PASS] testRevertReuseSerialAcrossTokens() (gas: 209900)
[PASS] testRevertZeroSerialNumber() (gas: 134223)
[PASS] testSerialNumberBurn() (gas: 323425)
[PASS] testSerialNumberTransfer() (gas: 466748)
Suite result: ok. 14 passed; 0 failed; 0 skipped; finished in 24.34ms (9.52ms CPU time)

Ran 2 tests for test/UnvaultBatchOperations.t.sol:UnvaultBatchOperationsTest
[PASS] testBatchSizeLimitEnforcement() (gas: 190308)
[PASS] testBatchUnvault() (gas: 1143882)
Suite result: ok. 2 passed; 0 failed; 0 skipped; finished in 27.85ms (32.49ms CPU time)

Ran 2 tests for test/BatchVaultOperations.t.sol:BatchVaultOperationsTest
[PASS] testBatchMintGasAnalysis() (gas: 6827586)
[PASS] testBatchSizeLimitEnforcement() (gas: 244063)
Suite result: ok. 2 passed; 0 failed; 0 skipped; finished in 45.48ms (53.25ms CPU time)

Ran 7 tests for test/MainnetFork.t.sol:MainnetForkTest
[PASS] testMainnetCollectionCreation() (gas: 44439)
[PASS] testMainnetCollectionOperations() (gas: 44653)
[PASS] testMainnetDeployment() (gas: 102658)
[PASS] testMainnetMintOperations() (gas: 41719)
[PASS] testMainnetMintWithSignedPrice() (gas: 231033)
[PASS] testMainnetUnvaultOperations() (gas: 27582)
[PASS] testMainnetWitnessOperations() (gas: 25548)
Suite result: ok. 7 passed; 0 failed; 0 skipped; finished in 12.67s (30.75s CPU time)

Ran 13 test suites in 12.67s (12.86s CPU time): 129 tests passed, 0 failed, 0 skipped (129 total tests)
```
