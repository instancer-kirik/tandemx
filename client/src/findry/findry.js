// WebSocket connection
let ws = null;

// Store state
let spaces = new Map();
let artists = new Map();
let matches = new Map();
let currentSpaceIndex = 0;
let isDragging = false;
let startX = 0;
let currentX = 0;
let currentView = 'spaces'; // 'spaces', 'artists', or 'matches'
let viewMode = 'card'; // 'card' or 'list'

function connectWebSocket() {
  ws = new WebSocket('ws://0.0.0.0:8000/ws/findry');
  
  ws.onopen = () => {
    console.log('Connected to Findry WebSocket');
    // Request initial state
    ws.send('init');
  };
  
  ws.onmessage = (event) => {
    const message = event.data;
    handleMessage(message);
  };
  
  ws.onerror = (error) => {
    console.error('WebSocket error:', error);
  };
  
  ws.onclose = () => {
    console.log('WebSocket connection closed');
    // Attempt to reconnect after 5 seconds
    setTimeout(connectWebSocket, 5000);
  };
}

function handleMessage(message) {
  const [type, ...params] = message.split(':');
  
  switch(type) {
    case 'space_added':
      const [spaceId, name] = params;
      spaces.set(spaceId, { id: spaceId, name });
      updateSpacesUI();
      updateSpacesListUI();
      break;
      
    case 'space_deleted':
      const deletedSpaceId = params[0];
      spaces.delete(deletedSpaceId);
      updateSpacesUI();
      updateSpacesListUI();
      break;
      
    case 'artist_added':
      const [artistId, artistName] = params;
      artists.set(artistId, { id: artistId, name: artistName });
      updateArtistsUI();
      break;
      
    case 'artist_deleted':
      const deletedArtistId = params[0];
      artists.delete(deletedArtistId);
      updateArtistsUI();
      break;
      
    case 'swipe_right':
    case 'swipe_left':
      const [swipingArtistId, swipedSpaceId] = params;
      updateSwipeUI(type, swipingArtistId, swipedSpaceId);
      break;
      
    case 'booking_request':
      const [bookingArtistId, bookingSpaceId, startTime, endTime] = params;
      showBookingRequest(bookingArtistId, bookingSpaceId, startTime, endTime);
      break;
  }
}

function updateSpacesUI() {
  const cardStack = document.querySelector('.card-stack');
  if (!cardStack) return;

  // Clear existing cards
  cardStack.innerHTML = '';

  // Get current space
  const spacesArray = Array.from(spaces.values());
  if (currentSpaceIndex >= spacesArray.length) {
    showEmptyState(cardStack);
    return;
  }

  const space = spacesArray[currentSpaceIndex];
  const card = createSpaceCard(space);
  cardStack.appendChild(card);
  initializeSwipeListeners(card);
}

function updateSpacesListUI() {
  const spacesList = document.querySelector('.spaces-list');
  if (!spacesList) return;

  // Clear existing list items
  spacesList.innerHTML = '';

  // Add all spaces to the list
  const spacesArray = Array.from(spaces.values());
  if (spacesArray.length === 0) {
    spacesList.innerHTML = '<p class="empty-message">No spaces available</p>';
    return;
  }

  spacesArray.forEach(space => {
    const listItem = createSpaceListItem(space);
    spacesList.appendChild(listItem);
  });
}

