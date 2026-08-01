import React from 'react';
import { AppBar, Toolbar, Box, Typography, Button, Tabs, Tab, Chip, Avatar } from '@mui/material';
import AccountBalanceWalletIcon from '@mui/icons-material/AccountBalanceWallet';
import ShoppingBagIcon from '@mui/icons-material/ShoppingBag';
import PieChartIcon from '@mui/icons-material/PieChart';
import PeopleIcon from '@mui/icons-material/People';
import GetAppIcon from '@mui/icons-material/GetApp';
import SmartphoneIcon from '@mui/icons-material/Smartphone';
import PhotoCameraIcon from '@mui/icons-material/PhotoCamera';
import HandshakeIcon from '@mui/icons-material/Handshake';
import LocalGasStationIcon from '@mui/icons-material/LocalGasStation';
import CalculateIcon from '@mui/icons-material/Calculate';
import ShowChartIcon from '@mui/icons-material/ShowChart';
import EventRepeatIcon from '@mui/icons-material/EventRepeat';
import StorageIcon from '@mui/icons-material/Storage';
import TrackChangesIcon from '@mui/icons-material/TrackChanges';
import CurrencyExchangeIcon from '@mui/icons-material/CurrencyExchange';
import PaletteIcon from '@mui/icons-material/Palette';
import MonitorHeartIcon from '@mui/icons-material/MonitorHeart';

interface NavbarProps {
  activeTab: string;
  setActiveTab: (tab: string) => void;
  onInstallPwa: () => void;
  canInstallPwa: boolean;
}

export const Navbar: React.FC<NavbarProps> = ({ activeTab, setActiveTab, onInstallPwa, canInstallPwa }) => {
  const tabs = [
    { id: 'dashboard', label: 'Dashboard', icon: PieChartIcon },
    { id: 'products', label: 'Product Master', icon: ShoppingBagIcon },
    { id: 'expenses', label: 'Expenses', icon: AccountBalanceWalletIcon },
    { id: 'budget', label: 'AI Budget', icon: TrackChangesIcon },
    { id: 'currency', label: 'Currency FX', icon: CurrencyExchangeIcon },
    { id: 'smsparser', label: 'SMS Parser', icon: SmartphoneIcon },
    { id: 'receipts', label: 'Receipt Scanner', icon: PhotoCameraIcon },
    { id: 'splitwise', label: 'Splitwise', icon: PeopleIcon },
    { id: 'lendborrow', label: 'Lend & Borrow', icon: HandshakeIcon },
    { id: 'fuel', label: 'Fuel Log', icon: LocalGasStationIcon },
    { id: 'assets', label: 'Assets', icon: ShowChartIcon },
    { id: 'health', label: 'Health Score', icon: MonitorHeartIcon },
    { id: 'theme', label: 'Theme', icon: PaletteIcon },
    { id: 'calculators', label: 'Calculators', icon: CalculateIcon },
    { id: 'sync', label: 'Sync & Backup', icon: StorageIcon }
  ];

  return (
    <AppBar position="static" color="transparent" elevation={0} sx={{ marginBottom: 3, borderBottom: '1px solid rgba(0, 245, 212, 0.2)' }}>
      <Toolbar sx={{ justifyContent: 'space-between', flexWrap: 'wrap', gap: 2, paddingY: 1 }}>
        
        {/* Brand Logo */}
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5, cursor: 'pointer' }} onClick={() => setActiveTab('dashboard')}>
          <Avatar sx={{ bgcolor: 'primary.main', width: 44, height: 44, boxShadow: '0 0 15px rgba(0, 245, 212, 0.5)' }}>
            <AccountBalanceWalletIcon sx={{ color: '#000' }} />
          </Avatar>
          <Box>
            <Typography variant="h6" sx={{ fontWeight: 800, background: 'linear-gradient(90deg, #FFFFFF 0%, #00F5D4 100%)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }}>
              My Wallet <Chip label="v2.0 MUI" size="small" color="primary" sx={{ fontWeight: 800, height: 20, fontSize: 10, ml: 1 }} />
            </Typography>
            <Typography variant="caption" color="text.secondary">
              Material UI Cyber Platform
            </Typography>
          </Box>
        </Box>

        {/* Navigation Tabs */}
        <Tabs
          value={activeTab}
          onChange={(_, val) => setActiveTab(val)}
          variant="scrollable"
          scrollButtons="auto"
          textColor="primary"
          indicatorColor="primary"
          sx={{
            background: 'rgba(22, 25, 46, 0.6)',
            borderRadius: 3,
            border: '1px solid rgba(255, 255, 255, 0.08)',
            '& .MuiTab-root': {
              minHeight: 44,
              fontSize: '0.8rem',
              fontWeight: 700,
              textTransform: 'none',
              borderRadius: 2,
              margin: '2px 4px'
            }
          }}
        >
          {tabs.map(t => {
            const Icon = t.icon;
            return (
              <Tab
                key={t.id}
                value={t.id}
                label={t.label}
                icon={<Icon sx={{ fontSize: 18 }} />}
                iconPosition="start"
              />
            );
          })}
        </Tabs>

        {/* Action Controls */}
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          {canInstallPwa && (
            <Button variant="contained" color="primary" startIcon={<GetAppIcon />} onClick={onInstallPwa} sx={{ fontSize: '0.8rem' }}>
              Install PWA
            </Button>
          )}
        </Box>

      </Toolbar>
    </AppBar>
  );
};
