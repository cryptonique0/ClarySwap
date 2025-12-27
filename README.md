# ClarySwap - Stacks AMM MVP

A decentralized exchange (DEX) built on Stacks blockchain using constant-product AMM (Automated Market Maker) model.

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
- Node.js 18+ and pnpm
- Rust & Cargo (for Clarinet)

### 1. Install Clarinet
```bash
cargo install --locked clarinet
```

### 2. Run Contract Tests
```bash
clarinet test
```

### 3. Start Frontend Development Server
```bash
cd frontend
pnpm install
pnpm dev
```

The frontend will be available at http://localhost:3000

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

- **Smart Contracts**: Clarity
- **Testing**: Clarinet
- **Frontend**: Next.js 14, React 18, TypeScript
- **Wallet Integration**: @stacks/connect
- **Blockchain**: Stacks

## 📝 License

Educational use only. Audit before production deployment.

## 🤝 Contributing

This is an MVP scaffold. Contributions welcome for:
- Enhanced test coverage
- Frontend wallet integration
- Multi-hop routing
- Price oracle integration
- Governance features
