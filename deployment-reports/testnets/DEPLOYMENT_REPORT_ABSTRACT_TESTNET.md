# Deployment Report: Abstract Testnet

## Deployment Date

March 25, 2025

## Network Information

- **Network**: Abstract Testnet
- **Chain ID**: 11124
- **RPC URL**: https://api.testnet.abs.xyz

## Deployed Contracts

### Diamond System

- **Diamond Address**: `0x939cc34De4eDC8DDb21326963Bc028299CCBDc3E`

### Facets

- **DiamondCutFacet**: `0xf5056dE15b2B466aB13d1325028De07afb5eE214`
- **DiamondLoupeFacet**: `0xedEcC51156152aB0ddaF51a4EcaD4048cD46ad75`
- **OwnershipFacet**: `0xe22Bfbfe4edC4A79E31b63B30cf00e9d456eBd19`
- **CoreFacet**: `0x56C19C729006C81b17f6d8cD56a00A7ca6758394`
- **UnvaultFacet**: `0x3Ad08De66A5D82927ceEf592781a5Ba8c30ff27E`
- **MintFacet**: `0xE517A786ABb547cfc75fe5AFa075AC38dB38B119`
- **CollectionFacet**: `0xeF392Ab483B6483f7A27d2801dB5e4a3DdD30623`
- **InitFacet**: `0x177FeBd3f6A16bd8288D2e4c3Bd25747B1517C8B`

## Deployment Transaction

- **Transaction Hash**: See broadcast/DeployDiamondSystem.s.sol/11124/run-latest.json

## Verification Status

Contracts can be verified using the `verify-contracts.sh` script.

## Explorer Links

- **Diamond**: [0x939cc34De4eDC8DDb21326963Bc028299CCBDc3E](https://sepolia.abscan.org/address/0x939cc34De4eDC8DDb21326963Bc028299CCBDc3E)
- **DiamondCutFacet**: [0xf5056dE15b2B466aB13d1325028De07afb5eE214](https://sepolia.abscan.org/address/0xf5056dE15b2B466aB13d1325028De07afb5eE214)
- **DiamondLoupeFacet**: [0xedEcC51156152aB0ddaF51a4EcaD4048cD46ad75](https://sepolia.abscan.org/address/0xedEcC51156152aB0ddaF51a4EcaD4048cD46ad75)
- **OwnershipFacet**: [0xe22Bfbfe4edC4A79E31b63B30cf00e9d456eBd19](https://sepolia.abscan.org/address/0xe22Bfbfe4edC4A79E31b63B30cf00e9d456eBd19)
- **CoreFacet**: [0x56C19C729006C81b17f6d8cD56a00A7ca6758394](https://sepolia.abscan.org/address/0x56C19C729006C81b17f6d8cD56a00A7ca6758394)
- **UnvaultFacet**: [0x3Ad08De66A5D82927ceEf592781a5Ba8c30ff27E](https://sepolia.abscan.org/address/0x3Ad08De66A5D82927ceEf592781a5Ba8c30ff27E)
- **MintFacet**: [0xE517A786ABb547cfc75fe5AFa075AC38dB38B119](https://sepolia.abscan.org/address/0xE517A786ABb547cfc75fe5AFa075AC38dB38B119)
- **CollectionFacet**: [0xeF392Ab483B6483f7A27d2801dB5e4a3DdD30623](https://sepolia.abscan.org/address/0xeF392Ab483B6483f7A27d2801dB5e4a3DdD30623)
- **InitFacet**: [0x177FeBd3f6A16bd8288D2e4c3Bd25747B1517C8B](https://sepolia.abscan.org/address/0x177FeBd3f6A16bd8288D2e4c3Bd25747B1517C8B)

## Notes

- Deployed using foundry-zksync Docker container
- Used the DeployDiamondSystem.s.sol script for deployment
- Verification requires passing the ETHERSCAN_API_KEY as an environment variable to the Docker container
