import React, { useState } from 'react';
import { Box, Card, CardContent, Typography, Button, Chip, Select, MenuItem, FormControl, Avatar } from '@mui/material';
import AccountBalanceWalletIcon from '@mui/icons-material/AccountBalanceWallet';
import ShoppingBagIcon from '@mui/icons-material/ShoppingBag';
import TrendingUpIcon from '@mui/icons-material/TrendingUp';
import CreditCardIcon from '@mui/icons-material/CreditCard';
import AccessTimeIcon from '@mui/icons-material/AccessTime';
import CalendarTodayIcon from '@mui/icons-material/CalendarToday';
import LanguageIcon from '@mui/icons-material/Language';
import SmartphoneIcon from '@mui/icons-material/Smartphone';
import PhotoCameraIcon from '@mui/icons-material/PhotoCamera';
import PeopleIcon from '@mui/icons-material/People';
import LocalGasStationIcon from '@mui/icons-material/LocalGasStation';
import CalculateIcon from '@mui/icons-material/Calculate';
import MonitorHeartIcon from '@mui/icons-material/MonitorHeart';
import NfcIcon from '@mui/icons-material/Nfc';
import AddCircleIcon from '@mui/icons-material/AddCircle';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import ArrowUpwardIcon from '@mui/icons-material/ArrowUpward';
import ArrowDownwardIcon from '@mui/icons-material/ArrowDownward';
import { Product, Transaction } from '../types';

interface DashboardProps {
  products: Product[];
  onOpenAddProduct: () => void;
  onOpenWebSearch: () => void;
  setActiveTab: (tab: string) => void;
}

