import { HardhatUserConfig } from "hardhat/config";
import type { NetworkUserConfig } from "hardhat/types";
import { config as dotenvConfig } from "dotenv";
import { ethers } from "ethers";
import { resolve } from "path";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-ethers";
import "@nomicfoundation/hardhat-chai-matchers";
import "@nomicfoundation/hardhat-ethers";
import "@typechain/hardhat";
import "@openzeppelin/hardhat-upgrades";

const DEFAULT_MNEMONIC =
  "smart yard rug river despair intact unfair scene symbol snow update goat";

const dotenvConfigPath: string = process.env.DOTENV_CONFIG_PATH || "./.env";
dotenvConfig({ path: resolve(__dirname, dotenvConfigPath) });

// Ensure that we have all the environment variables we need.
const mnemonic: string | undefined = process.env.MNEMONIC || DEFAULT_MNEMONIC;
if (!mnemonic) {
  throw new Error("Please set your MNEMONIC in a .env file");
}

const infuraApiKey: string | undefined = process.env.INFURA_API_KEY;
if (!infuraApiKey) {
  throw new Error("Please set your INFURA_API_KEY in a .env file");
}

export const chainIds = {
  "arbitrum-mainnet": 42161,
  "arbitrum-goerli": 421613,
  "zkSync-Era-Testnet": 280,
  avalanche: 43114,
  bsc: 56,
  hardhat: 31337,
  mainnet: 1,
  "optimism-mainnet": 10,
  "optimism-goerli": 420,
  "base": 8453,
  "base-sepolia": 84532,
  "blast": 81457,
  "blast-sepolia": 168587773,
  "scroll": 534352,
  "scroll-sepolia": 534351,
  "linea": 59144,
  "linea-sepolia": 59141,
  "polygon-mainnet": 137,
  "polygon-mumbai": 80001,
  "polygon-zkevm": 1101,
  sepolia: 11155111,
  "Arbitrum-Sepolia": 421614,
  "bsc-testnet": 97,
  goerli: 5,
  ganache: 1337,
  localhost: 313371,
};

function getChainConfig(chain: keyof typeof chainIds): NetworkUserConfig {
  let jsonRpcUrl: string;
  switch (chain) {
    case "avalanche":
      jsonRpcUrl = "https://api.avax.network/ext/bc/C/rpc";
      break;
    case "bsc":
      jsonRpcUrl = "https://bsc-dataseed1.binance.org";
      break;
    case "arbitrum-goerli":
      jsonRpcUrl = "https://endpoints.omniatech.io/v1/arbitrum/goerli/public";
      break;
    case "optimism-goerli":
      jsonRpcUrl = "https://optimism-goerli.public.blastapi.io";
      break;
    case "base":
      jsonRpcUrl = "https://mainnet.base.org";
      break;
    case "base-sepolia":
      jsonRpcUrl = "https://sepolia.base.org";
      break;
    case "blast":
      jsonRpcUrl = "https://rpc.blast.io";
      break;
    case "blast-sepolia":
      jsonRpcUrl = "https://sepolia.blast.io";
      break;
    case "scroll":
      jsonRpcUrl = "https://rpc.scroll.io";
      break;
    case "scroll-sepolia":
      jsonRpcUrl = "https://sepolia-rpc.scroll.io";
      break;
    case "linea":
      jsonRpcUrl = "https://rpc.linea.build";
      break;
    case "linea-sepolia":
      jsonRpcUrl = "https://rpc.sepolia.linea.build";
      break;
    case "zkSync-Era-Testnet":
      jsonRpcUrl = "https://testnet.era.zksync.dev";
      break;
    case "ganache":
      jsonRpcUrl = "http://127.0.0.1:7545";
      break;
    case "localhost":
      jsonRpcUrl = "http://127.0.0.1:8545";
      break;
    case "Arbitrum-Sepolia":
      jsonRpcUrl = "https://sepolia-rollup.arbitrum.io/rpc";
      break;
    case "polygon-zkevm":
      jsonRpcUrl = "https://polygon-zkevm.drpc.org";
      break;
    case "bsc-testnet":
      jsonRpcUrl = "https://bsc-testnet-rpc.publicnode.com";
      break;
    default:
      jsonRpcUrl = "https://" + chain + ".infura.io/v3/" + infuraApiKey;
  }
  return {
    accounts: {
      count: 20,
      mnemonic,
      path: "m/44'/60'/0'/0",
    },
    chainId: chainIds[chain],
    url: jsonRpcUrl,
  };
}