function createSpaceListItem(space) {
  const template = document.querySelector('#space-list-item-template');
  if (!template) {
    console.error('Space list item template not found');
    return document.createElement('div');
  }
  
  const listItem = template.content.cloneNode(true);
  
  // Set content
  const nameElement = listItem.querySelector('.space-name');
  if (nameElement) nameElement.textContent = space.name || 'Unnamed Space';
  
  const typeElement = listItem.querySelector('.space-type');
  if (typeElement) typeElement.textContent = formatSpaceType(space.space_type);
  
  // Add photo if available
  const photoContainer = listItem.querySelector('.space-list-photo');
  if (photoContainer && space.photos && space.photos.length > 0) {
    const img = document.createElement('img');
    img.src = space.photos[0];
    img.alt = space.name || 'Space photo';
    img.className = 'space-photo';
    photoContainer.appendChild(img);
  } else if (photoContainer) {
    // Add placeholder image
    photoContainer.innerHTML = '<div class="photo-placeholder"></div>';
  }
  
  // Add price
  const priceElement = listItem.querySelector('.space-price');
  if (priceElement && space.pricing_terms) {
    priceElement.textContent = formatPrice(space.pricing_terms);
  }
  
  // Add features
  const featuresContainer = listItem.querySelector('.space-features');
  if (featuresContainer) {
    addFeatureTags(featuresContainer, space);
  }
  
  // Add event listeners to buttons
  const viewDetailsBtn = listItem.querySelector('.view-details-btn');
  if (viewDetailsBtn) {
    viewDetailsBtn.addEventListener('click', () => {
      showSpaceDetails(space);
    });
  }
  
  const likeBtn = listItem.querySelector('.like-btn');
  if (likeBtn) {
    likeBtn.addEventListener('click', () => {
      if (ws && ws.readyState === WebSocket.OPEN) {
        ws.send(`swipe_right:current-user:${space.id}`);
        showNotification('Liked!', 'success');
      }
    });
  }
  
  return listItem.firstElementChild;
}

function showSpaceDetails(space) {
  // Create a modal to show space details
  const modal = document.createElement('div');
  modal.className = 'modal';
  modal.innerHTML = `
    <div class="modal-content">
      <span class="close-modal">&times;</span>
      <h2>${space.name || 'Unnamed Space'}</h2>
      <p class="space-type">${formatSpaceType(space.space_type)}</p>
      ${space.photos && space.photos.length > 0 ? 
        `<div class="space-photos">
          ${space.photos.map(photo => `<img src="${photo}" alt="${space.name}">`).join('')}
        </div>` : ''}
      <div class="space-details">
        ${space.square_footage ? `<p>Square Footage: ${space.square_footage} sq ft</p>` : ''}
        ${space.pricing_terms ? `<p>Price: ${formatPrice(space.pricing_terms)}</p>` : ''}
        ${space.acoustics_rating ? `<p>Acoustics Rating: ${space.acoustics_rating}/10</p>` : ''}
      </div>
      <div class="space-features">
        <h3>Features</h3>
        <div class="features-container"></div>
      </div>
      <div class="space-actions">
        <button class="like-space-btn">Like This Space</button>
      </div>
    </div>
  `;
  
  document.body.appendChild(modal);
  
  // Add features
  const featuresContainer = modal.querySelector('.features-container');
  if (featuresContainer) {
    addFeatureTags(featuresContainer, space);
  }
  
  // Add event listeners
  const closeBtn = modal.querySelector('.close-modal');
  if (closeBtn) {
    closeBtn.addEventListener('click', () => {
      modal.remove();
    });
  }
  
  const likeBtn = modal.querySelector('.like-space-btn');
  if (likeBtn) {
    likeBtn.addEventListener('click', () => {
      if (ws && ws.readyState === WebSocket.OPEN) {
        ws.send(`swipe_right:current-user:${space.id}`);
        showNotification('Liked!', 'success');
        modal.remove();
      }
    });
  }
  
  // Close modal when clicking outside
  modal.addEventListener('click', (e) => {
    if (e.target === modal) {
      modal.remove();
    }
  });
}

