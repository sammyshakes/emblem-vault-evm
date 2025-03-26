#!/bin/bash

# This script helps verify contracts on Abstract Testnet
# Using the addresses from the successful deployment

# Diamond system addresses from the deployment
DIAMOND_ADDRESS=0x61922db834314F2027175512aCFf5E815c5e9254
DIAMOND_CUT_FACET=0x70B1C8bf3C6A2340fBCA8f8F168B778925752734
DIAMOND_LOUPE_FACET=0x632253c6602454c6be9f63e369c410B21A008e26
OWNERSHIP_FACET=0x207FcEE0e60b988BC6D53E8dD2e1f51836570e14
CORE_FACET=0x256cF4Ae74F78e8C17761AC7EcdD584b23337B73
UNVAULT_FACET=0x0F832d843595b69Ccbb13bb887938b9deeE03123
MINT_FACET=0x518E9f4E214d3a7c6f4Cd9A6c19a1Fd073abe4c2
COLLECTION_FACET=0xc7d053B1218dEA987bc1dF1430da729Cf07a3ee7
INIT_FACET=0x25AD58B0392360Af5016f9cA375E4F42d216548B

# API key from .env file
API_KEY="B9EXK4PT6XVWN8EEW5YH37Y3MG38BIJY85"

# Verification parameters
CHAIN_ID="2741"
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

# Verify main diamond contract
verify_contract $DIAMOND_ADDRESS "src/EmblemVaultDiamond.sol:EmblemVaultDiamond"

# Verify facets
verify_contract $DIAMOND_CUT_FACET "src/facets/DiamondCutFacet.sol:DiamondCutFacet"
verify_contract $DIAMOND_LOUPE_FACET "src/facets/DiamondLoupeFacet.sol:DiamondLoupeFacet"
verify_contract $OWNERSHIP_FACET "src/facets/OwnershipFacet.sol:OwnershipFacet"
verify_contract $CORE_FACET "src/facets/EmblemVaultCoreFacet.sol:EmblemVaultCoreFacet"
verify_contract $UNVAULT_FACET "src/facets/EmblemVaultUnvaultFacet.sol:EmblemVaultUnvaultFacet"
verify_contract $MINT_FACET "src/facets/EmblemVaultMintFacet.sol:EmblemVaultMintFacet"
verify_contract $COLLECTION_FACET "src/facets/EmblemVaultCollectionFacet.sol:EmblemVaultCollectionFacet"
verify_contract $INIT_FACET "src/facets/EmblemVaultInitFacet.sol:EmblemVaultInitFacet"

echo "Verification process completed. Check the output above for any errors."
echo "If any verification failed, you may need to adjust the contract paths or names."
