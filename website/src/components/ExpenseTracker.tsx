import React, { useState } from 'react';
import { PlusCircle, TrendingUp, TrendingDown, DollarSign, Tag, Calendar, Trash2, CreditCard } from 'lucide-react';
import { Transaction } from '../types';

interface ExpenseTrackerProps {
  transactions: Transaction[];
  onAddTransaction: (t: Transaction) => void;
  onDeleteTransaction: (id: number) => void;
}

export const ExpenseTracker: React.FC<ExpenseTrackerProps> = ({ transactions, onAddTransaction, onDeleteTransaction }) => {
  const [title, setTitle] = useState('');
  const [amount, setAmount] = useState('');
  const [category, setCategory] = useState('Groceries');
  const [type, setType] = useState<'expense' | 'income'>('expense');
  const [account, setAccount] = useState('Main Bank');

  const totalIncome = transactions.filter(t => t.type === 'income').reduce((acc, t) => acc + t.amount, 0);
  const totalExpense = transactions.filter(t => t.type === 'expense').reduce((acc, t) => acc + t.amount, 0);
  const netSavings = totalIncome - totalExpense;

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim() || !amount.trim()) return;

    const newTx: Transaction = {
      id: Date.now(),
      title: title.trim(),
      amount: parseFloat(amount) || 0,
      category,
      type,
      date: new Date().toISOString().split('T')[0],
      account
    };

    onAddTransaction(newTx);
    setTitle('');
    setAmount('');
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
      
      {/* Financial Summary Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(260px, 1fr))', gap: '16px' }}>
        
        <div className="glass-card" style={{ padding: '20px', background: 'linear-gradient(135deg, rgba(22, 25, 46, 0.9) 0%, rgba(16, 185, 129, 0.15) 100%)' }}>
          <div style={{ fontSize: '13px', color: 'var(--text-muted)', fontWeight: '600' }}>Total Monthly Income</div>
          <div style={{ fontSize: '28px', fontWeight: '800', color: '#10B981', marginTop: '6px' }}>+₹{totalIncome.toLocaleString()}</div>
        </div>

        <div className="glass-card" style={{ padding: '20px', background: 'linear-gradient(135deg, rgba(22, 25, 46, 0.9) 0%, rgba(239, 68, 68, 0.15) 100%)' }}>
          <div style={{ fontSize: '13px', color: 'var(--text-muted)', fontWeight: '600' }}>Total Monthly Expenses</div>
          <div style={{ fontSize: '28px', fontWeight: '800', color: '#EF4444', marginTop: '6px' }}>-₹{totalExpense.toLocaleString()}</div>
        </div>

        <div className="glass-card" style={{ padding: '20px', background: 'linear-gradient(135deg, rgba(22, 25, 46, 0.9) 0%, rgba(0, 245, 212, 0.15) 100%)' }}>
          <div style={{ fontSize: '13px', color: 'var(--text-muted)', fontWeight: '600' }}>Net Monthly Balance</div>
          <div style={{ fontSize: '28px', fontWeight: '800', color: '#00F5D4', marginTop: '6px' }}>₹{netSavings.toLocaleString()}</div>
        </div>

      </div>

      {/* Add Transaction Form */}
      <div className="glass-card" style={{ padding: '20px' }}>
        <h3 style={{ fontSize: '18px', fontWeight: '800', color: '#FFF', marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '8px' }}>
          <PlusCircle size={20} color="#00F5D4" /> Log Expense or Income Transaction
        </h3>

        <form onSubmit={handleSubmit} style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '14px' }}>
          
          <div>
            <label style={{ fontSize: '12px', fontWeight: '700', color: 'var(--text-muted)', display: 'block', marginBottom: '4px' }}>Transaction Type</label>
            <div style={{ display: 'flex', gap: '8px' }}>
              <button
                type="button"
                onClick={() => setType('expense')}
                style={{
                  flex: 1,
                  padding: '10px',
                  borderRadius: '10px',
                  border: 'none',
                  background: type === 'expense' ? '#EF4444' : 'rgba(255, 255, 255, 0.05)',
                  color: '#FFF',
                  fontWeight: '700',
                  fontSize: '13px',
                  cursor: 'pointer'
                }}
              >
                Expense
              </button>
              <button
                type="button"
                onClick={() => setType('income')}
                style={{
                  flex: 1,
                  padding: '10px',
                  borderRadius: '10px',
                  border: 'none',
                  background: type === 'income' ? '#10B981' : 'rgba(255, 255, 255, 0.05)',
                  color: '#FFF',
                  fontWeight: '700',
                  fontSize: '13px',
                  cursor: 'pointer'
                }}
              >
                Income
              </button>
            </div>
          </div>

          <div>
            <label style={{ fontSize: '12px', fontWeight: '700', color: 'var(--text-muted)', display: 'block', marginBottom: '4px' }}>Title / Description *</label>
            <input
              type="text"
              required
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="e.g. Grocery store purchase"
              style={{ width: '100%', background: '#16192E', border: '1px solid rgba(255, 255, 255, 0.1)', borderRadius: '10px', padding: '10px 12px', color: '#FFF', fontSize: '14px', outline: 'none' }}
            />
          </div>

          <div>
            <label style={{ fontSize: '12px', fontWeight: '700', color: 'var(--text-muted)', display: 'block', marginBottom: '4px' }}>Amount (₹) *</label>
            <input
              type="number"
              required
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              placeholder="e.g. 1250"
              style={{ width: '100%', background: '#16192E', border: '1px solid rgba(255, 255, 255, 0.1)', borderRadius: '10px', padding: '10px 12px', color: '#FFF', fontSize: '14px', outline: 'none' }}
            />
          </div>

          <div>
            <label style={{ fontSize: '12px', fontWeight: '700', color: 'var(--text-muted)', display: 'block', marginBottom: '4px' }}>Category</label>
            <select
              value={category}
              onChange={(e) => setCategory(e.target.value)}
              style={{ width: '100%', background: '#16192E', border: '1px solid rgba(255, 255, 255, 0.1)', borderRadius: '10px', padding: '10px 12px', color: '#FFF', fontSize: '14px', outline: 'none' }}
            >
              <option value="Groceries">Groceries</option>
              <option value="Utilities">Utilities</option>
              <option value="Salary">Salary</option>
              <option value="Dining">Dining</option>
              <option value="Healthcare">Healthcare</option>
              <option value="Shopping">Shopping</option>
              <option value="Transport">Transport</option>
            </select>
          </div>

          <div style={{ display: 'flex', alignItems: 'flex-end' }}>
            <button type="submit" className="neon-btn" style={{ width: '100%', height: '42px', justifyContent: 'center' }}>
              Add Transaction
            </button>
          </div>

        </form>
      </div>

      {/* Transaction History */}
      <div className="glass-card" style={{ padding: '20px' }}>
        <h3 style={{ fontSize: '18px', fontWeight: '800', color: '#FFF', marginBottom: '16px' }}>Recent Transactions ({transactions.length})</h3>

        <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
          {transactions.map((t) => (
            <div key={t.id} style={{ background: 'rgba(14, 17, 31, 0.6)', border: '1px solid rgba(255, 255, 255, 0.08)', borderRadius: '14px', padding: '14px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              
              <div>
                <div style={{ fontSize: '15px', fontWeight: '700', color: '#FFF' }}>{t.title}</div>
                <div style={{ fontSize: '12px', color: 'var(--text-muted)', marginTop: '2px', display: 'flex', gap: '10px' }}>
                  <span>📅 {t.date}</span>
                  <span>🏷️ {t.category}</span>
                  <span>💳 {t.account}</span>
                </div>
              </div>

              <div style={{ display: 'flex', alignItems: 'center', gap: '14px' }}>
                <span style={{ fontSize: '16px', fontWeight: '800', color: t.type === 'income' ? '#10B981' : '#EF4444' }}>
                  {t.type === 'income' ? '+' : '-'}₹{t.amount.toLocaleString()}
                </span>
                <button
                  style={{ background: 'transparent', border: 'none', color: '#EF4444', cursor: 'pointer', padding: '4px' }}
                  onClick={() => onDeleteTransaction(t.id)}
                  title="Delete Transaction"
                >
                  <Trash2 size={16} />
                </button>
              </div>

            </div>
          ))}
        </div>
      </div>

    </div>
  );
};
