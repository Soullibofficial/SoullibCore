import { config } from "dotenv";
import type { HardhatUserConfig } from "hardhat/types";
import "@nomiclabs/hardhat-ethers";
import "@openzeppelin/hardhat-upgrades";
import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-truffle5";
import "@nomiclabs/hardhat-web3";
import "solidity-coverage";
var HDWalletProvider = require("truffle-hdwallet-provider");


config();

const confg: HardhatUserConfig = {
  solidity: "0.8.4"
}
// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  defaultNetwork: "matic",
  networks: {
    // hardhat: {
    //   initialBaseFeePerGas: 0, // workaround from https://github.com/sc-forks/solidity-coverage/issues/652#issuecomment-896330136 . Remove when that issue is closed.
    // },
    hardhat: {
    },
    matic: {
      url: "https://rpc-mumbai.maticvigil.com",
      accounts: [process.env.PRIVATE]
    },

    development: {
      url: "http://127.0.0.1:8545",     // Localhost (default: none)
      port: 8545,            // Standard Ethereum port (default: none)
      network_id: "*",       // Any network (default: none)
    },

    ropsten: {
      url: process.env.ROPSTEN_URL || "",
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },

    rinkeby: {
      url: process.env.RINKEBY_URL || "",
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },

    testnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545",
      chainId: 97,
      gasPrice: 20000000000,
      accounts: {mnemonic: process.env.MNEMONIC}
    },

    // matic: {
    //   url: "https://rpc-mumbai.matic.today",
    //   network_id: 80001,
    //   confirmations: 2,
    //   timeoutBlocks: 200,
    //   skipDryRun: true,
    //   gas: 6000000,
    //   gasPrice: 10000000000,
    //   accounts: {mnemonic: process.env.MNEMONIC}
    // },
  //   mainnet: {
  //     url: "https://bsc-dataseed.binance.org/",
  //     chainId: 56,
  //     gasPrice: 20000000000,
  //     accounts: {mnemonic: process.env.MNEMONIC}
  //   },
  // },
  // gasReporter: {
  //   enabled: process.env.REPORT_GAS !== undefined,
  //   currency: "USD",
  // },
  // etherscan: {
  //   apiKey: process.env.ETHERSCAN_API_KEY,
  },

  paths: {
    sources: "./contracts",
    tests: "./test",
    scripts: "./scripts",
    cache: "./cache",
    artifacts: "./artifacts"
  },

  mocha: {
    timeout: 100000
  },

  solidity: {
    version: "0.8.4",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  }
}
