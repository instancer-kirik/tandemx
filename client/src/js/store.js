// Store page functionality
let paymentOptions = null; // To store fetched payment options
let currentPurchase = { type: null, id: null, name: null, price: null }; // To store item being purchased

document.addEventListener('DOMContentLoaded', () => {
    loadTokens();
    loadUpgrades();
    loadPaymentOptions(); // Fetch payment options on load
});

// Load payment options from the API
async function loadPaymentOptions() {
    try {
        const response = await fetch('/api/payment-options');
        if (!response.ok) throw new Error('Failed to fetch payment options');
        paymentOptions = await response.json();
        // Pre-populate static info if modal exists (it might not on initial load)
        const bankInstructions = document.getElementById('bank-instructions');
        if (bankInstructions) {
            bankInstructions.textContent = paymentOptions.bank.instructions;
        }
        const cryptoList = document.getElementById('crypto-addresses');
        if (cryptoList) {
             populateCryptoAddresses(cryptoList);
        }
    } catch (error) {
        console.error('Error loading payment options:', error);
        // Handle error - maybe show a message to the user
    }
}

// Helper to populate crypto addresses list
function populateCryptoAddresses(listElement) {
    if (!paymentOptions || !paymentOptions.crypto) return;
    listElement.innerHTML = `
        <li><strong>SOL:</strong> ${paymentOptions.crypto.sol_address}</li>
        <li><strong>ETH:</strong> ${paymentOptions.crypto.eth_address}</li>
        <li><strong>ETC:</strong> ${paymentOptions.crypto.etc_address}</li>
    `;
}

// Load tokens from the API
async function loadTokens() {
    try {
        const response = await fetch('/api/tokens');
        const tokens = await response.json();
        displayTokens(tokens);
    } catch (error) {
        console.error('Error loading tokens:', error);
    }
}

// Load upgrades from the API
async function loadUpgrades() {
    try {
        const response = await fetch('/api/upgrades');
        const upgrades = await response.json();
        displayUpgrades(upgrades);
    } catch (error) {
        console.error('Error loading upgrades:', error);
    }
}

// Display tokens in the grid
function displayTokens(tokens) {
    const tokensGrid = document.getElementById('tokens-grid');
    tokensGrid.innerHTML = '';

    tokens.forEach(token => {
        const tokenCard = createTokenCard(token);
        tokensGrid.appendChild(tokenCard);
    });
}

// Display upgrades in the grid
function displayUpgrades(upgrades) {
    const upgradesGrid = document.getElementById('upgrades-grid');
    upgradesGrid.innerHTML = '';

    upgrades.forEach(upgrade => {
        const upgradeCard = createUpgradeCard(upgrade);
        upgradesGrid.appendChild(upgradeCard);
    });
}

// Create a token card element
function createTokenCard(token) {
    const card = document.createElement('div');
    card.className = 'token-card';

    const image = document.createElement('img');
    image.className = 'token-image';
    image.src = token.image;
    image.alt = token.name;

    const content = document.createElement('div');
    content.className = 'token-content';

    if (token.badge) {
        const badge = document.createElement('span');
        badge.className = 'token-badge';
        badge.textContent = token.badge;
        content.appendChild(badge);
    }

    const name = document.createElement('h3');
    name.className = 'token-name';
    name.textContent = token.name;

    const description = document.createElement('p');
    description.className = 'token-description';
    description.textContent = token.description;

    const price = document.createElement('div');
    price.className = 'token-price';
    price.textContent = `$${token.price.toFixed(2)}`;

    const button = document.createElement('button');
    button.className = 'purchase-button';
    button.textContent = 'Purchase';
    button.onclick = () => openPurchaseModal('token', token.id, token.name, token.price);

    content.appendChild(name);
    content.appendChild(description);
    content.appendChild(price);
    content.appendChild(button);

    card.appendChild(image);
    card.appendChild(content);

    return card;
}

// Create an upgrade card element
function createUpgradeCard(upgrade) {
    const card = document.createElement('div');
    card.className = 'upgrade-card';

    const image = document.createElement('img');
    image.className = 'upgrade-image';
    image.src = upgrade.image;
    image.alt = upgrade.name;

    const content = document.createElement('div');
    content.className = 'upgrade-content';

    if (upgrade.badge) {
        const badge = document.createElement('span');
        badge.className = 'upgrade-badge';
        badge.textContent = upgrade.badge;
        content.appendChild(badge);
    }

    const name = document.createElement('h3');
    name.className = 'upgrade-name';
    name.textContent = upgrade.name;

    const description = document.createElement('p');
    description.className = 'upgrade-description';
    description.textContent = upgrade.description;

    const priceContainer = document.createElement('div');
    priceContainer.className = 'upgrade-price-container';

    if (upgrade.salePrice) {
        const salePrice = document.createElement('span');
        salePrice.className = 'upgrade-sale-price';
        salePrice.textContent = `$${upgrade.price.toFixed(2)}`;
        priceContainer.appendChild(salePrice);
    }

    const price = document.createElement('span');
    price.className = 'upgrade-price';
    price.textContent = `$${(upgrade.salePrice || upgrade.price).toFixed(2)}`;
    priceContainer.appendChild(price);

    const specs = document.createElement('div');
    specs.className = 'upgrade-specs';
    const specsTitle = document.createElement('h4');
    specsTitle.textContent = 'Specifications';
    specs.appendChild(specsTitle);

    const specsList = document.createElement('ul');
    Object.entries(upgrade.specs).forEach(([key, value]) => {
        const li = document.createElement('li');
        li.innerHTML = `<span>${key}</span><span>${value}</span>`;
        specsList.appendChild(li);
    });
    specs.appendChild(specsList);

    const button = document.createElement('button');
    button.className = 'purchase-button';
    button.textContent = 'Purchase';
    button.onclick = () => openPurchaseModal('upgrade', upgrade.id, upgrade.name, upgrade.salePrice || upgrade.price);

    content.appendChild(name);
    content.appendChild(description);
    content.appendChild(priceContainer);
    content.appendChild(specs);
    content.appendChild(button);

    card.appendChild(image);
    card.appendChild(content);

    return card;
}

