// State Store
let appState = {
    user: null,
    categories: [],
    transactions: [],
    loans: [],
    lendBorrows: [],
    repayments: [],
    investments: [],
    categoryBudgets: [],
    fuelLogs: [],
    vehicleConfig: null
};

// Common Database Query API Client
async function dbQuery(sql, params = []) {
    try {
        const response = await fetch(CONFIG.apiGatewayUrl, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'x-api-key': CONFIG.apiKey,
                'x-app-name': 'web app'
            },
            body: JSON.stringify({
                query: sql,
                params: params
            })
        });

        if (!response.ok) {
            const errText = await response.text();
            throw new Error(`HTTP Error ${response.status}: ${errText}`);
        }

        const data = await response.json();
        if (!data.success) {
            throw new Error(data.error || 'Unknown query error');
        }
        return data.rows || [];
    } catch (err) {
        console.error('Database query failed:', err);
        showSyncStatus('Error', 'error');
        throw err;
    }
}

// UI Notification / Status helpers
function showSyncStatus(text, type = 'success') {
    const indicator = document.getElementById('sync-status');
    if (indicator) {
        indicator.textContent = `● ${text}`;
        indicator.className = `sync-indicator ${type}`;
    }
}

// Generate unique string ID for new records
function generateId() {
    return Date.now().toString() + Math.random().toString(36).substring(2, 7);
}

// Date helpers
function getTodayDateString() {
    return new Date().toISOString().split('T')[0];
}

// -------------------------------------------------------------
// Authentication flow
// -------------------------------------------------------------
const authContainer = document.getElementById('auth-container');
const appContainer = document.getElementById('app-container');
const mobileNav = document.getElementById('mobile-nav');

// Toggle between Login & Register forms
document.getElementById('go-to-register').addEventListener('click', (e) => {
    e.preventDefault();
    document.getElementById('login-form').classList.add('hidden');
    document.getElementById('register-form').classList.remove('hidden');
    document.getElementById('auth-subtitle').textContent = 'Create a new account';
    hideAuthMessage();
});

document.getElementById('go-to-login').addEventListener('click', (e) => {
    e.preventDefault();
    document.getElementById('register-form').classList.add('hidden');
    document.getElementById('login-form').classList.remove('hidden');
    document.getElementById('auth-subtitle').textContent = 'Premium Expense, Asset & Dues Manager';
    hideAuthMessage();
});

function showAuthMessage(text, type = 'error') {
    const msgBox = document.getElementById('auth-message');
    msgBox.textContent = text;
    msgBox.className = `message-box ${type}`;
    msgBox.classList.remove('hidden');
}

function hideAuthMessage() {
    document.getElementById('auth-message').classList.add('hidden');
}

// Form submissions
document.getElementById('login-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    hideAuthMessage();
    const mobile = document.getElementById('login-mobile').value.trim();
    const pin = document.getElementById('login-pin').value.trim();

    try {
        showSyncStatus('Authenticating...', 'pending');
        const rows = await dbQuery(
            'SELECT mobile_number, name FROM users WHERE mobile_number = $1 AND pin = $2',
            [mobile, pin]
        );

        if (rows.length === 0) {
            showAuthMessage('Invalid mobile number or PIN. Please try again.');
            showSyncStatus('Login Failed', 'error');
            return;
        }

        const user = { mobile_number: rows[0].mobile_number, name: rows[0].name };
        loginSuccess(user);
    } catch (err) {
        showAuthMessage('Connection error. Could not reach server.');
    }
});

document.getElementById('register-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    hideAuthMessage();
    const name = document.getElementById('register-name').value.trim();
    const mobile = document.getElementById('register-mobile').value.trim();
    const pin = document.getElementById('register-pin').value.trim();

    try {
        showSyncStatus('Checking details...', 'pending');
        const existing = await dbQuery(
            'SELECT 1 FROM users WHERE mobile_number = $1',
            [mobile]
        );

        if (existing.length > 0) {
            showAuthMessage('Mobile number is already registered.');
            showSyncStatus('Register Failed', 'error');
            return;
        }

        // Create user
        await dbQuery(
            'INSERT INTO users (mobile_number, name, pin) VALUES ($1, $2, $3)',
            [mobile, name, pin]
        );

        showAuthMessage('Registration successful! Logging you in...', 'success');
        setTimeout(() => {
            loginSuccess({ mobile_number: mobile, name: name });
        }, 1200);
    } catch (err) {
        showAuthMessage('Failed to register. Please try again.');
    }
});

function loginSuccess(user) {
    appState.user = user;
    localStorage.setItem('wallet_user', JSON.stringify(user));
    
    // UI Transitions
    authContainer.classList.add('hidden');
    appContainer.classList.remove('hidden');
    if (window.innerWidth <= 576) {
        mobileNav.classList.remove('hidden');
    }

    // Set header profile details
    document.getElementById('user-display-name').textContent = user.name;
    document.getElementById('user-display-mobile').textContent = user.mobile_number;

    // Load user data
    loadAllUserData();
}

// Logout
document.getElementById('logout-btn').addEventListener('click', () => {
    localStorage.removeItem('wallet_user');
    appState.user = null;
    appContainer.classList.add('hidden');
    mobileNav.classList.add('hidden');
    authContainer.classList.remove('hidden');
    document.getElementById('login-form').reset();
    document.getElementById('register-form').reset();
    hideAuthMessage();
});

// Auto login check
function checkAutoLogin() {
    const saved = localStorage.getItem('wallet_user');
    if (saved) {
        try {
            const user = JSON.parse(saved);
            loginSuccess(user);
        } catch (e) {
            localStorage.removeItem('wallet_user');
        }
    }
}

// -------------------------------------------------------------
// View Controller & Routing
// -------------------------------------------------------------
const tabPanels = document.querySelectorAll('.tab-panel');
const menuItems = document.querySelectorAll('.menu-item, .bottom-nav-item');
const pageTitle = document.getElementById('page-title');

menuItems.forEach(item => {
    item.addEventListener('click', (e) => {
        const tab = item.getAttribute('data-tab');
        if (tab) {
            switchTab(tab);
        }
    });
});

function switchTab(tabId) {
    // Update active class in menus
    menuItems.forEach(item => {
        if (item.getAttribute('data-tab') === tabId) {
            item.classList.add('active');
        } else {
            item.classList.remove('active');
        }
    });

    // Toggle panels
    tabPanels.forEach(panel => {
        if (panel.id === `panel-${tabId}`) {
            panel.classList.add('active');
        } else {
            panel.classList.remove('active');
        }
    });

    // Update Header title
    const formattedTitle = tabId.charAt(0).toUpperCase() + tabId.slice(1).replace('-', ' ');
    pageTitle.textContent = formattedTitle;

    // Trigger tab specific renders if needed
    if (tabId === 'dashboard') renderDashboard();
    if (tabId === 'transactions') renderTransactionsTab();
    if (tabId === 'lend-borrow') renderLendBorrowTab();
    if (tabId === 'loans') renderLoansTab();
    if (tabId === 'petrol') renderPetrolTab();
    if (tabId === 'investments') renderInvestmentsTab();
}

