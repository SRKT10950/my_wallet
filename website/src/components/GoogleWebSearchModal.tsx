import React, { useState, useEffect } from 'react';
import { X, Search, Globe, Plus, CheckCircle2, FileText, Loader2 } from 'lucide-react';
import { Product } from '../types';
import { GoogleProductSearchService } from '../services/googleProductSearchService';

interface GoogleWebSearchModalProps {
  isOpen: boolean;
  initialQuery: string;
  onClose: () => void;
  onSelectAndInsertProduct: (p: Product) => void;
}

export const GoogleWebSearchModal: React.FC<GoogleWebSearchModalProps> = ({
  isOpen,
  initialQuery,
  onClose,
  onSelectAndInsertProduct
}) => {
  const [query, setQuery] = useState(initialQuery);
  const [loading, setLoading] = useState(false);
  const [webProducts, setWebProducts] = useState<Product[]>([]);

  useEffect(() => {
    if (isOpen) {
      setQuery(initialQuery);
      if (initialQuery.trim()) {
        performSearch(initialQuery);
      }
    }
  }, [isOpen, initialQuery]);

  const performSearch = async (q: string) => {
    if (!q.trim()) return;
    setLoading(true);
    try {
      const results = await GoogleProductSearchService.searchGoogleProducts(q);
      setWebProducts(results);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  if (!isOpen) return null;

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-content" onClick={(e) => e.stopPropagation()}>
        
        {/* Modal Header */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
          <div>
            <h3 style={{ fontSize: '18px', fontWeight: '800', color: '#FFF', display: 'flex', alignItems: 'center', gap: '8px' }}>
              <Globe size={20} color="#00F5D4" /> Google & Web Product Search
            </h3>
            <div style={{ fontSize: '12px', color: 'var(--neon-cyan)', marginTop: '2px' }}>
              Search Google, OpenFoodFacts & Online Pharmacy Catalogs
            </div>
          </div>
          <button style={{ background: 'transparent', border: 'none', color: 'var(--text-muted)', cursor: 'pointer' }} onClick={onClose}>
            <X size={20} />
          </button>
        </div>

        {/* Search Bar */}
        <div style={{ display: 'flex', gap: '8px', marginBottom: '20px' }}>
          <div style={{ flex: 1, position: 'relative' }}>
            <Search size={18} color="var(--neon-cyan)" style={{ position: 'absolute', left: '14px', top: '50%', transform: 'translateY(-50%)' }} />
            <input
              type="text"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && performSearch(query)}
              placeholder="e.g. Ocotic Ear Drop, Matar, Amul Butter..."
              style={{
                width: '100%',
                background: '#16192E',
                border: '1px solid rgba(0, 245, 212, 0.4)',
                borderRadius: '12px',
                padding: '12px 14px 12px 42px',
                color: '#FFF',
                fontSize: '14px',
                outline: 'none'
              }}
            />
          </div>
          <button className="neon-btn" onClick={() => performSearch(query)}>
            Search
          </button>
        </div>

        {/* Loading State */}
        {loading && (
          <div style={{ padding: '40px', textAlign: 'center', color: 'var(--text-muted)' }}>
            <Loader2 size={32} color="#00F5D4" className="animate-spin" style={{ margin: '0 auto 12px auto' }} />
            <div>Executing Google & Web Product Search...</div>
          </div>
        )}

        {/* Search Results */}
        {!loading && (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
            {webProducts.map((webP, idx) => (
              <div key={idx} style={{ background: '#16192E', border: '1px solid rgba(0, 245, 212, 0.3)', borderRadius: '16px', padding: '14px', display: 'flex', flexDirection: 'column', gap: '10px' }}>
                
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: '8px' }}>
                  <div>
                    <h4 style={{ fontSize: '15px', fontWeight: '800', color: '#FFF' }}>{webP.productName}</h4>
                    {webP.localName && (
                      <div style={{ fontSize: '12px', color: 'var(--amber-gold)', marginTop: '2px' }}>{webP.localName}</div>
                    )}
                    <div className="badge-category" style={{ display: 'inline-block', marginTop: '6px' }}>🏷️ {webP.category}</div>
                  </div>
                  <span className="badge-price">₹{webP.currentPrice} / {webP.quantity} {webP.unit}</span>
                </div>

                {/* Description */}
                {webP.description && (
                  <div style={{ background: 'rgba(255, 255, 255, 0.04)', borderRadius: '8px', padding: '8px 10px', border: '1px solid rgba(255, 255, 255, 0.08)', display: 'flex', gap: '6px' }}>
                    <FileText size={14} color="#00F5D4" style={{ flexShrink: 0, marginTop: '2px' }} />
                    <div style={{ fontSize: '12px', color: 'var(--text-muted)' }}>
                      <strong style={{ color: '#FFF' }}>Description:</strong> {webP.description}
                    </div>
                  </div>
                )}

                {/* Footer Source & Selection Button */}
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: '4px' }}>
                  <span style={{ fontSize: '11px', color: 'var(--text-muted)' }}>Source: {webP.appName}</span>
                  <button className="neon-btn" style={{ fontSize: '12px', padding: '6px 12px' }} onClick={() => onSelectAndInsertProduct(webP)}>
                    <Plus size={14} /> Select & Insert to DB
                  </button>
                </div>

              </div>
            ))}
          </div>
        )}

      </div>
    </div>
  );
};
