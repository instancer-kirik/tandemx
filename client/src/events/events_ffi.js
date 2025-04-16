// Get the WebSocket URL for real-time updates
export function getWebSocketUrl() {
  const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
  const host = window.location.hostname === '0.0.0.0' ? 'localhost' : window.location.hostname;
  return `${protocol}//${host}:${window.location.port}/ws/events`;
}

// Dispatch messages to the Gleam application
export function dispatch(msg) {
  window.dispatchEvent(new CustomEvent('gleam-msg', { detail: msg }));
}

// Get the current window width for responsive design
export function getWindowWidth() {
  return window.innerWidth;
}

// Handle form input changes
export function onInput(handler) {
  return {
    onInput: (event) => {
      handler({
        target: {
          value: event.target.value,
          checked: event.target.checked,
        },
      });
    },
  };
}

// Handle form change events
export function onChange(handler) {
  return {
    onChange: (event) => {
      handler({
        target: {
          value: event.target.value,
          checked: event.target.checked,
        },
      });
    },
  };
}

// Handle click events
export function onClick(handler) {
  return {
    onClick: (event) => {
      handler(event);
    },
  };
}

// Share event on social media
export function shareEvent(event) {
  console.log('Events FFI: Sharing event', event);
  
  // Check if the Web Share API is available
  if (navigator.share) {
    navigator.share({
      title: event.title,
      text: event.description,
      url: window.location.origin + '/events/' + event.id,
    })
    .then(() => console.log('Successfully shared event'))
    .catch((error) => console.error('Error sharing event:', error));
  } else {
    // Fallback for browsers that don't support the Web Share API
    // Copy the event URL to clipboard
    const eventUrl = window.location.origin + '/events/' + event.id;
    navigator.clipboard.writeText(eventUrl)
      .then(() => {
        // Show a toast notification
        if (window.showToast) {
          window.showToast('Event link copied to clipboard!', 'success');
        } else {
          alert('Event link copied to clipboard!');
        }
      })
      .catch((error) => {
        console.error('Error copying to clipboard:', error);
        if (window.showToast) {
          window.showToast('Failed to copy event link', 'error');
        } else {
          alert('Failed to copy event link');
        }
      });
  }
  
  return true;
}

// Copy event link to clipboard
export function copyEventLink(eventId) {
  const eventUrl = `${window.location.origin}/events/${eventId}`;
  navigator.clipboard.writeText(eventUrl)
    .then(() => {
      // Show success message
      const toast = document.createElement('div');
      toast.className = 'toast';
      toast.textContent = 'Link copied to clipboard!';
      document.body.appendChild(toast);
      setTimeout(() => toast.remove(), 3000);
    })
    .catch(err => {
      console.error('Failed to copy link:', err);
    });
}

// Handle date range selection
export function handleDateRangeChange(startDate, endDate) {
  // This would typically update the UI and filter events based on the selected date range
  console.log('Date range changed:', { startDate, endDate });
}

// Handle event selection for sharing
export function handleEventSelection(eventId, selected) {
  // This would typically update the UI to show which events are selected for sharing
  console.log('Event selection changed:', { eventId, selected });
}

// Handle visibility option change
export function handleVisibilityChange(visibility) {
  // This would typically update the UI to reflect the selected visibility option
  console.log('Visibility changed:', visibility);
}

// Handle schedule sharing
export function handleScheduleShare(schedule) {
  // This would typically send the schedule to the server and handle the response
  console.log('Sharing schedule:', schedule);
}

// Handle navigation to events page
export function navigateToEvents() {
  window.history.pushState({}, '', '/events');
  
  // Dispatch a navigation event
  window.dispatchEvent(new CustomEvent('gleam-msg', { 
    detail: { type: 'Navigate', data: '/events' }
  }));
}

// Initialize the events module
export function init() {
  // Set up WebSocket connection
  try {
    const ws = new WebSocket(getWebSocketUrl());
    
    ws.onmessage = (event) => {
      dispatch(event.data);
    };

    ws.onerror = (error) => {
      console.error('WebSocket error:', error);
    };

    ws.onclose = () => {
      console.log('WebSocket connection closed');
    };

    // Set up event listeners for UI interactions
    document.addEventListener('DOMContentLoaded', () => {
      // Initialize any necessary UI components
      console.log('Events module initialized');
      
      // Add event listener for the "Discover Events" button on the home page
      document.addEventListener('click', (event) => {
        if (event.target.closest('.home-action-button')) {
          event.preventDefault();
          navigateToEvents();
        }
      });
    });
    
    return true;
  } catch (error) {
    console.error('Failed to initialize events module:', error);
    return false;
  }
}

// Initialize the map for event locations
export function initMap() {
  console.log('Events FFI: Initializing map');
  
  // Check if the map container exists
  const mapContainer = document.getElementById('map-container');
  if (!mapContainer) {
    console.error('Map container not found');
    return false;
  }
  
  // In a real implementation, this would initialize a map library like Leaflet or Google Maps
  // For now, we'll just add a placeholder
  mapContainer.innerHTML = '<div style="width: 100%; height: 100%; display: flex; align-items: center; justify-content: center; background-color: #f0f0f0;"><p>Map would be displayed here</p></div>';
  
  return true;
}

// Show an event location on the map
export function showEventLocation(lat, lng, title) {
  console.log(`Events FFI: Showing event location - ${title} at ${lat}, ${lng}`);
  
  // Check if the map container exists
  const mapContainer = document.getElementById('map-container');
  if (!mapContainer) {
    console.error('Map container not found');
    return false;
  }
  
  // Make the map container visible
  mapContainer.style.display = 'block';
  
  // In a real implementation, this would center the map on the event location
  // For now, we'll just update the placeholder
  mapContainer.innerHTML = `<div style="width: 100%; height: 100%; display: flex; align-items: center; justify-content: center; background-color: #f0f0f0;"><p>Map showing: ${title} at ${lat}, ${lng}</p></div>`;
  
  return true;
}

// Hide the map
export function hideMap() {
  console.log('Events FFI: Hiding map');
  
  // Check if the map container exists
  const mapContainer = document.getElementById('map-container');
  if (!mapContainer) {
    console.error('Map container not found');
    return false;
  }
  
  // Hide the map container
  mapContainer.style.display = 'none';
  
  return true;
}

// Generate a shareable calendar link
export function generateCalendarLink(events) {
  console.log('Events FFI: Generating calendar link for events', events);
  
  // In a real implementation, this would generate an iCal file or a link to a calendar service
  // For now, we'll just return a dummy link
  const calendarLink = window.location.origin + '/events/calendar?shared=true&events=' + events.map(e => e.id).join(',');
  
  return calendarLink;
}

// Initialize the module
console.log('Events FFI module loaded'); 