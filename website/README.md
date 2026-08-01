# My Wallet Version 2.0 - Futuristic Personal Finance & Product Master PWA

A high-performance, secure, type-safe Progressive Web Application (PWA) built with **TypeScript**, **React 19**, **Vite 6**, and a **Cyber-Glassmorphism 2.0 Dark UI/UX** design system.

---

## 🌟 Key Features

- **🌐 Product Master & Google Web Search**: Search Google Web, Shopping, OpenFoodFacts, and online pharmacy catalogs (e.g. *Ocotic Ear Drops*, *Matar*, *Amul Butter*). Insert products directly into the database with full field values and strictly lowercase **`description`** database column.
- **💳 Expense & Income Tracker**: Categorized transactions, account management (*Cash*, *Main Bank*, *Credit Card*), and net monthly balance summary.
- **🤝 Splitwise & Group Expenses**: Equal split calculations per person with settlement status tracking.
- **💸 Lend/Borrow & Debt Tracker**: Record money lent vs borrowed with repayment logging.
- **⛽ Fuel Log & Vehicle Mileage**: Odometer tracking and real-time **Mileage (km/L)** computation.
- **🧮 Financial Calculators**: Interactive EMI Calculator, SIP Investment Return Calculator, and Loan Offer Comparison.
- **📱 Bank SMS Parser & 🧾 Receipt OCR Scanner**: Extract transaction details automatically from bank SMS texts and receipt images.
- **📈 Asset Portfolio & 📅 Scheduled Payments**: Track Mutual Funds, Gold, FDs, and recurring subscription bills.
- **📊 AI Budgeting & 💱 Multi-Currency FX Engine**: Monthly budget limits, progress bars, and live exchange rate conversion.
- **🏥 Financial Health Score & 🎨 Custom Themes**: 0–100 health score gauge, AI wealth recommendations, and neon accent color switcher.
- **⚡ 100% Offline PWA & Desktop Shortcuts**: Pre-cached Service Worker (`sw.js`) and OS launcher shortcuts (`manifest.json`).

---

## 🚀 Quick Start Guide

### 1. Install Dependencies
```bash
cd website
npm install
```

### 2. Run Local Development Server
```bash
npm run dev
```
Open [http://localhost:3000/](http://localhost:3000/) in your browser.

### 3. Build Release Package into `build/web2.0`
```bash
npm run build
```

---

## 🐳 Docker Deployment

```bash
cd website
docker build -t my-wallet-v2 .
docker run -d -p 80:80 my-wallet-v2
```

---

## 📁 Release Directory

The compiled release package is located at [build/web2.0](file:///d:/project/my_wallet%20web%20App/build/web2.0).
