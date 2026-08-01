import React, { useState } from 'react';
import { Smartphone, Sparkles, CheckCircle2, ArrowRight, Copy } from 'lucide-react';
import { Transaction, ParsedSms } from '../types';

interface SmsParserProps {
  onAddTransaction: (t: Transaction) => void;
}

export const SmsParser: React.FC<SmsParserProps> = ({ onAddTransaction }) => {
  const [smsText, setSmsText] = useState('');
  const [parsed, setParsed] = useState<ParsedSms | null>(null);

  const sampleSMSList = [
    "Sent Rs.1,250.00 from HDFC Bank A/C XX4582 to Blinkit Supermarket on 31-Jul-26 ref no 62849102. Balance Rs.45,210.",
    "Rs 4,800.00 debited from A/C XX9012 for Zomato Dining on 28-Jul-26. UPI Ref 928374.",
    "Your A/C XX1045 credited by Rs.85,000.00 on 01-Jul-26 towards Salary Credit from Acme Corp."
  ];

  const parseSMS = (text: string) => {
    if (!text.trim()) {
      setParsed(null);
      return;
    }

    const lower = text.toLowerCase();
    
    // Amount extraction
    const amountMatch = text.match(/(?:rs\.?|inr|amt)\s*([\d,]+\.?\d*)/i) || text.match(/([\d,]+\.?\d*)\s*(?:debited|credited|spent)/i);
    let amount = 0;
    if (amountMatch) {
      amount = parseFloat(amountMatch[1].replace(/,/g, '')) || 0;
    }

    // Type extraction
    const isIncome = lower.includes('credited') || lower.includes('received') || lower.includes('salary');
    const type: 'expense' | 'income' = isIncome ? 'income' : 'expense';

    // Account extraction
    let account = 'Bank Account';
    if (lower.includes('hdfc')) account = 'HDFC Bank';
    else if (lower.includes('icici')) account = 'ICICI Bank';
    else if (lower.includes('sbi')) account = 'SBI Bank';
    else if (lower.includes('paytm')) account = 'Paytm Wallet';

    // Merchant extraction
    let merchant = 'Online Purchase';
    if (lower.includes('blinkit')) merchant = 'Blinkit Supermarket';
    else if (lower.includes('zomato')) merchant = 'Zomato Dining';
    else if (lower.includes('swiggy')) merchant = 'Swiggy Food';
    else if (lower.includes('amazon')) merchant = 'Amazon Shopping';
    else if (lower.includes('salary')) merchant = 'Salary Credit';

    setParsed({
      merchant,
      amount,
      type,
      account,
      date: new Date().toISOString().split('T')[0],
      rawText: text
    });
  };

  const handleSaveParsed = () => {
    if (!parsed) return;
    const newTx: Transaction = {
      id: Date.now(),
      title: parsed.merchant,
      amount: parsed.amount,
      category: parsed.type === 'income' ? 'Salary' : 'Shopping',
      type: parsed.type,
      date: parsed.date,
      account: parsed.account,
      merchantName: parsed.merchant
    };

    onAddTransaction(newTx);
    setSmsText('');
    setParsed(null);
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
      
      {/* Header Info */}
      <div className="glass-card" style={{ padding: '20px' }}>
        <h2 style={{ fontSize: '22px', fontWeight: '800', color: '#FFF', display: 'flex', alignItems: 'center', gap: '10px' }}>
          <Smartphone size={24} color="#00F5D4" /> SMS Financial Transaction Parser
        </h2>
        <div style={{ fontSize: '13px', color: 'var(--text-muted)', marginTop: '4px' }}>
          Paste bank SMS notifications from HDFC, ICICI, SBI, Paytm, or UPI to instantly extract transaction details.
        </div>
      </div>

      {/* Input Box & Quick Samples */}
      <div className="glass-card" style={{ padding: '20px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '10px' }}>
          <label style={{ fontSize: '13px', fontWeight: '700', color: '#FFF' }}>Paste Bank SMS Text</label>
          <span style={{ fontSize: '11px', color: 'var(--neon-cyan)' }}>Automated Pattern AI</span>
        </div>

        <textarea
          rows={3}
          value={smsText}
          onChange={(e) => {
            setSmsText(e.target.value);
            parseSMS(e.target.value);
          }}
          placeholder="Paste SMS here e.g. Sent Rs.1,250.00 from HDFC Bank to Blinkit on 31-Jul-26..."
          style={{ width: '100%', background: '#16192E', border: '1.5px solid rgba(0, 245, 212, 0.4)', borderRadius: '12px', padding: '12px', color: '#FFF', fontSize: '14px', outline: 'none', resize: 'vertical' }}
        />

        {/* Quick Sample Buttons */}
        <div style={{ marginTop: '12px' }}>
          <div style={{ fontSize: '11px', color: 'var(--text-muted)', fontWeight: '700', marginBottom: '6px' }}>Try Quick Test Templates:</div>
          <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap' }}>
            {sampleSMSList.map((sample, idx) => (
              <button
                key={idx}
                className="secondary-btn"
                style={{ fontSize: '11px', padding: '4px 10px' }}
                onClick={() => {
                  setSmsText(sample);
                  parseSMS(sample);
                }}
              >
                <Copy size={12} /> Test Template #{idx + 1}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Parsed Result Card */}
      {parsed && (
        <div className="glass-card" style={{ padding: '20px', background: 'linear-gradient(135deg, rgba(22, 25, 46, 0.95) 0%, rgba(0, 245, 212, 0.15) 100%)', border: '1.5px solid #00F5D4' }}>
          <h3 style={{ fontSize: '16px', fontWeight: '800', color: '#FFF', marginBottom: '14px', display: 'flex', alignItems: 'center', gap: '8px' }}>
            <Sparkles size={18} color="#00F5D4" /> Extracted Transaction Details
          </h3>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: '14px', marginBottom: '16px' }}>
            <div>
              <div style={{ fontSize: '11px', color: 'var(--text-muted)' }}>Merchant / Title</div>
              <div style={{ fontSize: '15px', fontWeight: '800', color: '#FFF' }}>{parsed.merchant}</div>
            </div>
            <div>
              <div style={{ fontSize: '11px', color: 'var(--text-muted)' }}>Extracted Amount</div>
              <div style={{ fontSize: '20px', fontWeight: '800', color: parsed.type === 'income' ? '#10B981' : '#EF4444' }}>
                {parsed.type === 'income' ? '+' : '-'}₹{parsed.amount.toLocaleString()}
              </div>
            </div>
            <div>
              <div style={{ fontSize: '11px', color: 'var(--text-muted)' }}>Transaction Type</div>
              <div style={{ fontSize: '13px', fontWeight: '700', color: parsed.type === 'income' ? '#10B981' : '#EF4444', textTransform: 'uppercase' }}>
                {parsed.type}
              </div>
            </div>
            <div>
              <div style={{ fontSize: '11px', color: 'var(--text-muted)' }}>Bank Account</div>
              <div style={{ fontSize: '13px', fontWeight: '700', color: '#FFF' }}>{parsed.account}</div>
            </div>
          </div>

          <button className="neon-btn" style={{ width: '100%', justifyContent: 'center' }} onClick={handleSaveParsed}>
            <CheckCircle2 size={16} /> Insert Parsed Transaction into Expense Tracker
          </button>
        </div>
      )}

    </div>
  );
};
