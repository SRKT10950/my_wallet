import React, { useState } from 'react';
import { HandCoins, PlusCircle, Calendar, CheckCircle2, AlertTriangle, ArrowUpRight, ArrowDownLeft } from 'lucide-react';
import { LendBorrow } from '../types';

interface LendBorrowTrackerProps {
  items: LendBorrow[];
  onAddLendBorrow: (item: LendBorrow) => void;
  onUpdateSettled: (id: number, amount: number) => void;
}

export const LendBorrowTracker: React.FC<LendBorrowTrackerProps> = ({ items, onAddLendBorrow, onUpdateSettled }) => {
  const [name, setName] = useState('');
  const [type, setType] = useState<'Lend' | 'Borrow'>('Lend');
  const [amount, setAmount] = useState('');
  const [dueDate, setDueDate] = useState('2026-08-15');
  const [notes, setNotes] = useState('');

  const totalLent = items.filter(i => i.type === 'Lend').reduce((acc, i) => acc + (i.amount - i.settled), 0);
  const totalBorrowed = items.filter(i => i.type === 'Borrow').reduce((acc, i) => acc + (i.amount - i.settled), 0);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim() || !amount.trim()) return;

    const newItem: LendBorrow = {
      id: Date.now(),
      name: name.trim(),
      type,
      amount: parseFloat(amount) || 0,
      date: new Date().toISOString().split('T')[0],
      dueDate,
      settled: 0,
      notes: notes.trim()
    };

    onAddLendBorrow(newItem);
    setName('');
    setAmount('');
    setNotes('');
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
      
      {/* Overview Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(260px, 1fr))', gap: '16px' }}>
        
        <div className="glass-card" style={{ padding: '20px', background: 'linear-gradient(135deg, rgba(22, 25, 46, 0.9) 0%, rgba(16, 185, 129, 0.15) 100%)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '13px', color: 'var(--text-muted)', fontWeight: '600' }}>Total Money Lent (Owed to You)</span>
            <ArrowUpRight size={18} color="#10B981" />
          </div>
          <div style={{ fontSize: '28px', fontWeight: '800', color: '#10B981', marginTop: '6px' }}>₹{totalLent.toLocaleString()}</div>
        </div>

        <div className="glass-card" style={{ padding: '20px', background: 'linear-gradient(135deg, rgba(22, 25, 46, 0.9) 0%, rgba(239, 68, 68, 0.15) 100%)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '13px', color: 'var(--text-muted)', fontWeight: '600' }}>Total Money Borrowed (You Owe)</span>
            <ArrowDownLeft size={18} color="#EF4444" />
          </div>
          <div style={{ fontSize: '28px', fontWeight: '800', color: '#EF4444', marginTop: '6px' }}>₹{totalBorrowed.toLocaleString()}</div>
        </div>

      </div>

      {/* New Form */}
      <div className="glass-card" style={{ padding: '20px' }}>
        <h3 style={{ fontSize: '18px', fontWeight: '800', color: '#FFF', marginBottom: '14px', display: 'flex', alignItems: 'center', gap: '8px' }}>
          <HandCoins size={20} color="#00F5D4" /> Log Lend or Borrow Record
        </h3>

        <form onSubmit={handleSubmit} style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '14px' }}>
          
          <div>
            <label style={{ fontSize: '12px', fontWeight: '700', color: 'var(--text-muted)', display: 'block', marginBottom: '4px' }}>Record Type</label>
            <div style={{ display: 'flex', gap: '8px' }}>
              <button
                type="button"
                onClick={() => setType('Lend')}
                style={{ flex: 1, padding: '10px', borderRadius: '10px', border: 'none', background: type === 'Lend' ? '#10B981' : 'rgba(255, 255, 255, 0.05)', color: '#FFF', fontWeight: '700', cursor: 'pointer' }}
              >
                Lend (You Gave)
              </button>
              <button
                type="button"
                onClick={() => setType('Borrow')}
                style={{ flex: 1, padding: '10px', borderRadius: '10px', border: 'none', background: type === 'Borrow' ? '#EF4444' : 'rgba(255, 255, 255, 0.05)', color: '#FFF', fontWeight: '700', cursor: 'pointer' }}
              >
                Borrow (You Took)
              </button>
            </div>
          </div>

          <div>
            <label style={{ fontSize: '12px', fontWeight: '700', color: 'var(--text-muted)', display: 'block', marginBottom: '4px' }}>Person / Entity Name *</label>
            <input
              type="text"
              required
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="e.g. Amit Kumar / Bank"
              style={{ width: '100%', background: '#16192E', border: '1px solid rgba(255, 255, 255, 0.1)', borderRadius: '10px', padding: '10px 12px', color: '#FFF', fontSize: '14px', outline: 'none' }}
            />
          </div>

          <div>
            <label style={{ fontSize: '12px', fontWeight: '700', color: 'var(--text-muted)', display: 'block', marginBottom: '4px' }}>Principal Amount (₹) *</label>
            <input
              type="number"
              required
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              placeholder="e.g. 5000"
              style={{ width: '100%', background: '#16192E', border: '1px solid rgba(255, 255, 255, 0.1)', borderRadius: '10px', padding: '10px 12px', color: '#FFF', fontSize: '14px', outline: 'none' }}
            />
          </div>

          <div>
            <label style={{ fontSize: '12px', fontWeight: '700', color: 'var(--text-muted)', display: 'block', marginBottom: '4px' }}>Expected Due Date</label>
            <input
              type="date"
              value={dueDate}
              onChange={(e) => setDueDate(e.target.value)}
              style={{ width: '100%', background: '#16192E', border: '1px solid rgba(255, 255, 255, 0.1)', borderRadius: '10px', padding: '10px 12px', color: '#FFF', fontSize: '14px', outline: 'none' }}
            />
          </div>

          <div style={{ display: 'flex', alignItems: 'flex-end', gridColumn: '1 / -1' }}>
            <button type="submit" className="neon-btn" style={{ width: '100%', height: '42px', justifyContent: 'center' }}>
              Save Lend/Borrow Record
            </button>
          </div>

        </form>
      </div>

      {/* List */}
      <div className="glass-card" style={{ padding: '20px' }}>
        <h3 style={{ fontSize: '18px', fontWeight: '800', color: '#FFF', marginBottom: '16px' }}>Active Loans & Debt Tracker ({items.length})</h3>

        <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
          {items.map((i) => {
            const pending = i.amount - i.settled;
            return (
              <div key={i.id} style={{ background: '#16192E', border: '1px solid rgba(0, 245, 212, 0.3)', borderRadius: '16px', padding: '16px', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '12px' }}>
                
                <div>
                  <div style={{ fontSize: '16px', fontWeight: '800', color: '#FFF' }}>{i.name}</div>
                  <div style={{ fontSize: '12px', color: 'var(--text-muted)', marginTop: '2px' }}>
                    Type: <strong style={{ color: i.type === 'Lend' ? '#10B981' : '#EF4444' }}>{i.type}</strong> • Due: {i.dueDate}
                  </div>
                  {i.notes && <div style={{ fontSize: '12px', color: 'var(--amber-gold)', marginTop: '4px' }}>Note: {i.notes}</div>}
                </div>

                <div style={{ textAlign: 'right' }}>
                  <div style={{ fontSize: '16px', fontWeight: '800', color: i.type === 'Lend' ? '#10B981' : '#EF4444' }}>
                    Remaining: ₹{pending.toLocaleString()}
                  </div>
                  <div style={{ fontSize: '12px', color: 'var(--text-muted)' }}>
                    Total: ₹{i.amount.toLocaleString()} (Settled: ₹{i.settled.toLocaleString()})
                  </div>
                  {pending > 0 && (
                    <button className="secondary-btn" style={{ fontSize: '11px', padding: '4px 10px', marginTop: '6px' }} onClick={() => onUpdateSettled(i.id, 1000)}>
                      + Log ₹1,000 Repayment
                    </button>
                  )}
                </div>

              </div>
            );
          })}
        </div>
      </div>

    </div>
  );
};
