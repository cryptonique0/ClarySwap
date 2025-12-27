#!/bin/bash
# deploy.sh - Deploy ClarySwap contracts to Stacks testnet or mainnet
set -e

NETWORK=${1:-testnet}
DEPLOYER=${2:-deployer}

echo "Deploying ClarySwap contracts to $NETWORK..."

# Deploy SIP-010 test token
echo "1/5 Deploying sip010-token..."
clarinet deployments generate --testnet --no-batch --manifest Clarinet.toml

# Deploy factory
echo "2/5 Deploying factory..."
clarinet deployments apply --manifest Clarinet.toml

# Deploy LP token
echo "3/5 Deploying lp-token..."
# (Automated via Clarinet deployment plan)

# Deploy pair
echo "4/5 Deploying pair..."
# (Automated via Clarinet deployment plan)

# Deploy router
echo "5/5 Deploying router..."
# (Automated via Clarinet deployment plan)

echo "✅ Deployment complete!"
echo "Update frontend/public/tokens.json with deployed contract addresses."
