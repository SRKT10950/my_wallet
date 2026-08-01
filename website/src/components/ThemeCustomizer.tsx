import React, { useState } from 'react';
import { Palette, Sparkles, Check } from 'lucide-react';

export const ThemeCustomizer: React.FC = () => {
  const [selectedColor, setSelectedColor] = useState('#00F5D4');

  const themes = [
    { name: 'Cyber Cyan', hex: '#00F5D4', label: 'Default Cyber-Glassmorphic Neon' },
    { name: 'Electric Violet', hex: '#A855F7', label: 'Futuristic Purple Ambient Glow' },
    { name: 'Emerald Green', hex: '#10B981', label: 'Financial Wealth Emerald Theme' },
    { name: 'Sunset Amber', hex: '#F59E0B', label: 'Warm Obsidian & Amber Glow' }
  ];

  const applyTheme = (colorHex: string) => {
    setSelectedColor(colorHex);
    document.documentElement.style.setProperty('--neon-cyan', colorHex);
    document.documentElement.style.setProperty('--border-card', `${colorHex}40`);
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
      
      {/* Header Info */}
      <div className="glass-card" style={{ padding: '20px' }}>
        <h2 style={{ fontSize: '22px', fontWeight: '800', color: '#FFF', display: 'flex', alignItems: 'center', gap: '10px' }}>
          <Palette size={24} color={selectedColor} /> Custom Theme & Aesthetics Personalizer
        </h2>
        <div style={{ fontSize: '13px', color: 'var(--text-muted)', marginTop: '4px' }}>
          Customize neon accent glow colors and glassmorphic aesthetics in real-time.
        </div>
      </div>

      {/* Color Selection Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))', gap: '16px' }}>
        {themes.map((t) => {
          const isSelected = selectedColor === t.hex;
          return (
            <div
              key={t.name}
              className="glass-card"
              onClick={() => applyTheme(t.hex)}
              style={{
                padding: '20px',
                cursor: 'pointer',
                border: isSelected ? `2px solid ${t.hex}` : '1px solid rgba(255, 255, 255, 0.1)',
                background: isSelected ? `linear-gradient(135deg, rgba(22, 25, 46, 0.95) 0%, ${t.hex}25 100%)` : 'var(--bg-card)'
              }}
            >
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px' }}>
                <div style={{ width: '32px', height: '32px', borderRadius: '50%', background: t.hex, boxShadow: `0 0 15px ${t.hex}` }} />
                {isSelected && <Check size={20} color={t.hex} />}
              </div>

              <div style={{ fontSize: '16px', fontWeight: '800', color: '#FFF' }}>{t.name}</div>
              <div style={{ fontSize: '12px', color: 'var(--text-muted)', marginTop: '4px' }}>{t.label}</div>
            </div>
          );
        })}
      </div>

    </div>
  );
};