// -------------------------------------------------------------
// Data Loading & Syncing
// -------------------------------------------------------------
async function loadAllUserData() {
    if (!appState.user) return;
    const userId = appState.user.mobile_number;

    showSyncStatus('Syncing data...', 'pending');

    try {
        // Run fetches in parallel
        const [
            cats, txs, loans, lb, repayments, inv, budgets, vehicle, fuel
        ] = await Promise.all([
            dbQuery('SELECT * FROM categories WHERE user_id = $1', [userId]),
            dbQuery('SELECT * FROM transactions WHERE user_id = $1 ORDER BY date DESC, id DESC', [userId]),
            dbQuery('SELECT * FROM loans WHERE user_id = $1 ORDER BY id DESC', [userId]),
            dbQuery('SELECT * FROM lend_borrows WHERE user_id = $1 ORDER BY date DESC, id DESC', [userId]),
            dbQuery('SELECT * FROM repayments WHERE user_id = $1 ORDER BY "paymentDate" DESC, id DESC', [userId]),
            dbQuery('SELECT * FROM investments WHERE user_id = $1 ORDER BY id DESC', [userId]),
            dbQuery('SELECT * FROM category_budgets WHERE user_id = $1', [userId]),
            dbQuery('SELECT * FROM vehicle_configs WHERE user_id = $1', [userId]),
            dbQuery('SELECT * FROM fuel_logs WHERE user_id = $1 ORDER BY odometer DESC, date DESC', [userId])
        ]);

        appState.categories = cats;
        appState.transactions = txs;
        appState.loans = loans;
        appState.lendBorrows = lb;
        appState.repayments = repayments;
        appState.investments = inv;
        appState.categoryBudgets = budgets;
        appState.vehicleConfig = vehicle.length > 0 ? vehicle[0] : null;
        appState.fuelLogs = fuel;

        // Auto create default categories if user has none
        if (appState.categories.length === 0) {
            await createDefaultCategories();
        }

        // Refresh UI
        switchTab('dashboard');
        populateCategoryDropdowns();
        showSyncStatus('Synced', 'success');
    } catch (err) {
        console.error('Failed to sync details:', err);
        showSyncStatus('Sync Failed', 'error');
    }
}

// Force Sync button
document.getElementById('sync-now-btn').addEventListener('click', loadAllUserData);

async function createDefaultCategories() {
    const userId = appState.user.mobile_number;
    const defaults = [
        { name: 'Food & Dining', limit: 8000 },
        { name: 'Rent & Living', limit: 15000 },
        { name: 'Transport & Fuel', limit: 4000 },
        { name: 'Shopping & Leisure', limit: 6000 },
        { name: 'Bills & Utilities', limit: 5000 },
        { name: 'Salary (Income)', limit: 0 }
    ];

    const futures = defaults.map(cat => {
        const id = generateId();
        return dbQuery(
            'INSERT INTO categories (id, user_id, name, "plannedAmount") VALUES ($1, $2, $3, $4)',
            [id, userId, cat.name, cat.limit]
        );
    });

    await Promise.all(futures);
    // Reload categories
    appState.categories = await dbQuery('SELECT * FROM categories WHERE user_id = $1', [userId]);
}

function populateCategoryDropdowns() {
    const dropdowns = ['qa-category', 'mt-category', 'tx-filter-category'];
    dropdowns.forEach(ddId => {
        const select = document.getElementById(ddId);
        if (!select) return;

        // Clear existing, keeping 'All' option for filter
        if (ddId === 'tx-filter-category') {
            select.innerHTML = '<option value="all">All Categories</option>';
        } else {
            select.innerHTML = '';
        }

        appState.categories.forEach(cat => {
            const opt = document.createElement('option');
            opt.value = cat.id;
            opt.textContent = cat.name;
            select.appendChild(opt);
        });
    });
}

// -------------------------------------------------------------
// 1. DASHBOARD COMPONENT
// -------------------------------------------------------------
function renderDashboard() {
    // Calculators totals
    let totalInvested = appState.investments.reduce((sum, item) => sum + parseFloat(item.amount), 0);
    
    // Lend & Borrow totals
    let toReceive = appState.lendBorrows
        .filter(item => item.type === 'Lend')
        .reduce((sum, item) => sum + (parseFloat(item.principal) - parseFloat(item.settled || 0)), 0);

    let toPay = appState.lendBorrows
        .filter(item => item.type === 'Borrow')
        .reduce((sum, item) => sum + (parseFloat(item.principal) - parseFloat(item.settled || 0)), 0);
    
    // Add bank loans balance to To Pay
    let pendingLoans = appState.loans
        .filter(l => l.status !== 'Settled')
        .reduce((sum, l) => sum + parseFloat(l.balance), 0);
    
    toPay += pendingLoans;

    // Net worth = Investments + Receive - Pay + Liquid cash (Income transactions - expense transactions)
    let totalIncome = appState.transactions
        .filter(t => {
            const cat = appState.categories.find(c => c.id === t.categoryId);
            return cat && cat.name.toLowerCase().includes('income');
        })
        .reduce((sum, t) => sum + parseFloat(t.cost), 0);

    let totalExpense = appState.transactions
        .filter(t => {
            const cat = appState.categories.find(c => c.id === t.categoryId);
            return !cat || !cat.name.toLowerCase().includes('income');
        })
        .reduce((sum, t) => sum + parseFloat(t.cost), 0);

    let liquidCash = totalIncome - totalExpense;
    let netWorth = liquidCash + totalInvested + toReceive - toPay;

    // Update UI elements
    document.getElementById('val-networth').textContent = `₹${Math.round(netWorth).toLocaleString()}`;
    document.getElementById('val-toreceive').textContent = `₹${Math.round(toReceive).toLocaleString()}`;
    document.getElementById('val-topay').textContent = `₹${Math.round(toPay).toLocaleString()}`;
    document.getElementById('val-investments').textContent = `₹${Math.round(totalInvested).toLocaleString()}`;

    // Render Recent timeline (limit to 5)
    const recentList = document.getElementById('recent-transactions-list');
    recentList.innerHTML = '';
    const slice = appState.transactions.slice(0, 5);

    if (slice.length === 0) {
        recentList.innerHTML = '<p class="placeholder-text">No transactions logged yet.</p>';
        return;
    }

    slice.forEach(t => {
        const cat = appState.categories.find(c => c.id === t.categoryId);
        const isIncome = cat && cat.name.toLowerCase().includes('income');

        const row = document.createElement('div');
        row.className = 'activity-item';
        row.innerHTML = `
            <div class="act-info">
                <span class="act-title">${t.itemService}</span>
                <span class="act-sub">${cat ? cat.name : 'Uncategorized'} | ${t.date}</span>
            </div>
            <span class="act-amount ${isIncome ? 'text-green' : 'text-red'}">
                ${isIncome ? '+' : '-'}₹${parseFloat(t.cost).toLocaleString()}
            </span>
        `;
        recentList.appendChild(row);
    });

    // Populate date fields with today by default
    document.getElementById('qa-date').value = getTodayDateString();
}

