import React, { useMemo, useState, useEffect } from 'react';
import { AppConfig, UserSession, showConnect } from '@stacks/connect';
import Faucet from '../components/Faucet';

const appConfig = new AppConfig(['store_write', 'publish_data']);
const userSession = new UserSession({ appConfig });

type Toast = { id: number; message: string; type: 'info' | 'success' | 'error' };
type NetworkKey = 'mainnet' | 'testnet';
type QuoteResult = { amountOut: number; priceImpact: number; minimumReceived: number };
type LiquidityPosition = { poolShare: number; lpBalance: number; claimableA: number; claimableB: number };
type PoolActivity = { type: 'swap' | 'add' | 'remove'; timestamp: number; amount: string; user: string };
type PoolStats = { volume24h: number; fees24h: number; tvl: number };

const styles = {
  page: {
    padding: '32px',
    fontFamily: 'Inter, Arial, sans-serif',
    background: '#0b1224',
    color: '#e5e7eb',
    minHeight: '100vh',
  },
  card: {
    background: '#111827',
    border: '1px solid #1f2937',
    borderRadius: '12px',
    padding: '20px',
    marginBottom: '16px',
    boxShadow: '0 10px 30px rgba(0,0,0,0.35)',
  },
  row: { display: 'flex', gap: '12px', flexWrap: 'wrap' },
  column: { display: 'flex', flexDirection: 'column', gap: '8px', flex: 1 },
  input: {
    padding: '10px 12px',
    borderRadius: '10px',
    border: '1px solid #374151',
    background: '#0f172a',
    color: '#e5e7eb',
    width: '100%',
  },
  label: { fontSize: '13px', color: '#9ca3af' },
  buttonPrimary: {
    padding: '12px 14px',
    borderRadius: '10px',
    border: '1px solid #2563eb',
    background: '#2563eb',
    color: 'white',
    cursor: 'pointer',
    fontWeight: 600,
  },
  buttonGhost: {
    padding: '10px 12px',
    borderRadius: '10px',
    border: '1px solid #374151',
    background: 'transparent',
    color: '#e5e7eb',
    cursor: 'pointer',
  },
  badge: {
    padding: '4px 8px',
    borderRadius: '8px',
    background: '#1f2937',
    color: '#9ca3af',
    fontSize: '12px',
  },
  alert: {
    padding: '10px 12px',
    borderRadius: '8px',
    background: '#7f1d1d',
    border: '1px solid #991b1b',
    color: '#fca5a5',
    fontSize: '13px',
    marginTop: '8px',
  },
  success: {
    padding: '10px 12px',
    borderRadius: '8px',
    background: '#065f46',
    border: '1px solid #047857',
    color: '#6ee7b7',
    fontSize: '13px',
    marginTop: '8px',
  },
};

function useToasts() {
  const [toasts, setToasts] = useState<Toast[]>([]);
  const addToast = (message: string, type: Toast['type'] = 'info') => {
    setToasts((prev) => [...prev, { id: Date.now(), message, type }]);
    setTimeout(() => setToasts((prev) => prev.slice(1)), 3000);
  };
  return { toasts, addToast };
}

function useQuote(amountIn: number, reserveA: number, reserveB: number, aToB: boolean, slippage: number): QuoteResult | null {
  return useMemo(() => {
    if (amountIn <= 0 || reserveA <= 0 || reserveB <= 0) return null;
    const feeMultiplier = 0.997; // 0.3% fee
    const [rin, rout] = aToB ? [reserveA, reserveB] : [reserveB, reserveA];
    const amountInWithFee = amountIn * feeMultiplier;
    const numerator = amountInWithFee * rout;
    const denom = rin + amountInWithFee;
    const out = numerator / denom;
    const priceImpact = (amountInWithFee / rin) * 100;
    const minimumReceived = out * (1 - slippage / 100);
    return { 
      amountOut: Number(out.toFixed(6)), 
      priceImpact: Number(priceImpact.toFixed(3)),
      minimumReceived: Number(minimumReceived.toFixed(6))
    };
  }, [amountIn, reserveA, reserveB, aToB, slippage]);
}

function useLiquidityPosition(lpBalance: number, totalSupply: number, reserveA: number, reserveB: number): LiquidityPosition {
  return useMemo(() => {
    if (totalSupply === 0 || lpBalance === 0) {
      return { poolShare: 0, lpBalance: 0, claimableA: 0, claimableB: 0 };
    }
    const share = (lpBalance / totalSupply) * 100;
    const claimableA = (lpBalance / totalSupply) * reserveA;
    const claimableB = (lpBalance / totalSupply) * reserveB;
    return {
      poolShare: Number(share.toFixed(4)),
      lpBalance,
      claimableA: Number(claimableA.toFixed(6)),
      claimableB: Number(claimableB.toFixed(6)),
    };
  }, [lpBalance, totalSupply, reserveA, reserveB]);
}

