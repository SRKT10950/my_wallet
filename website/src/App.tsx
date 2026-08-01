import React, { useState, useEffect } from 'react';
import { Navbar } from './components/Navbar';
import { Dashboard } from './components/Dashboard';
import { ProductMaster } from './components/ProductMaster';
import { ExpenseTracker } from './components/ExpenseTracker';
import { BudgetAnalytics } from './components/BudgetAnalytics';
import { CurrencyConverter } from './components/CurrencyConverter';
import { SmsParser } from './components/SmsParser';
import { ReceiptScanner } from './components/ReceiptScanner';
import { Splitwise } from './components/Splitwise';
import { LendBorrowTracker } from './components/LendBorrowTracker';
import { FuelTracker } from './components/FuelTracker';
import { AssetPortfolio } from './components/AssetPortfolio';
import { ScheduledPayments } from './components/ScheduledPayments';
import { HealthScore } from './components/HealthScore';
import { ThemeCustomizer } from './components/ThemeCustomizer';
import { Calculators } from './components/Calculators';
import { DataBackupSync } from './components/DataBackupSync';

import { GoogleWebSearchModal } from './components/GoogleWebSearchModal';
import { AddProductModal } from './components/AddProductModal';
import { PwaInstallBanner } from './components/PwaInstallBanner';
import { DBService } from './services/dbService';
import { Product, Transaction, LendBorrow, SplitBill, FuelLog, Asset, ScheduledPayment } from './types';
import { CheckCircle2 } from 'lucide-react';

