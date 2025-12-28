# ClarySwap Testnet Deployment Guide

## Prerequisites

1. **Install Clarinet** (if not already installed)
   ```bash
   # Option 1: Using Cargo
   cargo install clarinet --locked
   
   # Option 2: Download binary from GitHub
   # Visit: https://github.com/hirosystems/clarinet/releases
   ```

2. **Get Testnet STX**
   - Visit: https://explorer.hiro.so/sandbox/faucet?chain=testnet
   - Request testnet STX for your deployer address

3. **Install Stacks CLI** (optional, for advanced operations)
   ```bash
   npm install -g @stacks/cli
   ```

## Deployment Steps

### Step 1: Generate Deployment Plan

```bash
cd ClarySwap
./scripts/deploy.sh testnet
```

This creates a deployment plan at: `deployments/default.testnet-plan.yaml`

### Step 2: Review Deployment Plan

Check the generated plan:
```bash
cat deployments/default.testnet-plan.yaml
```

The plan includes deployment order for:
- `sip010-token.clar` - Test token for swaps
- `faucet.clar` - Token faucet for testing
- `factory.clar` - Pair factory contract
- `lp-token.clar` - LP token implementation
- `pair.clar` - AMM pair contract
- `pair-v2.clar` - Enhanced pair with security features
- `router.clar` - Multi-hop router
- `analytics.clar` - On-chain analytics tracker

### Step 3: Configure Deployer Wallet

Edit `deployments/default.testnet-plan.yaml` and set your deployer address:

```yaml
id: 0
name: Devnet deployment
network: testnet
stacks-node: "https://api.testnet.hiro.so"
bitcoin-node: "http://localhost:18332"
plan:
  batches:
    - id: 0
      transactions:
        - contract-publish:
            contract-name: factory
            expected-sender: ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM # Replace with your address
            ...
```

### Step 4: Apply Deployment

```bash
clarinet deployments apply -p deployments/default.testnet-plan.yaml
```

You'll be prompted to:
1. Confirm transaction details
2. Sign with your wallet
3. Wait for confirmations (~10 minutes per batch)

### Step 5: Verify Deployment

Check deployed contracts on Stacks Explorer:
```
https://explorer.hiro.so/txid/{transaction-id}?chain=testnet
```

### Step 6: Update Frontend Configuration

Once deployed, update contract addresses in `frontend/public/tokens.json`:

```json
{
  "tokens": [
    {
      "symbol": "TEST",
      "name": "Test Token",
      "address": "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sip010-token",
      "decimals": 6
    }
  ],
  "contracts": {
    "factory": "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.factory",
    "router": "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.router",
    "faucet": "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.faucet"
  }
}
```

## Alternative: Manual Deployment with Stacks CLI

```bash
# Deploy a single contract
stacks deploy ./contracts/factory.clar \
  --network testnet \
  --contract-name factory

# Deploy with specific nonce
stacks deploy ./contracts/pair.clar \
  --network testnet \
  --contract-name pair \
  --nonce 1
```

## Testing Deployment

1. **Initialize Faucet**
   ```bash
   stacks call ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM faucet init-faucet
   ```

2. **Claim Test Tokens**
   ```bash
   stacks call ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM faucet claim
   ```

3. **Create First Pair**
   ```bash
   stacks call ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM factory create-pair \
     -p token-a='ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sip010-token' \
     -p token-b='ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.test-token-b'
   ```

## Troubleshooting

### Clarinet not found
```bash
# Verify installation
clarinet --version

# Add to PATH if needed
export PATH="$HOME/.cargo/bin:$PATH"
```

### Insufficient STX balance
- Request more from faucet: https://explorer.hiro.so/sandbox/faucet?chain=testnet
- Each contract deployment costs ~0.1-0.5 STX on testnet

### Deployment hangs
- Check node connection: `curl https://api.testnet.hiro.so/v2/info`
- Verify mempool isn't congested on explorer

### Contract deployment failed
- Check syntax: `clarinet check`
- Review error in explorer transaction details
- Ensure contract size is under 100KB limit

## Next Steps

1. ✅ Deploy contracts to testnet
2. 🧪 Test basic functionality (swap, add liquidity)
3. 🔍 Monitor with analytics contract
4. 🐛 Fix any issues found
5. 📝 Document contract addresses
6. 🚀 Deploy to mainnet (when ready)

## Useful Links

- Testnet Explorer: https://explorer.hiro.so/?chain=testnet
- Testnet Faucet: https://explorer.hiro.so/sandbox/faucet?chain=testnet
- Clarinet Docs: https://docs.hiro.so/clarinet
- Stacks Docs: https://docs.stacks.co
