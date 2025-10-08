// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/SimpleSwap.sol";
import "../src/SwapToken.sol";

contract AddLiquidityDebugTest is Test {
    SimpleSwap public swap;
    SwapToken public tokenA;
    SwapToken public tokenB;
    
    address public user = address(0xd0C20417E0938D523Da76782947984B8B6e964F5);
    
    function setUp() public {
        // Deploy tokens
        tokenA = new SwapToken("Token A", "TKA", 1000000);
        tokenB = new SwapToken("Token B", "TKB", 1000000);
        
        // Deploy swap
        swap = new SimpleSwap(address(tokenA), address(tokenB));
        
        // Give tokens to user
        tokenA.transfer(user, 10000 * 10**18);
        tokenB.transfer(user, 10000 * 10**18);
        
        console.log("TokenA:", address(tokenA));
        console.log("TokenB:", address(tokenB));
        console.log("SimpleSwap:", address(swap));
        console.log("User:", user);
    }
    
    function testAddLiquidity() public {
        uint256 amount = 1000 * 10**18;
        
        // Act as user
        vm.startPrank(user);
        
        // Check balances
        console.log("User TokenA balance:", tokenA.balanceOf(user));
        console.log("User TokenB balance:", tokenB.balanceOf(user));
        
        // Approve
        tokenA.approve(address(swap), amount);
        tokenB.approve(address(swap), amount);
        
        // Check allowances
        console.log("TokenA allowance:", tokenA.allowance(user, address(swap)));
        console.log("TokenB allowance:", tokenB.allowance(user, address(swap)));
        
        // Add liquidity
        uint256 liquidity = swap.addLiquidity(amount, amount);
        
        vm.stopPrank();
        
        // Verify
        console.log("Liquidity minted:", liquidity);
        console.log("Reserve A:", swap.reserveA());
        console.log("Reserve B:", swap.reserveB());
        
        assertEq(swap.reserveA(), amount);
        assertEq(swap.reserveB(), amount);
    }
}