export default function Home() {
  const [address, setAddress] = useState<string>('');
  const [network, setNetwork] = useState<NetworkKey>('testnet');
  const [tokenA, setTokenA] = useState('token-a');
  const [tokenB, setTokenB] = useState('token-b');
  const [amountIn, setAmountIn] = useState<number>(0);
  const [aToB, setAToB] = useState(true);
  const [slippage, setSlippage] = useState(0.5);
  const [deadlineMinutes, setDeadlineMinutes] = useState(20);
  const [reserves, setReserves] = useState({ a: 1000, b: 1000 });
  const [lpBalance, setLpBalance] = useState(100);
  const [totalSupply, setTotalSupply] = useState(1000);
  const [activity, setActivity] = useState<PoolActivity[]>([
    { type: 'swap', timestamp: Date.now() - 300000, amount: '10 A → 9.8 B', user: 'SP2ABC...' },
    { type: 'add', timestamp: Date.now() - 600000, amount: '50 A + 50 B', user: 'SP1XYZ...' },
  ]);
  const [stats, setStats] = useState<PoolStats>({ volume24h: 5420, fees24h: 16.26, tvl: 45000 });
  const { toasts, addToast } = useToasts();

  const quote = useQuote(amountIn, reserves.a, reserves.b, aToB, slippage);
  const position = useLiquidityPosition(lpBalance, totalSupply, reserves.a, reserves.b);
  const networkLabel = network === 'mainnet' ? 'Mainnet' : 'Testnet';
  const deadlineSeconds = deadlineMinutes * 60;
  
  // Health checks
  const lowLiquidity = reserves.a < 100 || reserves.b < 100;
  const highPriceImpact = quote && quote.priceImpact > 5;

  const handleConnect = () => {
    showConnect({
      appDetails: { name: 'ClarySwap', icon: 'https://stacks.co/favicon.ico' },
      userSession,
      onFinish: () => {
        const key = network === 'mainnet' ? 'mainnet' : 'testnet';
        const profile = userSession.loadUserData();
        const stx = profile?.profile?.stxAddress?.[key];
        setAddress(stx ?? '');
        addToast('Wallet connected', 'success');
      },
      onCancel: () => addToast('Connection cancelled', 'info'),
    });
  };

  const handleDisconnect = () => {
    userSession.signUserOut();
    setAddress('');
    addToast('Disconnected', 'info');
  };

  const handleSwap = () => {
    if (!address) return addToast('Connect wallet first', 'error');
    if (!quote) return addToast('Enter amount and fetch quote', 'error');
    if (highPriceImpact) return addToast(`High price impact: ${quote.priceImpact}%`, 'error');
    const newActivity: PoolActivity = {
      type: 'swap',
      timestamp: Date.now(),
      amount: `${amountIn} ${aToB ? tokenA : tokenB} → ${quote.amountOut} ${aToB ? tokenB : tokenA}`,
      user: address.slice(0, 8) + '...',
    };
    setActivity([newActivity, ...activity.slice(0, 9)]);
    addToast(`Swap executed: ${amountIn} → ${quote.amountOut} (min: ${quote.minimumReceived})`, 'success');
  };

  const handleAddLiquidity = () => {
    if (!address) return addToast('Connect wallet first', 'error');
    const newActivity: PoolActivity = {
      type: 'add',
      timestamp: Date.now(),
      amount: `${amountIn} A + ${amountIn} B`,
      user: address.slice(0, 8) + '...',
    };
    setActivity([newActivity, ...activity.slice(0, 9)]);
    addToast('Liquidity added successfully', 'success');
  };

  const handleRemoveLiquidity = () => {
    if (!address) return addToast('Connect wallet first', 'error');
    if (lpBalance === 0) return addToast('No LP tokens to burn', 'error');
    const newActivity: PoolActivity = {
      type: 'remove',
      timestamp: Date.now(),
      amount: `${position.claimableA} A + ${position.claimableB} B`,
      user: address.slice(0, 8) + '...',
    };
    setActivity([newActivity, ...activity.slice(0, 9)]);
    addToast(`Liquidity removed: ${position.claimableA} A + ${position.claimableB} B`, 'success');
  };

  return (
    <div style={styles.page}>
      <header style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
        <div>
          <div style={{ fontSize: 18, fontWeight: 700 }}>ClarySwap</div>
          <div style={{ color: '#9ca3af', fontSize: 13 }}>Stacks AMM MVP · Single-hop router</div>
        </div>
        <div style={{ display: 'flex', gap: 10, alignItems: 'center' }}>
          <select
            value={network}
            onChange={(e) => setNetwork(e.target.value as NetworkKey)}
            style={{ ...styles.input, width: 140, padding: '8px 10px' }}
          >
            <option value="testnet">Testnet</option>
            <option value="mainnet">Mainnet</option>
          </select>
          {address ? (
            <>
              <span style={styles.badge}>{networkLabel}</span>
              <span style={styles.badge}>{address.slice(0, 6)}...{address.slice(-4)}</span>
              <button style={styles.buttonGhost} onClick={handleDisconnect}>Disconnect</button>
            </>
          ) : (
            <button style={styles.buttonPrimary} onClick={handleConnect}>Connect Wallet</button>
          )}
        </div>
      </header>

      <section style={styles.card}>
        <div style={{ marginBottom: 12, fontWeight: 700 }}>Analytics</div>
        <div style={{ ...styles.row, gap: 16 }}>
          <div style={{ flex: 1 }}>
            <div style={styles.label}>24h Volume</div>
            <div style={{ fontSize: 20, fontWeight: 600, marginTop: 4 }}>${stats.volume24h.toLocaleString()}</div>
          </div>
          <div style={{ flex: 1 }}>
            <div style={styles.label}>24h Fees</div>
            <div style={{ fontSize: 20, fontWeight: 600, marginTop: 4 }}>${stats.fees24h.toFixed(2)}</div>
          </div>
          <div style={{ flex: 1 }}>
            <div style={styles.label}>Total Value Locked</div>
            <div style={{ fontSize: 20, fontWeight: 600, marginTop: 4 }}>${stats.tvl.toLocaleString()}</div>
          </div>
        </div>
      </section>

      <section style={styles.card}>
        <div style={{ marginBottom: 12, fontWeight: 700 }}>Swap</div>
        {lowLiquidity && (
          <div style={styles.alert}>
            ⚠️ Low liquidity warning: Pool reserves are below recommended levels
          </div>
        )}
        {highPriceImpact && (
          <div style={styles.alert}>
            ⚠️ High price impact: {quote?.priceImpact}% - Consider reducing swap size
          </div>
        )}
        <div style={styles.row}>
          <div style={styles.column}>
            <label style={styles.label}>Token A</label>
            <input style={styles.input} value={tokenA} onChange={(e) => setTokenA(e.target.value)} />
          </div>
          <div style={styles.column}>
            <label style={styles.label}>Token B</label>
            <input style={styles.input} value={tokenB} onChange={(e) => setTokenB(e.target.value)} />
          </div>
          <div style={styles.column}>
            <label style={styles.label}>Direction</label>
            <button style={styles.buttonGhost} onClick={() => setAToB((v) => !v)}>
              {aToB ? `${tokenA} → ${tokenB}` : `${tokenB} → ${tokenA}`}
            </button>
          </div>
        </div>

        <div style={{ ...styles.row, marginTop: 12 }}>
          <div style={styles.column}>
            <label style={styles.label}>Amount In</label>
            <input
              style={styles.input}
              type="number"
              min="0"
              step="0.000001"
              value={amountIn}
              onChange={(e) => setAmountIn(Number(e.target.value))}
            />
          </div>
          <div style={styles.column}>
            <label style={styles.label}>Slippage (%)</label>
            <input
              style={styles.input}
              type="number"
              min="0"
              max="5"
              step="0.1"
              value={slippage}
              onChange={(e) => setSlippage(Number(e.target.value))}
            />
          </div>
          <div style={styles.column}>
            <label style={styles.label}>Deadline (minutes)</label>
            <input
              style={styles.input}
              type="number"
              min="1"
              max="120"
              step="1"
              value={deadlineMinutes}
              onChange={(e) => setDeadlineMinutes(Number(e.target.value))}
            />
          </div>
        </div>

        <div style={{ ...styles.row, marginTop: 12 }}>
          <div style={styles.column}>
            <label style={styles.label}>Reserves (A, B)</label>
            <input
              style={styles.input}
              type="text"
              value={`${reserves.a} / ${reserves.b}`}
              onChange={(e) => {
                const [a, b] = e.target.value.split('/').map((n) => Number(n.trim()));
                if (!Number.isNaN(a) && !Number.isNaN(b)) setReserves({ a, b });
              }}
            />
          </div>
          <div style={{ flex: 1 }}>
            <label style={styles.label}>Quote & Health</label>
            <div style={{ display: 'flex', gap: 10, alignItems: 'center', marginTop: 6 }}>
              <button style={styles.buttonGhost} onClick={() => addToast('Quote refreshed', 'info')}>Get Quote</button>
              <span style={styles.badge}>
                {quote ? `${quote.amountOut} out · impact ${quote.priceImpact}%` : 'Enter amount to quote'}
              </span>
            </div>
            {quote && (
              <div style={{ marginTop: 8, fontSize: 13, color: '#9ca3af' }}>
                Minimum received: {quote.minimumReceived} {aToB ? tokenB : tokenA} (with {slippage}% slippage)
              </div>
            )}
          </div>
        </div>

        <div style={{ display: 'flex', gap: 10, marginTop: 16 }}>
          <button style={styles.buttonPrimary} onClick={handleSwap}>Swap</button>
          <button style={styles.buttonGhost} onClick={handleAddLiquidity}>Add Liquidity</button>
        </div>
      </section>

      <section style={styles.card}>
        <div style={{ marginBottom: 12, fontWeight: 700 }}>Liquidity Position</div>
        {lpBalance > 0 ? (
          <>
            <div style={{ ...styles.row, gap: 16 }}>
              <div style={{ flex: 1 }}>
                <div style={styles.label}>LP Balance</div>
                <div style={{ fontSize: 18, fontWeight: 600, marginTop: 4 }}>{lpBalance} LP</div>
              </div>
              <div style={{ flex: 1 }}>
                <div style={styles.label}>Pool Share</div>
                <div style={{ fontSize: 18, fontWeight: 600, marginTop: 4 }}>{position.poolShare}%</div>
              </div>
            </div>
            <div style={{ marginTop: 12, padding: 12, background: '#0f172a', borderRadius: 8 }}>
              <div style={{ fontSize: 13, color: '#9ca3af', marginBottom: 6 }}>Claimable Amounts:</div>
              <div style={{ fontSize: 14 }}>
                {position.claimableA} {tokenA} + {position.claimableB} {tokenB}
              </div>
            </div>
            <button style={{ ...styles.buttonGhost, marginTop: 12, width: '100%' }} onClick={handleRemoveLiquidity}>
              Remove Liquidity
            </button>
          </>
        ) : (
          <div style={{ color: '#9ca3af', fontSize: 14 }}>No liquidity position. Add liquidity to earn fees.</div>
        )}
      </section>

      <section style={styles.card}>
        <div style={{ marginBottom: 12, fontWeight: 700 }}>Recent Activity</div>
        {activity.length > 0 ? (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            {activity.map((act, idx) => (
              <div
                key={idx}
                style={{
                  padding: 10,
                  background: '#0f172a',
                  borderRadius: 8,
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'center',
                }}
              >
                <div>
                  <span
                    style={{
                      padding: '2px 6px',
                      borderRadius: 4,
                      background: act.type === 'swap' ? '#1e3a8a' : act.type === 'add' ? '#065f46' : '#7f1d1d',
                      fontSize: 11,
                      marginRight: 8,
                    }}
                  >
                    {act.type.toUpperCase()}
                  </span>
                  <span style={{ fontSize: 13 }}>{act.amount}</span>
                </div>
                <div style={{ fontSize: 12, color: '#9ca3af' }}>
                  {act.user} · {Math.floor((Date.now() - act.timestamp) / 60000)}m ago
                </div>
              </div>
            ))}
          </div>
        ) : (
          <div style={{ color: '#9ca3af', fontSize: 14 }}>No recent activity</div>
        )}
      </section>

      {network === 'testnet' && <Faucet address={address} addToast={addToast} />}

      <section style={styles.card}>
        <div style={{ marginBottom: 8, fontWeight: 700 }}>SIP-010 Call Preview (mock)</div>
        <div style={{ color: '#9ca3af', fontSize: 14, lineHeight: 1.5 }}>
          - Approve token spend via SIP-010 `approve`
          <br />
          - Perform swap on pair contract (`swap-a-for-b` or `swap-b-for-a`)
          <br />
          - Slippage: {slippage}% · Deadline: {deadlineSeconds}s
          <br />
          - Direction: {aToB ? `${tokenA} → ${tokenB}` : `${tokenB} → ${tokenA}`}
        </div>
      </section>

      {toasts.length > 0 && (
        <div style={{ position: 'fixed', right: 20, bottom: 20, display: 'flex', flexDirection: 'column', gap: 8 }}>
          {toasts.map((t) => (
            <div
              key={t.id}
              style={{
                padding: '10px 12px',
                borderRadius: '10px',
                background: t.type === 'error' ? '#7f1d1d' : t.type === 'success' ? '#065f46' : '#1f2937',
                border: '1px solid #374151',
              }}
            >
              {t.message}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
