import React, { useState } from 'react';
import { Users, PlusCircle, CheckCircle, Clock, DollarSign } from 'lucide-react';
import { SplitBill } from '../types';

interface SplitwiseProps {
  splitBills: SplitBill[];
  onAddSplitBill: (b: SplitBill) => void;
  onToggleSettled: (id: number) => void;
}

export const Splitwise: React.FC<SplitwiseProps> = ({ splitBills, onAddSplitBill, onToggleSettled }) => {
  const [title, setTitle] = useState('');
  const [totalAmount, setTotalAmount] = useState('');
  const [paidBy, setPaidBy] = useState('You');
  const [participantsText, setParticipantsText] = useState('Rahul, Priya, Amit, You');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim() || !totalAmount.trim()) return;

    const parts = participantsText.split(',').map(p => p.trim()).filter(Boolean);
    const newBill: SplitBill = {
      id: Date.now(),
      title: title.trim(),
      totalAmount: parseFloat(totalAmount) || 0,
      paidBy,
      participants: parts.length > 0 ? parts : ['Rahul', 'Priya', 'You'],
      date: new Date().toISOString().split('T')[0],
      settled: false
    };

    onAddSplitBill(newBill);
    setTitle('');
    setTotalAmount('');
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
      
      {/* Header Info */}
      <div className="glass-card" style={{ padding: '20px' }}>
        <h2 style={{ fontSize: '22px', fontWeight: '800', color: '#FFF', display: 'flex', alignItems: 'center', gap: '10px' }}>
          <Users size={24} color="#00F5D4" /> Splitwise & Group Expense Manager
        </h2>
        <div style={{ fontSize: '13px', color: 'var(--text-muted)', marginTop: '4px' }}>
          Split dining, trips, and shared household bills equally or custom per participant.
        </div>
      </div>

      {/* New Split Bill Form */}
      <div className="glass-card" style={{ padding: '20px' }}>
        <h3 style={{ fontSize: '16px', fontWeight: '700', color: '#FFF', marginBottom: '14px', display: 'flex', alignItems: 'center', gap: '8px' }}>
          <PlusCircle size={18} color="#00F5D4" /> Add Shared Bill to Split
        </h3>

        <form onSubmit={handleSubmit} style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '14px' }}>
          
          <div>
            <label style={{ fontSize: '12px', fontWeight: '700', color: 'var(--text-muted)', display: 'block', marginBottom: '4px' }}>Bill Title *</label>
            <input
              type="text"
              required
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="e.g. Weekend Goa Trip / Restaurant Bill"
              style={{ width: '100%', background: '#16192E', border: '1px solid rgba(255, 255, 255, 0.1)', borderRadius: '10px', padding: '10px 12px', color: '#FFF', fontSize: '14px', outline: 'none' }}
            />
          </div>

          <div>
            <label style={{ fontSize: '12px', fontWeight: '700', color: 'var(--text-muted)', display: 'block', marginBottom: '4px' }}>Total Amount (₹) *</label>
            <input
              type="number"
              required
              value={totalAmount}
              onChange={(e) => setTotalAmount(e.target.value)}
              placeholder="e.g. 4800"
              style={{ width: '100%', background: '#16192E', border: '1px solid rgba(255, 255, 255, 0.1)', borderRadius: '10px', padding: '10px 12px', color: '#FFF', fontSize: '14px', outline: 'none' }}
            />
          </div>

          <div>
            <label style={{ fontSize: '12px', fontWeight: '700', color: 'var(--text-muted)', display: 'block', marginBottom: '4px' }}>Paid By</label>
            <select
              value={paidBy}
              onChange={(e) => setPaidBy(e.target.value)}
              style={{ width: '100%', background: '#16192E', border: '1px solid rgba(255, 255, 255, 0.1)', borderRadius: '10px', padding: '10px 12px', color: '#FFF', fontSize: '14px', outline: 'none' }}
            >
              <option value="You">You</option>
              <option value="Rahul">Rahul</option>
              <option value="Priya">Priya</option>
              <option value="Amit">Amit</option>
            </select>
          </div>

          <div>
            <label style={{ fontSize: '12px', fontWeight: '700', color: 'var(--text-muted)', display: 'block', marginBottom: '4px' }}>Participants (comma separated)</label>
            <input
              type="text"
              value={participantsText}
              onChange={(e) => setParticipantsText(e.target.value)}
              placeholder="Rahul, Priya, Amit, You"
              style={{ width: '100%', background: '#16192E', border: '1px solid rgba(255, 255, 255, 0.1)', borderRadius: '10px', padding: '10px 12px', color: '#FFF', fontSize: '14px', outline: 'none' }}
            />
          </div>

          <div style={{ display: 'flex', alignItems: 'flex-end', gridColumn: '1 / -1' }}>
            <button type="submit" className="neon-btn" style={{ width: '100%', height: '42px', justifyContent: 'center' }}>
              Create Split Bill
            </button>
          </div>

        </form>
      </div>

      {/* Active Split Bills List */}
      <div className="glass-card" style={{ padding: '20px' }}>
        <h3 style={{ fontSize: '18px', fontWeight: '800', color: '#FFF', marginBottom: '16px' }}>Shared Group Bills ({splitBills.length})</h3>

        <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
          {splitBills.map((b) => {
            const sharePerPerson = Math.round(b.totalAmount / (b.participants.length || 1));
            return (
              <div key={b.id} style={{ background: '#16192E', border: '1px solid rgba(0, 245, 212, 0.3)', borderRadius: '16px', padding: '16px', display: 'flex', flexDirection: 'column', gap: '10px' }}>
                
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <div>
                    <h4 style={{ fontSize: '16px', fontWeight: '800', color: '#FFF' }}>{b.title}</h4>
                    <div style={{ fontSize: '12px', color: 'var(--text-muted)', marginTop: '2px' }}>
                      Paid by <strong style={{ color: 'var(--neon-cyan)' }}>{b.paidBy}</strong> on {b.date}
                    </div>
                  </div>

                  <div style={{ textAlign: 'right' }}>
                    <div style={{ fontSize: '18px', fontWeight: '800', color: '#FFF' }}>₹{b.totalAmount}</div>
                    <div style={{ fontSize: '12px', color: 'var(--amber-gold)', fontWeight: '700' }}>₹{sharePerPerson} / person</div>
                  </div>
                </div>

                <div style={{ display: 'flex', gap: '6px', flexWrap: 'wrap', alignItems: 'center', marginTop: '4px' }}>
                  <span style={{ fontSize: '11px', color: 'var(--text-muted)', fontWeight: '700' }}>Participants:</span>
                  {b.participants.map(p => (
                    <span key={p} className="badge-category" style={{ fontSize: '10px' }}>{p}</span>
                  ))}
                </div>

                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderTop: '1px solid rgba(255, 255, 255, 0.08)', paddingTop: '10px', marginTop: '4px' }}>
                  <span style={{ fontSize: '12px', color: b.settled ? '#10B981' : '#F59E0B', fontWeight: '700', display: 'flex', alignItems: 'center', gap: '4px' }}>
                    {b.settled ? <CheckCircle size={14} /> : <Clock size={14} />}
                    {b.settled ? 'Settled Up' : 'Pending Settlement'}
                  </span>

                  <button className="secondary-btn" style={{ fontSize: '11px', padding: '4px 10px' }} onClick={() => onToggleSettled(b.id)}>
                    {b.settled ? 'Mark Pending' : 'Mark Settled'}
                  </button>
                </div>

              </div>
            );
          })}
        </div>
      </div>

    </div>
  );
};