// --- Modal Logic ---

const modal = document.getElementById('purchase-modal');

function openPurchaseModal(type, id, name, price) {
    if (!paymentOptions) {
        alert('Payment options not loaded yet. Please try again in a moment.');
        return;
    }
    currentPurchase = { type, id, name, price };

    // Populate modal title and item details
    document.getElementById('modal-title').textContent = `Purchase ${name}`;
    document.getElementById('modal-item-details').innerHTML = `
        <p><strong>Item:</strong> ${name}</p>
        <p><strong>Price:</strong> $${price.toFixed(2)}</p>
    `;

    // Populate payment options info
    document.getElementById('bank-instructions').textContent = paymentOptions.bank.instructions;
    populateCryptoAddresses(document.getElementById('crypto-addresses'));

    // Reset form fields
    document.querySelector('input[name="paymentMethod"][value="paddle"]').checked = true;
    updatePaymentDetails(); // Ensure correct details are shown initially
    document.getElementById('crypto-tx-id').value = '';
    document.getElementById('street').value = '';
    document.getElementById('city').value = '';
    document.getElementById('state').value = '';
    document.getElementById('zip').value = '';
    document.getElementById('country').value = '';
    document.getElementById('redemption-instructions').value = '';

    modal.style.display = 'block';
}

function closeModal() {
    modal.style.display = 'none';
}

// Close modal if user clicks outside of it
window.onclick = function(event) {
    if (event.target == modal) {
        closeModal();
    }
}

function updatePaymentDetails() {
    const selectedMethod = document.querySelector('input[name="paymentMethod"]:checked').value;
    document.getElementById('payment-details-paddle').style.display = selectedMethod === 'paddle' ? 'block' : 'none';
    document.getElementById('payment-details-crypto').style.display = selectedMethod === 'crypto' ? 'block' : 'none';
    document.getElementById('payment-details-bank').style.display = selectedMethod === 'bank' ? 'block' : 'none';
}

// Handle Confirm Purchase button click
async function confirmPurchase() {
    const selectedMethod = document.querySelector('input[name="paymentMethod"]:checked').value;
    const purchaseData = {
        payment_method: selectedMethod,
        crypto_address: null, // Specific address choice could be added if needed
        crypto_tx_id: null,
        shipping_address: null,
        redemption_instructions: document.getElementById('redemption-instructions').value || null,
    };

    // Collect crypto details if selected
    if (selectedMethod === 'crypto') {
        purchaseData.crypto_tx_id = document.getElementById('crypto-tx-id').value || null;
        // Optionally add which crypto address was chosen if needed
    }

    // Collect shipping address if provided
    const street = document.getElementById('street').value;
    const city = document.getElementById('city').value;
    const state = document.getElementById('state').value;
    const zip = document.getElementById('zip').value;
    const country = document.getElementById('country').value;
    if (street && city && state && zip && country) {
        purchaseData.shipping_address = { street, city, state, zip, country };
    }

     // --- Actual Purchase API Call --- (Replaces old purchaseToken/purchaseUpgrade)
    try {
        const userId = getCurrentUserId(); // Placeholder
        const url = `/api/purchase/${currentPurchase.type}/${userId}/${currentPurchase.id}`;

        console.log("Sending purchase request:", url, purchaseData);

        const response = await fetch(url, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(purchaseData)
        });

        const result = await response.json();

        if (response.ok && result.success) {
            alert(`${currentPurchase.name} purchase request submitted successfully! (${result.message})`);
            closeModal();
            // Optionally refresh lists if needed (e.g., if items become unavailable)
            if (currentPurchase.type === 'token') loadTokens();
            if (currentPurchase.type === 'upgrade') loadUpgrades();
        } else {
             const errorMsg = result.error || 'Failed to submit purchase request. Please try again.';
             alert(`Error: ${errorMsg}`);
        }
    } catch (error) {
        console.error(`Error purchasing ${currentPurchase.type}:`, error);
        alert(`An error occurred while submitting the purchase request for ${currentPurchase.name}.`);
    }
}

// Get the current user's ID (placeholder - implement based on your auth system)
function getCurrentUserId() {
    // This is a placeholder - implement based on your authentication system
    return 'user123'; // Using a fixed ID for now
} 