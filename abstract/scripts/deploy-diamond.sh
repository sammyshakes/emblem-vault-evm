#!/bin/bash

# Script to deploy Diamond System with improved parameters
echo "Deploying Diamond System to Abstract Testnet with improved parameters..."

# Deploy with more verbosity, longer timeout, higher gas price, and more confirmations
docker run --rm --entrypoint forge -v "$(pwd):/project" -w /project foundry-zksync script script/DeployDiamondSystem.s.sol --zksync --rpc-url abstract_mainnet -vvvv # --broadcast --slow

# Check if deployment was successful
if [ $? -eq 0 ]; then
  echo "Deployment command completed. Check the logs above to verify if transactions were confirmed."
  echo "After confirming successful deployment, you can verify contracts using commands like:"
  echo ""
  echo "docker run --rm --entrypoint forge -v \"\$(pwd):/project\" -w /project foundry-zksync verify-contract <CONTRACT_ADDRESS> <CONTRACT_NAME> --zksync --chain 11124 --verifier etherscan --verifier-url https://api-sepolia.abscan.org/api --etherscan-api-key B9EXK4PT6XVWN8EEW5YH37Y3MG38BIJY85"
  echo ""
  echo "Replace <CONTRACT_ADDRESS> and <CONTRACT_NAME> with the actual values."
else
  echo "Deployment failed. Check the logs above for errors."
fi
