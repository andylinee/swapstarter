// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title SimpleSwap
 * @dev A simplified AMM (Automated Market Maker) implementation
 * 
 * Key Concepts:
 * - Constant Product Formula: x * y = k
 * - Liquidity Pools: Users can add/remove liquidity
 * - Automated Pricing: No order books needed
 * 
 * Inspired by Uniswap V2 but simplified for learning
 */
contract SimpleSwap is ReentrancyGuard {
    using SafeERC20 for IERC20;

    // State variables - stored permanently on blockchain
    IERC20 public immutable tokenA;
    IERC20 public immutable tokenB;
    
    uint256 public reserveA;  // How much Token A is in the pool
    uint256 public reserveB;  // How much Token B is in the pool
    
    uint256 public totalLiquidity;  // Total liquidity provider shares
    mapping(address => uint256) public liquidity;  // Each provider's share

    // Events - for frontend to listen to changes
    event LiquidityAdded(
        address indexed provider,
        uint256 amountA,
        uint256 amountB,
        uint256 liquidityMinted
    );
    
    event LiquidityRemoved(
        address indexed provider,
        uint256 amountA,
        uint256 amountB,
        uint256 liquidityBurned
    );
    
    event Swap(
        address indexed user,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    /**
     * @dev Constructor - sets the two tokens that can be swapped
     * @param _tokenA Address of first token
     * @param _tokenB Address of second token
     */
    constructor(address _tokenA, address _tokenB) {
        require(_tokenA != address(0), "Invalid token A");
        require(_tokenB != address(0), "Invalid token B");
        require(_tokenA != _tokenB, "Tokens must be different");
        
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    /**
     * @dev Add liquidity to the pool
     * @param amountA Amount of Token A to add
     * @param amountB Amount of Token B to add
     * @return liquidityMinted Amount of liquidity tokens minted
     * 
     * First liquidity provider sets the initial price ratio
     * Subsequent providers must match the current ratio
     */
    function addLiquidity(
        uint256 amountA,
        uint256 amountB
    ) external nonReentrant returns (uint256 liquidityMinted) {
        require(amountA > 0 && amountB > 0, "Amounts must be greater than 0");

        // Transfer tokens from user to this contract
        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);

        // Calculate liquidity to mint
        if (totalLiquidity == 0) {
            // First liquidity provider
            // Use geometric mean to calculate initial liquidity
            liquidityMinted = sqrt(amountA * amountB);
            require(liquidityMinted > 0, "Insufficient liquidity minted");
        } else {
            // Subsequent providers must maintain the ratio
            // Calculate based on both tokens and take minimum to prevent manipulation
            uint256 liquidityA = (amountA * totalLiquidity) / reserveA;
            uint256 liquidityB = (amountB * totalLiquidity) / reserveB;
            liquidityMinted = liquidityA < liquidityB ? liquidityA : liquidityB;
        }

        require(liquidityMinted > 0, "Insufficient liquidity minted");

        // Update state
        liquidity[msg.sender] += liquidityMinted;
        totalLiquidity += liquidityMinted;
        reserveA += amountA;
        reserveB += amountB;

        emit LiquidityAdded(msg.sender, amountA, amountB, liquidityMinted);
    }

    /**
     * @dev Remove liquidity from the pool
     * @param liquidityAmount Amount of liquidity tokens to burn
     * @return amountA Amount of Token A returned
     * @return amountB Amount of Token B returned
     */
    function removeLiquidity(
        uint256 liquidityAmount
    ) external nonReentrant returns (uint256 amountA, uint256 amountB) {
        require(liquidityAmount > 0, "Amount must be greater than 0");
        require(
            liquidity[msg.sender] >= liquidityAmount,
            "Insufficient liquidity"
        );

        // Calculate amounts to return (proportional to share)
        amountA = (liquidityAmount * reserveA) / totalLiquidity;
        amountB = (liquidityAmount * reserveB) / totalLiquidity;

        require(amountA > 0 && amountB > 0, "Insufficient liquidity burned");

        // Update state
        liquidity[msg.sender] -= liquidityAmount;
        totalLiquidity -= liquidityAmount;
        reserveA -= amountA;
        reserveB -= amountB;

        // Transfer tokens back to user
        tokenA.safeTransfer(msg.sender, amountA);
        tokenB.safeTransfer(msg.sender, amountB);

        emit LiquidityRemoved(msg.sender, amountA, amountB, liquidityAmount);
    }

    /**
     * @dev Swap Token A for Token B
     * @param amountAIn Amount of Token A to swap
     * @param minAmountBOut Minimum amount of Token B expected (slippage protection)
     * @return amountBOut Actual amount of Token B received
     * 
     * Uses constant product formula: x * y = k
     */
    function swapAforB(
        uint256 amountAIn,
        uint256 minAmountBOut
    ) external nonReentrant returns (uint256 amountBOut) {
        require(amountAIn > 0, "Amount must be greater than 0");
        require(reserveA > 0 && reserveB > 0, "Insufficient liquidity");

        // Calculate output amount using constant product formula
        amountBOut = getAmountOut(amountAIn, reserveA, reserveB);
        require(amountBOut >= minAmountBOut, "Slippage too high");
        require(amountBOut < reserveB, "Insufficient liquidity for swap");

        // Transfer tokens
        tokenA.transferFrom(msg.sender, address(this), amountAIn);
        tokenB.transfer(msg.sender, amountBOut);

        // Update reserves
        reserveA += amountAIn;
        reserveB -= amountBOut;

        emit Swap(
            msg.sender,
            address(tokenA),
            address(tokenB),
            amountAIn,
            amountBOut
        );
    }

    /**
     * @dev Swap Token B for Token A
     * @param amountBIn Amount of Token B to swap
     * @param minAmountAOut Minimum amount of Token A expected (slippage protection)
     * @return amountAOut Actual amount of Token A received
     */
    function swapBforA(
        uint256 amountBIn,
        uint256 minAmountAOut
    ) external nonReentrant returns (uint256 amountAOut) {
        require(amountBIn > 0, "Amount must be greater than 0");
        require(reserveA > 0 && reserveB > 0, "Insufficient liquidity");

        // Calculate output amount
        amountAOut = getAmountOut(amountBIn, reserveB, reserveA);
        require(amountAOut >= minAmountAOut, "Slippage too high");
        require(amountAOut < reserveA, "Insufficient liquidity for swap");

        // Transfer tokens
        tokenB.transferFrom(msg.sender, address(this), amountBIn);
        tokenA.transfer(msg.sender, amountAOut);

        // Update reserves
        reserveB += amountBIn;
        reserveA -= amountAOut;

        emit Swap(
            msg.sender,
            address(tokenB),
            address(tokenA),
            amountBIn,
            amountAOut
        );
    }

    /**
     * @dev Calculate output amount using constant product formula
     * @param amountIn Amount of input token
     * @param reserveIn Reserve of input token
     * @param reserveOut Reserve of output token
     * @return amountOut Amount of output token
     * 
     * Formula: amountOut = (amountIn * reserveOut) / (reserveIn + amountIn)
     * 
     * This is derived from: (reserveIn + amountIn) * (reserveOut - amountOut) = k
     * where k = reserveIn * reserveOut
     * 
     * Note: In production, you'd apply a 0.3% fee here
     */
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure returns (uint256 amountOut) {
        require(amountIn > 0, "Insufficient input amount");
        require(reserveIn > 0 && reserveOut > 0, "Insufficient liquidity");

        // Constant product formula (simplified, no fee)
        // In Uniswap: amountInWithFee = amountIn * 997 (0.3% fee)
        uint256 numerator = amountIn * reserveOut;
        uint256 denominator = reserveIn + amountIn;
        amountOut = numerator / denominator;
    }

    /**
     * @dev Get current price of Token A in terms of Token B
     * @return price How much Token B you get for 1 Token A (scaled by 1e18)
     */
    function getPrice() external view returns (uint256 price) {
        require(reserveA > 0, "No liquidity");
        // Price = reserveB / reserveA (scaled to avoid decimals)
        price = (reserveB * 1e18) / reserveA;
    }

    /**
     * @dev Square root function (for initial liquidity calculation)
     * @param y Input value
     * @return z Square root of y
     * 
     * Babylonian method for square root
     */
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}
