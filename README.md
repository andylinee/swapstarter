# SwapStarter - Learning Blockchain DEX Development

A full-stack decentralized exchange (DEX) built from scratch to learn blockchain development.

## 🎯 Learning Journey

### Phase 1: Wallet Connection ✅
- Implemented wallet connection with RainbowKit
- Network switching and balance display
- Multi-wallet provider support

### Phase 2: ERC20 Tokens ✅
- Created SwapToken (ERC20) with mint/burn
- Deployed to Sepolia testnet
- Comprehensive test suite (7 tests)
- Frontend integration for viewing/transferring

### Phase 3: AMM Swap Contract ✅ **JUST COMPLETED**
- Implemented constant product formula (x × y = k)
- Liquidity pool with add/remove functionality
- Token swaps with slippage protection
- Deployed with 1000 TKA + 1000 TKB initial liquidity
- Solved real-world SafeERC20 compatibility issue

## 📊 Deployed Contracts (Sepolia)

| Contract | Address | Etherscan |
|----------|---------|-----------|
| Token A (TKA) | `0xd4F8...7374` | [View](https://sepolia.etherscan.io/address/0xd4F839332B5FfDdC5766f375b2196909f05D7374) |
| Token B (TKB) | `0xb8c1...fC6d` | [View](https://sepolia.etherscan.io/address/0xb8c1B5Be3bA28da0c286c91185E71014f2c8fC6d) |
| SimpleSwap | `0x1286...4706` | [View](https://sepolia.etherscan.io/address/0x12861dF7aa3b87b9F77Af9487e599092637b4706) |

## 🛠️ Tech Stack

**Smart Contracts:**
- Solidity ^0.8.20
- Foundry (testing & deployment)
- OpenZeppelin contracts

**Frontend:**
- Next.js 14 (App Router)
- TypeScript
- wagmi & viem
- RainbowKit
- TailwindCSS

## 🧪 Key Learnings

### AMM Mathematics
```code=
Constant Product: x × y = k
Example: 1000 TKA × 1000 TKB = 1,000,000
Swap 100 TKB → Get 90.91 TKA
New: 909.09 TKA × 1100 TKB = 1,000,000 ✓
```
### Real-World Issues Solved
- **SafeERC20 Compatibility**: Debugged and fixed transfer issues
- **Allowance Management**: Proper approve/transferFrom flow
- **Gas Estimation**: Understanding transaction costs
- **State Synchronization**: Keeping frontend in sync with blockchain