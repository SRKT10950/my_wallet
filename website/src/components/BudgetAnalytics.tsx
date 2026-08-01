import React, { useState } from 'react';
import { Target, AlertCircle, CheckCircle, TrendingUp, DollarSign } from 'lucide-react';
import { Transaction } from '../types';

interface BudgetAnalyticsProps {
  transactions: Transaction[];
}

interface CategoryBudget {
  category: string;
  limit: number;
}

export const BudgetAnalytics: React.FC<BudgetAnalyticsProps> = ({ transactions }) => {
  const [budgets, setBudgets] = useState<CategoryBudget[]>([
    { category: 'Groceries', limit: 10000 },
    { category: 'Utilities', limit: 5000 },
    { category: 'Dining', limit: 8000 },
    { category: 'Healthcare', limit: 4000 },
    { category: 'Shopping', limit: 12000 }
  ]);

  const [newCat, setNewCat] = useState('Transport');
  const [newLimit, setNewLimit] = useState('3000');

  const getSpentForCategory = (cat: string) => {
    return transactions
      .filter(t => t.type === 'expense' && t.category === cat)
      .reduce((sum, t) => sum + t.amount, 0);
  };

  const handleAddBudget = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newCat.trim() || !newLimit.trim()) return;
    const limitNum = parseFloat(newLimit) || 0;
    setBudgets([...budgets.filter(b => b.category !== newCat), { category: newCat, limit: limitNum }]);
    setNewCat('');
    setNewLimit('');
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
      
      {/* Header Info */}
      <div className="glass-card" style={{ padding: '20px' }}>
        <h2 style={{ fontSize: '22px', fontWeight: '800', color: '#FFF', display: 'flex', alignItems: 'center', gap: '10px' }}>
          <Target size={24} color="#00F5D4" /> AI Budgeting & Spending Analytics
        </h2>
        <div style={{ fontSize: '13px', color: 'var(--text-muted)', marginTop: '4px' }}>
          Set monthly limits per category and track real-time spending progress to prevent over-budgeting.
        </div>
      </div>

      {/* Add Budget Form */}
      <div className="glass-card" style={{ padding: '20px' }}>
        <h3 style={{ fontSize: '16px', fontWeight: '700', color: '#FFF', marginBottom: '14px' }}>Set Monthly Category Budget</h3>

        <form onSubmit={handleAddBudget} style={{ display: 'flex', gap: '12px', flexWrap: 'wrap' }}>
          <input
            type="text"
            required
            value={newCat}
            onChange={(e) => setNewCat(e.target.value)}
            placeholder="Category (e.g. Transport, Entertainment)"
            style={{ flex: 1, minWidth: '180px', background: '#16192E', border: '1px solid rgba(255, 255, 255, 0.1)', borderRadius: '10px', padding: '10px 12px', color: '#FFF', fontSize: '14px', outline: 'none' }}
          />

          <input
            type="number"
            required
            value={newLimit}
            onChange={(e) => setNewLimit(e.target.value)}
            placeholder="Monthly Limit (₹)"
            style={{ flex: 1, minWidth: '180px', background: '#16192E', border: '1px solid rgba(255, 255, 255, 0.1)', borderRadius: '10px', padding: '10px 12px', color: '#FFF', fontSize: '14px', outline: 'none' }}
          />

          <button type="submit" className="neon-btn">
            Set Budget Limit
          </button>
        </form>
      </div>

      {/* Category Budget Progress List */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))', gap: '16px' }}>
        {budgets.map((b) => {
          const spent = getSpentForCategory(b.category);
          const percent = Math.min(100, Math.round((spent / b.limit) * 100));
          const isOver = spent > b.limit;

          return (
            <div key={b.category} className="glass-card" style={{ padding: '18px', display: 'flex', flexDirection: 'column', gap: '10px' }}>
              
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <span style={{ fontSize: '16px', fontWeight: '800', color: '#FFF' }}>{b.category}</span>
                <span className="badge-category" style={{ background: isOver ? 'rgba(239, 68, 68, 0.2)' : 'rgba(0, 245, 212, 0.15)', color: isOver ? '#EF4444' : '#00F5D4' }}>
                  {percent}% Used
                </span>
              </div>

              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '13px' }}>
                <span style={{ color: 'var(--text-muted)' }}>Spent: ₹{spent.toLocaleString()}</span>
                <span style={{ color: '#FFF', fontWeight: '700' }}>Limit: ₹{b.limit.toLocaleString()}</span>
              </div>

              {/* Progress Bar */}
              <div style={{ height: '8px', background: 'rgba(255, 255, 255, 0.08)', borderRadius: '10px', overflow: 'hidden' }}>
                <div
                  style={{
                    height: '100%',
                    width: `${percent}%`,
                    background: isOver ? '#EF4444' : 'linear-gradient(90deg, #00F5D4 0%, #6366F1 100%)',
                    borderRadius: '10px',
                    transition: 'width 0.4s ease'
                  }}
                />
              </div>

              {isOver ? (
                <div style={{ fontSize: '11px', color: '#EF4444', fontWeight: '700', display: 'flex', alignItems: 'center', gap: '4px' }}>
                  <AlertCircle size={14} /> Over budget by ₹{(spent - b.limit).toLocaleString()}!
                </div>
              ) : (
                <div style={{ fontSize: '11px', color: '#10B981', fontWeight: '700', display: 'flex', alignItems: 'center', gap: '4px' }}>
                  <CheckCircle size={14} /> ₹{(b.limit - spent).toLocaleString()} remaining in budget
                </div>
              )}

            </div>
          );
        })}
      </div>

    </div>
  );
};
