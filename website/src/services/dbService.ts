import { Product, Transaction, LendBorrow, SplitBill, FuelLog, Asset, ScheduledPayment } from '../types';

const INITIAL_PRODUCTS: Product[] = [];

const INITIAL_TRANSACTIONS: Transaction[] = [
  { id: 101, title: 'Monthly Salary Credit', amount: 85000, category: 'Salary', type: 'income', date: '2026-07-01', account: 'Main Bank' },
  { id: 102, title: 'Grocery Shopping at Supermarket', amount: 3450, category: 'Groceries', type: 'expense', date: '2026-07-15', account: 'Cash', merchantName: 'Blinkit' },
  { id: 103, title: 'Electricity Bill Payment', amount: 2200, category: 'Utilities', type: 'expense', date: '2026-07-20', account: 'Main Bank' }
];

const INITIAL_LEND_BORROW: LendBorrow[] = [
  { id: 201, name: 'Amit Kumar', type: 'Lend', amount: 5000, date: '2026-07-10', dueDate: '2026-08-10', settled: 2000, notes: 'Emergency medical support' },
  { id: 202, name: 'HDFC Personal Credit', type: 'Borrow', amount: 15000, date: '2026-07-05', dueDate: '2026-08-05', settled: 5000, notes: 'Short term loan' }
];

const INITIAL_SPLIT_BILLS: SplitBill[] = [
  { id: 301, title: 'Weekend Dinner & Drinks', totalAmount: 4800, paidBy: 'You', participants: ['Rahul', 'Priya', 'Amit', 'You'], date: '2026-07-26', settled: false }
];

const INITIAL_FUEL_LOGS: FuelLog[] = [
  { id: 401, date: '2026-07-10', odometer: 12450, litres: 35, pricePerLitre: 96.5, totalCost: 3377.5, station: 'Indian Oil', mileage: 14.8 },
  { id: 402, date: '2026-07-22', odometer: 12970, litres: 34, pricePerLitre: 96.5, totalCost: 3281.0, station: 'HP Petrol Pump', mileage: 15.3 }
];

const INITIAL_ASSETS: Asset[] = [
  { id: 501, name: 'Nifty 50 Index Mutual Fund', type: 'Mutual Fund', investedAmount: 150000, currentValue: 184500, purchaseDate: '2025-01-15' },
  { id: 502, name: 'Sovereign Gold Bond (SGB)', type: 'Gold', investedAmount: 50000, currentValue: 62000, purchaseDate: '2025-03-10' },
  { id: 503, name: 'HDFC Bank Fixed Deposit', type: 'Fixed Deposit', investedAmount: 100000, currentValue: 107500, purchaseDate: '2025-08-01' }
];

const INITIAL_SCHEDULED: ScheduledPayment[] = [
  { id: 601, title: 'House Rent', amount: 18000, category: 'Housing', dueDate: '2026-08-05', frequency: 'Monthly', autoPay: true },
  { id: 602, title: 'Broadband Internet Bill', amount: 999, category: 'Utilities', dueDate: '2026-08-10', frequency: 'Monthly', autoPay: true }
];

export class DBService {
  private static KEY_PRODUCTS = 'mw2_wallet_products';
  private static KEY_TRANSACTIONS = 'mw2_wallet_transactions';
  private static KEY_LEND_BORROW = 'mw2_wallet_lend_borrow';
  private static KEY_SPLIT_BILLS = 'mw2_wallet_split_bills';
  private static KEY_FUEL_LOGS = 'mw2_wallet_fuel_logs';
  private static KEY_ASSETS = 'mw2_wallet_assets';
  private static KEY_SCHEDULED = 'mw2_wallet_scheduled';

  /* Products */
  static getProducts(): Product[] {
    const raw = localStorage.getItem(this.KEY_PRODUCTS);
    if (!raw) {
      localStorage.setItem(this.KEY_PRODUCTS, JSON.stringify(INITIAL_PRODUCTS));
      return INITIAL_PRODUCTS;
    }
    try { return JSON.parse(raw); } catch { return INITIAL_PRODUCTS; }
  }