const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",
  etherscan: {
    apiKey: {
      arbitrumOne: process.env.ARBISCAN_API_KEY || "",
      avalanche: process.env.SNOWTRACE_API_KEY || "",
      bsc: process.env.BSCSCAN_API_KEY || "",
      mainnet: process.env.ETHERSCAN_API_KEY || "",
      optimisticEthereum: process.env.OPTIMISM_API_KEY || "",
      polygon: process.env.POLYGONSCAN_API_KEY || "",
      polygonMumbai: process.env.POLYGONSCAN_API_KEY || "",
      sepolia: process.env.ETHERSCAN_API_KEY || "",
      goerli: process.env.ETHERSCAN_API_KEY || "",
      arbitrumSepolia: process.env.ARBISCAN_API_KEY || "",
    },
    customChains: [
      {
        network: "arbitrumSepolia",
        chainId: 421614,
        urls: {
          apiURL: "https://api-sepolia.arbiscan.io/api",
          browserURL: "https://arbiscan.io/",
        },
      },
    ],
  },
  gasReporter: {
    currency: "USD",
    enabled: process.env.REPORT_GAS ? true : false,
    excludeContracts: [],
    // coinmarketcap: process.env.COINMARKETCAP_KEY,
    src: "./contracts",
    outputFile: "./gas_report.md",
    noColors: true,
  },
  networks: {
    hardhat: {
      hardfork: "shanghai",
      accounts: {
        mnemonic,
        count: 20,
        accountsBalance: ethers.parseEther("100") + "",
      },
      chainId: chainIds.hardhat,
      allowUnlimitedContractSize: false,
    },
    arbitrum: getChainConfig("arbitrum-mainnet"),
    avalanche: getChainConfig("avalanche"),
    bsc: getChainConfig("bsc"),
    mainnet: getChainConfig("mainnet"),
    optimism: getChainConfig("optimism-mainnet"),
    base: getChainConfig("base"),
    'base-sepolia': getChainConfig('base-sepolia'),
    blast: getChainConfig('blast'),
    'blast-sepolia': getChainConfig('blast-sepolia'),
    scroll: getChainConfig('scroll'),
    'scroll-sepolia': getChainConfig('scroll-sepolia'),
    linea: getChainConfig('linea'),
    'linea-sepolia': getChainConfig('linea-sepolia'),
    "polygon-mainnet": getChainConfig("polygon-mainnet"),
    "polygon-mumbai": getChainConfig("polygon-mumbai"),
    sepolia: getChainConfig("sepolia"),
    goerli: getChainConfig("goerli"),
    "arbitrum-goerli": getChainConfig("arbitrum-goerli"),
    "optimism-goerli": getChainConfig("optimism-goerli"),
    "era-goerli": getChainConfig("zkSync-Era-Testnet"),
    ganache: getChainConfig("ganache"),
    "Arbitrum-Sepolia": getChainConfig("Arbitrum-Sepolia"),
    "polygon-zkevm": getChainConfig("polygon-zkevm"),
    "bsc-testnet": getChainConfig("bsc-testnet"),
  },

  paths: {
    artifacts: "./artifacts",
    cache: "./cache",
    sources: "./contracts",
    tests: "./test",
  },
  solidity: {
    compilers: [
      {
        version: "0.8.23",
        settings: {
          metadata: {
            // Not including the metadata hash
            // https://github.com/paulrberg/hardhat-template/issues/31
            bytecodeHash: "none",
          },
          // Disable the optimizer when debugging
          // https://hardhat.org/hardhat-network/#solidity-optimizer-support
          optimizer: {
            enabled: true,
            runs: 99999,
          },
          viaIR: false,
        },
      },
    ],
  },
  mocha: {
    timeout: 4000000000,
  },
  sourcify: {
    enabled: true,
  },
};

export default config;
