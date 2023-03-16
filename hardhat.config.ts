import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import 'hardhat-contract-sizer'
require("dotenv").config();

const config: HardhatUserConfig = {
  	solidity: "0.8.10",
  	networks: {
		hardhat: {
			forking: {
				url:`https://polygon-mainnet.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY}`,
				enabled:true
			},
			chainId: 31337,
			allowUnlimitedContractSize: true,
			gas: 5000000, //units of gas you are willing to pay, aka gas limit
			gasPrice:  500000000000, //gas is typically in units of gwei, but you must enter it as wei here
		},

	},
	contractSizer: {
		alphaSort: true,
		disambiguatePaths: false,
		runOnCompile: true,
		strict: true,
		only: [':TriangularArbitrage$'],
	},
};

export default config;
