# Abstract Layer 2 Deployment Tools

This directory contains scripts and documentation for deploying and verifying contracts on Abstract Layer 2.

## Directory Structure

- **scripts/**: Contains shell scripts for deploying and verifying contracts

  - `verify-contracts.sh`: Verifies the Diamond system contracts
  - `deploy-vault-implementations.sh`: Deploys the ERC721 and ERC1155 vault implementations
  - `verify-vault-implementations.sh`: Verifies the vault implementations
  - `deploy-beacon-and-factory.sh`: Deploys the beacon and factory system
  - `verify-beacon-and-factory.sh`: Verifies the beacon and factory contracts

- **docs/**: Contains documentation for deploying to Abstract Layer 2

  - `abstract-foundry-commands.md`: Reference for foundry-zksync commands
  - `abstract-deployment-guide.md`: Guide for deploying to Abstract Testnet
  - `abstract-mainnet-deployment-guide.md`: Guide for deploying to Abstract Mainnet

- **deployment-reports/**: Contains deployment reports for Abstract Layer 2 deployments

## Usage

1. Make sure you have the foundry-zksync Docker image installed:

   ```bash
   docker pull foundry-zksync
   ```

2. Follow the deployment guides in the docs/ directory to deploy your contracts to Abstract Layer 2.

3. Use the scripts in the scripts/ directory to deploy and verify your contracts.

## Important Notes

- All scripts should be run from the project root directory, not from within the abstract/ directory.
- Make sure to update the contract addresses in the verification scripts after deployment.
- Always test on testnet before deploying to mainnet.
