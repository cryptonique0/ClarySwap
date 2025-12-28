# 🚀 Testnet Deployment - Quick Start

## Option 1: Interactive Script (Recommended)

```bash
cd ClarySwap
./scripts/quick-deploy.sh
```

This will:
- ✅ Download Clarinet automatically
- ✅ Validate your configuration
- ✅ Show deployment plan before executing
- ✅ Guide you through the process step-by-step

## Option 2: Manual Deployment

### 1. Generate Wallet

```bash
npx @stacks/cli make_keychain -t > wallet.json
cat wallet.json
```

Save your mnemonic and address!

### 2. Get Testnet STX

Visit: https://explorer.hiro.so/sandbox/faucet?chain=testnet

Request ~10 STX to your address from `wallet.json`

### 3. Configure Settings

Edit `settings/Testnet.toml`:

```toml
[network]
name = "testnet"
stacks_node_rpc_address = "https://api.testnet.hiro.so"
deployment_fee_rate = 10

[accounts.deployer]
mnemonic = "your twenty four word mnemonic phrase here from wallet json file output above saved"
```

### 4. Deploy

```bash
/tmp/clarinet deployments generate --testnet
/tmp/clarinet deployments apply -p deployments/default.testnet-plan.yaml
```

### 5. Save Contract Addresses

After deployment completes, note your contract addresses:

```
ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.factory
ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.router
ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.faucet
... etc
```

### 6. Update Frontend

Edit `frontend/public/tokens.json` with your deployed addresses.

### 7. Test

```bash
cd frontend
pnpm install
pnpm dev
```

Open http://localhost:3000 and test!

## 📚 Full Documentation

- **Detailed Guide**: See [TESTNET_DEPLOY.md](./TESTNET_DEPLOY.md)
- **Deployment Docs**: See [DEPLOYMENT.md](./DEPLOYMENT.md)

## ⚡ Quick Commands

```bash
# Check contract syntax
/tmp/clarinet check

# View deployment plan
cat deployments/default.testnet-plan.yaml

# Initialize faucet after deployment
npx @stacks/cli call <YOUR_ADDRESS> faucet init-faucet -k <PRIVATE_KEY> -n testnet
```

## 🔗 Useful Links

- Testnet Explorer: https://explorer.hiro.so/?chain=testnet
- Testnet Faucet: https://explorer.hiro.so/sandbox/faucet?chain=testnet
- Clarinet Docs: https://docs.hiro.so/clarinet

## 💰 Cost Estimate

Total deployment: ~5-6 STX on testnet

## ⚠️ Before Mainnet

1. Audit all contracts
2. Test thoroughly on testnet
3. Review security features
4. Document all functions
5. Set proper access controls
