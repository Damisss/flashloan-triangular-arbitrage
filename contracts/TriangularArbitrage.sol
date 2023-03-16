// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IUniswapV2Router02} from './interfaces/IUniswapV2Router02.sol';
import {FlashLoanSimpleReceiverBase} from "@aave/core-v3/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";

import 'hardhat/console.sol';

contract TriangularArbitrage is FlashLoanSimpleReceiverBase {
    constructor(address _addressProvider) FlashLoanSimpleReceiverBase(
        IPoolAddressesProvider(_addressProvider)
    ){}

    function executeTrade(
        address[] calldata _routersAddresses,
        address _tokenA,
        address _tokenB,
        address _tokenC,
        uint256 _amountIn
    ) external {
        uint balnaceBefore = IERC20(_tokenA).balanceOf(address(this));
        bytes memory params = abi.encode(
            _routersAddresses,
            _tokenA,
            _tokenB,
            _tokenC,
            balnaceBefore,
            _amountIn
        );
        uint16 referralCode = 0;
        POOL.flashLoanSimple(
            address(this),
            _tokenA,
            _amountIn,
            params,
            referralCode
        );
    
    }

    function swapExactTokensForTokens(
        uint _amountIn,
        uint _amountOutMin,
        address _routerAddress,
        address[] memory path
    ) internal returns (uint[] memory amounts){
        IERC20(path[0]).approve(_routerAddress, _amountIn);
        
        amounts = IUniswapV2Router02(_routerAddress).swapExactTokensForTokens(
            _amountIn,
            _amountOutMin,
            path,
            address(this),
            block.timestamp + 5 minutes
        );
    }

    function executeOperation(
         address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external override returns (bool){
        (
            address[] memory routersAddresses,
            address tokenA,
            address tokenB,
            address tokenC,
            uint256 balnaceBefore,
            uint256 flashLoan
        ) = abi.decode(params, (address[], address, address, address, uint256, uint256));
       
        uint balnaceAfter = IERC20(tokenA).balanceOf(address(this));
        
        require(balnaceAfter - balnaceBefore == flashLoan, 'No flash loan available');

        address[] memory path = new address[](2);
        
        //echange 1
        path[0] = tokenA;
        path[1] = tokenB;
        
        swapExactTokensForTokens(
            flashLoan,
            0,
            routersAddresses[0],
            path
        );
        
        // exchange 2
        path[0] = tokenB;
        path[1] = tokenC;
        swapExactTokensForTokens(
            IERC20(tokenB).balanceOf(address(this)),
            0,
            routersAddresses[1],
            path
        );
         
        //exchange 3
        path[0] = tokenC;
        path[1] = tokenA;
        swapExactTokensForTokens(
            IERC20(tokenC).balanceOf(address(this)),
            flashLoan,
            routersAddresses[2],
            path
        );
        
        uint256 amountOwed = amount + premium;
        IERC20(asset).approve(address(POOL), amountOwed);

        return true;
    }
}