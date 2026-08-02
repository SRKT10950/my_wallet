export interface Product {
  id?: number;
  userId?: string;
  productName: string;
  localName?: string;
  category: string;
  referenceLink?: string;
  appName?: string;
  priceDate?: string;
  currentPrice: number;
  oldPrice?: number;
  unit: string;
  quantity: number;
  barcode?: string;
  qrCode?: string;
  imageUrl?: string;
  description?: string; // Strictly lowercase DB column 'description'
  active: boolean;
  deleted?: boolean;
}

export interface Transaction {
  id: number;
  title: string;
  amount: number;
  category: string;
  type: 'expense' | 'income';
  date: string;
  account: string;
  merchantName?: string;
}

export interface Category {
  id: number;
  name: string;
  icon: string;
  color: string;
  budget: number;
}

export interface Account {
  id: number;
  name: string;
  type: string;
  balance: number;
  currency: string;
  color: string;
}

export interface LendBorrow {
  id: number;
  name: string;
  type: 'Lend' | 'Borrow';
  amount: number;
  date: string;
  dueDate: string;
  settled: number;
  notes: string;
}

export interface SplitBill {
  id: number;
  title: string;
  totalAmount: number;
  paidBy: string;
  participants: string[];
  date: string;
  settled: boolean;
}

export interface FuelLog {
  id: number;
  date: string;
  odometer: number;
  litres: number;
  pricePerLitre: number;
  totalCost: number;
  station: string;
  mileage?: number;
}

export interface Asset {
  id: number;
  name: string;
  type: 'Mutual Fund' | 'Stock' | 'Gold' | 'Fixed Deposit' | 'Real Estate';
  investedAmount: number;
  currentValue: number;
  purchaseDate: string;
}

export interface ScheduledPayment {
  id: number;
  title: string;
  amount: number;
  category: string;
  dueDate: string;
  frequency: 'Monthly' | 'Quarterly' | 'Yearly';
  autoPay: boolean;
}

export interface ParsedSms {
  merchant: string;
  amount: number;
  type: 'expense' | 'income';
  account: string;
  date: string;
  rawText: string;
}
