# Ujira

A DeFi platform that enables transparent, instant, and secure distribution of dividends to shareholders

## Getting Started

1.  Install dependencies

```bash
npm install
```

2. Obtain your wallet's private key and add it to the .env file

3. Compile the smart contract

```bash
npx hardhat compile
```

4. Deploy the smart contract

```bash
npx hardhat run scripts/deploy.js --network maratestnet
```

5. Obtain the logged address of the deployed smart contract and add it to the .env file

6. Call the functions in the smart contract

```bash
node scripts/calls.js <function-name>
```
