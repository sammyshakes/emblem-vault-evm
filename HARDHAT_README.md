# Hardhat Integration for Emblem Vault Diamond

This project integrates Hardhat with the existing Foundry setup to enable deployment to Merlin Chain. The integration allows you to use both Foundry and Hardhat for different chains as needed.

## Setup

1. Install dependencies:

```bash
npm install
```

2. Configure environment variables in `.env`:

```
PRIVATE_KEY=your_private_key
MERLIN_MAINNET_RPC_URL=https://rpc.merlinchain.io
MERLIN_TESTNET_RPC_URL=https://testnet-rpc.merlinchain.io
MERLINSCAN_API_KEY=your_merlinscan_api_key
```

## Deployment Scripts

The following Hardhat scripts are available for deploying to Merlin Chain:

### Complete Deployment

To deploy the entire system in one go:

```bash
npx hardhat run scripts/deploy-merlin-complete.js --network merlin
```

This script will:

1. Deploy the Diamond system (Diamond and all facets)
2. Deploy the vault implementations (ERC721 and ERC1155)
3. Deploy the beacon system (ERC721 and ERC1155 beacons)
4. Deploy the collection factory
5. Create priority collections
6. Generate a comprehensive deployment report

### Step-by-Step Deployment

If you prefer to deploy step by step:

1. Deploy the Diamond system:

```bash
npx hardhat run scripts/deploy-merlin.js --network merlin
```

2. Deploy the vault implementations:

```bash
npx hardhat run scripts/deploy-vault-implementations.js --network merlin
```

3. Deploy the beacon system and collection factory:

```bash
npx hardhat run scripts/deploy-beacon-and-factory.js --network merlin
```

4. Create priority collections:

```bash
npx hardhat run scripts/create-priority-collections.js --network merlin
```

### Contract Verification

To verify the deployed contracts on Merlin Chain:

```bash
npx hardhat run scripts/verify-contracts.js --network merlin
```

### Verification API Details

Merlin Chain uses the Unifra verification API. The API endpoints are:

- Mainnet: `https://scan.merlinchain.io/api`
- Testnet: `https://testnet-scan.merlinchain.io/api`

For more information about the verification API, see:

- [Contract Verification API](https://unifra.readme.io/reference/contract-verification-api)
- [How to Verify a Smart Contract](https://unifra.readme.io/reference/how-to-verify-a-smart-contract)

## Deployment Reports

Deployment reports are automatically generated in the `deployment-reports` directory. These reports include:

- Contract addresses
- Deployment timestamps
- Links to the block explorer
- Next steps

## Using Hardhat with Foundry

This setup allows you to use both Hardhat and Foundry in the same project:

- **Foundry**: Use for local development, testing, and deployment to chains like Ethereum, Base, and Arbitrum.
- **Hardhat**: Use for deployment to Merlin Chain and other chains that require specific tooling.

The project is configured to share the same source code and artifacts between both tools, ensuring consistency.

## Hardhat Configuration

The Hardhat configuration is in `hardhat.config.js` and includes:

- Solidity compiler settings matching Foundry
- Network configurations for Merlin mainnet and testnet
- Etherscan verification settings
- Gas reporter
- TypeChain for TypeScript support

## Troubleshooting

If you encounter issues:

1. Make sure your `.env` file is properly configured
2. Check that you have the correct RPC URLs
3. Ensure your private key has sufficient funds
4. For verification issues, make sure you have the correct API key

## Additional Resources

- [Hardhat Documentation](https://hardhat.org/docs)
- [Merlin Chain Documentation](https://docs.merlinchain.io)
- [Ethers.js Documentation](https://docs.ethers.org/v6/)