// Quick Add Transaction form
document.getElementById('quick-add-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const userId = appState.user.mobile_number;
    const desc = document.getElementById('qa-desc').value.trim();
    const cost = parseFloat(document.getElementById('qa-cost').value);
    const categoryId = document.getElementById('qa-category').value;
    const paidInput = document.getElementById('qa-paid').value;
    const paid = paidInput === '' ? cost : parseFloat(paidInput);
    const date = document.getElementById('qa-date').value;
    const cleared = document.getElementById('qa-cleared').checked ? 1 : 0;
    const id = generateId();

    try {
        showSyncStatus('Saving...', 'pending');
        await dbQuery(
            'INSERT INTO transactions (id, user_id, "categoryId", "itemService", cost, "paidAmount", cleared, date) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)',
            [id, userId, categoryId, desc, cost, paid, cleared, date]
        );

        // Add locally & reload
        appState.transactions.unshift({
            id: id,
            categoryId: categoryId,
            itemService: desc,
            cost: cost,
            paidAmount: paid,
            cleared: cleared,
            date: date
        });

        document.getElementById('quick-add-form').reset();
        document.getElementById('qa-date').value = getTodayDateString();
        document.getElementById('qa-cleared').checked = true;

        renderDashboard();
        showSyncStatus('Synced', 'success');
    } catch (e) {
        alert('Failed to save transaction');
    }
});

// -------------------------------------------------------------
// 2. TRANSACTIONS & BUDGETS COMPONENT
// -------------------------------------------------------------
const txTableBody = document.getElementById('tx-table-body');
const txSearch = document.getElementById('tx-search');
const txFilterCategory = document.getElementById('tx-filter-category');
const txFilterMonth = document.getElementById('tx-filter-month');
const modalTx = document.getElementById('modal-tx');

// Modal triggers
document.getElementById('btn-add-tx').addEventListener('click', () => {
    document.getElementById('mt-date').value = getTodayDateString();
    modalTx.classList.remove('hidden');
});
document.getElementById('modal-tx-close').addEventListener('click', () => modalTx.classList.add('hidden'));

// Filters listeners
txSearch.addEventListener('input', renderTransactionsList);
txFilterCategory.addEventListener('change', renderTransactionsList);
txFilterMonth.addEventListener('change', renderTransactionsList);

function renderTransactionsTab() {
    // Set default month/year filter to current month
    if (!txFilterMonth.value) {
        const now = new Date();
        const m = (now.getMonth() + 1).toString().padStart(2, '0');
        txFilterMonth.value = `${now.getFullYear()}-${m}`;
    }

    renderTransactionsList();
    renderBudgets();
}

function renderTransactionsList() {
    txTableBody.innerHTML = '';
    const q = txSearch.value.toLowerCase().trim();
    const catFilter = txFilterCategory.value;
    const monthFilter = txFilterMonth.value; // YYYY-MM

    const filtered = appState.transactions.filter(t => {
        // Search description or category name
        const cat = appState.categories.find(c => c.id === t.categoryId);
        const catName = cat ? cat.name.toLowerCase() : '';
        const desc = t.itemService.toLowerCase();
        const matchesQuery = q === '' || desc.includes(q) || catName.includes(q);

        // Category filter
        const matchesCategory = catFilter === 'all' || t.categoryId === catFilter;

        // Month filter
        const matchesMonth = monthFilter === '' || t.date.startsWith(monthFilter);

        return matchesQuery && matchesCategory && matchesMonth;
    });

    if (filtered.length === 0) {
        txTableBody.innerHTML = '<tr><td colspan="7" class="text-center placeholder-text">No matching transactions.</td></tr>';
        return;
    }

    filtered.forEach(t => {
        const cat = appState.categories.find(c => c.id === t.categoryId);
        const tr = document.createElement('tr');
        tr.innerHTML = `
            <td>${t.date}</td>
            <td class="font-bold">${t.itemService}</td>
            <td><span class="tag">${cat ? cat.name : 'General'}</span></td>
            <td>₹${parseFloat(t.cost).toLocaleString()}</td>
            <td>₹${parseFloat(t.paidAmount).toLocaleString()}</td>
            <td>
                <span class="status-badge ${t.cleared ? 'cleared' : 'pending'}">
                    ${t.cleared ? 'Cleared' : 'Pending'}
                </span>
            </td>
            <td>
                <button class="btn-danger-sm" onclick="deleteTransaction('${t.id}')">Delete</button>
            </td>
        `;
        txTableBody.appendChild(tr);
    });
}

// Delete transaction
window.deleteTransaction = async function(id) {
    if (!confirm('Are you sure you want to delete this transaction?')) return;
    try {
        showSyncStatus('Deleting...', 'pending');
        await dbQuery('DELETE FROM transactions WHERE user_id = $1 AND id = $2', [appState.user.mobile_number, id]);
        
        // Remove locally
        appState.transactions = appState.transactions.filter(t => t.id !== id);
        
        renderTransactionsList();
        renderBudgets();
        showSyncStatus('Synced', 'success');
    } catch (e) {
        alert('Failed to delete transaction');
    }
};

// Add category & budgets
document.getElementById('budget-set-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const userId = appState.user.mobile_number;
    const name = document.getElementById('budget-cat-name').value.trim();
    const limit = parseFloat(document.getElementById('budget-amount').value);
    
    // Check if category exists
    const match = appState.categories.find(c => c.name.toLowerCase() === name.toLowerCase());

    try {
        showSyncStatus('Saving category...', 'pending');
        if (match) {
            // Update
            await dbQuery(
                'UPDATE categories SET "plannedAmount" = $1 WHERE user_id = $2 AND id = $3',
                [limit, userId, match.id]
            );
            match.plannedAmount = limit;
        } else {
            // Create
            const id = generateId();
            await dbQuery(
                'INSERT INTO categories (id, user_id, name, "plannedAmount") VALUES ($1, $2, $3, $4)',
                [id, userId, name, limit]
            );
            appState.categories.push({ id: id, name: name, plannedAmount: limit });
        }

        document.getElementById('budget-set-form').reset();
        populateCategoryDropdowns();
        renderBudgets();
        showSyncStatus('Synced', 'success');
    } catch (e) {
        alert('Failed to configure category');
    }
});

