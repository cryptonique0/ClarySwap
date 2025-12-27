# ClarySwap - Stacks AMM DEX

A fully-featured decentralized exchange (DEX) built on Stacks blockchain using constant-product AMM (x * y = k) model with multi-hop routing, wallet integration, and advanced trading features.

## ✨ Features

- **🔄 Multi-hop Routing**: Optimized swap paths through intermediate tokens (A → B → C)
- **💰 Liquidity Pools**: Add/remove liquidity with automatic LP token minting
- **🛡️ Slippage Protection**: Configurable slippage tolerance (0-5%)
- **⏰ Deadline Controls**: Transaction expiry protection (1-120 minutes)
- **💱 Real-time Quotes**: Price impact calculation with 0.3% fee display
- **🔗 Wallet Integration**: Connect with Leather or Hiro Wallet
- **📊 Price Impact Display**: See exactly how your trade affects the pool
- **🎨 Dark Theme UI**: Modern, responsive interface
- **🧪 SIP-010 Support**: Full integration with Stacks fungible token standard

## 🏗️ Project Structure

```
ClarySwap/
├── contracts/           # Clarity smart contracts
│   ├── factory.clar    # Pair registry and factory
│   ├── pair.clar       # Constant-product AMM pair
│   ├── router.clar     # Multi-hop swap router
│   ├── lp-token.clar   # LP token (SIP-010-like)
│   └── sip010-token.clar # Example SIP-010 token for testing
├── frontend/           # Next.js frontend (port 3000)
│   ├── pages/          # React pages
│   ├── lib/            # Stacks integration helpers
│   └── public/         # Static assets & token list
├── scripts/            # Deployment scripts
├── tests/              # Clarinet test suite
└── Clarinet.toml       # Clarinet configuration
```

## 🚀 Quick Start

### Prerequisites
- **Node.js 18+** and **pnpm**
- **Clarinet** ([installation guide](https://github.com/hirosystems/clarinet))
- **Stacks Wallet** (Leather or Hiro Wallet browser extension)

### 1. Clone and Setup
```bash
git clone https://github.com/cryptonique0/ClarySwap.git
cd ClarySwap
```

### 2. Test Smart Contracts
```bash
clarinet check  # Verify contract syntax
clarinet test   # Run test suite
```

### 3. Launch Frontend
```bash
cd frontend
pnpm install
pnpm dev
```

🌐 Open http://localhost:3000 and connect your Stacks wallet to start trading!

### 4. Deploy Contracts (Optional)
```bash
# Deploy to testnet
./scripts/deploy.sh

# Or manually
clarinet deployments generate --testnet
clarinet deployments apply -p deployments/default.testnet-plan.yaml
```

## 📋 Contract Overview

### Factory (`factory.clar`)
- Registers and tracks deployed pair contracts
- Maps token pairs to their corresponding pair contract addresses

### Pair (`pair.clar`)
- Implements constant-product AMM (x * y = k)
- 0.3% swap fee (997/1000 fee multiplier)
- Functions:
  - `initialize` - Create a new liquidity pool
  - `mint-liquidity` - Add liquidity and receive LP tokens
  - `burn-liquidity` - Remove liquidity by burning LP tokens
  - `swap-a-for-b` / `swap-b-for-a` - Execute swaps with slippage protection

### Router (`router.clar`)
- Single-hop and multi-hop swap routing
- Deadline-based transaction expiry
- Functions:
  - `swap-single-hop` - Direct swap via one pair contract
  - `swap-two-hop` - Multi-hop routing (A → B → C)
  - `quote-output` - Off-chain price estimation

### SIP-010 Token (`sip010-token.clar`)
- Reference implementation of SIP-010 fungible token standard
- Mint function for testing (owner-only)
- Used for integration testing with pair contracts

### LP Token (`lp-token.clar`)
- Minimal SIP-010-like fungible token for liquidity providers
- Features minter role controls
- **⚠️ Warning**: Mint/burn permissions need hardening before production

## 🔧 Development

### Prerequisites
- Clarinet installed ([installation guide](https://github.com/hirosystems/clarinet))
- Node.js 18+ and pnpm (for frontend development)
- Stacks wallet (Leather or Hiro Wallet)

### Frontend Development
```bash
cd ClarySwap/frontend
pnpm install
pnpm dev  # Starts on http://localhost:3000
```

### Contract Deployment
```bash
# Using the deployment script
cd ClarySwap
./scripts/deploy.sh

# Manual deployment
clarinet deployments generate --testnet
clarinet deployments apply -p deployments/default.testnet-plan.yaml
```

### Integration Helpers
The `frontend/lib/stacks.ts` module provides contract call abstractions:
- `callSwapSingleHop` - Execute token swap
- `callAddLiquidity` - Provide liquidity to pool
- `callRemoveLiquidity` - Withdraw liquidity from pool

Token metadata is managed in `frontend/public/tokens.json`.

### Check Contract Syntax
```bash
clarinet check
```

### Run Tests
```bash
clarinet test
```

## ⚠️ Security Notice

**This is an educational MVP scaffold.** Before deploying to mainnet:

1. **Audit all contracts** - Especially LP token minter permissions
2. **Implement proper access controls** - Restrict mint/burn operations
3. **Add SIP-010 token transfers** - Current implementation is simplified
4. **Test thoroughly** - Run comprehensive integration tests
5. **Consider reentrancy protection** - Add checks-effects-interactions pattern

## 🛠️ Tech Stack

### Blockchain Layer
- **Smart Contracts**: Clarity (Stacks blockchain)
- **Token Standard**: SIP-010 (Fungible Token)
- **Testing Framework**: Clarinet
- **Network**: Stacks Mainnet/Testnet

### Frontend Layer
- **Framework**: Next.js 14.x
- **UI Library**: React 18.x
- **Language**: TypeScript 5.x
- **Wallet SDK**: @stacks/connect ^7.6.0
- **Blockchain SDK**: @stacks/transactions ^6.13.0, @stacks/network ^6.13.0
- **Package Manager**: pnpm

### Development Tools
- **CI/CD**: GitHub Actions
- **Type Checking**: TypeScript strict mode
- **Code Quality**: ESLint, Prettier (via Biome)
- **Deployment**: Automated via scripts/deploy.sh

## 📝 License

Educational use only. Audit before production deployment.

## 🚧 Roadmap

Completed ✅:
- ✅ Constant-product AMM implementation
- ✅ Multi-hop routing (swap-two-hop)
- ✅ Wallet integration (@stacks/connect)
- ✅ Slippage & deadline controls
- ✅ Real-time price quotes
- ✅ SIP-010 token support
- ✅ Deployment automation

Planned 🔜:
- 🔜 Enhanced analytics dashboard
- 🔜 Price oracle integration
- 🔜 Governance features (DAO voting)
- 🔜 Farming/staking rewards
- 🔜 Advanced charting
- 🔜 Transaction history

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 🔗 Links

- **Repository**: https://github.com/cryptonique0/ClarySwap
- **Stacks Docs**: https://docs.stacks.co
- **Clarinet**: https://github.com/hirosystems/clarinet
