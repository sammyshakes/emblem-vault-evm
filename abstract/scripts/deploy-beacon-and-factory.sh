#!/bin/bash

# This script deploys the beacon and factory system to Abstract Testnet

echo "Deploying Beacon and Factory System to Abstract Mainnet..."
echo "========================================================"

# Deploy the beacon and factory system
docker run --rm --entrypoint forge -v "$(pwd):/project" -w /project foundry-zksync script script/DeployBeaconAndFactory.s.sol --zksync --rpc-url abstract_mainnet --broadcast --slow

# Check if deployment was successful
if [ $? -eq 0 ]; then
    echo "Deployment completed successfully!"
    echo "Check the output above for the deployed contract addresses."
    echo "Update the verify-beacon-and-factory.sh script with the deployed addresses."
else
    echo "Deployment failed. Check the logs above for errors."
fi
