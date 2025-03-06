// WebSocket connection
const ws = new WebSocket(`ws://${window.location.host}/ws/findry`);
let spaces = [];
let currentSpaceIndex = 0;

// DOM Elements
const cardStack = document.querySelector('.card-stack');
const cardTemplate = document.querySelector('#space-card-template');
const modal = document.querySelector('.space-details.modal');
const filtersPanel = document.querySelector('.filters-panel');
const filterForm = {
    spaceType: document.querySelector('#spaceType'),
    minSqFt: document.querySelector('#minSqFt'),
    maxSqFt: document.querySelector('#maxSqFt'),
    minBudget: document.querySelector('#minBudget'),
    maxBudget: document.querySelector('#maxBudget'),
    acoustics: document.querySelector('#acoustics'),
    naturalLight: document.querySelector('#naturalLight'),
};

// WebSocket event handlers
ws.onopen = () => {
    console.log('Connected to Findry server');
    requestInitialSpaces();
};

ws.onmessage = (event) => {
    const message = JSON.parse(event.data);
    handleServerMessage(message);
};

ws.onclose = () => {
    console.log('Disconnected from Findry server');
};

function handleServerMessage(message) {
    switch (message.type) {
        case 'SpaceAdded':
            addSpace(message.space);
            break;
        case 'SpaceUpdated':
            updateSpace(message.space);
            break;
        case 'SpaceDeleted':
            removeSpace(message.spaceId);
            break;
        case 'MatchCreated':
            handleMatch(message.match);
            break;
        case 'BookingConfirmed':
            handleBookingConfirmation(message.booking);
            break;
    }
}

function requestInitialSpaces() {
    ws.send(JSON.stringify({
        type: 'GetSpaces',
        filters: getActiveFilters()
    }));
}

// Card Stack Management
function addSpace(space) {
    spaces.push(space);
    renderCard(space);
}

function updateSpace(updatedSpace) {
    const index = spaces.findIndex(s => s.id === updatedSpace.id);
    if (index !== -1) {
        spaces[index] = updatedSpace;
        if (index === currentSpaceIndex) {
            renderCard(updatedSpace);
        }
    }
}

function removeSpace(spaceId) {
    const index = spaces.findIndex(s => s.id === spaceId);
    if (index !== -1) {
        spaces.splice(index, 1);
        if (index === currentSpaceIndex) {
            currentSpaceIndex = Math.min(currentSpaceIndex, spaces.length - 1);
            renderCurrentCard();
        }
    }
}

function renderCard(space) {
    const card = cardTemplate.content.cloneNode(true);
    
    // Set card content
    card.querySelector('.space-name').textContent = space.name;
    card.querySelector('.space-type').textContent = formatSpaceType(space.space_type);
    card.querySelector('.space-price').textContent = formatPrice(space.pricing_terms);
    
    // Add photos
    const photosContainer = card.querySelector('.card-photos');
    space.photos.forEach((photoUrl, index) => {
        if (index === 0) { // Only show first photo in card
            const img = document.createElement('img');
            img.src = photoUrl;
            img.alt = space.name;
            photosContainer.appendChild(img);
        }
    });
    
    // Add features
    const featuresContainer = card.querySelector('.space-features');
    addFeatureTags(featuresContainer, space);
    
    // Clear existing cards and add new one
    cardStack.innerHTML = '';
    cardStack.appendChild(card);
    
    // Add swipe functionality
    initializeSwipe(cardStack.querySelector('.space-card'));
}

function renderCurrentCard() {
    if (spaces.length > 0 && currentSpaceIndex < spaces.length) {
        renderCard(spaces[currentSpaceIndex]);
    } else {
        cardStack.innerHTML = '<div class="no-spaces">No more spaces available</div>';
    }
}

// Swipe Functionality
function initializeSwipe(card) {
    let startX = 0;
    let currentX = 0;
    
    card.addEventListener('touchstart', handleTouchStart);
    card.addEventListener('touchmove', handleTouchMove);
    card.addEventListener('touchend', handleTouchEnd);
    card.addEventListener('mousedown', handleMouseDown);
    
    function handleTouchStart(e) {
        startX = e.touches[0].clientX;
    }
    
    function handleMouseDown(e) {
        startX = e.clientX;
        document.addEventListener('mousemove', handleMouseMove);
        document.addEventListener('mouseup', handleMouseUp);
    }
    
    function handleTouchMove(e) {
        e.preventDefault();
        currentX = e.touches[0].clientX - startX;
        updateCardPosition(currentX);
    }
    
    function handleMouseMove(e) {
        currentX = e.clientX - startX;
        updateCardPosition(currentX);
    }
    
    function handleTouchEnd() {
        handleSwipeEnd();
    }
    
    function handleMouseUp() {
        handleSwipeEnd();
        document.removeEventListener('mousemove', handleMouseMove);
        document.removeEventListener('mouseup', handleMouseUp);
    }
    
    function updateCardPosition(offset) {
        const rotate = offset * 0.1;
        card.style.transform = `translateX(${offset}px) rotate(${rotate}deg)`;
        card.style.opacity = 1 - Math.abs(offset) / 1000;
    }
    
    function handleSwipeEnd() {
        const threshold = window.innerWidth * 0.3;
        if (Math.abs(currentX) > threshold) {
            if (currentX > 0) {
                handleLike();
            } else {
                handlePass();
            }
        } else {
            // Reset position
            card.style.transform = '';
            card.style.opacity = '';
        }
        currentX = 0;
    }
}

