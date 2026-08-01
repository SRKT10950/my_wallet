import React, { useState } from 'react';
import { Camera, FileText, CheckCircle2, Upload, Loader2, DollarSign } from 'lucide-react';
import { Transaction } from '../types';

interface ReceiptScannerProps {
  onAddTransaction: (t: Transaction) => void;
}

export const ReceiptScanner: React.FC<ReceiptScannerProps> = ({ onAddTransaction }) => {
  const [scanning, setScanning] = useState(false);
  const [scannedData, setScannedData] = useState<{
    merchant: string;
    amount: number;
    date: string;
    items: string[];
  } | null>(null);

  const simulateScan = () => {
    setScanning(true);
    setScannedData(null);

    setTimeout(() => {
      setScanning(false);
      setScannedData({
        merchant: 'Reliance Smart Supermarket',
        amount: 2840,
        date: new Date().toISOString().split('T')[0],
        items: [
          'Organic Basmati Rice 5kg - ₹650',
          'Amul Pasteurised Butter 500g - ₹275',
          'Safal Frozen Green Peas 500g - ₹65',
          'Fresh Vegetables & Fruits - ₹480',
          'Household Supplies - ₹1370'
        ]
      });
    }, 1200);
  };

  const handleSaveReceipt = () => {
    if (!scannedData) return;
    const newTx: Transaction = {
      id: Date.now(),
      title: scannedData.merchant,
      amount: scannedData.amount,
      category: 'Groceries',
      type: 'expense',
      date: scannedData.date,
      account: 'Credit Card',
      merchantName: scannedData.merchant
    };

    onAddTransaction(newTx);
    setScannedData(null);
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
      
      {/* Header Info */}
      <div className="glass-card" style={{ padding: '20px' }}>
        <h2 style={{ fontSize: '22px', fontWeight: '800', color: '#FFF', display: 'flex', alignItems: 'center', gap: '10px' }}>
          <Camera size={24} color="#00F5D4" /> Receipt & Invoice OCR Scanner
        </h2>
        <div style={{ fontSize: '13px', color: 'var(--text-muted)', marginTop: '4px' }}>
          Upload or take a photo of shopping receipts to automatically extract store merchant, items, and total amount.
        </div>
      </div>

      {/* Upload & Scan Trigger Box */}
      <div className="glass-card" style={{ padding: '30px', textAlign: 'center', border: '2px dashed rgba(0, 245, 212, 0.4)', borderRadius: '20px' }}>
        <Camera size={48} color="#00F5D4" style={{ margin: '0 auto 12px auto' }} />
        <h3 style={{ fontSize: '18px', fontWeight: '800', color: '#FFF', marginBottom: '6px' }}>Upload or Snap Receipt Image</h3>
        <p style={{ fontSize: '13px', color: 'var(--text-muted)', marginBottom: '18px' }}>Supports JPG, PNG, and PDF receipts</p>

        <div style={{ display: 'flex', justifyContent: 'center', gap: '12px' }}>
          <button className="neon-btn" onClick={simulateScan} disabled={scanning}>
            {scanning ? <Loader2 size={16} className="animate-spin" /> : <Upload size={16} />}
            {scanning ? 'Processing OCR Extraction...' : 'Scan Sample Receipt'}
          </button>
        </div>
      </div>

      {/* Scanned Result Card */}
      {scannedData && (
        <div className="glass-card" style={{ padding: '20px', background: 'linear-gradient(135deg, rgba(22, 25, 46, 0.95) 0%, rgba(0, 245, 212, 0.15) 100%)', border: '1.5px solid #00F5D4' }}>
          <h3 style={{ fontSize: '16px', fontWeight: '800', color: '#FFF', marginBottom: '14px', display: 'flex', alignItems: 'center', gap: '8px' }}>
            <FileText size={18} color="#00F5D4" /> Extracted Receipt Invoice Breakdown
          </h3>

          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '14px' }}>
            <div>
              <div style={{ fontSize: '18px', fontWeight: '800', color: '#FFF' }}>{scannedData.merchant}</div>
              <div style={{ fontSize: '12px', color: 'var(--text-muted)' }}>Date: {scannedData.date}</div>
            </div>
            <div style={{ textAlign: 'right' }}>
              <div style={{ fontSize: '24px', fontWeight: '800', color: '#00F5D4' }}>₹{scannedData.amount.toLocaleString()}</div>
              <div style={{ fontSize: '11px', color: 'var(--amber-gold)', fontWeight: '700' }}>Verified OCR Invoice</div>
            </div>
          </div>

          <div style={{ background: '#16192E', borderRadius: '10px', padding: '12px', marginBottom: '16px' }}>
            <div style={{ fontSize: '12px', fontWeight: '700', color: 'var(--text-muted)', marginBottom: '6px' }}>Line Items Extracted:</div>
            {scannedData.items.map((item, idx) => (
              <div key={idx} style={{ fontSize: '13px', color: '#FFF', padding: '4px 0', borderBottom: idx < scannedData.items.length - 1 ? '1px solid rgba(255, 255, 255, 0.05)' : 'none' }}>
                • {item}
              </div>
            ))}
          </div>

          <button className="neon-btn" style={{ width: '100%', justifyContent: 'center' }} onClick={handleSaveReceipt}>
            <CheckCircle2 size={16} /> Add Receipt Expense to Wallet Database
          </button>
        </div>
      )}

    </div>
  );
};
