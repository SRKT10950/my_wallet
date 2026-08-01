-- Manual database schema setup for mWallet Application.
-- Includes multi-device conflict prevention (updated_at, deleted, last_updated_by)

-- 1. Users Table
CREATE TABLE IF NOT EXISTS users (
    mobile_number VARCHAR(20) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    pin VARCHAR(256) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at BIGINT DEFAULT 0,
    last_updated_by VARCHAR(100)
);

-- 2. Categories Table
CREATE TABLE IF NOT EXISTS categories (
    id VARCHAR(50) NOT NULL,
    user_id VARCHAR(20) NOT NULL,
    name VARCHAR(100) NOT NULL,
    "plannedAmount" DOUBLE PRECISION NOT NULL,
    deleted INTEGER DEFAULT 0,
    updated_at BIGINT DEFAULT 0,
    last_updated_by VARCHAR(100),
    PRIMARY KEY (user_id, id),
    FOREIGN KEY (user_id) REFERENCES users(mobile_number) ON DELETE CASCADE
);

-- 3. Transactions Table
CREATE TABLE IF NOT EXISTS transactions (
    id VARCHAR(50) NOT NULL,
    user_id VARCHAR(20) NOT NULL,
    "categoryId" VARCHAR(50) NOT NULL,
    "itemService" TEXT NOT NULL,
    cost DOUBLE PRECISION NOT NULL,
    "paidAmount" DOUBLE PRECISION NOT NULL,
    cleared INTEGER NOT NULL,
    date VARCHAR(50) NOT NULL,
    "merchantName" TEXT,
    deleted INTEGER DEFAULT 0,
    updated_at BIGINT DEFAULT 0,
    last_updated_by VARCHAR(100),
    PRIMARY KEY (user_id, id),
    FOREIGN KEY (user_id) REFERENCES users(mobile_number) ON DELETE CASCADE
);

-- 4. Loans Table
CREATE TABLE IF NOT EXISTS loans (
    id VARCHAR(50) NOT NULL,
    user_id VARCHAR(20) NOT NULL,
    lender VARCHAR(100) NOT NULL,
    "startDate" VARCHAR(50) NOT NULL,
    "endDate" VARCHAR(50) NOT NULL,
    tenure INTEGER NOT NULL,
    roi DOUBLE PRECISION NOT NULL,
    principal DOUBLE PRECISION NOT NULL,
    interest DOUBLE PRECISION NOT NULL,
    total DOUBLE PRECISION NOT NULL,
    paid DOUBLE PRECISION NOT NULL,
    balance DOUBLE PRECISION NOT NULL,
    emi DOUBLE PRECISION NOT NULL,
    "tenurePending" INTEGER NOT NULL,
    status VARCHAR(20) NOT NULL,
    deleted INTEGER DEFAULT 0,
    updated_at BIGINT DEFAULT 0,
    last_updated_by VARCHAR(100),
    PRIMARY KEY (user_id, id),
    FOREIGN KEY (user_id) REFERENCES users(mobile_number) ON DELETE CASCADE
);

-- 5. Income Configs Table
CREATE TABLE IF NOT EXISTS income_configs (
    id VARCHAR(50) NOT NULL,
    user_id VARCHAR(20) NOT NULL,
    month INTEGER NOT NULL,
    year INTEGER NOT NULL,
    amount DOUBLE PRECISION NOT NULL,
    "isDefault" INTEGER NOT NULL,
    deleted INTEGER DEFAULT 0,
    updated_at BIGINT DEFAULT 0,
    last_updated_by VARCHAR(100),
    PRIMARY KEY (user_id, id),
    FOREIGN KEY (user_id) REFERENCES users(mobile_number) ON DELETE CASCADE
);

-- 6. Lend Borrows Table
CREATE TABLE IF NOT EXISTS lend_borrows (
    id VARCHAR(50) NOT NULL,
    user_id VARCHAR(20) NOT NULL,
    name VARCHAR(100) NOT NULL,
    type VARCHAR(20) NOT NULL,
    date VARCHAR(50) NOT NULL,
    tenure INTEGER NOT NULL,
    principal DOUBLE PRECISION NOT NULL,
    "returnDate" VARCHAR(50),
    settled DOUBLE PRECISION,
    diff DOUBLE PRECISION,
    status VARCHAR(20) NOT NULL,
    deleted INTEGER DEFAULT 0,
    updated_at BIGINT DEFAULT 0,
    last_updated_by VARCHAR(100),
    PRIMARY KEY (user_id, id),
    FOREIGN KEY (user_id) REFERENCES users(mobile_number) ON DELETE CASCADE
);