// Swipe Actions
function handleLike() {
    const space = spaces[currentSpaceIndex];
    ws.send(JSON.stringify({
        type: 'SwipeRight',
        spaceId: space.id
    }));
    showNextCard('right');
}

function handlePass() {
    const space = spaces[currentSpaceIndex];
    ws.send(JSON.stringify({
        type: 'SwipeLeft',
        spaceId: space.id
    }));
    showNextCard('left');
}

function showNextCard(direction) {
    const card = cardStack.querySelector('.space-card');
    card.style.transition = 'transform 0.5s ease-out';
    card.style.transform = `translateX(${direction === 'right' ? '150%' : '-150%'}) rotate(${direction === 'right' ? '30deg' : '-30deg'})`;
    
    setTimeout(() => {
        currentSpaceIndex++;
        renderCurrentCard();
    }, 500);
}

// UI Helpers
function formatSpaceType(type) {
    return type.toLowerCase().split('_').map(word => 
        word.charAt(0).toUpperCase() + word.slice(1)
    ).join(' ');
}

function formatPrice(pricing) {
    const rate = pricing.hourly_rate;
    return `$${rate}/hour`;
}

function addFeatureTags(container, space) {
    if (space.acoustics_rating > 7) {
        addTag(container, '🎵 Great Acoustics');
    }
    if (space.lighting_details.natural_light) {
        addTag(container, '☀️ Natural Light');
    }
    if (space.equipment_list.length > 0) {
        addTag(container, '🛠️ Equipped');
    }
    if (space.location_data.parking_available) {
        addTag(container, '🅿️ Parking');
    }
}

function addTag(container, text) {
    const tag = document.createElement('span');
    tag.className = 'feature-tag';
    tag.textContent = text;
    container.appendChild(tag);
}

// Filter Management
function getActiveFilters() {
    return {
        spaceType: filterForm.spaceType.value,
        squareFootage: {
            min: filterForm.minSqFt.value || null,
            max: filterForm.maxSqFt.value || null
        },
        budget: {
            min: filterForm.minBudget.value || null,
            max: filterForm.maxBudget.value || null
        },
        acousticsRating: filterForm.acoustics.value,
        naturalLight: filterForm.naturalLight.checked
    };
}

document.querySelector('.apply-filters').addEventListener('click', () => {
    requestInitialSpaces();
});

// Modal Management
function showSpaceDetails(space) {
    const modal = document.querySelector('.space-details');
    
    // Fill in space details
    modal.querySelector('.space-name').textContent = space.name;
    modal.querySelector('.space-type').textContent = formatSpaceType(space.space_type);
    modal.querySelector('.square-footage').textContent = `${space.square_footage} sq ft`;
    modal.querySelector('.acoustics').textContent = `${space.acoustics_rating}/10`;
    modal.querySelector('.lighting').textContent = space.lighting_details.natural_light ? 'Natural' : 'Artificial';
    modal.querySelector('.rate').textContent = formatPrice(space.pricing_terms);
    
    // Equipment list
    const equipmentList = modal.querySelector('.equipment-list ul');
    equipmentList.innerHTML = '';
    space.equipment_list.forEach(item => {
        const li = document.createElement('li');
        li.textContent = item;
        equipmentList.appendChild(li);
    });
    
    // Show modal
    modal.hidden = false;
}

document.querySelector('.close-modal').addEventListener('click', () => {
    modal.hidden = true;
});

// Initialize swipe buttons
document.querySelector('.swipe-btn.pass').addEventListener('click', handlePass);
document.querySelector('.swipe-btn.like').addEventListener('click', handleLike);

// Handle card clicks for details
cardStack.addEventListener('click', (e) => {
    if (e.target.closest('.space-card')) {
        showSpaceDetails(spaces[currentSpaceIndex]);
    }
}); 