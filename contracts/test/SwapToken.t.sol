// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/SwapToken.sol";

/**
 * @title SwapTokenTest
 * @dev Testing token contract
 * 
 * Foundry provides helpful functions:
 * - assertEq(): assert values are equal
 * - vm.prank(address): next call will be from this address
 * - vm.expectRevert(): expect the next call to fail
 */
contract SwapTokenTest is Test {
    SwapToken public tokenA;
    SwapToken public tokenB;
    
    address public owner;
    address public user1;
    address public user2;

    // setUp runs before each test
    function setUp() public {
        owner = address(this); // Test contract is the owner
        user1 = address(0x1);
        user2 = address(0x2);

        // Deploy two tokens
        tokenA = new SwapToken("Token A", "TKA", 1000000); // 1M tokens
        tokenB = new SwapToken("Token B", "TKB", 1000000);
    }

    function testInitialSupply() public view {
        // Check owner received initial supply
        assertEq(tokenA.balanceOf(owner), 1000000 * 10**18);
        assertEq(tokenA.totalSupply(), 1000000 * 10**18);
    }

    function testTokenMetadata() public view {
        assertEq(tokenA.name(), "Token A");
        assertEq(tokenA.symbol(), "TKA");
        assertEq(tokenA.decimals(), 18);
    }

    function testTransfer() public {
        uint256 amount = 100 * 10**18; // 100 tokens
        
        // Transfer from owner to user1
        require(tokenA.transfer(user1, amount), "Transfer failed");
        
        assertEq(tokenA.balanceOf(user1), amount);
        assertEq(tokenA.balanceOf(owner), 1000000 * 10**18 - amount);
    }

    function testTransferFailsWithInsufficientBalance() public {
        uint256 initialBalance = tokenA.balanceOf(owner);
        uint256 tooMuch = initialBalance + 1; // Just 1 more than we have
        
        // Expect the specific custom error from OpenZeppelin
        vm.expectRevert(
            abi.encodeWithSelector(
                bytes4(keccak256("ERC20InsufficientBalance(address,uint256,uint256)")),
                owner,
                initialBalance,
                tooMuch
            )
        );
        tokenA.transfer(user1, tooMuch);
    }

    function testMintOnlyOwner() public {
        uint256 mintAmount = 1000 * 10**18;
        
        // Owner can mint
        tokenA.mint(user1, mintAmount);
        assertEq(tokenA.balanceOf(user1), mintAmount);
        
        // Non-owner cannot mint
        vm.prank(user1); // Next call will be from user1
        vm.expectRevert(); // Expect revert because user1 is not owner
        tokenA.mint(user2, mintAmount);
    }

    function testBurn() public {
        uint256 burnAmount = 1000 * 10**18;
        uint256 initialSupply = tokenA.totalSupply();
        
        tokenA.burn(burnAmount);
        
        assertEq(tokenA.totalSupply(), initialSupply - burnAmount);
        assertEq(tokenA.balanceOf(owner), initialSupply - burnAmount);
    }

    function testApproveAndTransferFrom() public {
        uint256 amount = 100 * 10**18;
        
        // Owner approves user1 to spend tokens
        tokenA.approve(user1, amount);
        assertEq(tokenA.allowance(owner, user1), amount);
        
        // user1 transfers tokens from owner to user2
        vm.prank(user1);
        require(tokenA.transferFrom(owner, user2, amount), "Transfer failed");
        
        assertEq(tokenA.balanceOf(user2), amount);
        assertEq(tokenA.allowance(owner, user1), 0); // Allowance consumed
    }
}