export const Dashboard: React.FC<DashboardProps> = ({ products, onOpenAddProduct, onOpenWebSearch, setActiveTab }) => {
  const [selectedMonth, setSelectedMonth] = useState('Jul');
  const [selectedYear, setSelectedYear] = useState('2026');

  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  const years = ['2024', '2025', '2026', '2027'];

  const activeProducts = products.filter(p => p.active);

  const hubActions = [
    { title: 'Search Google Products', desc: 'Web & Pharmacy search', icon: LanguageIcon, color: '#00F5D4', tab: 'products', action: onOpenWebSearch },
    { title: 'Add Product Master', desc: 'Manual catalog entry', icon: AddCircleIcon, color: '#10B981', tab: 'products', action: onOpenAddProduct },
    { title: 'Parse Bank SMS', desc: 'Auto extract transactions', icon: SmartphoneIcon, color: '#3B82F6', tab: 'smsparser' },
    { title: 'Scan Receipt OCR', desc: 'Extract bill line items', icon: PhotoCameraIcon, color: '#EC4899', tab: 'receipts' },
    { title: 'Split Bill with Friends', desc: 'Equal & custom split', icon: PeopleIcon, color: '#F59E0B', tab: 'splitwise' },
    { title: 'Vehicle Fuel Log', desc: 'Calculate km/L mileage', icon: LocalGasStationIcon, color: '#06B6D4', tab: 'fuel' },
    { title: 'EMI & SIP Calculator', desc: 'Loan & return planner', icon: CalculateIcon, color: '#6366F1', tab: 'calculators' },
    { title: 'Financial Health Score', desc: '0-100 resilience score', icon: MonitorHeartIcon, color: '#EF4444', tab: 'health' }
  ];

  const sampleRecentTransactions = [
    { title: 'Ocotic Ear Drops Purchase', merchant: 'Tata 1mg', date: '31 Jul 2026', amount: 85, category: 'Medicines', cleared: true },
    { title: 'Monthly Salary Credit', merchant: 'Acme Corp', date: '01 Jul 2026', amount: 85000, category: 'Salary', cleared: true, type: 'income' },
    { title: 'Amul Pasteurised Butter (500g)', merchant: 'Blinkit', date: '15 Jul 2026', amount: 275, category: 'Dairy', cleared: true },
    { title: 'Electricity Bill Payment', merchant: 'State Power Board', date: '20 Jul 2026', amount: 2200, category: 'Utilities', cleared: false }
  ];

  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
      
      {/* 1. Financial Period Selector Header */}
      <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: 2 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
          <CalendarTodayIcon sx={{ color: 'primary.main', fontSize: 20 }} />
          <Typography variant="body2" sx={{ fontWeight: 800, color: 'text.secondary' }}>
            Financial Period:
          </Typography>

          <FormControl size="small" sx={{ minWidth: 90 }}>
            <Select
              value={selectedMonth}
              onChange={(e) => setSelectedMonth(e.target.value)}
              sx={{ borderRadius: 2, height: 36, fontSize: '0.85rem', fontWeight: 700 }}
            >
              {months.map(m => <MenuItem key={m} value={m}>{m}</MenuItem>)}
            </Select>
          </FormControl>

          <FormControl size="small" sx={{ minWidth: 90 }}>
            <Select
              value={selectedYear}
              onChange={(e) => setSelectedYear(e.target.value)}
              sx={{ borderRadius: 2, height: 36, fontSize: '0.85rem', fontWeight: 700 }}
            >
              {years.map(y => <MenuItem key={y} value={y}>{y}</MenuItem>)}
            </Select>
          </FormControl>
        </Box>

        <Chip
          icon={<CheckCircleIcon sx={{ fontSize: 16 }} />}
          label="Period Realtime Sync Active"
          color="primary"
          variant="outlined"
          sx={{ fontWeight: 700, borderRadius: 2 }}
        />
      </Box>

      {/* 2. Global TOTAL NET WORTH Credit Card Hero Widget */}
      <Card sx={{ background: 'linear-gradient(135deg, #1E1B4B 0%, #312E81 50%, #4338CA 100%)', border: '1.5px solid rgba(0, 245, 212, 0.4)', borderRadius: 4, position: 'relative', overflow: 'hidden' }}>
        <CardContent sx={{ padding: 3.5 }}>
          <AccountBalanceWalletIcon sx={{ position: 'absolute', right: -20, bottom: -25, fontSize: 160, opacity: 0.08, color: '#FFF' }} />

          <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 1 }}>
            <Typography variant="caption" sx={{ fontWeight: 800, color: 'rgba(255, 255, 255, 0.7)', letterSpacing: 1.5 }}>
              TOTAL NET WORTH
            </Typography>
            <NfcIcon sx={{ color: 'rgba(255, 255, 255, 0.6)' }} />
          </Box>

          <Typography variant="h3" sx={{ fontWeight: 800, color: '#FFF', letterSpacing: -1, my: 1 }}>
            ₹5,84,750
          </Typography>

          <Box sx={{ display: 'flex', gap: 2, flexWrap: 'wrap', fontSize: '0.85rem', fontWeight: 700 }}>
            <Typography variant="body2" sx={{ color: 'rgba(255, 255, 255, 0.85)', fontWeight: 700 }}>Wallets: ₹50,350</Typography>
            <Typography variant="body2" sx={{ color: '#6EE7B7', fontWeight: 700 }}>• Assets: ₹3,54,000</Typography>
            <Typography variant="body2" sx={{ color: '#FCA5A5', fontWeight: 700 }}>• Pending Loans: ₹15,000</Typography>
          </Box>
        </CardContent>
      </Card>

      {/* 3. 4 Core Metrics Grid */}
      <Box sx={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))', gap: 2 }}>
        <Card>
          <CardContent sx={{ padding: 2.5 }}>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 1 }}>
              <Typography variant="caption" color="text.secondary" sx={{ fontWeight: 800 }}>Monthly Expenditure</Typography>
              <ShoppingBagIcon sx={{ color: '#F43F5E' }} />
            </Box>
            <Typography variant="h5" sx={{ fontWeight: 800, color: '#FFF' }}>₹34,650</Typography>
            <Typography variant="caption" sx={{ color: '#F43F5E', fontWeight: 700 }}>Spent in {selectedMonth} {selectedYear}</Typography>
          </CardContent>
        </Card>

        <Card>
          <CardContent sx={{ padding: 2.5 }}>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 1 }}>
              <Typography variant="caption" color="text.secondary" sx={{ fontWeight: 800 }}>Asset Investments</Typography>
              <TrendingUpIcon sx={{ color: '#10B981' }} />
            </Box>
            <Typography variant="h5" sx={{ fontWeight: 800, color: '#FFF' }}>₹3,54,000</Typography>
            <Typography variant="caption" sx={{ color: '#10B981', fontWeight: 700 }}>Growth portfolio +14.8%</Typography>
          </CardContent>
        </Card>

        <Card>
          <CardContent sx={{ padding: 2.5 }}>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 1 }}>
              <Typography variant="caption" color="text.secondary" sx={{ fontWeight: 800 }}>Monthly EMIs</Typography>
              <CreditCardIcon sx={{ color: '#6366F1' }} />
            </Box>
            <Typography variant="h5" sx={{ fontWeight: 800, color: '#FFF' }}>₹12,400</Typography>
            <Typography variant="caption" sx={{ color: '#6366F1', fontWeight: 700 }}>2 Active loans</Typography>
          </CardContent>
        </Card>

        <Card>
          <CardContent sx={{ padding: 2.5 }}>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 1 }}>
              <Typography variant="caption" color="text.secondary" sx={{ fontWeight: 800 }}>Scheduled Bills</Typography>
              <AccessTimeIcon sx={{ color: '#F59E0B' }} />
            </Box>
            <Typography variant="h5" sx={{ fontWeight: 800, color: '#FFF' }}>2 Bills Due</Typography>
            <Typography variant="caption" sx={{ color: '#F59E0B', fontWeight: 700 }}>Next 7 days</Typography>
          </CardContent>
        </Card>
      </Box>

      {/* 4. Quick Action Hub Launchpad Grid */}
      <Box>
        <Typography variant="subtitle1" sx={{ fontWeight: 800, color: '#FFF', mb: 1.5, display: 'flex', alignItems: 'center', gap: 1 }}>
          <AddCircleIcon color="primary" /> Quick Action Launchpad
        </Typography>

        <Box sx={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))', gap: 2 }}>
          {hubActions.map((h, idx) => {
            const Icon = h.icon;
            return (
              <Card key={idx} onClick={() => h.action ? h.action() : setActiveTab(h.tab)} sx={{ cursor: 'pointer', height: '100%' }}>
                <CardContent sx={{ padding: 2, display: 'flex', alignItems: 'center', gap: 1.5 }}>
                  <Avatar sx={{ bgcolor: `${h.color}20`, color: h.color, width: 40, height: 40 }}>
                    <Icon sx={{ fontSize: 22 }} />
                  </Avatar>
                  <Box sx={{ flex: 1 }}>
                    <Typography variant="body2" sx={{ fontWeight: 700, color: '#FFF' }}>{h.title}</Typography>
                    <Typography variant="caption" color="text.secondary">{h.desc}</Typography>
                  </Box>
                </CardContent>
              </Card>
            );
          })}
        </Box>
      </Box>

      {/* 5. Product Master Snapshot */}
      <Card>
        <CardContent sx={{ padding: 3 }}>
          <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2, flexWrap: 'wrap', gap: 1 }}>
            <Box>
              <Typography variant="h6" sx={{ fontWeight: 800, color: '#FFF', display: 'flex', alignItems: 'center', gap: 1 }}>
                <ShoppingBagIcon color="primary" /> Product Master Catalog Snapshot
              </Typography>
              <Typography variant="caption" color="primary" sx={{ fontWeight: 700 }}>
                {activeProducts.length} Items cataloged with Google & Pharmacy benchmark prices
              </Typography>
            </Box>

            <Box sx={{ display: 'flex', gap: 1 }}>
              <Button variant="contained" color="primary" size="small" startIcon={<LanguageIcon />} onClick={onOpenWebSearch}>
                Web Search
              </Button>
              <Button variant="outlined" color="secondary" size="small" onClick={() => setActiveTab('products')}>
                View Catalog ({products.length})
              </Button>
            </Box>
          </Box>

          <Box sx={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))', gap: 2 }}>
            {activeProducts.slice(0, 4).map((p) => (
              <Box key={p.id} sx={{ background: '#16192E', border: '1px solid rgba(0, 245, 212, 0.25)', borderRadius: 3, padding: 2, display: 'flex', flexDirection: 'column', justifyContent: 'space-between', height: '100%' }}>
                <Box>
                  <Typography variant="subtitle2" sx={{ fontWeight: 800, color: '#FFF' }}>{p.productName}</Typography>
                  {p.localName && <Typography variant="caption" sx={{ color: 'warning.main', fontWeight: 700, display: 'block' }}>{p.localName}</Typography>}
                  <Chip label={p.category} size="small" color="secondary" sx={{ height: 20, fontSize: 10, mt: 1, fontWeight: 700 }} />
                </Box>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mt: 1.5, pt: 1, borderTop: '1px solid rgba(255, 255, 255, 0.08)' }}>
                  <Chip label={`₹${p.currentPrice}`} size="small" color="primary" sx={{ fontWeight: 800, height: 22 }} />
                  <Typography variant="caption" color="text.secondary">{p.appName || 'Catalog'}</Typography>
                </Box>
              </Box>
            ))}
          </Box>
        </CardContent>
      </Card>

      {/* 6. Recent Financial Activity Table */}
      <Card>
        <CardContent sx={{ padding: 3 }}>
          <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
            <Typography variant="h6" sx={{ fontWeight: 800, color: '#FFF' }}>Recent Financial Activity</Typography>
            <Chip label="Realtime Sync" size="small" color="primary" variant="outlined" sx={{ fontWeight: 700 }} />
          </Box>

          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
            {sampleRecentTransactions.map((tx, idx) => (
              <Box key={idx} sx={{ background: 'rgba(14, 17, 31, 0.6)', border: '1px solid rgba(255, 255, 255, 0.08)', borderRadius: 2.5, padding: 1.5, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
                  <Avatar sx={{ bgcolor: tx.type === 'income' ? 'rgba(16, 185, 129, 0.15)' : 'rgba(244, 63, 94, 0.15)', color: tx.type === 'income' ? '#10B981' : '#F43F5E', width: 36, height: 36 }}>
                    {tx.type === 'income' ? <ArrowDownwardIcon sx={{ fontSize: 18 }} /> : <ArrowUpwardIcon sx={{ fontSize: 18 }} />}
                  </Avatar>
                  <Box>
                    <Typography variant="body2" sx={{ fontWeight: 700, color: '#FFF' }}>{tx.title}</Typography>
                    <Typography variant="caption" color="text.secondary">{tx.merchant} • {tx.date}</Typography>
                  </Box>
                </Box>

                <Box sx={{ textAlign: 'right' }}>
                  <Typography variant="subtitle2" sx={{ fontWeight: 800, color: tx.type === 'income' ? '#10B981' : '#F43F5E' }}>
                    {tx.type === 'income' ? '+' : '-'}₹{tx.amount.toLocaleString()}
                  </Typography>
                  <Chip label={tx.cleared ? 'Cleared' : 'Pending'} size="small" color={tx.cleared ? 'success' : 'warning'} sx={{ height: 18, fontSize: 9, fontWeight: 700 }} />
                </Box>
              </Box>
            ))}
          </Box>
        </CardContent>
      </Card>

    </Box>
  );
};
