import React from 'react';
import { Smartphone, Download, X } from 'lucide-react';

interface PwaInstallBannerProps {
  onInstall: () => void;
  onClose: () => void;
}

export const PwaInstallBanner: React.FC<PwaInstallBannerProps> = ({ onInstall, onClose }) => {
  return (
    <div style={{
      position: 'fixed',
      bottom: '24px',
      left: '50%',
      transform: 'translateX(-50%)',
      zIndex: 99999,
      background: 'linear-gradient(135deg, #16192E 0%, #0E111F 100%)',
      border: '1.5px solid #00F5D4',
      borderRadius: '18px',
      padding: '14px 20px',
      boxShadow: '0 15px 40px rgba(0, 0, 0, 0.7)',
      display: 'flex',
      alignItems: 'center',
      gap: '16px',
      maxWidth: '92vw',
      width: '460px'
    }}>
      <div style={{ background: 'rgba(0, 245, 212, 0.15)', padding: '10px', borderRadius: '12px', display: 'flex', alignItems: 'center' }}>
        <Smartphone size={22} color="#00F5D4" />
      </div>

      <div style={{ flex: 1 }}>
        <div style={{ fontWeight: '800', fontSize: '14px', color: '#FFF' }}>Install My Wallet 2.0 App</div>
        <div style={{ fontSize: '11px', color: 'var(--text-muted)' }}>Offline access & full-screen native desktop/mobile app</div>
      </div>

      <button className="neon-btn" style={{ fontSize: '12px', padding: '8px 14px' }} onClick={onInstall}>
        <Download size={14} /> Install
      </button>

      <button style={{ background: 'transparent', border: 'none', color: 'var(--text-muted)', cursor: 'pointer', padding: '4px' }} onClick={onClose}>
        <X size={18} />
      </button>
    </div>
  );
};