-- 7. Repayments Table
CREATE TABLE IF NOT EXISTS repayments (
    id VARCHAR(50) NOT NULL,
    user_id VARCHAR(20) NOT NULL,
    "lendBorrowId" VARCHAR(50) NOT NULL,
    name VARCHAR(100) NOT NULL,
    "paymentDate" VARCHAR(50) NOT NULL,
    amount DOUBLE PRECISION NOT NULL,
    method VARCHAR(50) NOT NULL,
    deleted INTEGER DEFAULT 0,
    updated_at BIGINT DEFAULT 0,
    last_updated_by VARCHAR(100),
    PRIMARY KEY (user_id, id),
    FOREIGN KEY (user_id) REFERENCES users(mobile_number) ON DELETE CASCADE
);

-- 8. Investments Table
CREATE TABLE IF NOT EXISTS investments (
    id VARCHAR(50) NOT NULL,
    user_id VARCHAR(20) NOT NULL,
    name VARCHAR(100) NOT NULL,
    type VARCHAR(20) NOT NULL,
    amount DOUBLE PRECISION NOT NULL,
    "expectedRoi" DOUBLE PRECISION NOT NULL,
    "tenureMonths" INTEGER NOT NULL,
    "startDate" VARCHAR(50) NOT NULL,
    deleted INTEGER DEFAULT 0,
    updated_at BIGINT DEFAULT 0,
    last_updated_by VARCHAR(100),
    PRIMARY KEY (user_id, id),
    FOREIGN KEY (user_id) REFERENCES users(mobile_number) ON DELETE CASCADE
);

-- 9. Category Budgets Table
CREATE TABLE IF NOT EXISTS category_budgets (
    id VARCHAR(50) NOT NULL,
    user_id VARCHAR(20) NOT NULL,
    "categoryId" VARCHAR(50) NOT NULL,
    month INTEGER NOT NULL,
    year INTEGER NOT NULL,
    amount DOUBLE PRECISION NOT NULL,
    deleted INTEGER DEFAULT 0,
    updated_at BIGINT DEFAULT 0,
    last_updated_by VARCHAR(100),
    PRIMARY KEY (user_id, "categoryId", month, year),
    FOREIGN KEY (user_id) REFERENCES users(mobile_number) ON DELETE CASCADE
);

-- 10. OD Accounts Table
CREATE TABLE IF NOT EXISTS od_accounts (
    id VARCHAR(50) NOT NULL,
    user_id VARCHAR(20) NOT NULL,
    name VARCHAR(100) NOT NULL,
    "limit" DOUBLE PRECISION NOT NULL,
    "interestRate" DOUBLE PRECISION NOT NULL,
    "billingDay" INTEGER NOT NULL,
    deleted INTEGER DEFAULT 0,
    updated_at BIGINT DEFAULT 0,
    last_updated_by VARCHAR(100),
    PRIMARY KEY (user_id, id),
    FOREIGN KEY (user_id) REFERENCES users(mobile_number) ON DELETE CASCADE
);

-- 11. OD Transactions Table
CREATE TABLE IF NOT EXISTS od_transactions (
    id VARCHAR(50) NOT NULL,
    user_id VARCHAR(20) NOT NULL,
    "odAccountId" VARCHAR(50) NOT NULL,
    amount DOUBLE PRECISION NOT NULL,
    type VARCHAR(20) NOT NULL,
    date VARCHAR(50) NOT NULL,
    deleted INTEGER DEFAULT 0,
    updated_at BIGINT DEFAULT 0,
    last_updated_by VARCHAR(100),
    PRIMARY KEY (user_id, id),
    FOREIGN KEY (user_id) REFERENCES users(mobile_number) ON DELETE CASCADE
);

