import React, { useState } from 'react';
import { Calendar, PlusCircle, Bell, CheckCircle, Clock } from 'lucide-react';
import { ScheduledPayment } from '../types';

interface ScheduledPaymentsProps {
  scheduledList: ScheduledPayment[];
  onAddScheduledPayment: (sp: ScheduledPayment) => void;
}

export const ScheduledPayments: React.FC<ScheduledPaymentsProps> = ({ scheduledList, onAddScheduledPayment }) => {
  const [title, setTitle] = useState('');
  const [amount, setAmount] = useState('');
  const [dueDate, setDueDate] = useState('2026-08-05');
  const [frequency, setFrequency] = useState<'Monthly' | 'Quarterly' | 'Yearly'>('Monthly');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim() || !amount.trim()) return;

    const newSp: ScheduledPayment = {
      id: Date.now(),
      title: title.trim(),
      amount: parseFloat(amount) || 0,
      category: 'Bills',
      dueDate,
      frequency,
      autoPay: true
    };

    onAddScheduledPayment(newSp);
    setTitle('');
    setAmount('');
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
      
      {/* Header Info */}
      <div className="glass-card" style={{ padding: '20px' }}>
        <h2 style={{ fontSize: '22px', fontWeight: '800', color: '#FFF', display: 'flex', alignItems: 'center', gap: '10px' }}>
          <Calendar size={24} color="#00F5D4" /> Scheduled Payments & Subscriptions
        </h2>
        <div style={{ fontSize: '13px', color: 'var(--text-muted)', marginTop: '4px' }}>
          Never miss house rent, broadband bills, OTT subscriptions, or loan EMIs with automated reminders.
        </div>
      </div>

      {/* Form */}
      <div className="glass-card" style={{ padding: '20px' }}>
        <h3 style={{ fontSize: '18px', fontWeight: '800', color: '#FFF', marginBottom: '14px', display: 'flex', alignItems: 'center', gap: '8px' }}>
          <PlusCircle size={20} color="#00F5D4" /> Add Recurring Subscription / Bill
        </h3>

        <form onSubmit={handleSubmit} style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '14px' }}>
          
          <div>
            <label style={{ fontSize: '12px', fontWeight: '700', color: 'var(--text-muted)', display: 'block', marginBottom: '4px' }}>Bill Name / Subscription *</label>
            <input
              type="text"
              required
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="e.g. Netflix Premium / House Rent"
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
              placeholder="e.g. 649"
              style={{ width: '100%', background: '#16192E', border: '1px solid rgba(255, 255, 255, 0.1)', borderRadius: '10px', padding: '10px 12px', color: '#FFF', fontSize: '14px', outline: 'none' }}
            />
          </div>

          <div>
            <label style={{ fontSize: '12px', fontWeight: '700', color: 'var(--text-muted)', display: 'block', marginBottom: '4px' }}>Due Date</label>
            <input
              type="date"
              value={dueDate}
              onChange={(e) => setDueDate(e.target.value)}
              style={{ width: '100%', background: '#16192E', border: '1px solid rgba(255, 255, 255, 0.1)', borderRadius: '10px', padding: '10px 12px', color: '#FFF', fontSize: '14px', outline: 'none' }}
            />
          </div>

          <div>
            <label style={{ fontSize: '12px', fontWeight: '700', color: 'var(--text-muted)', display: 'block', marginBottom: '4px' }}>Frequency</label>
            <select
              value={frequency}
              onChange={(e) => setFrequency(e.target.value as any)}
              style={{ width: '100%', background: '#16192E', border: '1px solid rgba(255, 255, 255, 0.1)', borderRadius: '10px', padding: '10px 12px', color: '#FFF', fontSize: '14px', outline: 'none' }}
            >
              <option value="Monthly">Monthly</option>
              <option value="Quarterly">Quarterly</option>
              <option value="Yearly">Yearly</option>
            </select>
          </div>

          <div style={{ display: 'flex', alignItems: 'flex-end', gridColumn: '1 / -1' }}>
            <button type="submit" className="neon-btn" style={{ width: '100%', height: '42px', justifyContent: 'center' }}>
              Add Recurring Payment Reminder
            </button>
          </div>

        </form>
      </div>

      {/* List */}
      <div className="glass-card" style={{ padding: '20px' }}>
        <h3 style={{ fontSize: '18px', fontWeight: '800', color: '#FFF', marginBottom: '16px' }}>Upcoming Scheduled Bills ({scheduledList.length})</h3>

        <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
          {scheduledList.map((sp) => (
            <div key={sp.id} style={{ background: '#16192E', border: '1px solid rgba(0, 245, 212, 0.3)', borderRadius: '16px', padding: '16px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              
              <div>
                <div style={{ fontSize: '16px', fontWeight: '800', color: '#FFF' }}>{sp.title}</div>
                <div style={{ fontSize: '12px', color: 'var(--text-muted)', marginTop: '2px' }}>
                  📅 Due Date: {sp.dueDate} • Frequency: {sp.frequency}
                </div>
              </div>

              <div style={{ textAlign: 'right' }}>
                <div style={{ fontSize: '18px', fontWeight: '800', color: '#00F5D4' }}>₹{sp.amount.toLocaleString()}</div>
                <button className="secondary-btn" style={{ fontSize: '11px', padding: '4px 10px', marginTop: '4px' }}>
                  Mark Paid
                </button>
              </div>

            </div>
          ))}
        </div>
      </div>

    </div>
  );
};
