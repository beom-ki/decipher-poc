require("@nomicfoundation/hardhat-toolbox");
require('hardhat-deploy');

require("dotenv").config();


/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
    solidity: "0.8.17",

    networks: {
        goerli: {
            url: 'https://goerli.infura.io/v3/' + process.env.INFURA_API_KEY,
            accounts: [
                process.env.PRIVATE_KEY,
            ],
        }
    },

    namedAccounts: {
        deployer: {
            default: 0,
        },
    },

    verify: {
        etherscan: {
            apiKey: process.env.ETHERSCAN_API_KEY,
        }
    }
};