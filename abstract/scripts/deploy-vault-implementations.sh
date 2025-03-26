#!/bin/bash

# This script deploys the vault implementations to Abstract Mainnet

echo "Deploying Vault Implementations to Abstract Mainnet..."
echo "===================================================="

# Deploy the vault implementations
docker run --rm --entrypoint forge -v "$(pwd):/project" -w /project foundry-zksync script script/DeployVaultImplementations.s.sol --zksync --rpc-url abstract_mainnet --broadcast --slow

# Check if deployment was successful
if [ $? -eq 0 ]; then
    echo "Deployment completed successfully!"
    echo "Check the output above for the deployed contract addresses."
    echo "Update the verify-vault-implementations.sh script with the deployed addresses."
else
    echo "Deployment failed. Check the logs above for errors."
fi