  static addProduct(product: Product): Product {
    const products = this.getProducts();
    const newId = product.id || Date.now();
    const newProduct: Product = { ...product, id: newId, description: product.description || '' };
    const updated = [newProduct, ...products.filter(p => p.id !== newId)];
    localStorage.setItem(this.KEY_PRODUCTS, JSON.stringify(updated));
    return newProduct;
  }

  static updateProduct(product: Product): void {
    const products = this.getProducts();
    const idx = products.findIndex(p => p.id === product.id);
    if (idx !== -1) {
      products[idx] = { ...product };
      localStorage.setItem(this.KEY_PRODUCTS, JSON.stringify(products));
    }
  }

  static deleteProduct(id: number): void {
    const updated = this.getProducts().filter(p => p.id !== id);
    localStorage.setItem(this.KEY_PRODUCTS, JSON.stringify(updated));
  }

  static deleteAllProducts(): void {
    localStorage.setItem(this.KEY_PRODUCTS, JSON.stringify([]));
  }

  /* Transactions */
  static getTransactions(): Transaction[] {
    const raw = localStorage.getItem(this.KEY_TRANSACTIONS);
    if (!raw) {
      localStorage.setItem(this.KEY_TRANSACTIONS, JSON.stringify(INITIAL_TRANSACTIONS));
      return INITIAL_TRANSACTIONS;
    }
    try { return JSON.parse(raw); } catch { return INITIAL_TRANSACTIONS; }
  }

  static addTransaction(tx: Transaction): Transaction {
    const items = this.getTransactions();
    const newTx = { ...tx, id: tx.id || Date.now() };
    const updated = [newTx, ...items];
    localStorage.setItem(this.KEY_TRANSACTIONS, JSON.stringify(updated));
    return newTx;
  }

  static deleteTransaction(id: number): void {
    const updated = this.getTransactions().filter(t => t.id !== id);
    localStorage.setItem(this.KEY_TRANSACTIONS, JSON.stringify(updated));
  }

  /* Lend & Borrow */
  static getLendBorrow(): LendBorrow[] {
    const raw = localStorage.getItem(this.KEY_LEND_BORROW);
    if (!raw) {
      localStorage.setItem(this.KEY_LEND_BORROW, JSON.stringify(INITIAL_LEND_BORROW));
      return INITIAL_LEND_BORROW;
    }
    try { return JSON.parse(raw); } catch { return INITIAL_LEND_BORROW; }
  }

  static addLendBorrow(item: LendBorrow): LendBorrow {
    const items = this.getLendBorrow();
    const newItem = { ...item, id: item.id || Date.now() };
    const updated = [newItem, ...items];
    localStorage.setItem(this.KEY_LEND_BORROW, JSON.stringify(updated));
    return newItem;
  }

  static updateLendBorrowSettled(id: number, addAmount: number): void {
    const items = this.getLendBorrow();
    const idx = items.findIndex(i => i.id === id);
    if (idx !== -1) {
      items[idx].settled = Math.min(items[idx].amount, items[idx].settled + addAmount);
      localStorage.setItem(this.KEY_LEND_BORROW, JSON.stringify(items));
    }
  }

  /* Split Bills */
  static getSplitBills(): SplitBill[] {
    const raw = localStorage.getItem(this.KEY_SPLIT_BILLS);
    if (!raw) {
      localStorage.setItem(this.KEY_SPLIT_BILLS, JSON.stringify(INITIAL_SPLIT_BILLS));
      return INITIAL_SPLIT_BILLS;
    }
    try { return JSON.parse(raw); } catch { return INITIAL_SPLIT_BILLS; }
  }

  static addSplitBill(bill: SplitBill): SplitBill {
    const bills = this.getSplitBills();
    const newBill = { ...bill, id: bill.id || Date.now() };
    const updated = [newBill, ...bills];
    localStorage.setItem(this.KEY_SPLIT_BILLS, JSON.stringify(updated));
    return newBill;
  }

  static toggleSplitBillSettled(id: number): void {
    const bills = this.getSplitBills();
    const idx = bills.findIndex(b => b.id === id);
    if (idx !== -1) {
      bills[idx].settled = !bills[idx].settled;
      localStorage.setItem(this.KEY_SPLIT_BILLS, JSON.stringify(bills));
    }
  }

