// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {Address} from '@openzeppelin/contracts/utils/Address.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import {TriangularArbitrage, IUniswapV2Router02} from '../../contracts/TriangularArbitrage.sol';

interface IFactory{
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IV2Pair{
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}
contract TriangularArbitrageTest is Test {
    using stdStorage for StdStorage;
    using Address for address;
    TriangularArbitrage public triangularArbitrage;

    address constant poolProvider = 0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb;
   
    address constant tokenA = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619; //weth;
    address constant tokenB = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063 ; //dai;
    address constant tokenC = 0xD6DF932A45C0f255f85145f286eA0b292B21C90B; //aave
    //0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270; //wmatic;

    function setUp() public {
        triangularArbitrage = new TriangularArbitrage(poolProvider);
    }

    function testDeployment() public {
        assertTrue(Address.isContract(address(triangularArbitrage)));
    }

    function manipulatePrice(address router, address factory, address tokenA_, address tokenB_, uint ammount_) private {
        // account impersonating
        stdstore
        .target(tokenA_)
        .sig(IERC20(tokenA_).balanceOf.selector)
        .with_key(address(this))
        .checked_write(ammount_);
        uint balance = IERC20(tokenA_).balanceOf(address(this));
        
        IERC20(tokenA_).approve(router, balance);
        address pair = IFactory(factory).getPair(tokenA_, tokenB_);
        (uint112 reserve0, uint112 reserve1, ) = IV2Pair(pair).getReserves();
        
        console.log('pricedBefore:', reserve1/reserve0);

        address [] memory path = new address[](2);
        path[0] = tokenA_;
        path[1] = tokenB_;

        IUniswapV2Router02(router).swapExactTokensForTokens(
           balance,
           0,
           path,
           address(this),
           (block.timestamp + 1200)
        );
        (uint112 reserve0After, uint112 reserve1After,) = IV2Pair(pair).getReserves();
        console.log('priceAfter:', reserve1After/reserve0After);
    }
    
    function testExecutetrade() public {
        //manipulate the price
        address quickRouter = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
        address quickFactory = 0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32;
        address shushiRouter = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
        address shushiFactory = 0xc35DADB65012eC5796536bD9864eD8773aBc74C4;
        manipulatePrice(quickRouter, quickFactory, tokenB, tokenA, 10000*1e18);
        manipulatePrice(shushiRouter, shushiFactory, tokenC, tokenB, 100*1e18);
        // execute trade
        uint wethBalanceBeforeTrade = IERC20(tokenA).balanceOf(address(triangularArbitrage));
        address[] memory routersAddresses = new address[](3);
        routersAddresses[0] = quickRouter;
        routersAddresses[1] = shushiRouter;
        routersAddresses[2] = 0xA102072A4C07F06EC3B4900FDC4C7B80b6c57429; //DFYN
        triangularArbitrage.executeTrade(
            routersAddresses,
            tokenA,
            tokenB, 
            tokenC,
            1*1e18
        );

        uint wethBalanceAfterTrade = IERC20(tokenA).balanceOf(address(triangularArbitrage));
        console.log('wethBalanceBeforeTrade:',wethBalanceBeforeTrade);
        console.log('wethBalanceAfterTrade:',wethBalanceAfterTrade);
    }
}

