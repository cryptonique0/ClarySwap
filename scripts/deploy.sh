#!/bin/bash
# deploy.sh - Deploy ClarySwap contracts to Stacks testnet or mainnet
set -e

NETWORK=${1:-testnet}

echo "🚀 Deploying ClarySwap contracts to $NETWORK..."
echo ""

# Check if clarinet is available
if ! command -v clarinet &> /dev/null; then
    echo "❌ Clarinet not found. Please install it first:"
    echo "   cargo install clarinet --locked"
    echo "   OR download from: https://github.com/hirosystems/clarinet/releases"
    exit 1
fi

# Generate deployment plan
echo "📝 Generating deployment plan for $NETWORK..."
if [ "$NETWORK" = "mainnet" ]; then
    clarinet deployments generate --mainnet
else
    clarinet deployments generate --testnet
fi

echo ""
echo "📋 Deployment plan generated in: deployments/default.$NETWORK-plan.yaml"
echo ""
echo "To proceed with deployment:"
echo "1. Review the deployment plan"
echo "2. Ensure you have STX in your deployer wallet"
echo "3. Run: clarinet deployments apply -p deployments/default.$NETWORK-plan.yaml"
echo ""
echo "For testnet STX faucet: https://explorer.hiro.so/sandbox/faucet?chain=testnet"
echo ""