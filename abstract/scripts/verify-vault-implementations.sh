#!/bin/bash

# This script helps verify vault implementation contracts on Abstract Testnet
# Replace the contract addresses with the actual addresses from your deployment

# Vault implementation addresses - replace these with your actual deployed addresses
ERC721_IMPLEMENTATION="0xEBd35023A3938aDF5C6475E39557A359a81EBfa5"
ERC1155_IMPLEMENTATION="0xf5056dE15b2B466aB13d1325028De07afb5eE214"

# API key
API_KEY="B9EXK4PT6XVWN8EEW5YH37Y3MG38BIJY85"

# Verification parameters
VERIFIER="etherscan"
# VERIFIER_URL="https://api-sepolia.abscan.org/api"
VERIFIER_URL="https://api.abscan.org/api" # mainnet

# Function to verify a contract
verify_contract() {
    local address=$1
    local name=$2
    
    echo "Verifying $name at $address..."
    # Create a temporary .env file with the API key
    echo "ETHERSCAN_API_KEY=$API_KEY" > .env.verify
    
    # Use the .env file with Docker - following the exact format from the docs
    docker run --rm --env-file .env.verify --entrypoint forge -v "$(pwd):/project" -w /project foundry-zksync verify-contract $address \
        $name \
        --verifier $VERIFIER \
        --verifier-url $VERIFIER_URL \
        --etherscan-api-key $API_KEY \
        --zksync
    
    # Remove the temporary .env file
    rm .env.verify
    
    # Wait a bit between verifications to avoid rate limiting
    sleep 5
}

# Verify vault implementations
verify_contract $ERC721_IMPLEMENTATION "src/implementations/ERC721VaultImplementation.sol:ERC721VaultImplementation"
verify_contract $ERC1155_IMPLEMENTATION "src/implementations/ERC1155VaultImplementation.sol:ERC1155VaultImplementation"

echo "Verification process completed. Check the output above for any errors."
echo "If any verification failed, you may need to adjust the contract paths or names."