-- 12. Fuel Logs Table
CREATE TABLE IF NOT EXISTS fuel_logs (
    id VARCHAR(50) NOT NULL,
    user_id VARCHAR(20) NOT NULL,
    date VARCHAR(50) NOT NULL,
    odometer DOUBLE PRECISION NOT NULL,
    "fuelAmount" DOUBLE PRECISION NOT NULL,
    "pricePerUnit" DOUBLE PRECISION NOT NULL,
    "totalCost" DOUBLE PRECISION NOT NULL,
    "isFullTank" INTEGER NOT NULL,
    notes TEXT NOT NULL,
    deleted INTEGER DEFAULT 0,
    updated_at BIGINT DEFAULT 0,
    last_updated_by VARCHAR(100),
    PRIMARY KEY (user_id, id),
    FOREIGN KEY (user_id) REFERENCES users(mobile_number) ON DELETE CASCADE
);

-- 13. Vehicle Configs Table
CREATE TABLE IF NOT EXISTS vehicle_configs (
    id VARCHAR(50) NOT NULL,
    user_id VARCHAR(20) NOT NULL,
    "initialOdometer" DOUBLE PRECISION NOT NULL,
    "currentOdometer" DOUBLE PRECISION NOT NULL,
    "vehicleName" VARCHAR(100) NOT NULL,
    "lastSyncTime" VARCHAR(50) NOT NULL,
    "autoStartOnBoot" INTEGER NOT NULL DEFAULT 1,
    deleted INTEGER DEFAULT 0,
    updated_at BIGINT DEFAULT 0,
    last_updated_by VARCHAR(100),
    PRIMARY KEY (user_id, id),
    FOREIGN KEY (user_id) REFERENCES users(mobile_number) ON DELETE CASCADE
);

-- 14. Car Trips Table
CREATE TABLE IF NOT EXISTS car_trips (
    id VARCHAR(50) NOT NULL,
    user_id VARCHAR(20) NOT NULL,
    date VARCHAR(50) NOT NULL,
    "distanceTravelled" DOUBLE PRECISION NOT NULL,
    "startOdometer" DOUBLE PRECISION NOT NULL,
    "endOdometer" DOUBLE PRECISION NOT NULL,
    "gpsPath" TEXT NOT NULL,
    "durationSeconds" INTEGER NOT NULL,
    status VARCHAR(20) NOT NULL,
    deleted INTEGER DEFAULT 0,
    updated_at BIGINT DEFAULT 0,
    last_updated_by VARCHAR(100),
    PRIMARY KEY (user_id, id),
    FOREIGN KEY (user_id) REFERENCES users(mobile_number) ON DELETE CASCADE
);

-- 15. Wallet Contacts Table
CREATE TABLE IF NOT EXISTS wallet_contacts (
    id VARCHAR(50) NOT NULL,
    user_id VARCHAR(20) NOT NULL,
    name VARCHAR(150) NOT NULL,
    mobile VARCHAR(20),
    place VARCHAR(150),
    occupation VARCHAR(150),
    "businessName" VARCHAR(150),
    "transactionNotification" INTEGER DEFAULT 1,
    "notificationMethod" VARCHAR(20) DEFAULT 'WhatsApp',
    active INTEGER NOT NULL DEFAULT 1,
    deleted INTEGER DEFAULT 0,
    updated_at BIGINT DEFAULT 0,
    last_updated_by VARCHAR(100),
    PRIMARY KEY (user_id, id),
    FOREIGN KEY (user_id) REFERENCES users(mobile_number) ON DELETE CASCADE
);

-- 16. Wallet Products Master Table
CREATE TABLE IF NOT EXISTS wallet_products (
    id VARCHAR(50) NOT NULL,
    user_id VARCHAR(20) NOT NULL,
    "productName" VARCHAR(200) NOT NULL,
    "localName" VARCHAR(200),
    category VARCHAR(100) DEFAULT 'General',
    "referenceLink" TEXT,
    "appName" VARCHAR(100),
    "priceDate" VARCHAR(50),
    "currentPrice" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "oldPrice" DOUBLE PRECISION NOT NULL DEFAULT 0,
    unit VARCHAR(50) DEFAULT 'Pcs',
    quantity DOUBLE PRECISION NOT NULL DEFAULT 1,
    "description" TEXT DEFAULT '',
    active INTEGER NOT NULL DEFAULT 1,
    deleted INTEGER DEFAULT 0,
    updated_at BIGINT DEFAULT 0,
    last_updated_by VARCHAR(100),
    PRIMARY KEY (user_id, id),
    FOREIGN KEY (user_id) REFERENCES users(mobile_number) ON DELETE CASCADE
);
