import React, { useState } from 'react';
import { Calculator, Percent, DollarSign, Calendar, TrendingUp } from 'lucide-react';

export const Calculators: React.FC = () => {
  const [calcTab, setCalcTab] = useState<'emi' | 'sip'>('emi');

  // EMI Calculator State
  const [loanAmount, setLoanAmount] = useState('500000');
  const [interestRate, setInterestRate] = useState('9.5');
  const [tenureYears, setTenureYears] = useState('5');

  // SIP Calculator State
  const [sipMonthly, setSipMonthly] = useState('5000');
  const [sipRate, setSipRate] = useState('12');
  const [sipYears, setSipYears] = useState('10');

  // Compute EMI
  const calculateEMI = () => {
    const P = parseFloat(loanAmount) || 0;
    const r = (parseFloat(interestRate) || 0) / 12 / 100;
    const n = (parseFloat(tenureYears) || 0) * 12;
    if (P <= 0 || r <= 0 || n <= 0) return { emi: 0, totalInterest: 0, totalPayment: 0 };

    const emi = (P * r * Math.pow(1 + r, n)) / (Math.pow(1 + r, n) - 1);
    const totalPayment = emi * n;
    const totalInterest = totalPayment - P;

    return {
      emi: Math.round(emi),
      totalInterest: Math.round(totalInterest),
      totalPayment: Math.round(totalPayment)
    };
  };

  // Compute SIP
  const calculateSIP = () => {
    const P = parseFloat(sipMonthly) || 0;
    const i = (parseFloat(sipRate) || 0) / 12 / 100;
    const n = (parseFloat(sipYears) || 0) * 12;
    if (P <= 0 || i <= 0 || n <= 0) return { invested: 0, returns: 0, totalWealth: 0 };

    const totalWealth = P * ((Math.pow(1 + i, n) - 1) / i) * (1 + i);
    const invested = P * n;
    const returns = totalWealth - invested;

    return {
      invested: Math.round(invested),
      returns: Math.round(returns),
      totalWealth: Math.round(totalWealth)
    };
  };

  const emiRes = calculateEMI();
  const sipRes = calculateSIP();

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
      
      {/* Header Tabs */}
      <div className="glass-card" style={{ padding: '16px', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '12px' }}>
        <div style={{ fontSize: '20px', fontWeight: '800', color: '#FFF', display: 'flex', alignItems: 'center', gap: '10px' }}>
          <Calculator size={22} color="#00F5D4" /> Financial Planning Calculators
        </div>

        <div style={{ display: 'flex', gap: '8px', background: 'rgba(14, 17, 31, 0.8)', padding: '4px', borderRadius: '12px' }}>
          <button
            onClick={() => setCalcTab('emi')}
            style={{
              background: calcTab === 'emi' ? 'var(--neon-cyan)' : 'transparent',
              color: calcTab === 'emi' ? '#000' : 'var(--text-muted)',
              border: 'none',
              borderRadius: '8px',
              padding: '8px 16px',
              fontWeight: '700',
              cursor: 'pointer'
            }}
          >
            EMI Calculator
          </button>
          <button
            onClick={() => setCalcTab('sip')}
            style={{
              background: calcTab === 'sip' ? 'var(--neon-indigo)' : 'transparent',
              color: calcTab === 'sip' ? '#FFF' : 'var(--text-muted)',
              border: 'none',
              borderRadius: '8px',
              padding: '8px 16px',
              fontWeight: '700',
              cursor: 'pointer'
            }}
          >
            SIP Calculator
          </button>
        </div>
      </div>

      {/* EMI Calculator */}
      {calcTab === 'emi' && (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', gap: '20px' }}>
          
          <div className="glass-card" style={{ padding: '20px' }}>
            <h3 style={{ fontSize: '16px', fontWeight: '700', color: '#FFF', marginBottom: '16px' }}>Loan EMI Inputs</h3>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
              <div>
                <label style={{ fontSize: '12px', fontWeight: '700', color: 'var(--text-muted)', display: 'block', marginBottom: '4px' }}>Loan Principal Amount (₹)</label>
                <input
                  type="number"
                  value={loanAmount}
                  onChange={(e) => setLoanAmount(e.target.value)}
                  style={{ width: '100%', background: '#16192E', border: '1px solid rgba(255, 255, 255, 0.1)', borderRadius: '10px', padding: '10px 12px', color: '#FFF', fontSize: '14px', outline: 'none' }}
                />
              </div>

              <div>
                <label style={{ fontSize: '12px', fontWeight: '700', color: 'var(--text-muted)', display: 'block', marginBottom: '4px' }}>Annual Interest Rate (%)</label>
                <input
                  type="number"
                  step="0.1"
                  value={interestRate}
                  onChange={(e) => setInterestRate(e.target.value)}
                  style={{ width: '100%', background: '#16192E', border: '1px solid rgba(255, 255, 255, 0.1)', borderRadius: '10px', padding: '10px 12px', color: '#FFF', fontSize: '14px', outline: 'none' }}
                />
              </div>

              <div>
                <label style={{ fontSize: '12px', fontWeight: '700', color: 'var(--text-muted)', display: 'block', marginBottom: '4px' }}>Loan Tenure (Years)</label>
                <input
                  type="number"
                  value={tenureYears}
                  onChange={(e) => setTenureYears(e.target.value)}
                  style={{ width: '100%', background: '#16192E', border: '1px solid rgba(255, 255, 255, 0.1)', borderRadius: '10px', padding: '10px 12px', color: '#FFF', fontSize: '14px', outline: 'none' }}
                />
              </div>
            </div>
          </div>

          <div className="glass-card" style={{ padding: '20px', background: 'linear-gradient(135deg, rgba(22, 25, 46, 0.95) 0%, rgba(0, 245, 212, 0.15) 100%)', display: 'flex', flexDirection: 'column', justifyContent: 'space-around' }}>
            <div>
              <div style={{ fontSize: '13px', color: 'var(--text-muted)', fontWeight: '600' }}>Monthly Payable EMI</div>
              <div style={{ fontSize: '36px', fontWeight: '800', color: '#00F5D4', marginTop: '4px' }}>₹{emiRes.emi.toLocaleString()}</div>
            </div>

            <div style={{ borderTop: '1px solid rgba(255, 255, 255, 0.1)', paddingTop: '14px', marginTop: '14px', display: 'flex', flexDirection: 'column', gap: '8px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '14px' }}>
                <span style={{ color: 'var(--text-muted)' }}>Total Interest Payable:</span>
                <span style={{ color: '#F59E0B', fontWeight: '700' }}>₹{emiRes.totalInterest.toLocaleString()}</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '14px' }}>
                <span style={{ color: 'var(--text-muted)' }}>Total Amount Payable:</span>
                <span style={{ color: '#FFF', fontWeight: '800' }}>₹{emiRes.totalPayment.toLocaleString()}</span>
              </div>
            </div>
          </div>

        </div>
      )}

      {/* SIP Calculator */}
      {calcTab === 'sip' && (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', gap: '20px' }}>
          
          <div className="glass-card" style={{ padding: '20px' }}>
            <h3 style={{ fontSize: '16px', fontWeight: '700', color: '#FFF', marginBottom: '16px' }}>SIP Wealth Inputs</h3>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
              <div>
                <label style={{ fontSize: '12px', fontWeight: '700', color: 'var(--text-muted)', display: 'block', marginBottom: '4px' }}>Monthly SIP Investment (₹)</label>
                <input
                  type="number"
                  value={sipMonthly}
                  onChange={(e) => setSipMonthly(e.target.value)}
                  style={{ width: '100%', background: '#16192E', border: '1px solid rgba(255, 255, 255, 0.1)', borderRadius: '10px', padding: '10px 12px', color: '#FFF', fontSize: '14px', outline: 'none' }}
                />
              </div>

              <div>
                <label style={{ fontSize: '12px', fontWeight: '700', color: 'var(--text-muted)', display: 'block', marginBottom: '4px' }}>Expected Annual Return (%)</label>
                <input
                  type="number"
                  step="0.5"
                  value={sipRate}
                  onChange={(e) => setSipRate(e.target.value)}
                  style={{ width: '100%', background: '#16192E', border: '1px solid rgba(255, 255, 255, 0.1)', borderRadius: '10px', padding: '10px 12px', color: '#FFF', fontSize: '14px', outline: 'none' }}
                />
              </div>

              <div>
                <label style={{ fontSize: '12px', fontWeight: '700', color: 'var(--text-muted)', display: 'block', marginBottom: '4px' }}>Investment Period (Years)</label>
                <input
                  type="number"
                  value={sipYears}
                  onChange={(e) => setSipYears(e.target.value)}
                  style={{ width: '100%', background: '#16192E', border: '1px solid rgba(255, 255, 255, 0.1)', borderRadius: '10px', padding: '10px 12px', color: '#FFF', fontSize: '14px', outline: 'none' }}
                />
              </div>
            </div>
          </div>

          <div className="glass-card" style={{ padding: '20px', background: 'linear-gradient(135deg, rgba(22, 25, 46, 0.95) 0%, rgba(99, 102, 241, 0.2) 100%)', display: 'flex', flexDirection: 'column', justifyContent: 'space-around' }}>
            <div>
              <div style={{ fontSize: '13px', color: 'var(--text-muted)', fontWeight: '600' }}>Expected Future Total Wealth</div>
              <div style={{ fontSize: '36px', fontWeight: '800', color: '#A5B4FC', marginTop: '4px' }}>₹{sipRes.totalWealth.toLocaleString()}</div>
            </div>

            <div style={{ borderTop: '1px solid rgba(255, 255, 255, 0.1)', paddingTop: '14px', marginTop: '14px', display: 'flex', flexDirection: 'column', gap: '8px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '14px' }}>
                <span style={{ color: 'var(--text-muted)' }}>Total Amount Invested:</span>
                <span style={{ color: '#FFF', fontWeight: '700' }}>₹{sipRes.invested.toLocaleString()}</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '14px' }}>
                <span style={{ color: 'var(--text-muted)' }}>Estimated Investment Growth:</span>
                <span style={{ color: '#10B981', fontWeight: '800' }}>+₹{sipRes.returns.toLocaleString()}</span>
              </div>
            </div>
          </div>

        </div>
      )}

    </div>
  );
};