// Render Budgets Progress
function renderBudgets() {
    const budgetsGrid = document.getElementById('category-budgets-grid');
    budgetsGrid.innerHTML = '';
    
    const monthFilter = txFilterMonth.value; // YYYY-MM
    if (!monthFilter) return;

    // Filter categories that have a planned limit > 0
    const budgetCategories = appState.categories.filter(c => parseFloat(c.plannedAmount) > 0);

    if (budgetCategories.length === 0) {
        budgetsGrid.innerHTML = '<p class="placeholder-text">Configure categories to set monthly budgets.</p>';
        return;
    }

    budgetCategories.forEach(cat => {
        // Calculate spend in current month
        const spend = appState.transactions
            .filter(t => t.categoryId === cat.id && t.date.startsWith(monthFilter))
            .reduce((sum, t) => sum + parseFloat(t.cost), 0);

        const limit = parseFloat(cat.plannedAmount);
        const percent = Math.min(100, Math.round((spend / limit) * 100));

        let statusClass = 'safe';
        if (percent >= 90) statusClass = 'danger';
        else if (percent >= 75) statusClass = 'warning';

        const card = document.createElement('div');
        card.className = 'budget-card';
        card.innerHTML = `
            <div class="budget-card-header">
                <strong>${cat.name}</strong>
                <span>${percent}%</span>
            </div>
            <div class="budget-bar">
                <div class="budget-fill ${statusClass}" style="width: ${percent}%;"></div>
            </div>
            <div class="budget-card-footer">
                <span>Spent: ₹${spend.toLocaleString()}</span>
                <span>Limit: ₹${limit.toLocaleString()}</span>
            </div>
        `;
        budgetsGrid.appendChild(card);
    });
}

// Modal transaction form
document.getElementById('modal-tx-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const userId = appState.user.mobile_number;
    const desc = document.getElementById('mt-desc').value.trim();
    const cost = parseFloat(document.getElementById('mt-cost').value);
    const categoryId = document.getElementById('mt-category').value;
    const paidInput = document.getElementById('mt-paid').value;
    const paid = paidInput === '' ? cost : parseFloat(paidInput);
    const date = document.getElementById('mt-date').value;
    const cleared = document.getElementById('mt-cleared').checked ? 1 : 0;
    const id = generateId();

    try {
        showSyncStatus('Saving...', 'pending');
        await dbQuery(
            'INSERT INTO transactions (id, user_id, "categoryId", "itemService", cost, "paidAmount", cleared, date) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)',
            [id, userId, categoryId, desc, cost, paid, cleared, date]
        );

        // Add locally
        appState.transactions.unshift({
            id: id,
            categoryId: categoryId,
            itemService: desc,
            cost: cost,
            paidAmount: paid,
            cleared: cleared,
            date: date
        });

        document.getElementById('modal-tx-form').reset();
        modalTx.classList.add('hidden');
        renderTransactionsTab();
        showSyncStatus('Synced', 'success');
    } catch (e) {
        alert('Failed to save transaction');
    }
});

// -------------------------------------------------------------
// 3. LEND & BORROW / SMART FIFO REPAYMENTS
// -------------------------------------------------------------
function renderLendBorrowTab() {
    renderLendBorrowList();
    renderRepaymentsList();
    
    // Set default dates
    document.getElementById('lb-date').value = getTodayDateString();
    document.getElementById('fifo-date').value = getTodayDateString();
}

function renderLendBorrowList() {
    const body = document.getElementById('lb-table-body');
    body.innerHTML = '';

    if (appState.lendBorrows.length === 0) {
        body.innerHTML = '<tr><td colspan="7" class="text-center placeholder-text">No active records logged.</td></tr>';
        return;
    }

    appState.lendBorrows.forEach(item => {
        const principal = parseFloat(item.principal);
        const settled = parseFloat(item.settled || 0);
        const balance = principal - settled;
        
        // Calculate due date
        const date = new Date(item.date);
        date.setDate(date.getDate() + parseInt(item.tenure));
        const dueDateStr = date.toISOString().split('T')[0];

        const tr = document.createElement('tr');
        tr.innerHTML = `
            <td class="font-bold">${item.name}</td>
            <td><span class="badge ${item.type === 'Lend' ? 'badge-orange' : 'btn-secondary-sm'}">${item.type}</span></td>
            <td>₹${principal.toLocaleString()}</td>
            <td>₹${settled.toLocaleString()}</td>
            <td class="font-bold ${balance > 0 ? (item.type === 'Lend' ? 'text-green' : 'text-red') : 'text-grey'}">
                ₹${balance.toLocaleString()}
            </td>
            <td>${dueDateStr}</td>
            <td>
                <span class="status-badge ${item.status.toLowerCase()}">${item.status}</span>
            </td>
        `;
        body.appendChild(tr);
    });
}

function renderRepaymentsList() {
    const body = document.getElementById('repayments-table-body');
    body.innerHTML = '';

    if (appState.repayments.length === 0) {
        body.innerHTML = '<tr><td colspan="4" class="text-center placeholder-text">No repayments recorded.</td></tr>';
        return;
    }

    appState.repayments.forEach(r => {
        const tr = document.createElement('tr');
        tr.innerHTML = `
            <td class="font-bold">${r.name}</td>
            <td>${r.paymentDate}</td>
            <td class="text-green font-bold">₹${parseFloat(r.amount).toLocaleString()}</td>
            <td><span class="tag">${r.method}</span></td>
        `;
        body.appendChild(tr);
    });
}

// Log new Lend/Borrow Record
document.getElementById('lend-borrow-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const userId = appState.user.mobile_number;
    const name = document.getElementById('lb-name').value.trim();
    const type = document.getElementById('lb-type').value;
    const principal = parseFloat(document.getElementById('lb-amount').value);
    const date = document.getElementById('lb-date').value;
    const tenure = parseInt(document.getElementById('lb-tenure').value);
    const id = generateId();

    try {
        showSyncStatus('Saving record...', 'pending');
        await dbQuery(
            'INSERT INTO lend_borrows (id, user_id, name, type, date, tenure, principal, "returnDate", settled, diff, status) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)',
            [id, userId, name, type, date, tenure, principal, null, 0, 0, 'Active']
        );

        // Load locally
        appState.lendBorrows.unshift({
            id: id,
            name: name,
            type: type,
            principal: principal,
            date: date,
            tenure: tenure,
            settled: 0,
            diff: 0,
            status: 'Active'
        });

        document.getElementById('lend-borrow-form').reset();
        document.getElementById('lb-date').value = getTodayDateString();
        document.getElementById('lb-tenure').value = 30;

        renderLendBorrowList();
        showSyncStatus('Synced', 'success');
    } catch (e) {
        alert('Failed to log debt record');
    }
});

