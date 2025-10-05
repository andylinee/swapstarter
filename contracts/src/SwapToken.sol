// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title SwapToken
 * @dev Simple ERC20 token
 * 
 * Key Concepts:
 * - Inherits from OpenZeppelin's audited ERC20 implementation
 * - Ownable: only deployer can mint new tokens
 * - 18 decimals (standard for most tokens)
 */
contract SwapToken is ERC20, Ownable {
    
    /**
     * @dev Constructor - runs once when contract is deployed
     * @param name Token name (e.g., "Token A")
     * @param symbol Token symbol (e.g., "TKA")
     * @param initialSupply Amount of tokens to mint to deployer
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) ERC20(name, symbol) Ownable(msg.sender) {
        _mint(msg.sender, initialSupply * 10**decimals());
    }

    /**
     * @dev Mint new tokens (only owner can call this)
     * @param to Address to receive tokens
     * @param amount Number of tokens to mint
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    /**
     * @dev Burn tokens from your own balance
     * @param amount Number of tokens to destroy
     */
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}
