# Abstract Layer 2 Foundry Commands Reference

## Basic Commands

### Forge (Compilation & Testing)

```bash
# Compile contracts
docker run --rm --entrypoint forge -v "$(pwd):/project" -w /project foundry-zksync build

# Run tests
docker run --rm --entrypoint forge -v "$(pwd):/project" -w /project foundry-zksync test

# Run tests with gas reporting
docker run --rm --entrypoint forge -v "$(pwd):/project" -w /project foundry-zksync test --gas-report

# Run a specific test
docker run --rm --entrypoint forge -v "$(pwd):/project" -w /project foundry-zksync test --match-test testFunctionName

# Get forge version
docker run --rm --entrypoint forge -v "$(pwd):/project" -w /project foundry-zksync --version
```

### Cast (EVM Interaction)

```bash
# Get ETH balance
docker run --rm --entrypoint cast -v "$(pwd):/project" -w /project foundry-zksync balance <ADDRESS> --rpc-url <RPC_URL>

# Call a read function
docker run --rm --entrypoint cast -v "$(pwd):/project" -w /project foundry-zksync call <CONTRACT_ADDRESS> "functionName()" --rpc-url <RPC_URL>

# Estimate gas
docker run --rm --entrypoint cast -v "$(pwd):/project" -w /project foundry-zksync estimate <CONTRACT_ADDRESS> "functionName(arg1,arg2)" --rpc-url <RPC_URL>
```

### Anvil (Local Node)

```bash
# Start a local node
docker run --rm --entrypoint anvil -v "$(pwd):/project" -w /project -p 8545:8545 foundry-zksync

# Start with specific chain ID
docker run --rm --entrypoint anvil -v "$(pwd):/project" -w /project -p 8545:8545 foundry-zksync --chain-id 1337
```

### Chisel (Solidity REPL)

```bash
# Start interactive Solidity console
docker run --rm -it --entrypoint chisel -v "$(pwd):/project" -w /project foundry-zksync
```

## Project Management

```bash
# Initialize a new project
docker run --rm --entrypoint forge -v "$(pwd):/project" -w /project foundry-zksync init my-zksync-project

# Install dependencies
docker run --rm --entrypoint forge -v "$(pwd):/project" -w /project foundry-zksync install OpenZeppelin/openzeppelin-contracts

# Update dependencies
docker run --rm --entrypoint forge -v "$(pwd):/project" -w /project foundry-zksync update
```

## Deployment & Verification

```bash
# Deploy a contract (using script)
docker run --rm --entrypoint forge -v "$(pwd):/project" -w /project foundry-zksync script script/Deploy.s.sol --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> --broadcast

# Deploy to Abstract Layer 2
docker run --rm --entrypoint forge -v "$(pwd):/project" -w /project foundry-zksync script script/Deploy.s.sol --rpc-url https://rpc.abstract.xyz --private-key <PRIVATE_KEY> --broadcast

# Verify contract on Abstract Explorer
docker run --rm --entrypoint forge -v "$(pwd):/project" -w /project foundry-zksync verify-contract <CONTRACT_ADDRESS> <CONTRACT_NAME> --chain-id <ABSTRACT_CHAIN_ID> --verifier-url <ABSTRACT_VERIFIER_URL> --etherscan-api-key <API_KEY>
```

## Advanced Usage

```bash
# Create and send raw transaction
docker run --rm --entrypoint cast -v "$(pwd):/project" -w /project foundry-zksync send --private-key <PRIVATE_KEY> --rpc-url <RPC_URL> <TO> <VALUE> <DATA>

# Decode calldata
docker run --rm --entrypoint cast -v "$(pwd):/project" -w /project foundry-zksync calldata-decode "functionSignature(types)" <CALLDATA>

# ABI encoding
docker run --rm --entrypoint cast -v "$(pwd):/project" -w /project foundry-zksync abi-encode "functionSignature(types)" <VALUES>
```

## Troubleshooting

If you encounter permission issues, add the user flag:

```bash
docker run --rm --user $(id -u):$(id -g) --entrypoint forge -v "$(pwd):/project" -w /project foundry-zksync build
```

For network connectivity issues, add the host network:

```bash
docker run --rm --network host --entrypoint forge -v "$(pwd):/project" -w /project foundry-zksync script script/Deploy.s.sol --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> --broadcast
```

## Abstract Layer 2 Specific Commands

### Deployment to Abstract

```bash
# Deploy to Abstract Layer 2
docker run --rm --entrypoint forge -v "$(pwd):/project" -w /project foundry-zksync script script/DeployDiamondSystem.s.sol --rpc-url https://rpc.abstract.xyz --private-key <PRIVATE_KEY> --broadcast
```

### Contract Verification on Abstract

```bash
# Verify contract on Abstract Explorer
docker run --rm --entrypoint forge -v "$(pwd):/project" -w /project foundry-zksync verify-contract <CONTRACT_ADDRESS> <CONTRACT_NAME> --chain-id <ABSTRACT_CHAIN_ID> --verifier-url https://explorer.abstract.xyz/api --etherscan-api-key <API_KEY>
```

Note: Replace placeholders like `<RPC_URL>`, `<PRIVATE_KEY>`, `<CONTRACT_ADDRESS>`, `<CONTRACT_NAME>`, `<ABSTRACT_CHAIN_ID>`, and `<API_KEY>` with your actual values.
