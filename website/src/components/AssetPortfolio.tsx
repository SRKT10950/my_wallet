import React, { useState } from 'react';
import { TrendingUp, PlusCircle, PieChart, Shield, Landmark } from 'lucide-react';
import { Asset } from '../types';

interface AssetPortfolioProps {
  assets: Asset[];
  onAddAsset: (a: Asset) => void;
}

export const AssetPortfolio: React.FC<AssetPortfolioProps> = ({ assets, onAddAsset }) => {
  const [name, setName] = useState('');
  const [type, setType] = useState<'Mutual Fund' | 'Stock' | 'Gold' | 'Fixed Deposit' | 'Real Estate'>('Mutual Fund');
  const [investedAmount, setInvestedAmount] = useState('');
  const [currentValue, setCurrentValue] = useState('');

  const totalInvested = assets.reduce((acc, a) => acc + a.investedAmount, 0);
  const totalCurrent = assets.reduce((acc, a) => acc + a.currentValue, 0);
  const netProfit = totalCurrent - totalInvested;
  const netProfitPercent = totalInvested > 0 ? ((netProfit / totalInvested) * 100).toFixed(1) : '0.0';

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim() || !investedAmount.trim()) return;

    const inv = parseFloat(investedAmount) || 0;
    const cur = parseFloat(currentValue) || inv;

    const newAsset: Asset = {
      id: Date.now(),
      name: name.trim(),
      type,
      investedAmount: inv,
      currentValue: cur,
      purchaseDate: new Date().toISOString().split('T')[0]
    };

    onAddAsset(newAsset);
    setName('');
    setInvestedAmount('');
    setCurrentValue('');
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
      
      {/* Portfolio Overview Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(260px, 1fr))', gap: '16px' }}>
        
        <div className="glass-card" style={{ padding: '20px', background: 'linear-gradient(135deg, rgba(22, 25, 46, 0.9) 0%, rgba(99, 102, 241, 0.2) 100%)' }}>
          <div style={{ fontSize: '13px', color: 'var(--text-muted)', fontWeight: '600' }}>Current Portfolio Valuation</div>
          <div style={{ fontSize: '32px', fontWeight: '800', color: '#A5B4FC', marginTop: '4px' }}>₹{totalCurrent.toLocaleString()}</div>
          <div style={{ fontSize: '12px', color: 'var(--text-muted)', marginTop: '4px' }}>Invested: ₹{totalInvested.toLocaleString()}</div>
        </div>

        <div className="glass-card" style={{ padding: '20px', background: 'linear-gradient(135deg, rgba(22, 25, 46, 0.9) 0%, rgba(16, 185, 129, 0.2) 100%)' }}>
          <div style={{ fontSize: '13px', color: 'var(--text-muted)', fontWeight: '600' }}>Net Investment Profit / Returns</div>
          <div style={{ fontSize: '32px', fontWeight: '800', color: '#10B981', marginTop: '4px' }}>+₹{netProfit.toLocaleString()}</div>
          <div style={{ fontSize: '12px', color: '#10B981', marginTop: '4px', fontWeight: '700' }}>⚡ +{netProfitPercent}% All-Time Gain</div>
        </div>

      </div>

      {/* New Asset Form */}
      <div className="glass-card" style={{ padding: '20px' }}>
        <h3 style={{ fontSize: '18px', fontWeight: '800', color: '#FFF', marginBottom: '14px', display: 'flex', alignItems: 'center', gap: '8px' }}>
          <PlusCircle size={20} color="#00F5D4" /> Log Investment Asset
        </h3>

        <form onSubmit={handleSubmit} style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '14px' }}>
          
          <div>
            <label style={{ fontSize: '12px', fontWeight: '700', color: 'var(--text-muted)', display: 'block', marginBottom: '4px' }}>Asset Name / Scheme *</label>
            <input
              type="text"
              required
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="e.g. Reliance Growth Mutual Fund"
              style={{ width: '100%', background: '#16192E', border: '1px solid rgba(255, 255, 255, 0.1)', borderRadius: '10px', padding: '10px 12px', color: '#FFF', fontSize: '14px', outline: 'none' }}
            />
          </div>

          <div>
            <label style={{ fontSize: '12px', fontWeight: '700', color: 'var(--text-muted)', display: 'block', marginBottom: '4px' }}>Asset Category</label>
            <select
              value={type}
              onChange={(e) => setType(e.target.value as any)}
              style={{ width: '100%', background: '#16192E', border: '1px solid rgba(255, 255, 255, 0.1)', borderRadius: '10px', padding: '10px 12px', color: '#FFF', fontSize: '14px', outline: 'none' }}
            >
              <option value="Mutual Fund">Mutual Fund</option>
              <option value="Stock">Stock</option>
              <option value="Gold">Gold</option>
              <option value="Fixed Deposit">Fixed Deposit</option>
              <option value="Real Estate">Real Estate</option>
            </select>
          </div>

          <div>
            <label style={{ fontSize: '12px', fontWeight: '700', color: 'var(--text-muted)', display: 'block', marginBottom: '4px' }}>Invested Amount (₹) *</label>
            <input
              type="number"
              required
              value={investedAmount}
              onChange={(e) => setInvestedAmount(e.target.value)}
              placeholder="e.g. 50000"
              style={{ width: '100%', background: '#16192E', border: '1px solid rgba(255, 255, 255, 0.1)', borderRadius: '10px', padding: '10px 12px', color: '#FFF', fontSize: '14px', outline: 'none' }}
            />
          </div>

          <div>
            <label style={{ fontSize: '12px', fontWeight: '700', color: 'var(--text-muted)', display: 'block', marginBottom: '4px' }}>Current Market Value (₹)</label>
            <input
              type="number"
              value={currentValue}
              onChange={(e) => setCurrentValue(e.target.value)}
              placeholder="e.g. 62500"
              style={{ width: '100%', background: '#16192E', border: '1px solid rgba(255, 255, 255, 0.1)', borderRadius: '10px', padding: '10px 12px', color: '#FFF', fontSize: '14px', outline: 'none' }}
            />
          </div>

          <div style={{ display: 'flex', alignItems: 'flex-end', gridColumn: '1 / -1' }}>
            <button type="submit" className="neon-btn" style={{ width: '100%', height: '42px', justifyContent: 'center' }}>
              Add to Asset Portfolio
            </button>
          </div>

        </form>
      </div>

      {/* Asset List */}
      <div className="glass-card" style={{ padding: '20px' }}>
        <h3 style={{ fontSize: '18px', fontWeight: '800', color: '#FFF', marginBottom: '16px' }}>Portfolio Investments ({assets.length})</h3>

        <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
          {assets.map((a) => {
            const gain = a.currentValue - a.investedAmount;
            return (
              <div key={a.id} style={{ background: '#16192E', border: '1px solid rgba(0, 245, 212, 0.3)', borderRadius: '16px', padding: '16px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                
                <div>
                  <div style={{ fontSize: '16px', fontWeight: '800', color: '#FFF' }}>{a.name}</div>
                  <div style={{ marginTop: '4px' }}>
                    <span className="badge-category">{a.type}</span>
                    <span style={{ fontSize: '12px', color: 'var(--text-muted)', marginLeft: '8px' }}>Purchased: {a.purchaseDate}</span>
                  </div>
                </div>

                <div style={{ textAlign: 'right' }}>
                  <div style={{ fontSize: '18px', fontWeight: '800', color: '#FFF' }}>₹{a.currentValue.toLocaleString()}</div>
                  <div style={{ fontSize: '12px', color: gain >= 0 ? '#10B981' : '#EF4444', fontWeight: '700' }}>
                    {gain >= 0 ? '+' : ''}₹{gain.toLocaleString()}
                  </div>
                </div>

              </div>
            );
          })}
        </div>
      </div>

    </div>
  );
};