function createSpaceCard(space) {
  const template = document.querySelector('#space-card-template');
  if (!template) {
    console.error('Space card template not found');
    return document.createElement('div');
  }
  
  const card = template.content.cloneNode(true);
  
  // Set card content
  const nameElement = card.querySelector('.space-name');
  if (nameElement) nameElement.textContent = space.name || 'Unnamed Space';
  
  const typeElement = card.querySelector('.space-type');
  if (typeElement) typeElement.textContent = formatSpaceType(space.space_type);
  
  // Add photo if available
  const photosContainer = card.querySelector('.card-photos');
  if (photosContainer && space.photos && space.photos.length > 0) {
    const img = document.createElement('img');
    img.src = space.photos[0];
    img.alt = space.name || 'Space photo';
    img.className = 'space-photo';
    photosContainer.appendChild(img);
  } else if (photosContainer) {
    // Add placeholder image
    photosContainer.innerHTML = '<div class="photo-placeholder"></div>';
  }
  
  // Add price
  const priceElement = card.querySelector('.space-price');
  if (priceElement && space.pricing_terms) {
    priceElement.textContent = formatPrice(space.pricing_terms);
  }
  
  // Add features
  const featuresContainer = card.querySelector('.space-features');
  if (featuresContainer) {
    addFeatureTags(featuresContainer, space);
  }
  
  return card.firstElementChild;
}

function showEmptyState(container) {
  const template = document.querySelector('#empty-state-template');
  if (template) {
    container.appendChild(template.content.cloneNode(true));
  } else {
    // Create a fallback empty state if template doesn't exist
    const emptyState = document.createElement('div');
    emptyState.className = 'empty-state';
    emptyState.innerHTML = `
      <h3>No More Spaces</h3>
      <p>Try adjusting your filters to see more spaces</p>
    `;
    container.appendChild(emptyState);
  }
}

function initializeSwipeListeners(card) {
  // Touch events
  card.addEventListener('touchstart', handleTouchStart);
  card.addEventListener('touchmove', handleTouchMove);
  card.addEventListener('touchend', handleTouchEnd);
  
  // Mouse events
  card.addEventListener('mousedown', handleMouseDown);
  document.addEventListener('mousemove', handleMouseMove);
  document.addEventListener('mouseup', handleMouseUp);
}

function handleTouchStart(e) {
  startX = e.touches[0].clientX;
  isDragging = true;
  this.classList.add('swiping');
}

function handleMouseDown(e) {
  startX = e.clientX;
  isDragging = true;
  this.classList.add('swiping');
}

function handleTouchMove(e) {
  if (!isDragging) return;
  e.preventDefault();
  currentX = e.touches[0].clientX - startX;
  updateCardPosition(this, currentX);
}

function handleMouseMove(e) {
  if (!isDragging) return;
  currentX = e.clientX - startX;
  const card = document.querySelector('.space-card');
  if (card) {
    updateCardPosition(card, currentX);
  }
}

function handleTouchEnd() {
  handleSwipeEnd(this);
}

function handleMouseUp() {
  const card = document.querySelector('.space-card');
  if (card) {
    handleSwipeEnd(card);
  }
}

function updateCardPosition(card, offset) {
  const rotate = offset * 0.1;
  const opacity = Math.max(1 - Math.abs(offset) / 500, 0);
  card.style.transform = `translateX(${offset}px) rotate(${rotate}deg)`;
  card.style.opacity = opacity;
}

function handleSwipeEnd(card) {
  if (!isDragging) return;
  isDragging = false;
  card.classList.remove('swiping');
  
  const threshold = window.innerWidth * 0.3;
  if (Math.abs(currentX) > threshold) {
    if (currentX > 0) {
      card.classList.add('swipe-right');
      handleSwipeRight();
    } else {
      card.classList.add('swipe-left');
      handleSwipeLeft();
    }
    
    // Show next card after animation
    setTimeout(() => {
      currentSpaceIndex++;
      updateSpacesUI();
    }, 300);
  } else {
    // Reset position
    card.style.transform = '';
    card.style.opacity = '';
  }
  
  currentX = 0;
  startX = 0;
}

function handleSwipeRight() {
  const spacesArray = Array.from(spaces.values());
  const space = spacesArray[currentSpaceIndex];
  if (space && ws && ws.readyState === WebSocket.OPEN) {
    ws.send(`swipe_right:current-user:${space.id}`);
    showNotification('Liked!', 'success');
  }
}

function handleSwipeLeft() {
  const spacesArray = Array.from(spaces.values());
  const space = spacesArray[currentSpaceIndex];
  if (space && ws && ws.readyState === WebSocket.OPEN) {
    ws.send(`swipe_left:current-user:${space.id}`);
    showNotification('Passed', 'info');
  }
}