export const App: React.FC = () => {
  const [activeTab, setActiveTab] = useState('dashboard');

  // DB Data States
  const [products, setProducts] = useState<Product[]>([]);
  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [lendBorrows, setLendBorrows] = useState<LendBorrow[]>([]);
  const [splitBills, setSplitBills] = useState<SplitBill[]>([]);
  const [fuelLogs, setFuelLogs] = useState<FuelLog[]>([]);
  const [assets, setAssets] = useState<Asset[]>([]);
  const [scheduledList, setScheduledList] = useState<ScheduledPayment[]>([]);

  // Modals & UI States
  const [isWebSearchOpen, setIsWebSearchOpen] = useState(false);
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [initialSearchQuery, setInitialSearchQuery] = useState('');
  const [toastMessage, setToastMessage] = useState<string | null>(null);

  // PWA Prompt
  const [deferredPrompt, setDeferredPrompt] = useState<any>(null);
  const [showPwaBanner, setShowPwaBanner] = useState(false);

  const reloadAllData = () => {
    setProducts(DBService.getProducts());
    setTransactions(DBService.getTransactions());
    setLendBorrows(DBService.getLendBorrow());
    setSplitBills(DBService.getSplitBills());
    setFuelLogs(DBService.getFuelLogs());
    setAssets(DBService.getAssets());
    setScheduledList(DBService.getScheduledPayments());
  };

  useEffect(() => {
    reloadAllData();

    const handleBeforeInstallPrompt = (e: any) => {
      e.preventDefault();
      setDeferredPrompt(e);
      setShowPwaBanner(true);
    };

    window.addEventListener('beforeinstallprompt', handleBeforeInstallPrompt);
    return () => window.removeEventListener('beforeinstallprompt', handleBeforeInstallPrompt);
  }, []);

  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(null), 3500);
  };

  const handleInstallPwa = () => {
    if (deferredPrompt) {
      deferredPrompt.prompt();
      deferredPrompt.userChoice.then(() => {
        setDeferredPrompt(null);
        setShowPwaBanner(false);
      });
    } else {
      alert("To Install My Wallet 2.0:\n\n• On Chrome/Edge: Click Install icon in URL bar or Browser Menu (⋮) -> 'Install My Wallet 2.0'\n• On iOS Safari: Tap Share (↑) -> 'Add to Home Screen'");
    }
  };

  // Handlers
  const handleAddProduct = (newProd: Product) => {
    const saved = DBService.addProduct(newProd);
    setProducts(DBService.getProducts());
    setActiveTab('products');
    showToast(`✅ Successfully inserted "${saved.productName}" into database with all details!`);
  };

  const handleDeleteProduct = (id: number) => {
    DBService.deleteProduct(id);
    setProducts(DBService.getProducts());
    showToast('🗑️ Product deleted from database.');
  };

  const handleAddTransaction = (t: Transaction) => {
    DBService.addTransaction(t);
    setTransactions(DBService.getTransactions());
    showToast('💰 Transaction logged successfully.');
  };

  const handleDeleteTransaction = (id: number) => {
    DBService.deleteTransaction(id);
    setTransactions(DBService.getTransactions());
    showToast('🗑️ Transaction removed.');
  };

  const handleAddLendBorrow = (item: LendBorrow) => {
    DBService.addLendBorrow(item);
    setLendBorrows(DBService.getLendBorrow());
    showToast('🤝 Lend/Borrow record saved.');
  };

  const handleUpdateSettled = (id: number, amount: number) => {
    DBService.updateLendBorrowSettled(id, amount);
    setLendBorrows(DBService.getLendBorrow());
    showToast('✅ Repayment recorded.');
  };

  const handleAddSplitBill = (bill: SplitBill) => {
    DBService.addSplitBill(bill);
    setSplitBills(DBService.getSplitBills());
    showToast('👥 Shared split bill created.');
  };

  const handleToggleSplitBillSettled = (id: number) => {
    DBService.toggleSplitBillSettled(id);
    setSplitBills(DBService.getSplitBills());
  };

  const handleAddFuelLog = (log: FuelLog) => {
    DBService.addFuelLog(log);
    setFuelLogs(DBService.getFuelLogs());
    showToast('⛽ Fuel refill log saved & mileage calculated.');
  };

  const handleAddAsset = (asset: Asset) => {
    DBService.addAsset(asset);
    setAssets(DBService.getAssets());
    showToast('📈 Asset added to investment portfolio.');
  };

  const handleAddScheduledPayment = (sp: ScheduledPayment) => {
    DBService.addScheduledPayment(sp);
    setScheduledList(DBService.getScheduledPayments());
    showToast('📅 Scheduled payment reminder added.');
  };

  return (
    <div style={{ maxWidth: '1440px', margin: '0 auto', padding: '0 16px 40px 16px' }}>
      
      {/* Top Navbar */}
      <Navbar
        activeTab={activeTab}
        setActiveTab={setActiveTab}
        onInstallPwa={handleInstallPwa}
        canInstallPwa={!!deferredPrompt || true}
      />

      {/* Main Content Modules */}
      <main>
        {activeTab === 'dashboard' && (
          <Dashboard
            products={products}
            onOpenAddProduct={() => setIsAddModalOpen(true)}
            onOpenWebSearch={() => { setInitialSearchQuery(''); setIsWebSearchOpen(true); }}
            setActiveTab={setActiveTab}
          />
        )}

        {activeTab === 'products' && (
          <ProductMaster
            products={products}
            onAddProduct={handleAddProduct}
            onUpdateProduct={(p) => { DBService.updateProduct(p); setProducts(DBService.getProducts()); }}
            onDeleteProduct={handleDeleteProduct}
            onOpenWebSearch={(q) => { setInitialSearchQuery(q || ''); setIsWebSearchOpen(true); }}
          />
        )}

        {activeTab === 'expenses' && (
          <ExpenseTracker
            transactions={transactions}
            onAddTransaction={handleAddTransaction}
            onDeleteTransaction={handleDeleteTransaction}
          />
        )}

        {activeTab === 'budget' && (
          <BudgetAnalytics
            transactions={transactions}
          />
        )}

        {activeTab === 'currency' && (
          <CurrencyConverter />
        )}

        {activeTab === 'smsparser' && (
          <SmsParser
            onAddTransaction={handleAddTransaction}
          />
        )}

        {activeTab === 'receipts' && (
          <ReceiptScanner
            onAddTransaction={handleAddTransaction}
          />
        )}

        {activeTab === 'splitwise' && (
          <Splitwise
            splitBills={splitBills}
            onAddSplitBill={handleAddSplitBill}
            onToggleSettled={handleToggleSplitBillSettled}
          />
        )}

        {activeTab === 'lendborrow' && (
          <LendBorrowTracker
            items={lendBorrows}
            onAddLendBorrow={handleAddLendBorrow}
            onUpdateSettled={handleUpdateSettled}
          />
        )}

        {activeTab === 'fuel' && (
          <FuelTracker
            logs={fuelLogs}
            onAddFuelLog={handleAddFuelLog}
          />
        )}

        {activeTab === 'assets' && (
          <AssetPortfolio
            assets={assets}
            onAddAsset={handleAddAsset}
          />
        )}

        {activeTab === 'health' && (
          <HealthScore
            transactions={transactions}
            assets={assets}
            lendBorrows={lendBorrows}
          />
        )}

        {activeTab === 'theme' && (
          <ThemeCustomizer />
        )}

        {activeTab === 'calculators' && (
          <Calculators />
        )}

        {activeTab === 'sync' && (
          <DataBackupSync
            onReloadAllData={reloadAllData}
          />
        )}
      </main>

      {/* Modals & Banners */}
      <GoogleWebSearchModal
        isOpen={isWebSearchOpen}
        initialQuery={initialSearchQuery}
        onClose={() => setIsWebSearchOpen(false)}
        onSelectAndInsertProduct={(p) => { handleAddProduct(p); setIsWebSearchOpen(false); }}
      />

      <AddProductModal
        isOpen={isAddModalOpen}
        onClose={() => setIsAddModalOpen(false)}
        onAddProduct={handleAddProduct}
      />

      {showPwaBanner && (
        <PwaInstallBanner
          onInstall={handleInstallPwa}
          onClose={() => setShowPwaBanner(false)}
        />
      )}

      {/* Toast Feedback Notification */}
      {toastMessage && (
        <div style={{
          position: 'fixed',
          top: '24px',
          right: '24px',
          zIndex: 999999,
          background: 'linear-gradient(135deg, #00F5D4 0%, #00C4A7 100%)',
          color: '#000',
          fontWeight: '800',
          fontSize: '13px',
          padding: '12px 20px',
          borderRadius: '14px',
          boxShadow: '0 10px 30px rgba(0, 245, 212, 0.4)',
          display: 'flex',
          alignItems: 'center',
          gap: '8px'
        }}>
          <CheckCircle2 size={18} />
          {toastMessage}
        </div>
      )}

    </div>
  );
};
