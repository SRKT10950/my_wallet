import React, { useState } from 'react';
import { X, Plus, FileText, ShoppingBag, Tag, Store } from 'lucide-react';
import { Product } from '../types';

interface AddProductModalProps {
  isOpen: boolean;
  onClose: () => void;
  onAddProduct: (p: Product) => void;
}

export const AddProductModal: React.FC<AddProductModalProps> = ({ isOpen, onClose, onAddProduct }) => {
  const [productName, setProductName] = useState('');
  const [localName, setLocalName] = useState('');
  const [category, setCategory] = useState('Groceries');
  const [currentPrice, setCurrentPrice] = useState('0');
  const [unit, setUnit] = useState('Pcs');
  const [quantity, setQuantity] = useState('1');
  const [appName, setAppName] = useState('Local Store');
  const [description, setDescription] = useState('');

  if (!isOpen) return null;

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!productName.trim()) return;

    const newProd: Product = {
      productName: productName.trim(),
      localName: localName.trim(),
      category,
      currentPrice: parseFloat(currentPrice) || 0,
      oldPrice: Math.round((parseFloat(currentPrice) || 0) * 1.10),
      unit,
      quantity: parseFloat(quantity) || 1,
      appName: appName.trim() || 'Local Store',
      priceDate: new Date().toISOString().split('T')[0],
      referenceLink: '',
      barcode: `890${Date.now().toString().slice(-10)}`,
      imageUrl: '',
      description: description.trim(), // Strictly lowercase DB field 'description'
      active: true
    };

    onAddProduct(newProd);
    onClose();
  };

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-content" onClick={(e) => e.stopPropagation()}>
        
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
          <h3 style={{ fontSize: '18px', fontWeight: '800', color: '#FFF' }}>Add New Catalog Product</h3>
          <button style={{ background: 'transparent', border: 'none', color: 'var(--text-muted)', cursor: 'pointer' }} onClick={onClose}>
            <X size={20} />
          </button>
        </div>

        <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
          
          <div>
            <label style={{ fontSize: '12px', fontWeight: '700', color: 'var(--text-muted)', display: 'block', marginBottom: '4px' }}>
              Product Name (English) *
            </label>
            <input
              type="text"
              required
              value={productName}
              onChange={(e) => setProductName(e.target.value)}
              placeholder="e.g. Organic Basmati Rice"
              style={{ width: '100%', background: '#16192E', border: '1px solid rgba(255, 255, 255, 0.1)', borderRadius: '10px', padding: '10px 12px', color: '#FFF', fontSize: '14px', outline: 'none' }}
            />
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
            <div>
              <label style={{ fontSize: '12px', fontWeight: '700', color: 'var(--text-muted)', display: 'block', marginBottom: '4px' }}>Local Name (Hindi / Hinglish)</label>
              <input
                type="text"
                value={localName}
                onChange={(e) => setLocalName(e.target.value)}
                placeholder="e.g. बासमती चावल (Basmati Chawal)"
                style={{ width: '100%', background: '#16192E', border: '1px solid rgba(255, 255, 255, 0.1)', borderRadius: '10px', padding: '10px 12px', color: '#FFF', fontSize: '14px', outline: 'none' }}
              />
            </div>
            <div>
              <label style={{ fontSize: '12px', fontWeight: '700', color: 'var(--text-muted)', display: 'block', marginBottom: '4px' }}>Category</label>
              <select
                value={category}
                onChange={(e) => setCategory(e.target.value)}
                style={{ width: '100%', background: '#16192E', border: '1px solid rgba(255, 255, 255, 0.1)', borderRadius: '10px', padding: '10px 12px', color: '#FFF', fontSize: '14px', outline: 'none' }}
              >
                <option value="Groceries">Groceries</option>
                <option value="Vegetables & Fruits">Vegetables & Fruits</option>
                <option value="Dairy & Bakery">Dairy & Bakery</option>
                <option value="Snacks & Drinks">Snacks & Drinks</option>
                <option value="Medicines">Medicines</option>
                <option value="Personal Care">Personal Care</option>
                <option value="Electronics">Electronics</option>
              </select>
            </div>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '12px' }}>
            <div>
              <label style={{ fontSize: '12px', fontWeight: '700', color: 'var(--text-muted)', display: 'block', marginBottom: '4px' }}>Current Price (₹)</label>
              <input
                type="number"
                value={currentPrice}
                onChange={(e) => setCurrentPrice(e.target.value)}
                style={{ width: '100%', background: '#16192E', border: '1px solid rgba(255, 255, 255, 0.1)', borderRadius: '10px', padding: '10px 12px', color: '#FFF', fontSize: '14px', outline: 'none' }}
              />
            </div>
            <div>
              <label style={{ fontSize: '12px', fontWeight: '700', color: 'var(--text-muted)', display: 'block', marginBottom: '4px' }}>Quantity</label>
              <input
                type="number"
                value={quantity}
                onChange={(e) => setQuantity(e.target.value)}
                style={{ width: '100%', background: '#16192E', border: '1px solid rgba(255, 255, 255, 0.1)', borderRadius: '10px', padding: '10px 12px', color: '#FFF', fontSize: '14px', outline: 'none' }}
              />
            </div>
            <div>
              <label style={{ fontSize: '12px', fontWeight: '700', color: 'var(--text-muted)', display: 'block', marginBottom: '4px' }}>Unit</label>
              <select
                value={unit}
                onChange={(e) => setUnit(e.target.value)}
                style={{ width: '100%', background: '#16192E', border: '1px solid rgba(255, 255, 255, 0.1)', borderRadius: '10px', padding: '10px 12px', color: '#FFF', fontSize: '14px', outline: 'none' }}
              >
                <option value="Pcs">Pcs</option>
                <option value="Kg">Kg</option>
                <option value="Gram">Gram</option>
                <option value="Ml">Ml</option>
                <option value="Ltr">Ltr</option>
                <option value="Pack">Pack</option>
                <option value="Box">Box</option>
              </select>
            </div>
          </div>

          <div>
            <label style={{ fontSize: '12px', fontWeight: '700', color: 'var(--text-muted)', display: 'block', marginBottom: '4px' }}>
              Product Description (description)
            </label>
            <textarea
              rows={2}
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="e.g. Premium long grain basmati rice..."
              style={{ width: '100%', background: '#16192E', border: '1px solid rgba(255, 255, 255, 0.1)', borderRadius: '10px', padding: '10px 12px', color: '#FFF', fontSize: '14px', outline: 'none', resize: 'vertical' }}
            />
          </div>

          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px', marginTop: '12px' }}>
            <button type="button" className="secondary-btn" onClick={onClose}>
              Cancel
            </button>
            <button type="submit" className="neon-btn">
              <Plus size={16} /> Insert to Database
            </button>
          </div>

        </form>

      </div>
    </div>
  );
};
