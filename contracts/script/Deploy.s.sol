// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/SwapToken.sol";
import "../src/SimpleSwap.sol";

/**
 * @title DeployScript
 * @dev Deployment script for tokens
 * 
 * Run with: forge script script/Deploy.s.sol --rpc-url sepolia --broadcast
 */
contract DeployScript is Script {
    function run() external {
        // Get private key from environment variable
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy Token A
        SwapToken tokenA = new SwapToken(
            "Token A",
            "TKA",
            1000000 // 1M tokens initial supply
        );
        console.log("Token A deployed at:", address(tokenA));

        // Deploy Token B
        SwapToken tokenB = new SwapToken(
            "Token B",
            "TKB",
            1000000
        );
        console.log("Token B deployed at:", address(tokenB));

        // Deploy SimpleSwap
        SimpleSwap simpleSwap = new SimpleSwap(
            address(tokenA),
            address(tokenB)
        );
        console.log("SimpleSwap deployed at:", address(simpleSwap));

        vm.stopBroadcast();

        // Save deployment info
        console.log("\n=== Deployment Complete ===");
        console.log("Network: Sepolia");
        console.log("Token A:", address(tokenA));
        console.log("Token B:", address(tokenB));
        console.log("SimpleSwap:", address(simpleSwap));
        console.log("\nNext steps:");
        console.log("1. Add these addresses to your frontend");
        console.log("2. Approve SimpleSwap to spend your tokens");
        console.log("3. Add initial liquidity");
    }
}
