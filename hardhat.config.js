require("@nomicfoundation/hardhat-toolbox");
require('dotenv').config({path: '.env'});

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  defaultNetwork: "maratestnet",
  networks: {
    maratestnet: {
      url: "https://testapi.mara.xyz/http",
      accounts: [process.env.PRIVATE_KEY],
      chainId: 123456,
      gas: 2100000,
      gasPrice: 1000000,
    },
  },
  solidity: {
    version: '0.8.1',
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
};