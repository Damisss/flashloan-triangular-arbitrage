### Triangular Arbitrage trading with AAVE Flashloan
This project demonstrates a use case of triangular arbitrage trading using flash loan. It comes with foundry integrated with Hardhat.
**steps**
    1. Get Flashloan from AAVE 
    2. Swap token(tokenA) from flashloan to tokenB on a DEX (e.g. Quickswap)
    3. Swap tokenB into tokenC on another DEX or the same DEX used in previous step, depending of the output amount of tokenC.
    4. Swap tokenC into tokenA(flashloan token) on another DEX or the same DEX used in previous step depending on the output amount of tokenA.
    5. Pay back the loan and then send the profit to the owner account (smart contract owner).

# Configure .env file:
Create a .env file, and fill in the following values (refer to the .env.example file):
- ALCHEMY_API_KEY="API_KEY_POLYGON_MAINNET"

# Setting up the project
Clone the repo into a directory
- cd into the directory
- execute command:
```console
npm install
```

# Run test (forking mainnet)
- cd into the project directory
- execute command:
```console
forge test --mp test/foundry/TriangularArbitrage.t.sol  --fork-url  https://polygon-mainnet.g.alchemy.com/v2/<YOUR_ALCHEMY_API_KEY> -vv
```
    


