// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/SimpleSwap.sol";
import "../src/SwapToken.sol";

contract SimpleSwapTest is Test {
    SimpleSwap public swap;
    SwapToken public tokenA;
    SwapToken public tokenB;

    address public owner;
    address public user1;
    address public user2;

    function setUp() public {
        owner = address(this);
        user1 = address(0x1);
        user2 = address(0x2);

        // Deploy tokens
        tokenA = new SwapToken("Token A", "TKA", 1000000);
        tokenB = new SwapToken("Token B", "TKB", 1000000);

        // Deploy swap contract
        swap = new SimpleSwap(address(tokenA), address(tokenB));

        // Distribute tokens to users for testing
        tokenA.transfer(user1, 10000 * 10**18);
        tokenB.transfer(user1, 10000 * 10**18);
        tokenA.transfer(user2, 10000 * 10**18);
        tokenB.transfer(user2, 10000 * 10**18);
    }

    function testInitialState() public view {
        assertEq(address(swap.tokenA()), address(tokenA));
        assertEq(address(swap.tokenB()), address(tokenB));
        assertEq(swap.reserveA(), 0);
        assertEq(swap.reserveB(), 0);
        assertEq(swap.totalLiquidity(), 0);
    }

    function testAddLiquidityFirst() public {
        uint256 amountA = 1000 * 10**18;
        uint256 amountB = 1000 * 10**18;

        // Approve swap contract to spend tokens
        tokenA.approve(address(swap), amountA);
        tokenB.approve(address(swap), amountB);

        // Add liquidity
        uint256 liquidity = swap.addLiquidity(amountA, amountB);

        // Check state
        assertEq(swap.reserveA(), amountA);
        assertEq(swap.reserveB(), amountB);
        assertEq(swap.totalLiquidity(), liquidity);
        assertEq(swap.liquidity(owner), liquidity);
        assertTrue(liquidity > 0);
    }

    function testAddLiquiditySecond() public {
        // First liquidity provider
        uint256 amountA1 = 1000 * 10**18;
        uint256 amountB1 = 1000 * 10**18;
        
        tokenA.approve(address(swap), amountA1);
        tokenB.approve(address(swap), amountB1);
        swap.addLiquidity(amountA1, amountB1);

        // Second liquidity provider (user1)
        uint256 amountA2 = 500 * 10**18;
        uint256 amountB2 = 500 * 10**18;
        
        vm.startPrank(user1);
        tokenA.approve(address(swap), amountA2);
        tokenB.approve(address(swap), amountB2);
        uint256 liquidity2 = swap.addLiquidity(amountA2, amountB2);
        vm.stopPrank();

        // Check reserves increased
        assertEq(swap.reserveA(), amountA1 + amountA2);
        assertEq(swap.reserveB(), amountB1 + amountB2);
        assertTrue(liquidity2 > 0);
    }

    function testRemoveLiquidity() public {
        // Add liquidity first
        uint256 amountA = 1000 * 10**18;
        uint256 amountB = 1000 * 10**18;
        
        tokenA.approve(address(swap), amountA);
        tokenB.approve(address(swap), amountB);
        uint256 liquidityMinted = swap.addLiquidity(amountA, amountB);

        // Record balances before removal
        uint256 balanceABefore = tokenA.balanceOf(owner);
        uint256 balanceBBefore = tokenB.balanceOf(owner);

        // Remove half of liquidity
        uint256 liquidityToRemove = liquidityMinted / 2;
        (uint256 amountAReturned, uint256 amountBReturned) = 
            swap.removeLiquidity(liquidityToRemove);

        // Check balances increased
        assertEq(tokenA.balanceOf(owner), balanceABefore + amountAReturned);
        assertEq(tokenB.balanceOf(owner), balanceBBefore + amountBReturned);
        
        // Check reserves decreased
        assertTrue(swap.reserveA() < amountA);
        assertTrue(swap.reserveB() < amountB);
    }

    function testSwapAforB() public {
        // Add initial liquidity
        uint256 liquidityA = 1000 * 10**18;
        uint256 liquidityB = 1000 * 10**18;
        
        tokenA.approve(address(swap), liquidityA);
        tokenB.approve(address(swap), liquidityB);
        swap.addLiquidity(liquidityA, liquidityB);

        // User1 swaps Token A for Token B
        uint256 swapAmount = 100 * 10**18;
        
        vm.startPrank(user1);
        uint256 balanceBBefore = tokenB.balanceOf(user1);
        
        tokenA.approve(address(swap), swapAmount);
        uint256 amountOut = swap.swapAforB(swapAmount, 0); // 0 = no slippage protection for test
        
        vm.stopPrank();

        // Check user received Token B
        assertEq(tokenB.balanceOf(user1), balanceBBefore + amountOut);
        
        // Check reserves updated correctly
        assertEq(swap.reserveA(), liquidityA + swapAmount);
        assertEq(swap.reserveB(), liquidityB - amountOut);
        
        // Verify constant product (should be close, might have minor rounding)
        uint256 k_before = liquidityA * liquidityB;
        uint256 k_after = swap.reserveA() * swap.reserveB();
        assertTrue(k_after >= k_before); // Should maintain or slightly increase due to rounding
    }

    function testSwapBforA() public {
        // Add initial liquidity
        uint256 liquidityA = 1000 * 10**18;
        uint256 liquidityB = 1000 * 10**18;
        
        tokenA.approve(address(swap), liquidityA);
        tokenB.approve(address(swap), liquidityB);
        swap.addLiquidity(liquidityA, liquidityB);

        // User1 swaps Token B for Token A
        uint256 swapAmount = 100 * 10**18;
        
        vm.startPrank(user1);
        uint256 balanceABefore = tokenA.balanceOf(user1);
        
        tokenB.approve(address(swap), swapAmount);
        uint256 amountOut = swap.swapBforA(swapAmount, 0);
        
        vm.stopPrank();

        // Check user received Token A
        assertEq(tokenA.balanceOf(user1), balanceABefore + amountOut);
    }

    function testSlippageProtection() public {
        // Add liquidity
        uint256 liquidityA = 1000 * 10**18;
        uint256 liquidityB = 1000 * 10**18;
        
        tokenA.approve(address(swap), liquidityA);
        tokenB.approve(address(swap), liquidityB);
        swap.addLiquidity(liquidityA, liquidityB);

        // Try to swap with unrealistic minimum output
        vm.startPrank(user1);
        tokenA.approve(address(swap), 100 * 10**18);
        
        // This should fail because minAmountOut is too high
        vm.expectRevert("Slippage too high");
        swap.swapAforB(100 * 10**18, 1000 * 10**18); // Expecting 1000, will get ~90
        
        vm.stopPrank();
    }

    function testGetAmountOut() public view {
        uint256 amountIn = 100 * 10**18;
        uint256 reserveIn = 1000 * 10**18;
        uint256 reserveOut = 1000 * 10**18;

        uint256 amountOut = swap.getAmountOut(amountIn, reserveIn, reserveOut);
        
        // With 100 in and 1000 reserves each
        // Expected: (100 * 1000) / (1000 + 100) = 90.909...
        uint256 expected = (amountIn * reserveOut) / (reserveIn + amountIn);
        assertEq(amountOut, expected);
    }

    function testPriceImpact() public {
        // Add liquidity
        uint256 liquidity = 1000 * 10**18;
        tokenA.approve(address(swap), liquidity);
        tokenB.approve(address(swap), liquidity);
        swap.addLiquidity(liquidity, liquidity);

        // Small swap - low price impact
        uint256 smallSwap = 10 * 10**18; // 1% of pool
        uint256 smallOut = swap.getAmountOut(smallSwap, liquidity, liquidity);
        
        // Large swap - high price impact
        uint256 largeSwap = 100 * 10**18; // 10% of pool
        uint256 largeOut = swap.getAmountOut(largeSwap, liquidity, liquidity);

        // Verify larger trades have worse rates
        // Rate = output / input
        uint256 smallRate = (smallOut * 1e18) / smallSwap;
        uint256 largeRate = (largeOut * 1e18) / largeSwap;
        
        assertTrue(largeRate < smallRate, "Large trades should have worse rates");
    }

    function testCannotRemoveMoreThanOwned() public {
        // Add liquidity
        tokenA.approve(address(swap), 1000 * 10**18);
        tokenB.approve(address(swap), 1000 * 10**18);
        uint256 liquidity = swap.addLiquidity(1000 * 10**18, 1000 * 10**18);

        // Try to remove more than owned
        vm.expectRevert("Insufficient liquidity");
        swap.removeLiquidity(liquidity + 1);
    }

    function testCannotSwapWithoutLiquidity() public {
        vm.startPrank(user1);
        tokenA.approve(address(swap), 100 * 10**18);
        
        vm.expectRevert("Insufficient liquidity");
        swap.swapAforB(100 * 10**18, 0);
        
        vm.stopPrank();
    }
}
