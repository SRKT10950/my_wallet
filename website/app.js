// Interactive FIFO Repayment Simulator Logic

// State management
let loansList = [
    { id: 1, date: '2026-06-10', amount: 15000, settled: 0, pending: 15000, status: 'Active' },
    { id: 2, date: '2026-06-11', amount: 10000, settled: 0, pending: 10000, status: 'Active' },
    { id: 3, date: '2026-06-12', amount: 8000, settled: 0, pending: 8000, status: 'Active' }
];

let nextLoanId = 4;

// DOM Elements
const loansContainer = document.getElementById('loans-container');
const addLoanBtn = document.getElementById('add-loan-btn');
const repayAmountInput = document.getElementById('repay-amount');
const allocateBtn = document.getElementById('allocate-btn');
const repayLogs = document.getElementById('repay-logs');

// Initialize list rendering
function renderLoans() {
    loansContainer.innerHTML = '';
    
    // Sort oldest first chronologically by date
    const sorted = [...loansList].sort((a, b) => new Date(a.date) - new Date(b.date));

    sorted.forEach((loan, idx) => {
        const row = document.createElement('div');
        row.className = `loan-input-row ${loan.status.toLowerCase()}`;
        
        row.innerHTML = `
            <span class="loan-index">${idx + 1}</span>
            <div class="loan-details">
                <span class="loan-details-title">Loan amount: ₹${loan.amount.toLocaleString()}</span>
                <span class="loan-details-sub">Date: ${loan.date} | Status: <strong class="${loan.status === 'Settled' ? 'text-green' : 'text-red'}">${loan.status}</strong></span>
                <span class="loan-details-sub">Settled: ₹${loan.settled.toLocaleString()} | Pending: ₹${loan.pending.toLocaleString()}</span>
            </div>
            <button class="btn-remove-loan" onclick="removeLoan(${loan.id})">&times;</button>
        `;
        loansContainer.appendChild(row);
    });
}

// Add custom loan
addLoanBtn.addEventListener('click', () => {
    // Generate dates consecutively
    const today = new Date();
    today.setDate(today.getDate() + (loansList.length));
    const dateStr = today.toISOString().split('T')[0];
    
    // Random amount between 5000 and 20000
    const amt = Math.floor(Math.random() * 4 + 1) * 5000;

    loansList.push({
        id: nextLoanId++,
        date: dateStr,
        amount: amt,
        settled: 0,
        pending: amt,
        status: 'Active'
    });

    renderLoans();
});

// Remove loan
window.removeLoan = function(id) {
    loansList = loansList.filter(l => l.id !== id);
    renderLoans();
};

// FIFO Repayment Logic
allocateBtn.addEventListener('click', () => {
    let repayAmt = parseFloat(repayAmountInput.value);
    
    if (isNaN(repayAmt) || repayAmt <= 0) {
        repayLogs.innerHTML = `<span class="placeholder-text" style="color: #f43f5e;">Please enter a valid repayment amount!</span>`;
        return;
    }

    // Reset previous settlements for a clean run
    loansList.forEach(l => {
        l.settled = 0;
        l.pending = l.amount;
        l.status = 'Active';
    });

    // Sort oldest first chronologically by date
    const sorted = [...loansList].sort((a, b) => new Date(a.date) - new Date(b.date));
    const activeEntries = sorted.filter(l => l.status === 'Active');

    let remaining = repayAmt;
    let logsHtml = '';

    for (let i = 0; i < activeEntries.length; i++) {
        if (remaining <= 0) break;
        
        let loan = activeEntries[i];
        let pending = loan.pending;
        let repayForThis = remaining >= pending ? pending : remaining;
        
        loan.settled = repayForThis;
        loan.pending = loan.amount - repayForThis;
        loan.status = loan.pending <= 0 ? 'Settled' : 'Active';
        
        remaining -= repayForThis;

        logsHtml += `
            <div class="log-entry ${loan.status.toLowerCase()}">
                <div class="log-title-row">
                    <span>Applied to Loan on ${loan.date}</span>
                    <span class="${loan.status === 'Settled' ? 'text-green' : 'text-red'}">₹${repayForThis.toLocaleString()}</span>
                </div>
                <div class="log-subText">
                    Status: ${loan.status} | Remaining Pending: ₹${loan.pending.toLocaleString()}
                </div>
            </div>
        `;
    }

    // Handle overflow allocation to the newest entry
    if (remaining > 0) {
        // Find the newest overall entry
        const sortedNewest = [...loansList].sort((a, b) => new Date(b.date) - new Date(a.date));
        if (sortedNewest.length > 0) {
            const newest = sortedNewest[0];
            
            // Add overflow to its settled amount
            newest.settled += remaining;
            newest.pending = newest.amount - newest.settled; // will go negative (credit balance)
            newest.status = 'Settled';

            logsHtml += `
                <div class="log-entry settled" style="border-left-color: #f59e0b;">
                    <div class="log-title-row">
                        <span style="color: #f59e0b;">Overflow Applied to Newest Loan (${newest.date})</span>
                        <span style="color: #f59e0b;">+₹${remaining.toLocaleString()}</span>
                    </div>
                    <div class="log-subText">
                        Over-allocation Credit Balance: ₹${Math.abs(newest.pending).toLocaleString()}
                    </div>
                </div>
            `;
            remaining = 0;
        }
    }

    repayLogs.innerHTML = logsHtml || `<span class="placeholder-text">No active loans to allocate to!</span>`;
    
    // Sync calculations back to local state and update list view
    renderLoans();
});

// Initial Render
renderLoans();
