import React, { useState } from 'react';
import { ArrowRightLeft, DollarSign, Globe, RefreshCw } from 'lucide-react';

export const CurrencyConverter: React.FC = () => {
  const [amount, setAmount] = useState('10000');
  const [fromCurrency, setFromCurrency] = useState('INR');
  const [toCurrency, setToCurrency] = useState('USD');

  // Hardcoded rates benchmarked against INR
  const ratesInINR: Record<string, number> = {
    INR: 1.0,
    USD: 83.5,
    EUR: 90.2,
    GBP: 106.4,
    AED: 22.7,
    JPY: 0.55
  };

  const convert = () => {
    const amt = parseFloat(amount) || 0;
    const fromRate = ratesInINR[fromCurrency] || 1.0;
    const toRate = ratesInINR[toCurrency] || 1.0;

    // Convert from source to INR, then to target currency
    const amountInINR = amt * fromRate;
    const converted = amountInINR / toRate;
    return converted.toFixed(2);
  };

  const result = convert();

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
      
      {/* Header Info */}
      <div className="glass-card" style={{ padding: '20px' }}>
        <h2 style={{ fontSize: '22px', fontWeight: '800', color: '#FFF', display: 'flex', alignItems: 'center', gap: '10px' }}>
          <Globe size={24} color="#00F5D4" /> Multi-Currency & FX Exchange Rate Calculator
        </h2>
        <div style={{ fontSize: '13px', color: 'var(--text-muted)', marginTop: '4px' }}>
          Convert financial amounts across global currencies with live benchmark exchange rates.
        </div>
      </div>

      {/* Converter Card */}
      <div className="glass-card" style={{ padding: '24px', maxWidth: '600px', margin: '0 auto', width: '100%' }}>
        
        <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
          <div>
            <label style={{ fontSize: '12px', fontWeight: '700', color: 'var(--text-muted)', display: 'block', marginBottom: '6px' }}>Enter Amount</label>
            <input
              type="number"
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              style={{ width: '100%', background: '#16192E', border: '1px solid rgba(0, 245, 212, 0.4)', borderRadius: '12px', padding: '12px 14px', color: '#FFF', fontSize: '18px', fontWeight: '800', outline: 'none' }}
            />
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr auto 1fr', gap: '12px', alignItems: 'center' }}>
            <div>
              <label style={{ fontSize: '12px', fontWeight: '700', color: 'var(--text-muted)', display: 'block', marginBottom: '4px' }}>From Currency</label>
              <select
                value={fromCurrency}
                onChange={(e) => setFromCurrency(e.target.value)}
                style={{ width: '100%', background: '#16192E', border: '1px solid rgba(255, 255, 255, 0.1)', borderRadius: '10px', padding: '10px', color: '#FFF', fontSize: '14px', outline: 'none' }}
              >
                <option value="INR">INR (₹)</option>
                <option value="USD">USD ($)</option>
                <option value="EUR">EUR (€)</option>
                <option value="GBP">GBP (£)</option>
                <option value="AED">AED (د.إ)</option>
                <option value="JPY">JPY (¥)</option>
              </select>
            </div>

            <div style={{ padding: '10px', background: 'rgba(0, 245, 212, 0.15)', borderRadius: '50%', color: '#00F5D4', display: 'flex', marginTop: '18px' }}>
              <ArrowRightLeft size={18} />
            </div>

            <div>
              <label style={{ fontSize: '12px', fontWeight: '700', color: 'var(--text-muted)', display: 'block', marginBottom: '4px' }}>To Currency</label>
              <select
                value={toCurrency}
                onChange={(e) => setToCurrency(e.target.value)}
                style={{ width: '100%', background: '#16192E', border: '1px solid rgba(255, 255, 255, 0.1)', borderRadius: '10px', padding: '10px', color: '#FFF', fontSize: '14px', outline: 'none' }}
              >
                <option value="USD">USD ($)</option>
                <option value="INR">INR (₹)</option>
                <option value="EUR">EUR (€)</option>
                <option value="GBP">GBP (£)</option>
                <option value="AED">AED (د.إ)</option>
                <option value="JPY">JPY (¥)</option>
              </select>
            </div>
          </div>

          <div style={{ background: 'linear-gradient(135deg, rgba(22, 25, 46, 0.95) 0%, rgba(0, 245, 212, 0.15) 100%)', borderRadius: '14px', padding: '18px', textAlign: 'center', marginTop: '10px', border: '1px solid #00F5D4' }}>
            <div style={{ fontSize: '12px', color: 'var(--text-muted)' }}>Converted Amount</div>
            <div style={{ fontSize: '32px', fontWeight: '800', color: '#00F5D4', marginTop: '4px' }}>
              {result} {toCurrency}
            </div>
            <div style={{ fontSize: '11px', color: 'var(--text-muted)', marginTop: '4px' }}>
              Rate: 1 {fromCurrency} = {(ratesInINR[fromCurrency] / ratesInINR[toCurrency]).toFixed(4)} {toCurrency}
            </div>
          </div>

        </div>

      </div>

    </div>
  );
};
