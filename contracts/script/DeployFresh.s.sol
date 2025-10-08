// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/SwapToken.sol";
import "../src/SimpleSwap.sol";

contract DeployFreshScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deployer:", deployer);
        console.log("Balance:", deployer.balance);
        
        vm.startBroadcast(deployerPrivateKey);

        // Deploy fresh tokens
        SwapToken tokenA = new SwapToken("Token A Fresh", "TKAF", 1000000);
        SwapToken tokenB = new SwapToken("Token B Fresh", "TKBF", 1000000);
        
        // Deploy SimpleSwap with new tokens
        SimpleSwap simpleSwap = new SimpleSwap(
            address(tokenA),
            address(tokenB)
        );

        vm.stopBroadcast();

        console.log("\n=== FRESH DEPLOYMENT ===");
        console.log("Token A:", address(tokenA));
        console.log("Token B:", address(tokenB));
        console.log("SimpleSwap:", address(simpleSwap));
        
        // Verify configuration
        console.log("\nVerifying SimpleSwap configuration...");
        console.log("SimpleSwap.tokenA():", address(simpleSwap.tokenA()));
        console.log("SimpleSwap.tokenB():", address(simpleSwap.tokenB()));
    }
}
