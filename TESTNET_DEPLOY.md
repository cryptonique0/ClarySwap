## Quick Testnet Deployment Setup

### Step 1: Install Clarinet

Clarinet is already downloaded at `/tmp/clarinet`. To install it system-wide:

```bash
sudo cp /tmp/clarinet /usr/local/bin/
clarinet --version
```

### Step 2: Configure Testnet Wallet

Generate a new Stacks wallet or use existing one:

```bash
# Generate new wallet
npx @stacks/cli make_keychain -t 2>&1 | tee wallet.json

# Example output:
# {
#   "mnemonic": "word1 word2 word3 ... word24",
#   "keyInfo": {
#     "privateKey": "...",
#     "address": "ST..."
#   }
# }
```

### Step 3: Fund Your Wallet

Get testnet STX from the faucet:
1. Visit: https://explorer.hiro.so/sandbox/faucet?chain=testnet
2. Enter your address from `wallet.json`
3. Request STX (you'll need ~5-10 STX for deployment)

### Step 4: Update Settings

Edit `settings/Testnet.toml` and add your mnemonic:

```toml
[network]
name = "testnet"
stacks_node_rpc_address = "https://api.testnet.hiro.so"
deployment_fee_rate = 10

[accounts.deployer]
mnemonic = "YOUR 24 WORD MNEMONIC FROM wallet.json"
```

**⚠️ IMPORTANT**: Never commit this file with your real mnemonic!

Add to `.gitignore`:
```
settings/Testnet.toml
settings/Mainnet.toml
wallet.json
```

### Step 5: Generate Deployment Plan

```bash
cd /home/web3joker/ClarySwap/my-swap-dapp/ClarySwap
/tmp/clarinet deployments generate --testnet
```

This creates: `deployments/default.testnet-plan.yaml`

### Step 6: Review Deployment Plan

```bash
cat deployments/default.testnet-plan.yaml
```

The plan will show:
- Deployment order of contracts
- Estimated fees
- Deployer address
- Transaction details

### Step 7: Execute Deployment

```bash
/tmp/clarinet deployments apply -p deployments/default.testnet-plan.yaml
```

This will:
1. Broadcast transactions to testnet
2. Wait for confirmations (~10 min per contract)
3. Save deployment receipts

### Step 8: Save Contract Addresses

After successful deployment, note the contract addresses from the output:

```bash
# Example addresses
ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.factory
ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.pair
ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.router
ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.faucet
... (and others)
```

### Step 9: Update Frontend

Edit `frontend/public/tokens.json`:

```json
{
  "network": "testnet",
  "contracts": {
    "factory": "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.factory",
    "router": "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.router",
    "pair": "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.pair",
    "faucet": "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.faucet",
    "analytics": "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.analytics"
  },
  "tokens": [
    {
      "symbol": "TEST",
      "name": "Test Token",
      "address": "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sip010-token",
      "decimals": 6,
      "logoUrl": ""
    }
  ]
}
```

### Step 10: Initialize Contracts

After deployment, initialize the faucet:

```bash
npx @stacks/cli call ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM faucet init-faucet \
  -k YOUR_PRIVATE_KEY \
  -n testnet
```

### Step 11: Test on Frontend

```bash
cd frontend
pnpm dev
```

Open http://localhost:3000 and:
1. Connect your wallet
2. Switch to testnet
3. Claim tokens from faucet
4. Try a test swap

## Deployment Cost Estimate

| Contract | Estimated Fee |
|----------|---------------|
| factory | 0.5 STX |
| pair | 0.8 STX |
| pair-v2 | 1.2 STX |
| router | 0.7 STX |
| lp-token | 0.6 STX |
| sip010-token | 0.4 STX |
| faucet | 0.5 STX |
| analytics | 0.6 STX |
| **Total** | **~5.3 STX** |

## Troubleshooting

### "Insufficient balance" error
Request more STX from faucet or reduce deployment batch size

### "Nonce conflict" error
Wait for previous transaction to confirm, then retry

### "Contract too large" error
Split complex contracts into smaller modules

### "Timeout" error
Testnet may be slow - wait and check explorer for confirmation

## Alternative: Use Hiro Platform

For easier deployment:
1. Visit: https://platform.hiro.so
2. Create account
3. Upload contracts via UI
4. Deploy with one click

## Next Steps After Deployment

✅ Verify contracts on explorer
✅ Initialize faucet with tokens
✅ Create first trading pair
✅ Add initial liquidity
✅ Test swaps
✅ Monitor with analytics
✅ Document deployment for team
