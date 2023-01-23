# Decipher POC Smart Contracts
[Decipher](https://decipher.ac/) PoC(Proof of Contribution)


## Installations

```shell
$ npm install
```

## Configurations

- Update your own Ethereum Private Key, [Infura](https://www.infura.io/) API Key, and [Etherscan](https://etherscan.io/) API Key to `.env`:

```shell
export ETHERSCAN_API_KEY=""
export INFURA_API_KEY=""
export PRIVATE_KEY=""
```


## Deployments
### Deploy on localhost([Hardhat Node](https://hardhat.org/hardhat-network/docs/overview)):

```shell
$ npx hardhat compile
$ npx hardhat deploy
$ npx hardhat run scripts/create_poc_holders.js --network localhost
```

### Deploy on [Goerli](https://goerli.net/):

```shell
$ npx hardhat deploy --network goerli
$ npx hardhat etherscan-verify --network goerli
```