function showNotification(message, type = 'info') {
  const notification = document.createElement('div');
  notification.className = `notification ${type}`;
  notification.textContent = message;
  document.body.appendChild(notification);
  
  setTimeout(() => {
    notification.classList.add('fade-out');
    setTimeout(() => notification.remove(), 300);
  }, 2000);
}

function formatSpaceType(type) {
  if (!type) return 'Unknown';
  return type.toLowerCase().split('_').map(word => 
    word.charAt(0).toUpperCase() + word.slice(1)
  ).join(' ');
}

function formatPrice(pricing) {
  if (!pricing || typeof pricing.hourly_rate === 'undefined') {
    return 'Price unavailable';
  }
  return `$${pricing.hourly_rate}/hour`;
}

function addFeatureTags(container, space) {
  if (space.acoustics_rating > 7) {
    addTag(container, '🎵', 'Great Acoustics');
  }
  if (space.lighting_details?.natural_light) {
    addTag(container, '☀️', 'Natural Light');
  }
  if (space.equipment_list?.length > 0) {
    addTag(container, '🛠️', 'Equipped');
  }
  if (space.location_data?.parking_available) {
    addTag(container, '🅿️', 'Parking');
  }
}

function addTag(container, icon, text) {
  const tag = document.createElement('div');
  tag.className = 'feature-tag';
  tag.innerHTML = `${icon} ${text}`;
  container.appendChild(tag);
}

function updateArtistsUI() {
  const artistsList = document.querySelector('.artists-list');
  if (!artistsList) return;

  // Clear existing list items
  artistsList.innerHTML = '';

  // Add all artists to the list
  const artistsArray = Array.from(artists.values());
  if (artistsArray.length === 0) {
    artistsList.innerHTML = '<p class="empty-message">No artists available</p>';
    return;
  }

  artistsArray.forEach(artist => {
    const listItem = createArtistListItem(artist);
    artistsList.appendChild(listItem);
  });
}

function createArtistListItem(artist) {
  const template = document.querySelector('#artist-list-item-template');
  if (!template) {
    console.error('Artist list item template not found');
    return document.createElement('div');
  }
  
  const listItem = template.content.cloneNode(true);
  
  // Set content
  const nameElement = listItem.querySelector('.artist-name');
  if (nameElement) nameElement.textContent = artist.name || 'Unnamed Artist';
  
  // Add placeholder photo if no photo available
  const photoContainer = listItem.querySelector('.artist-list-photo');
  if (photoContainer) {
    photoContainer.innerHTML = '<div class="photo-placeholder"></div>';
  }
  
  // Add event listeners to buttons
  const viewProfileBtn = listItem.querySelector('.view-profile-btn');
  if (viewProfileBtn) {
    viewProfileBtn.addEventListener('click', () => {
      showArtistProfile(artist);
    });
  }
  
  return listItem.firstElementChild;
}

function showArtistProfile(artist) {
  // Create a modal to show artist profile
  const modal = document.createElement('div');
  modal.className = 'modal';
  modal.innerHTML = `
    <div class="modal-content">
      <span class="close-modal">&times;</span>
      <h2>${artist.name || 'Unnamed Artist'}</h2>
      <div class="artist-details">
        <p>ID: ${artist.id}</p>
      </div>
    </div>
  `;
  
  document.body.appendChild(modal);
  
  // Add event listeners
  const closeBtn = modal.querySelector('.close-modal');
  if (closeBtn) {
    closeBtn.addEventListener('click', () => {
      modal.remove();
    });
  }
  
  // Close modal when clicking outside
  modal.addEventListener('click', (e) => {
    if (e.target === modal) {
      modal.remove();
    }
  });
}

function updateSwipeUI(type, artistId, spaceId) {
  const space = spaces.get(spaceId);
  const artist = artists.get(artistId);
  if (!space || !artist) return;

  const message = type === 'swipe_right' 
    ? `${artist.name} liked ${space.name}!`
    : `${artist.name} passed on ${space.name}`;
    
  // Show a temporary notification
  const notification = document.createElement('div');
  notification.className = 'swipe-notification';
  notification.textContent = message;
  document.body.appendChild(notification);
  setTimeout(() => notification.remove(), 3000);
}

