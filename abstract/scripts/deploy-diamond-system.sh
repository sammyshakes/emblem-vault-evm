#!/bin/bash

# This script deploys the Diamond System to Abstract Layer 2

echo "Deploying Diamond System to Abstract Layer 2..."
echo "=============================================="

# Deploy the Diamond System
docker run --rm --entrypoint forge -v "$(pwd):/project" -w /project foundry-zksync script script/DeployDiamondSystem.s.sol --zksync --rpc-url abstract_testnet --broadcast --slow

# Check if deployment was successful
if [ $? -eq 0 ]; then
    echo "Deployment completed successfully!"
    echo "Check the output above for the deployed contract addresses."
    echo "Update the verify-contracts.sh script with the deployed addresses."
else
    echo "Deployment failed. Check the logs above for errors."
fi
