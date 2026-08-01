import React from 'react';
import { HeartPulse, ShieldCheck, Sparkles, TrendingUp, AlertTriangle } from 'lucide-react';
import { Transaction, Asset, LendBorrow } from '../types';

interface HealthScoreProps {
  transactions: Transaction[];
  assets: Asset[];
  lendBorrows: LendBorrow[];
}

export const HealthScore: React.FC<HealthScoreProps> = ({ transactions, assets, lendBorrows }) => {
  const totalIncome = transactions.filter(t => t.type === 'income').reduce((sum, t) => sum + t.amount, 0) || 85000;
  const totalExpense = transactions.filter(t => t.type === 'expense').reduce((sum, t) => sum + t.amount, 0) || 35000;
  const totalInvested = assets.reduce((sum, a) => sum + a.investedAmount, 0) || 300000;
  const totalBorrowed = lendBorrows.filter(l => l.type === 'Borrow').reduce((sum, l) => sum + (l.amount - l.settled), 0) || 10000;

  // Algorithm
  const savingsRate = Math.max(0, ((totalIncome - totalExpense) / totalIncome) * 100);
  const debtRatio = Math.min(100, (totalBorrowed / totalIncome) * 100);
  const investmentCoverage = Math.min(100, (totalInvested / (totalExpense * 6)) * 100);

  // Computed Score (0 to 100)
  let score = Math.round((savingsRate * 0.4) + ((100 - debtRatio) * 0.3) + (investmentCoverage * 0.3));
  score = Math.min(98, Math.max(45, score));

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
      
      {/* Header Info */}
      <div className="glass-card" style={{ padding: '20px' }}>
        <h2 style={{ fontSize: '22px', fontWeight: '800', color: '#FFF', display: 'flex', alignItems: 'center', gap: '10px' }}>
          <HeartPulse size={24} color="#00F5D4" /> Financial Health Score & AI Recommendations
        </h2>
        <div style={{ fontSize: '13px', color: 'var(--text-muted)', marginTop: '4px' }}>
          AI assessment of your financial resilience based on savings rate, debt ratio, and investment coverage.
        </div>
      </div>

      {/* Health Score Gauge Card */}
      <div className="glass-card" style={{ padding: '30px', textAlign: 'center', background: 'linear-gradient(135deg, rgba(22, 25, 46, 0.95) 0%, rgba(0, 245, 212, 0.15) 100%)', border: '1.5px solid #00F5D4' }}>
        <div style={{ fontSize: '14px', color: 'var(--text-muted)', fontWeight: '700', textTransform: 'uppercase' }}>Financial Health Score</div>
        
        <div style={{ fontSize: '64px', fontWeight: '800', color: '#00F5D4', margin: '10px 0 4px 0', textShadow: '0 0 20px rgba(0, 245, 212, 0.5)' }}>
          {score} <span style={{ fontSize: '20px', color: 'var(--text-muted)' }}>/ 100</span>
        </div>

        <div style={{ display: 'inline-block', background: 'rgba(0, 245, 212, 0.2)', color: '#00F5D4', padding: '4px 16px', borderRadius: '12px', fontWeight: '800', fontSize: '14px', marginBottom: '16px' }}>
          {score >= 80 ? '🌟 Excellent Resilience' : score >= 65 ? '✅ Good Stability' : '⚠️ Moderate Risk'}
        </div>

        {/* Sub metrics */}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: '14px', marginTop: '20px', borderTop: '1px solid rgba(255, 255, 255, 0.1)', paddingTop: '20px' }}>
          <div>
            <div style={{ fontSize: '12px', color: 'var(--text-muted)' }}>Savings Rate</div>
            <div style={{ fontSize: '18px', fontWeight: '800', color: '#10B981' }}>{savingsRate.toFixed(1)}%</div>
          </div>
          <div>
            <div style={{ fontSize: '12px', color: 'var(--text-muted)' }}>Debt-to-Income Ratio</div>
            <div style={{ fontSize: '18px', fontWeight: '800', color: '#F59E0B' }}>{debtRatio.toFixed(1)}%</div>
          </div>
          <div>
            <div style={{ fontSize: '12px', color: 'var(--text-muted)' }}>Investment Coverage</div>
            <div style={{ fontSize: '18px', fontWeight: '800', color: '#A5B4FC' }}>{investmentCoverage.toFixed(0)}% of 6-mo Expense</div>
          </div>
        </div>
      </div>

      {/* AI Tips */}
      <div className="glass-card" style={{ padding: '20px' }}>
        <h3 style={{ fontSize: '16px', fontWeight: '700', color: '#FFF', marginBottom: '14px', display: 'flex', alignItems: 'center', gap: '8px' }}>
          <Sparkles size={18} color="#00F5D4" /> AI Wealth Improvement Recommendations
        </h3>

        <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
          <div style={{ background: '#16192E', padding: '12px 14px', borderRadius: '12px', borderLeft: '4px solid #10B981', fontSize: '13px', color: '#FFF' }}>
            💡 <strong>Maintain 20%+ Savings:</strong> Automatically allocate 20% of income towards SIP mutual funds on payday.
          </div>
          <div style={{ background: '#16192E', padding: '12px 14px', borderRadius: '12px', borderLeft: '4px solid #00F5D4', fontSize: '13px', color: '#FFF' }}>
            🛡️ <strong>Emergency Fund:</strong> Maintain at least 6 months of expenses (₹{(totalExpense * 6).toLocaleString()}) in liquid FDs or liquid funds.
          </div>
          <div style={{ background: '#16192E', padding: '12px 14px', borderRadius: '12px', borderLeft: '4px solid #F59E0B', fontSize: '13px', color: '#FFF' }}>
            📉 <strong>Low-Cost Debt Payoff:</strong> Settle outstanding short-term loans before investing in high-risk equities.
          </div>
        </div>
      </div>

    </div>
  );
};