function showBookingRequest(artistId, spaceId, startTime, endTime) {
  const space = spaces.get(spaceId);
  const artist = artists.get(artistId);
  if (!space || !artist) return;

  const notification = document.createElement('div');
  notification.className = 'booking-notification';
  notification.innerHTML = `
    <h3>New Booking Request</h3>
    <p>${artist.name} wants to book ${space.name}</p>
    <p>From: ${startTime}</p>
    <p>To: ${endTime}</p>
  `;
  document.body.appendChild(notification);
  setTimeout(() => notification.remove(), 5000);
}

function toggleView(viewName) {
  currentView = viewName;
  
  // Update nav links
  const navLinks = document.querySelectorAll('.nav-link');
  navLinks.forEach(link => {
    link.classList.toggle('active', link.dataset.view === viewName);
  });
  
  // Update view sections
  const viewSections = document.querySelectorAll('.view-section');
  viewSections.forEach(section => {
    const isActive = section.classList.contains(`${viewName}-list-container`);
    section.classList.toggle('active', isActive);
  });
  
  // Update UI based on current view
  if (viewName === 'spaces') {
    updateSpacesUI();
    updateSpacesListUI();
  } else if (viewName === 'artists') {
    updateArtistsUI();
  } else if (viewName === 'matches') {
    // TODO: Implement matches UI
  }
}

function toggleViewMode(mode) {
  viewMode = mode;
  
  // Update toggle buttons
  const toggleBtns = document.querySelectorAll('.toggle-btn');
  toggleBtns.forEach(btn => {
    btn.classList.toggle('active', btn.dataset.mode === mode);
  });
  
  // Update view containers
  const cardView = document.querySelector('.card-view');
  const listView = document.querySelector('.list-view');
  
  if (cardView) cardView.classList.toggle('active', mode === 'card');
  if (listView) listView.classList.toggle('active', mode === 'list');
}

// Initialize
document.addEventListener('DOMContentLoaded', () => {
  // Connect WebSocket
  connectWebSocket();
  
  // Add click handlers for swipe buttons
  const passButton = document.querySelector('.swipe-btn.pass');
  if (passButton) {
    passButton.addEventListener('click', () => {
      const card = document.querySelector('.space-card');
      if (card) {
        card.classList.add('swipe-left');
        handleSwipeLeft();
        setTimeout(() => {
          currentSpaceIndex++;
          updateSpacesUI();
        }, 300);
      }
    });
  }
  
  const likeButton = document.querySelector('.swipe-btn.like');
  if (likeButton) {
    likeButton.addEventListener('click', () => {
      const card = document.querySelector('.space-card');
      if (card) {
        card.classList.add('swipe-right');
        handleSwipeRight();
        setTimeout(() => {
          currentSpaceIndex++;
          updateSpacesUI();
        }, 300);
      }
    });
  }
  
  // Initialize range slider value display
  const acousticsSlider = document.querySelector('#acoustics');
  const rangeValue = document.querySelector('.range-value');
  if (acousticsSlider && rangeValue) {
    rangeValue.textContent = acousticsSlider.value;
    acousticsSlider.addEventListener('input', (e) => {
      rangeValue.textContent = e.target.value;
    });
  }
  
  // Add event listeners for nav links
  const navLinks = document.querySelectorAll('.nav-link');
  navLinks.forEach(link => {
    link.addEventListener('click', (e) => {
      e.preventDefault();
      const viewName = link.dataset.view;
      if (viewName) {
        toggleView(viewName);
      }
    });
  });
  
  // Add event listeners for view toggle buttons
  const toggleBtns = document.querySelectorAll('.toggle-btn');
  toggleBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      const mode = btn.dataset.mode;
      if (mode) {
        toggleViewMode(mode);
      }
    });
  });
  
  // Initialize with default view
  toggleView('spaces');
  toggleViewMode('card');
}); 