// Smart FIFO repayment allocation
document.getElementById('repay-fifo-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const userId = appState.user.mobile_number;
    const name = document.getElementById('fifo-name').value.trim();
    const amountVal = parseFloat(document.getElementById('fifo-amount').value);
    const method = document.getElementById('fifo-method').value;
    const paymentDate = document.getElementById('fifo-date').value;

    let remaining = amountVal;
    let traceHtml = '';

    // 1. Fetch active lend_borrow records for that contact
    // In Vanilla JS, we sort the records in the memory state to ensure chronological (oldest first) order
    const activeDebts = appState.lendBorrows
        .filter(item => item.name.toLowerCase() === name.toLowerCase() && item.status === 'Active')
        .sort((a, b) => new Date(a.date) - new Date(b.date));

    if (activeDebts.length === 0) {
        // Create an overflow/independent repayment record
        const repId = generateId();
        await dbQuery(
            'INSERT INTO repayments (id, user_id, "lendBorrowId", name, "paymentDate", amount, method) VALUES ($1, $2, $3, $4, $5, $6, $7)',
            [repId, userId, '0', name, paymentDate, amountVal, method]
        );
        traceHtml = `<div class="trace-row"><span class="text-yellow">No active loans for ${name}. Created independent repayment log.</span><strong>₹${amountVal.toLocaleString()}</strong></div>`;
        
        // Push locally
        appState.repayments.unshift({
            id: repId,
            lendBorrowId: '0',
            name: name,
            paymentDate: paymentDate,
            amount: amountVal,
            method: method
        });
    } else {
        showSyncStatus('Allocating (FIFO)...', 'pending');
        
        try {
            for (let i = 0; i < activeDebts.length; i++) {
                if (remaining <= 0) break;

                const debt = activeDebts[i];
                const pending = parseFloat(debt.principal) - parseFloat(debt.settled || 0);
                const allocation = Math.min(remaining, pending);

                const newSettled = parseFloat(debt.settled || 0) + allocation;
                const status = newSettled >= parseFloat(debt.principal) ? 'Settled' : 'Active';

                // Update database
                await dbQuery(
                    'UPDATE lend_borrows SET settled = $1, status = $2, "returnDate" = $3 WHERE user_id = $4 AND id = $5',
                    [newSettled, status, status === 'Settled' ? paymentDate : null, userId, debt.id]
                );

                // Create repayment entry linked to this debt
                const repId = generateId();
                await dbQuery(
                    'INSERT INTO repayments (id, user_id, "lendBorrowId", name, "paymentDate", amount, method) VALUES ($1, $2, $3, $4, $5, $6, $7)',
                    [repId, userId, debt.id.toString(), name, paymentDate, allocation, method]
                );

                // Update local memory
                const localDebt = appState.lendBorrows.find(d => d.id === debt.id);
                if (localDebt) {
                    localDebt.settled = newSettled;
                    localDebt.status = status;
                    localDebt.returnDate = status === 'Settled' ? paymentDate : null;
                }

                appState.repayments.unshift({
                    id: repId,
                    lendBorrowId: debt.id,
                    name: name,
                    paymentDate: paymentDate,
                    amount: allocation,
                    method: method
                });

                traceHtml += `
                    <div class="trace-row">
                        <span>Applied to ${debt.type} on ${debt.date} (${status})</span>
                        <strong class="text-green">₹${allocation.toLocaleString()}</strong>
                    </div>
                `;

                remaining -= allocation;
            }

            // Handle credit balance overflow (applies to newest entry)
            if (remaining > 0) {
                // Find newest entry overall for this contact
                const sortedNewest = appState.lendBorrows
                    .filter(item => item.name.toLowerCase() === name.toLowerCase())
                    .sort((a, b) => new Date(b.date) - new Date(a.date));

                if (sortedNewest.length > 0) {
                    const newest = sortedNewest[0];
                    const newSettled = parseFloat(newest.settled || 0) + remaining;

                    await dbQuery(
                        'UPDATE lend_borrows SET settled = $1, status = $2 WHERE user_id = $3 AND id = $4',
                        [newSettled, 'Settled', userId, newest.id]
                    );

                    const repId = generateId();
                    await dbQuery(
                        'INSERT INTO repayments (id, user_id, "lendBorrowId", name, "paymentDate", amount, method) VALUES ($1, $2, $3, $4, $5, $6, $7)',
                        [repId, userId, newest.id.toString(), name, paymentDate, remaining, method]
                    );

                    const localDebt = appState.lendBorrows.find(d => d.id === newest.id);
                    if (localDebt) {
                        localDebt.settled = newSettled;
                        localDebt.status = 'Settled';
                    }

                    appState.repayments.unshift({
                        id: repId,
                        lendBorrowId: newest.id,
                        name: name,
                        paymentDate: paymentDate,
                        amount: remaining,
                        method: method
                    });

                    traceHtml += `
                        <div class="trace-row">
                            <span class="text-yellow">Overflow Applied to Newest Loan (${newest.date})</span>
                            <strong class="text-yellow">₹${remaining.toLocaleString()}</strong>
                        </div>
                    `;
                }
            }

            showSyncStatus('Synced', 'success');
        } catch (err) {
            alert('Failed smart allocation');
        }
    }

    // Display trace logs
    document.getElementById('fifo-logs-container').classList.remove('hidden');
    document.getElementById('fifo-trace').innerHTML = traceHtml;

    // Reset inputs
    document.getElementById('repay-fifo-form').reset();
    document.getElementById('fifo-date').value = getTodayDateString();

    renderLendBorrowList();
    renderRepaymentsList();
});

// -------------------------------------------------------------
// 4. LOANS MANAGEMENT
// -------------------------------------------------------------
function renderLoansTab() {
    renderLoansList();
    document.getElementById('loan-start-date').value = getTodayDateString();
}

function renderLoansList() {
    const body = document.getElementById('loans-table-body');
    body.innerHTML = '';

    if (appState.loans.length === 0) {
        body.innerHTML = '<tr><td colspan="9" class="text-center placeholder-text">No bank loans configured.</td></tr>';
        return;
    }

    appState.loans.forEach(loan => {
        const tr = document.createElement('tr');
        tr.innerHTML = `
            <td class="font-bold">${loan.lender}</td>
            <td>₹${parseFloat(loan.principal).toLocaleString()}</td>
            <td>${parseFloat(loan.roi)}%</td>
            <td class="text-violet font-bold">₹${Math.round(parseFloat(loan.emi)).toLocaleString()}</td>
            <td>₹${Math.round(parseFloat(loan.total)).toLocaleString()}</td>
            <td>₹${Math.round(parseFloat(loan.paid)).toLocaleString()}</td>
            <td>${loan.tenurePending} / ${loan.tenure} months</td>
            <td class="font-bold ${parseFloat(loan.balance) > 0 ? 'text-red' : 'text-grey'}">
                ₹${Math.round(parseFloat(loan.balance)).toLocaleString()}
            </td>
            <td>
                ${parseFloat(loan.balance) > 0 ? 
                    `<button class="btn-secondary-sm" onclick="payLoanEmi('${loan.id}')">Pay EMI</button>` : 
                    `<span class="tag">Settled</span>`
                }
            </td>
        `;
        body.appendChild(tr);
    });
}

