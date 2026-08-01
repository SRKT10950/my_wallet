import React, { useState } from 'react';
import { Fuel, PlusCircle, Gauge, DollarSign, MapPin } from 'lucide-react';
import { FuelLog } from '../types';

interface FuelTrackerProps {
  logs: FuelLog[];
  onAddFuelLog: (log: FuelLog) => void;
}

export const FuelTracker: React.FC<FuelTrackerProps> = ({ logs, onAddFuelLog }) => {
  const [odometer, setOdometer] = useState('');
  const [litres, setLitres] = useState('');
  const [pricePerLitre, setPricePerLitre] = useState('96.5');
  const [station, setStation] = useState('Indian Oil');

  const latestLog = logs.length > 0 ? logs[0] : null;
  const avgMileage = logs.length > 0
    ? (logs.reduce((acc, l) => acc + (l.mileage || 14.5), 0) / logs.length).toFixed(1)
    : '14.8';

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!odometer.trim() || !litres.trim()) return;

    const odo = parseFloat(odometer) || 0;
    const lit = parseFloat(litres) || 0;
    const price = parseFloat(pricePerLitre) || 96.5;

    const newLog: FuelLog = {
      id: Date.now(),
      date: new Date().toISOString().split('T')[0],
      odometer: odo,
      litres: lit,
      pricePerLitre: price,
      totalCost: Math.round(lit * price),
      station
    };

    onAddFuelLog(newLog);
    setOdometer('');
    setLitres('');
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
      
      {/* Vehicle Fuel Metrics Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(260px, 1fr))', gap: '16px' }}>
        
        <div className="glass-card" style={{ padding: '20px', background: 'linear-gradient(135deg, rgba(22, 25, 46, 0.9) 0%, rgba(0, 245, 212, 0.15) 100%)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '13px', color: 'var(--text-muted)', fontWeight: '600' }}>Average Vehicle Mileage</span>
            <Gauge size={18} color="#00F5D4" />
          </div>
          <div style={{ fontSize: '32px', fontWeight: '800', color: '#00F5D4', marginTop: '6px' }}>{avgMileage} <span style={{ fontSize: '14px', color: 'var(--text-muted)' }}>km/L</span></div>
          <div style={{ fontSize: '12px', color: 'var(--text-muted)', marginTop: '4px' }}>Calculated across last {logs.length} refills</div>
        </div>

        <div className="glass-card" style={{ padding: '20px', background: 'linear-gradient(135deg, rgba(22, 25, 46, 0.9) 0%, rgba(245, 158, 11, 0.15) 100%)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '13px', color: 'var(--text-muted)', fontWeight: '600' }}>Latest Odometer Reading</span>
            <Fuel size={18} color="#F59E0B" />
          </div>
          <div style={{ fontSize: '32px', fontWeight: '800', color: '#F59E0B', marginTop: '6px' }}>{latestLog ? latestLog.odometer.toLocaleString() : '12,970'} <span style={{ fontSize: '14px', color: 'var(--text-muted)' }}>km</span></div>
          <div style={{ fontSize: '12px', color: 'var(--text-muted)', marginTop: '4px' }}>Last refilled on {latestLog ? latestLog.date : 'Recent'}</div>
        </div>

      </div>

      {/* New Fuel Refill Form */}
      <div className="glass-card" style={{ padding: '20px' }}>
        <h3 style={{ fontSize: '18px', fontWeight: '800', color: '#FFF', marginBottom: '14px', display: 'flex', alignItems: 'center', gap: '8px' }}>
          <PlusCircle size={20} color="#00F5D4" /> Record Vehicle Fuel Refill
        </h3>

        <form onSubmit={handleSubmit} style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '14px' }}>
          
          <div>
            <label style={{ fontSize: '12px', fontWeight: '700', color: 'var(--text-muted)', display: 'block', marginBottom: '4px' }}>Odometer Reading (km) *</label>
            <input
              type="number"
              required
              value={odometer}
              onChange={(e) => setOdometer(e.target.value)}
              placeholder="e.g. 13450"
              style={{ width: '100%', background: '#16192E', border: '1px solid rgba(255, 255, 255, 0.1)', borderRadius: '10px', padding: '10px 12px', color: '#FFF', fontSize: '14px', outline: 'none' }}
            />
          </div>

          <div>
            <label style={{ fontSize: '12px', fontWeight: '700', color: 'var(--text-muted)', display: 'block', marginBottom: '4px' }}>Litres Filled *</label>
            <input
              type="number"
              required
              value={litres}
              onChange={(e) => setLitres(e.target.value)}
              placeholder="e.g. 32.5"
              style={{ width: '100%', background: '#16192E', border: '1px solid rgba(255, 255, 255, 0.1)', borderRadius: '10px', padding: '10px 12px', color: '#FFF', fontSize: '14px', outline: 'none' }}
            />
          </div>

          <div>
            <label style={{ fontSize: '12px', fontWeight: '700', color: 'var(--text-muted)', display: 'block', marginBottom: '4px' }}>Fuel Price (₹/Litre)</label>
            <input
              type="number"
              value={pricePerLitre}
              onChange={(e) => setPricePerLitre(e.target.value)}
              style={{ width: '100%', background: '#16192E', border: '1px solid rgba(255, 255, 255, 0.1)', borderRadius: '10px', padding: '10px 12px', color: '#FFF', fontSize: '14px', outline: 'none' }}
            />
          </div>

          <div>
            <label style={{ fontSize: '12px', fontWeight: '700', color: 'var(--text-muted)', display: 'block', marginBottom: '4px' }}>Fuel Station</label>
            <input
              type="text"
              value={station}
              onChange={(e) => setStation(e.target.value)}
              placeholder="e.g. Indian Oil / HP"
              style={{ width: '100%', background: '#16192E', border: '1px solid rgba(255, 255, 255, 0.1)', borderRadius: '10px', padding: '10px 12px', color: '#FFF', fontSize: '14px', outline: 'none' }}
            />
          </div>

          <div style={{ display: 'flex', alignItems: 'flex-end', gridColumn: '1 / -1' }}>
            <button type="submit" className="neon-btn" style={{ width: '100%', height: '42px', justifyContent: 'center' }}>
              Calculate Mileage & Save Log
            </button>
          </div>

        </form>
      </div>

      {/* Fuel Log History */}
      <div className="glass-card" style={{ padding: '20px' }}>
        <h3 style={{ fontSize: '18px', fontWeight: '800', color: '#FFF', marginBottom: '16px' }}>Fuel Refill Log History ({logs.length})</h3>

        <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
          {logs.map((l) => (
            <div key={l.id} style={{ background: '#16192E', border: '1px solid rgba(0, 245, 212, 0.3)', borderRadius: '16px', padding: '16px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              
              <div>
                <div style={{ fontSize: '16px', fontWeight: '800', color: '#FFF' }}>{l.odometer.toLocaleString()} km</div>
                <div style={{ fontSize: '12px', color: 'var(--text-muted)', marginTop: '2px' }}>
                  📅 {l.date} • ⛽ {l.litres} Litres @ ₹{l.pricePerLitre}/L • 📍 {l.station}
                </div>
              </div>

              <div style={{ textAlign: 'right' }}>
                <div style={{ fontSize: '16px', fontWeight: '800', color: '#00F5D4' }}>₹{l.totalCost}</div>
                {l.mileage && (
                  <div style={{ fontSize: '12px', color: 'var(--amber-gold)', fontWeight: '700', marginTop: '2px' }}>
                    ⚡ {l.mileage} km/L
                  </div>
                )}
              </div>

            </div>
          ))}
        </div>
      </div>

    </div>
  );
};
