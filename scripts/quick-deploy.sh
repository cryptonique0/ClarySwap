#!/bin/bash
# quick-deploy.sh - Quick deployment helper for ClarySwap testnet
set -e

echo "🚀 ClarySwap Testnet Deployment Helper"
echo "========================================"
echo ""

# Check if Clarinet is available
if [ ! -f "/tmp/clarinet" ]; then
    echo "📥 Downloading Clarinet..."
    curl -L "https://github.com/hirosystems/clarinet/releases/download/v2.5.0/clarinet-linux-x64-glibc.tar.gz" -o /tmp/clarinet-2.5.0.tar.gz
    tar -xzf /tmp/clarinet-2.5.0.tar.gz -C /tmp
    chmod +x /tmp/clarinet
    echo "✅ Clarinet downloaded to /tmp/clarinet"
else
    echo "✅ Clarinet found at /tmp/clarinet"
fi

echo ""
echo "📋 Pre-deployment Checklist:"
echo ""
echo "1. ✅ Clarinet installed"
echo "2. ⏸️  Wallet configured (settings/Testnet.toml)"
echo "3. ⏸️  Wallet funded with testnet STX"
echo ""

# Check if Testnet.toml exists and has a mnemonic
if [ -f "settings/Testnet.toml" ]; then
    if grep -q "YOUR_MNEMONIC_HERE" settings/Testnet.toml; then
        echo "⚠️  WARNING: Testnet.toml still has placeholder mnemonic!"
        echo ""
        echo "To fix this:"
        echo "1. Generate a wallet: npx @stacks/cli make_keychain -t"
        echo "2. Edit settings/Testnet.toml and replace <YOUR_MNEMONIC_HERE> with your 24-word mnemonic"
        echo "3. Get testnet STX: https://explorer.hiro.so/sandbox/faucet?chain=testnet"
        echo ""
        read -p "Press Enter to continue when ready, or Ctrl+C to exit..."
    else
        echo "2. ✅ Wallet configured"
    fi
else
    echo "❌ settings/Testnet.toml not found!"
    exit 1
fi

echo ""
echo "🔨 Generating deployment plan..."
if /tmp/clarinet deployments generate --testnet; then
    echo "✅ Deployment plan generated at: deployments/default.testnet-plan.yaml"
    echo ""
    
    # Show deployment plan summary
    if [ -f "deployments/default.testnet-plan.yaml" ]; then
        echo "📄 Deployment Plan Summary:"
        echo "------------------------"
        grep "contract-name:" deployments/default.testnet-plan.yaml | sed 's/.*contract-name: /  - /'
        echo ""
    fi
    
    read -p "Proceed with deployment? (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo "🚀 Deploying to testnet..."
        echo "This may take 10-20 minutes..."
        echo ""
        
        if /tmp/clarinet deployments apply -p deployments/default.testnet-plan.yaml; then
            echo ""
            echo "✅ Deployment successful!"
            echo ""
            echo "📝 Next steps:"
            echo "1. Note your contract addresses from the output above"
            echo "2. Update frontend/public/tokens.json with contract addresses"
            echo "3. Initialize faucet: stacks call <address> faucet init-faucet"
            echo "4. Test on frontend: cd frontend && pnpm dev"
            echo ""
            echo "View your contracts on explorer:"
            echo "https://explorer.hiro.so/address/<your-address>?chain=testnet"
        else
            echo ""
            echo "❌ Deployment failed!"
            echo "Check the error messages above and:"
            echo "- Ensure you have enough testnet STX"
            echo "- Verify your mnemonic is correct"
            echo "- Check testnet RPC is accessible"
        fi
    else
        echo "Deployment cancelled."
    fi
else
    echo "❌ Failed to generate deployment plan"
    echo "Please check:"
    echo "- Clarinet.toml syntax"
    echo "- settings/Testnet.toml configuration"
    echo "- Contract syntax (run: /tmp/clarinet check)"
fi