// Add Bank Loan
document.getElementById('loan-add-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const userId = appState.user.mobile_number;
    const lender = document.getElementById('loan-lender').value.trim();
    const principal = parseFloat(document.getElementById('loan-principal').value);
    const roi = parseFloat(document.getElementById('loan-roi').value);
    const tenure = parseInt(document.getElementById('loan-tenure').value);
    const startDate = document.getElementById('loan-start-date').value;

    // Calculate Loan Values (EMI compound interest formula)
    const monthlyRate = (roi / 100) / 12;
    const emi = (principal * monthlyRate * Math.pow(1 + monthlyRate, tenure)) / (Math.pow(1 + monthlyRate, tenure) - 1);
    const totalPayback = emi * tenure;
    const totalInterest = totalPayback - principal;

    // Calculate End Date
    const start = new Date(startDate);
    start.setMonth(start.getMonth() + tenure);
    const endDate = start.toISOString().split('T')[0];

    const id = generateId();

    try {
        showSyncStatus('Creating loan...', 'pending');
        await dbQuery(
            'INSERT INTO loans (id, user_id, lender, "startDate", "endDate", tenure, roi, principal, interest, total, paid, balance, emi, "tenurePending", status) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)',
            [id, userId, lender, startDate, endDate, tenure, roi, principal, totalInterest, totalPayback, 0, totalPayback, emi, tenure, 'Active']
        );

        // Add locally
        appState.loans.unshift({
            id: id,
            lender: lender,
            startDate: startDate,
            endDate: endDate,
            tenure: tenure,
            roi: roi,
            principal: principal,
            interest: totalInterest,
            total: totalPayback,
            paid: 0,
            balance: totalPayback,
            emi: emi,
            tenurePending: tenure,
            status: 'Active'
        });

        document.getElementById('loan-add-form').reset();
        document.getElementById('loan-start-date').value = getTodayDateString();

        renderLoansList();
        showSyncStatus('Synced', 'success');
    } catch (e) {
        alert('Failed to register loan');
    }
});

// Pay Loan EMI
window.payLoanEmi = async function(id) {
    const userId = appState.user.mobile_number;
    const loan = appState.loans.find(l => l.id === id);
    if (!loan) return;

    const emiAmount = parseFloat(loan.emi);
    const newPaid = Math.min(parseFloat(loan.total), parseFloat(loan.paid) + emiAmount);
    const newBalance = Math.max(0, parseFloat(loan.total) - newPaid);
    const newTenurePending = Math.max(0, loan.tenurePending - 1);
    const status = newBalance <= 0 ? 'Settled' : 'Active';

    try {
        showSyncStatus('Paying EMI...', 'pending');
        
        // 1. Update loan balances
        await dbQuery(
            'UPDATE loans SET paid = $1, balance = $2, "tenurePending" = $3, status = $4 WHERE user_id = $5 AND id = $6',
            [newPaid, newBalance, newTenurePending, status, userId, id]
        );

        // 2. Add an expense transaction automatically for the EMI payment
        const txId = generateId();
        // Try to find Transport or Transport & Fuel or create/use general
        let category = appState.categories.find(c => c.name.toLowerCase().includes('bill') || c.name.toLowerCase().includes('util'));
        const catId = category ? category.id : appState.categories[0].id;
        
        await dbQuery(
            'INSERT INTO transactions (id, user_id, "categoryId", "itemService", cost, "paidAmount", cleared, date) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)',
            [txId, userId, catId, `EMI Payment - ${loan.lender}`, emiAmount, emiAmount, 1, getTodayDateString()]
        );

        // Update locally
        loan.paid = newPaid;
        loan.balance = newBalance;
        loan.tenurePending = newTenurePending;
        loan.status = status;

        appState.transactions.unshift({
            id: txId,
            categoryId: catId,
            itemService: `EMI Payment - ${loan.lender}`,
            cost: emiAmount,
            paidAmount: emiAmount,
            cleared: 1,
            date: getTodayDateString()
        });

        renderLoansList();
        showSyncStatus('Synced', 'success');
    } catch (e) {
        alert('Failed to pay EMI');
    }
};

// EMI Calculator live input bindings
const calcInputs = ['calc-principal', 'calc-roi', 'calc-tenure'];
calcInputs.forEach(id => {
    document.getElementById(id).addEventListener('input', runEmiCalc);
});

function runEmiCalc() {
    const principal = parseFloat(document.getElementById('calc-principal').value);
    const roi = parseFloat(document.getElementById('calc-roi').value);
    const tenure = parseInt(document.getElementById('calc-tenure').value);

    if (isNaN(principal) || isNaN(roi) || isNaN(tenure) || principal <= 0 || roi <= 0 || tenure <= 0) {
        return;
    }

    const monthlyRate = (roi / 100) / 12;
    const emi = (principal * monthlyRate * Math.pow(1 + monthlyRate, tenure)) / (Math.pow(1 + monthlyRate, tenure) - 1);
    const totalPayback = emi * tenure;
    const totalInterest = totalPayback - principal;

    document.getElementById('calc-emi-val').textContent = `₹${Math.round(emi).toLocaleString()}`;
    document.getElementById('calc-interest-val').textContent = `₹${Math.round(totalInterest).toLocaleString()}`;
    document.getElementById('calc-payback-val').textContent = `₹${Math.round(totalPayback).toLocaleString()}`;
}

// -------------------------------------------------------------
// 5. PETROL TRACKER & MILEAGE LOG
// -------------------------------------------------------------
function renderPetrolTab() {
    renderPetrolLogsList();
    renderVehicleConfig();
    
    document.getElementById('petrol-date').value = getTodayDateString();
}

