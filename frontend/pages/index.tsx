import React, { useMemo, useState } from 'react';
import { AppConfig, UserSession, showConnect } from '@stacks/connect';

const appConfig = new AppConfig(['store_write', 'publish_data']);
const userSession = new UserSession({ appConfig });

type Toast = { id: number; message: string; type: 'info' | 'success' | 'error' };
type NetworkKey = 'mainnet' | 'testnet';
type QuoteResult = { amountOut: number; priceImpact: number };

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
};

function useToasts() {
  const [toasts, setToasts] = useState<Toast[]>([]);
  const addToast = (message: string, type: Toast['type'] = 'info') => {
    setToasts((prev) => [...prev, { id: Date.now(), message, type }]);
    setTimeout(() => setToasts((prev) => prev.slice(1)), 3000);
  };
  return { toasts, addToast };
}

function useQuote(amountIn: number, reserveA: number, reserveB: number, aToB: boolean): QuoteResult | null {
  return useMemo(() => {
    if (amountIn <= 0 || reserveA <= 0 || reserveB <= 0) return null;
    const feeMultiplier = 0.997; // 0.3% fee
    const [rin, rout] = aToB ? [reserveA, reserveB] : [reserveB, reserveA];
    const amountInWithFee = amountIn * feeMultiplier;
    const numerator = amountInWithFee * rout;
    const denom = rin + amountInWithFee;
    const out = numerator / denom;
    const priceImpact = (amountInWithFee / rin) * 100;
    return { amountOut: Number(out.toFixed(6)), priceImpact: Number(priceImpact.toFixed(3)) };
  }, [amountIn, reserveA, reserveB, aToB]);
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
  const { toasts, addToast } = useToasts();

  const quote = useQuote(amountIn, reserves.a, reserves.b, aToB);
  const networkLabel = network === 'mainnet' ? 'Mainnet' : 'Testnet';
  const deadlineSeconds = deadlineMinutes * 60;

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
    addToast(`Swap prepared: ${amountIn} ${aToB ? tokenA : tokenB} → ${quote.amountOut} ${aToB ? tokenB : tokenA}`, 'success');
  };

  const handleAddLiquidity = () => {
    if (!address) return addToast('Connect wallet first', 'error');
    addToast('Add liquidity flow prepared (mock)', 'success');
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
        <div style={{ marginBottom: 12, fontWeight: 700 }}>Swap</div>
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
            <label style={styles.label}>Quote</label>
            <div style={{ display: 'flex', gap: 10, alignItems: 'center', marginTop: 6 }}>
              <button style={styles.buttonGhost} onClick={() => addToast('Quote refreshed', 'info')}>Get Quote</button>
              <span style={styles.badge}>
                {quote ? `${quote.amountOut} out · impact ${quote.priceImpact}%` : 'Enter amount to quote'}
              </span>
              <span style={styles.badge}>Deadline {deadlineSeconds}s</span>
            </div>
          </div>
        </div>

        <div style={{ display: 'flex', gap: 10, marginTop: 16 }}>
          <button style={styles.buttonPrimary} onClick={handleSwap}>Swap</button>
          <button style={styles.buttonGhost} onClick={handleAddLiquidity}>Add Liquidity</button>
        </div>
      </section>

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
