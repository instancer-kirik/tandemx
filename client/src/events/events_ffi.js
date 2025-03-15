// Get the WebSocket URL for real-time updates
export function getWebSocketUrl() {
  const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
  return `${protocol}//${window.location.host}/events/ws`;
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
export function shareEvent(eventId, platform) {
  const eventUrl = `${window.location.origin}/events/${eventId}`;
  const eventTitle = document.querySelector('.event-title h1')?.textContent || 'Check out this event!';
  
  let shareUrl;
  switch (platform) {
    case 'facebook':
      shareUrl = `https://www.facebook.com/sharer/sharer.php?u=${encodeURIComponent(eventUrl)}`;
      break;
    case 'twitter':
      shareUrl = `https://twitter.com/intent/tweet?url=${encodeURIComponent(eventUrl)}&text=${encodeURIComponent(eventTitle)}`;
      break;
    case 'instagram':
      // Instagram doesn't support direct sharing via URL
      // You might want to implement a different sharing mechanism
      console.log('Instagram sharing not supported');
      return;
    case 'email':
      shareUrl = `mailto:?subject=${encodeURIComponent(eventTitle)}&body=${encodeURIComponent(`Check out this event: ${eventUrl}`)}`;
      break;
    default:
      console.error('Unsupported sharing platform');
      return;
  }

  if (shareUrl) {
    window.open(shareUrl, '_blank', 'width=600,height=400');
  }
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

// Log when the module is loaded
console.log('Events FFI module loaded'); 