function renderPetrolLogsList() {
    const body = document.getElementById('petrol-table-body');
    body.innerHTML = '';

    if (appState.fuelLogs.length === 0) {
        body.innerHTML = '<tr><td colspan="9" class="text-center placeholder-text">No refueling logs added yet.</td></tr>';
        return;
    }

    // Sort ascending for consecutive calculations
    const sortedLogs = [...appState.fuelLogs].sort((a, b) => parseFloat(a.odometer) - parseFloat(b.odometer));
    
    // Calculate distance and mileage interval values
    let totalMileageSum = 0;
    let mileageIntervalCount = 0;
    let totalSpend = 0;
    let totalKilometersRun = 0;

    for (let i = 0; i < sortedLogs.length; i++) {
        const log = sortedLogs[i];
        let distance = 0;
        let mileage = 'N/A';

        // Spend total
        totalSpend += parseFloat(log.totalCost);

        if (i > 0) {
            const prev = sortedLogs[i - 1];
            distance = parseFloat(log.odometer) - parseFloat(prev.odometer);
            
            // Full to Full mileage calculation logic
            // If current is full and prev was full, we can calculate mileage
            if (log.isFullTank && prev.isFullTank) {
                // Find all partial fuel volumes filled between prev and current
                let fuelConsumed = parseFloat(log.fuelAmount);
                // Note: since prev was full, the fuel filled at log i represents the fuel consumed 
                // to cover the distance between j and i.
                mileage = (distance / fuelConsumed).toFixed(2);
                
                totalMileageSum += parseFloat(mileage);
                mileageIntervalCount++;
            }
        }

        // Attach values in-memory to row for display
        log.calculatedMileage = mileage;
        log.distanceRun = distance;
    }

    // Odometer span total run
    if (sortedLogs.length > 1) {
        totalKilometersRun = parseFloat(sortedLogs[sortedLogs.length - 1].odometer) - parseFloat(sortedLogs[0].odometer);
    }

    // Display averages
    const avgMileageLabel = document.getElementById('petrol-avg-mileage');
    const costPerKmLabel = document.getElementById('petrol-cost-per-km');

    if (mileageIntervalCount > 0) {
        const avg = totalMileageSum / mileageIntervalCount;
        avgMileageLabel.textContent = avg.toFixed(2);
    } else {
        avgMileageLabel.textContent = '0.00';
    }

    if (totalKilometersRun > 0) {
        const cost = totalSpend / totalKilometersRun;
        costPerKmLabel.textContent = `₹${cost.toFixed(2)}`;
    } else {
        costPerKmLabel.textContent = `₹0.00`;
    }

    // Render history descending (newest first)
    const displayList = [...sortedLogs].reverse();
    displayList.forEach(log => {
        const tr = document.createElement('tr');
        tr.innerHTML = `
            <td>${log.date}</td>
            <td>${parseFloat(log.odometer).toLocaleString()} km</td>
            <td>${log.distanceRun > 0 ? `${parseFloat(log.distanceRun).toLocaleString()} km` : '-'}</td>
            <td>${parseFloat(log.fuelAmount)} L</td>
            <td>₹${parseFloat(log.pricePerUnit)}</td>
            <td class="font-bold">₹${parseFloat(log.totalCost).toLocaleString()}</td>
            <td><span class="badge ${log.isFullTank ? 'status-badge cleared' : 'status-badge active'}">${log.isFullTank ? 'Full Tank' : 'Partial'}</span></td>
            <td class="font-bold text-green">${log.calculatedMileage !== 'N/A' ? `${log.calculatedMileage} km/L` : '-'}</td>
            <td>
                <button class="btn-danger-sm" onclick="deleteFuelLog('${log.id}')">Delete</button>
            </td>
        `;
        body.appendChild(tr);
    });
}

// Log refueling
document.getElementById('petrol-add-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const userId = appState.user.mobile_number;
    const date = document.getElementById('petrol-date').value;
    const odometer = parseFloat(document.getElementById('petrol-odometer').value);
    const fuelAmount = parseFloat(document.getElementById('petrol-fuel').value);
    const pricePerUnit = parseFloat(document.getElementById('petrol-price').value);
    const isFullTank = document.getElementById('petrol-fulltank').checked ? 1 : 0;
    const notes = document.getElementById('petrol-notes').value.trim();

    const totalCost = fuelAmount * pricePerUnit;
    const id = generateId();

    try {
        showSyncStatus('Saving fuel log...', 'pending');
        await dbQuery(
            'INSERT INTO fuel_logs (id, user_id, date, odometer, "fuelAmount", "pricePerUnit", "totalCost", "isFullTank", notes) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)',
            [id, userId, date, odometer, fuelAmount, pricePerUnit, totalCost, isFullTank, notes]
        );

        // Update locally
        appState.fuelLogs.unshift({
            id: id,
            date: date,
            odometer: odometer,
            fuelAmount: fuelAmount,
            pricePerUnit: pricePerUnit,
            totalCost: totalCost,
            isFullTank: isFullTank,
            notes: notes
        });

        // Add auto transaction expense under Fuel/Transport
        const txId = generateId();
        let category = appState.categories.find(c => c.name.toLowerCase().includes('transport') || c.name.toLowerCase().includes('fuel'));
        const catId = category ? category.id : appState.categories[0].id;
        
        await dbQuery(
            'INSERT INTO transactions (id, user_id, "categoryId", "itemService", cost, "paidAmount", cleared, date) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)',
            [txId, userId, catId, `Fuel Refill (${fuelAmount}L)`, totalCost, totalCost, 1, date]
        );

        appState.transactions.unshift({
            id: txId,
            categoryId: catId,
            itemService: `Fuel Refill (${fuelAmount}L)`,
            cost: totalCost,
            paidAmount: totalCost,
            cleared: 1,
            date: date
        });

        document.getElementById('petrol-add-form').reset();
        document.getElementById('petrol-date').value = getTodayDateString();
        document.getElementById('petrol-fulltank').checked = true;

        renderPetrolLogsList();
        showSyncStatus('Synced', 'success');
    } catch (e) {
        alert('Failed to save fuel log');
    }
});

// Delete fuel log
window.deleteFuelLog = async function(id) {
    if (!confirm('Are you sure you want to delete this fuel log?')) return;
    try {
        showSyncStatus('Deleting fuel log...', 'pending');
        await dbQuery('DELETE FROM fuel_logs WHERE user_id = $1 AND id = $2', [appState.user.mobile_number, id]);
        appState.fuelLogs = appState.fuelLogs.filter(f => f.id !== id);
        renderPetrolLogsList();
        showSyncStatus('Synced', 'success');
    } catch (e) {
        alert('Failed to delete fuel log');
    }
};

