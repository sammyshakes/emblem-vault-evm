#!/bin/bash

# This script helps verify beacon and factory contracts on Abstract Testnet
# Replace the contract addresses with the actual addresses from your deployment

# Beacon and factory addresses - replace these with your actual deployed addresses
ERC721_BEACON="0xedEcC51156152aB0ddaF51a4EcaD4048cD46ad75"
ERC1155_BEACON="0xe22Bfbfe4edC4A79E31b63B30cf00e9d456eBd19"
COLLECTION_FACTORY="0x56C19C729006C81b17f6d8cD56a00A7ca6758394"

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

# Verify beacon and factory contracts
verify_contract $ERC721_BEACON "src/beacon/VaultBeacon.sol:ERC721VaultBeacon"
verify_contract $ERC1155_BEACON "src/beacon/VaultBeacon.sol:ERC1155VaultBeacon"
verify_contract $COLLECTION_FACTORY "src/factories/VaultCollectionFactory.sol:VaultCollectionFactory"

echo "Verification process completed. Check the output above for any errors."
echo "If any verification failed, you may need to adjust the contract paths or names."
