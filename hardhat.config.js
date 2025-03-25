require("@nomicfoundation/hardhat-foundry");
require("@nomicfoundation/hardhat-ethers");
require("@nomicfoundation/hardhat-verify");
require("hardhat-deploy");
require("hardhat-gas-reporter");
require("solidity-coverage");
require("@typechain/hardhat");
require("dotenv").config();

const PRIVATE_KEY = process.env.PRIVATE_KEY || "0x0000000000000000000000000000000000000000000000000000000000000000";
const MERLINSCAN_API_KEY = process.env.MERLINSCAN_API_KEY || "";

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
    solidity: {
        version: "0.8.28",
        settings: {
            optimizer: {
                enabled: true,
                runs: 200,
            },
            viaIR: true,
            evmVersion: "shanghai"
        },
    },
    // Use the same paths as Foundry for compatibility
    paths: {
        sources: "./src",
        tests: "./test",
        cache: "./cache/hardhat",
        artifacts: "./artifacts",
    },
    // Network configurations
    networks: {
        hardhat: {
            chainId: 31337,
        },
        merlin: {
            url: process.env.MERLIN_MAINNET_RPC_URL || "https://rpc.merlinchain.io",
            accounts: [PRIVATE_KEY],
            chainId: 4200,
            gasPrice: 1000000000, // 1 gwei
            verify: {
                etherscan: {
                    apiUrl: "https://scan.merlinchain.io/api",
                    apiKey: MERLINSCAN_API_KEY,
                },
            },
        },
        merlinTestnet: {
            url: process.env.MERLIN_TESTNET_RPC_URL || "https://testnet-rpc.merlinchain.io",
            accounts: [PRIVATE_KEY],
            chainId: 686868,
            gasPrice: 1000000000, // 1 gwei
            verify: {
                etherscan: {
                    apiUrl: "https://testnet-scan.merlinchain.io/api",
                    apiKey: MERLINSCAN_API_KEY,
                },
            },
        },
    },
    // Etherscan verification config
    etherscan: {
        apiKey: {
            merlin: MERLINSCAN_API_KEY,
            merlinTestnet: MERLINSCAN_API_KEY,
        },
        customChains: [
            {
                network: "merlin",
                chainId: 4200,
                urls: {
                    apiURL: "https://scan.merlinchain.io/api",
                    browserURL: "https://scan.merlinchain.io",
                },
            },
            {
                network: "merlinTestnet",
                chainId: 686868,
                urls: {
                    apiURL: "https://testnet-scan.merlinchain.io/api",
                    browserURL: "https://testnet-scan.merlinchain.io",
                },
            },
        ],
    },
    // Gas reporter configuration
    gasReporter: {
        enabled: process.env.REPORT_GAS !== undefined,
        currency: "USD",
    },
    // TypeChain configuration
    typechain: {
        outDir: "typechain",
        target: "ethers-v6",
    },
};