// Save vehicle parameters
document.getElementById('veh-save-btn').addEventListener('click', async () => {
    const userId = appState.user.mobile_number;
    const name = document.getElementById('veh-name').value.trim();
    const initOdo = parseFloat(document.getElementById('veh-init-odo').value);

    try {
        showSyncStatus('Saving vehicle config...', 'pending');
        await dbQuery(
            'INSERT INTO vehicle_configs (id, user_id, "initialOdometer", "currentOdometer", "vehicleName", "lastSyncTime", "autoStartOnBoot") VALUES ($1, $2, $3, $4, $5, $6, $7) ON CONFLICT (user_id, id) DO UPDATE SET "vehicleName" = EXCLUDED."vehicleName", "initialOdometer" = EXCLUDED."initialOdometer", "currentOdometer" = EXCLUDED."currentOdometer", "lastSyncTime" = EXCLUDED."lastSyncTime", "autoStartOnBoot" = EXCLUDED."autoStartOnBoot"',
            ['default_vehicle', userId, initOdo, initOdo, name, getTodayDateString(), 1]
        );
        appState.vehicleConfig = {
            id: 'default_vehicle',
            vehicleName: name,
            initialOdometer: initOdo,
            currentOdometer: initOdo
        };
        alert('Vehicle parameters updated!');
        showSyncStatus('Synced', 'success');
    } catch (e) {
        alert('Failed to save config');
    }
});

function renderVehicleConfig() {
    if (appState.vehicleConfig) {
        document.getElementById('veh-name').value = appState.vehicleConfig.vehicleName;
        document.getElementById('veh-init-odo').value = appState.vehicleConfig.initialOdometer;
    }
}

// -------------------------------------------------------------
// 6. INVESTMENTS PORTFOLIO
// -------------------------------------------------------------
function renderInvestmentsTab() {
    renderInvestmentsList();
    document.getElementById('inv-start-date').value = getTodayDateString();
}

function renderInvestmentsList() {
    const body = document.getElementById('invest-table-body');
    body.innerHTML = '';
    
    let totalPortfolioVal = 0;

    if (appState.investments.length === 0) {
        body.innerHTML = '<tr><td colspan="7" class="text-center placeholder-text">No portfolio assets configured.</td></tr>';
        document.getElementById('port-total-invested').textContent = '₹0';
        document.getElementById('proj-current').textContent = '₹0';
        document.getElementById('proj-1yr').textContent = '₹0';
        document.getElementById('proj-3yr').textContent = '₹0';
        document.getElementById('proj-5yr').textContent = '₹0';
        return;
    }

    appState.investments.forEach(item => {
        const amount = parseFloat(item.amount);
        totalPortfolioVal += amount;

        // Calculate investment age
        const start = new Date(item.startDate);
        const diffTime = Math.abs(new Date() - start);
        const ageDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

        const tr = document.createElement('tr');
        tr.innerHTML = `
            <td class="font-bold">${item.name}</td>
            <td><span class="tag">${item.type}</span></td>
            <td class="font-bold">₹${amount.toLocaleString()}</td>
            <td class="text-green">${parseFloat(item.expectedRoi)}%</td>
            <td>${item.startDate}</td>
            <td>${ageDays} days</td>
            <td>
                <button class="btn-danger-sm" onclick="deleteInvestment('${item.id}')">Delete</button>
            </td>
        `;
        body.appendChild(tr);
    });

    document.getElementById('port-total-invested').textContent = `₹${totalPortfolioVal.toLocaleString()}`;
    
    // Calculate compound growth projections
    let val1yr = 0;
    let val3yr = 0;
    let val5yr = 0;

    appState.investments.forEach(item => {
        const principal = parseFloat(item.amount);
        const r = parseFloat(item.expectedRoi) / 100;
        
        val1yr += principal * Math.pow(1 + r, 1);
        val3yr += principal * Math.pow(1 + r, 3);
        val5yr += principal * Math.pow(1 + r, 5);
    });

    document.getElementById('proj-current').textContent = `₹${Math.round(totalPortfolioVal).toLocaleString()}`;
    document.getElementById('proj-1yr').textContent = `₹${Math.round(val1yr).toLocaleString()}`;
    document.getElementById('proj-3yr').textContent = `₹${Math.round(val3yr).toLocaleString()}`;
    document.getElementById('proj-5yr').textContent = `₹${Math.round(val5yr).toLocaleString()}`;
}

// Add Investment asset
document.getElementById('invest-add-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const userId = appState.user.mobile_number;
    const name = document.getElementById('inv-name').value.trim();
    const type = document.getElementById('inv-type').value;
    const amount = parseFloat(document.getElementById('inv-amount').value);
    const roi = parseFloat(document.getElementById('inv-roi').value);
    const startDate = document.getElementById('inv-start-date').value;

    const id = generateId();

    try {
        showSyncStatus('Adding asset...', 'pending');
        await dbQuery(
            'INSERT INTO investments (id, user_id, name, type, amount, "expectedRoi", "tenureMonths", "startDate") VALUES ($1, $2, $3, $4, $5, $6, $7, $8)',
            [id, userId, name, type, amount, roi, 12, startDate]
        );

        // Add locally
        appState.investments.unshift({
            id: id,
            name: name,
            type: type,
            amount: amount,
            expectedRoi: roi,
            tenureMonths: 12,
            startDate: startDate
        });

        // Add auto transaction expense under Investments
        const txId = generateId();
        let category = appState.categories.find(c => c.name.toLowerCase().includes('invest'));
        
        // If no investment category found, create one
        let catId;
        if (category) {
            catId = category.id;
        } else {
            catId = generateId();
            await dbQuery(
                'INSERT INTO categories (id, user_id, name, "plannedAmount") VALUES ($1, $2, $3, $4)',
                [catId, userId, 'Investments', 0]
            );
            appState.categories.push({ id: catId, name: 'Investments', plannedAmount: 0 });
            populateCategoryDropdowns();
        }

        await dbQuery(
            'INSERT INTO transactions (id, user_id, "categoryId", "itemService", cost, "paidAmount", cleared, date) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)',
            [txId, userId, catId, `Asset Invest - ${name}`, amount, amount, 1, startDate]
        );

        appState.transactions.unshift({
            id: txId,
            categoryId: catId,
            itemService: `Asset Invest - ${name}`,
            cost: amount,
            paidAmount: amount,
            cleared: 1,
            date: startDate
        });

        document.getElementById('invest-add-form').reset();
        document.getElementById('inv-start-date').value = getTodayDateString();

        renderInvestmentsList();
        showSyncStatus('Synced', 'success');
    } catch (e) {
        alert('Failed to log investment');
    }
});

// Delete Investment
window.deleteInvestment = async function(id) {
    if (!confirm('Are you sure you want to delete this asset?')) return;
    try {
        showSyncStatus('Deleting asset...', 'pending');
        await dbQuery('DELETE FROM investments WHERE user_id = $1 AND id = $2', [appState.user.mobile_number, id]);
        appState.investments = appState.investments.filter(i => i.id !== id);
        renderInvestmentsList();
        showSyncStatus('Synced', 'success');
    } catch (e) {
        alert('Failed to delete asset');
    }
};

// -------------------------------------------------------------
// App Initialization
// -------------------------------------------------------------
window.addEventListener('DOMContentLoaded', () => {
    checkAutoLogin();
});
