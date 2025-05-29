// Preorder functionality for Lemon Squeezy integration

// Initialize preorder checkout
export function initPreorderCheckout(productId, variantId, releaseDate) {
    // Get the store ID from your Lemon Squeezy configuration
    const storeId = 'tandemx'; // Replace with your actual store ID
    
    // Construct the checkout URL with preorder parameters
    const checkoutUrl = `https://${storeId}.lemonsqueezy.com/checkout/buy/${productId}?variant=${variantId}&preorder=true&release_date=${encodeURIComponent(releaseDate)}`;
    
    // Redirect to the Lemon Squeezy checkout
    window.location.href = checkoutUrl;
}

// Format release date for display
export function formatReleaseDate(dateString) {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'long',
        day: 'numeric'
    });
}

// Add preorder badge to product display
export function addPreorderBadge(element, releaseDate) {
    const badge = document.createElement('div');
    badge.className = 'preorder-badge';
    badge.innerHTML = `
        <span class="badge-text">Preorder</span>
        <span class="release-date">Available ${formatReleaseDate(releaseDate)}</span>
    `;
    element.appendChild(badge);
}

// Handle preorder button click
export function handlePreorderClick(productId, variantId, releaseDate) {
    // Show confirmation dialog
    const confirmed = confirm(
        `This is a preorder item that will be available on ${formatReleaseDate(releaseDate)}. ` +
        'Would you like to proceed with the preorder?'
    );
    
    if (confirmed) {
        initPreorderCheckout(productId, variantId, releaseDate);
    }
}

// Add preorder styles
export function addPreorderStyles() {
    const style = document.createElement('style');
    style.textContent = `
        .preorder-badge {
            position: absolute;
            top: 10px;
            right: 10px;
            background: #1b1eb4;
            color: white;
            padding: 8px 12px;
            border-radius: 4px;
            display: flex;
            flex-direction: column;
            align-items: center;
            font-size: 0.9rem;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        
        .badge-text {
            font-weight: bold;
            margin-bottom: 4px;
        }
        
        .release-date {
            font-size: 0.8rem;
            opacity: 0.9;
        }
        
        .preorder-button {
            background: #1b1eb4;
            color: white;
            border: none;
            padding: 12px 24px;
            border-radius: 4px;
            font-size: 1rem;
            cursor: pointer;
            transition: background-color 0.2s;
        }
        
        .preorder-button:hover {
            background: #1517a0;
        }
    `;
    document.head.appendChild(style);
} 