import React, { useState } from 'react';

type FaucetProps = {
  address: string;
  addToast: (message: string, type: 'info' | 'success' | 'error') => void;
};

const styles = {
  card: {
    background: '#111827',
    border: '1px solid #1f2937',
    borderRadius: '12px',
    padding: '20px',
    marginBottom: '16px',
    boxShadow: '0 10px 30px rgba(0,0,0,0.35)',
  },
  button: {
    padding: '12px 14px',
    borderRadius: '10px',
    border: '1px solid #2563eb',
    background: '#2563eb',
    color: 'white',
    cursor: 'pointer',
    fontWeight: 600,
    width: '100%',
  },
  buttonDisabled: {
    padding: '12px 14px',
    borderRadius: '10px',
    border: '1px solid #374151',
    background: '#1f2937',
    color: '#6b7280',
    cursor: 'not-allowed',
    fontWeight: 600,
    width: '100%',
  },
  badge: {
    padding: '4px 8px',
    borderRadius: '8px',
    background: '#1f2937',
    color: '#9ca3af',
    fontSize: '12px',
  },
  info: {
    fontSize: '13px',
    color: '#9ca3af',
    marginTop: '8px',
  },
};

export default function Faucet({ address, addToast }: FaucetProps) {
  const [lastClaim, setLastClaim] = useState<number>(0);
  const [cooldownBlocks, setCooldownBlocks] = useState<number>(0);

  const handleClaim = async () => {
    if (!address) {
      addToast('Connect wallet first', 'error');
      return;
    }

    try {
      // Mock faucet claim - in production, call actual contract
      setLastClaim(Date.now());
      setCooldownBlocks(144); // 24 hours
      addToast('Claimed 1,000,000 TEST tokens! (Mock)', 'success');
      
      // Simulate cooldown countdown
      const interval = setInterval(() => {
        setCooldownBlocks((prev) => {
          if (prev <= 1) {
            clearInterval(interval);
            return 0;
          }
          return prev - 1;
        });
      }, 60000); // Decrement every minute (simulating 10min blocks)
    } catch (error) {
      addToast('Faucet claim failed', 'error');
    }
  };

  const canClaim = cooldownBlocks === 0;
  const hoursLeft = Math.floor((cooldownBlocks * 10) / 60); // Assuming 10min blocks

  return (
    <div style={styles.card}>
      <div style={{ marginBottom: 12, fontWeight: 700 }}>Test Token Faucet</div>
      <div style={styles.info}>
        Claim 1,000,000 TEST tokens every 24 hours for testing on testnet.
      </div>
      
      {!canClaim && (
        <div style={{ ...styles.info, color: '#fbbf24', marginTop: 12 }}>
          ⏳ Cooldown: {hoursLeft}h remaining ({cooldownBlocks} blocks)
        </div>
      )}
      
      <button
        style={canClaim ? styles.button : styles.buttonDisabled}
        onClick={handleClaim}
        disabled={!canClaim}
      >
        {canClaim ? 'Claim TEST Tokens' : `Cooldown Active (${hoursLeft}h)`}
      </button>
      
      <div style={{ display: 'flex', gap: 8, marginTop: 12, justifyContent: 'space-between' }}>
        <span style={styles.badge}>Amount: 1,000,000 TEST</span>
        <span style={styles.badge}>Cooldown: 24h</span>
      </div>
    </div>
  );
}