  /* Fuel Logs */
  static getFuelLogs(): FuelLog[] {
    const raw = localStorage.getItem(this.KEY_FUEL_LOGS);
    if (!raw) {
      localStorage.setItem(this.KEY_FUEL_LOGS, JSON.stringify(INITIAL_FUEL_LOGS));
      return INITIAL_FUEL_LOGS;
    }
    try { return JSON.parse(raw); } catch { return INITIAL_FUEL_LOGS; }
  }

  static addFuelLog(log: FuelLog): FuelLog {
    const logs = this.getFuelLogs();
    const prevLog = logs.length > 0 ? logs[0] : null;
    let computedMileage = log.mileage || 14.5;
    if (prevLog && log.odometer > prevLog.odometer && log.litres > 0) {
      computedMileage = parseFloat(((log.odometer - prevLog.odometer) / log.litres).toFixed(1));
    }
    const newLog = { ...log, id: log.id || Date.now(), mileage: computedMileage };
    const updated = [newLog, ...logs];
    localStorage.setItem(this.KEY_FUEL_LOGS, JSON.stringify(updated));
    return newLog;
  }

  /* Assets */
  static getAssets(): Asset[] {
    const raw = localStorage.getItem(this.KEY_ASSETS);
    if (!raw) {
      localStorage.setItem(this.KEY_ASSETS, JSON.stringify(INITIAL_ASSETS));
      return INITIAL_ASSETS;
    }
    try { return JSON.parse(raw); } catch { return INITIAL_ASSETS; }
  }

  static addAsset(asset: Asset): Asset {
    const items = this.getAssets();
    const newAsset = { ...asset, id: asset.id || Date.now() };
    const updated = [newAsset, ...items];
    localStorage.setItem(this.KEY_ASSETS, JSON.stringify(updated));
    return newAsset;
  }

  /* Scheduled Payments */
  static getScheduledPayments(): ScheduledPayment[] {
    const raw = localStorage.getItem(this.KEY_SCHEDULED);
    if (!raw) {
      localStorage.setItem(this.KEY_SCHEDULED, JSON.stringify(INITIAL_SCHEDULED));
      return INITIAL_SCHEDULED;
    }
    try { return JSON.parse(raw); } catch { return INITIAL_SCHEDULED; }
  }

  static addScheduledPayment(sp: ScheduledPayment): ScheduledPayment {
    const items = this.getScheduledPayments();
    const newSp = { ...sp, id: sp.id || Date.now() };
    const updated = [newSp, ...items];
    localStorage.setItem(this.KEY_SCHEDULED, JSON.stringify(updated));
    return newSp;
  }

  /* Database Export & Import */
  static exportFullDatabaseJSON(): string {
    const backup = {
      version: '2.0.0',
      exportedAt: new Date().toISOString(),
      wallet_products: this.getProducts(),
      transactions: this.getTransactions(),
      lend_borrow: this.getLendBorrow(),
      split_bills: this.getSplitBills(),
      fuel_logs: this.getFuelLogs(),
      assets: this.getAssets(),
      scheduled_payments: this.getScheduledPayments()
    };
    return JSON.stringify(backup, null, 2);
  }

  static importFullDatabaseJSON(jsonStr: string): boolean {
    try {
      const data = JSON.parse(jsonStr);
      if (Array.isArray(data.wallet_products)) localStorage.setItem(this.KEY_PRODUCTS, JSON.stringify(data.wallet_products));
      if (Array.isArray(data.transactions)) localStorage.setItem(this.KEY_TRANSACTIONS, JSON.stringify(data.transactions));
      if (Array.isArray(data.lend_borrow)) localStorage.setItem(this.KEY_LEND_BORROW, JSON.stringify(data.lend_borrow));
      if (Array.isArray(data.split_bills)) localStorage.setItem(this.KEY_SPLIT_BILLS, JSON.stringify(data.split_bills));
      if (Array.isArray(data.fuel_logs)) localStorage.setItem(this.KEY_FUEL_LOGS, JSON.stringify(data.fuel_logs));
      if (Array.isArray(data.assets)) localStorage.setItem(this.KEY_ASSETS, JSON.stringify(data.assets));
      if (Array.isArray(data.scheduled_payments)) localStorage.setItem(this.KEY_SCHEDULED, JSON.stringify(data.scheduled_payments));
      return true;
    } catch {
      return false;
    }
  }
}
