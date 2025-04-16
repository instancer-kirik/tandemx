/**
 * Setlist Sharing FFI Functions
 * 
 * This file provides JavaScript functions for the setlist sharing functionality:
 * - Generating shareable links
 * - Exporting setlists in various formats
 * - Sharing via email and other channels
 * - QR code generation
 * - Clipboard operations
 */

// Generate a shareable link for a setlist
export function generateShareLink(setlistId) {
  // In a real implementation, this would create a unique URL with the server
  // For now, we'll generate a demo link
  const baseUrl = window.location.origin;
  const shareId = Math.random().toString(36).substring(2, 15);
  return `${baseUrl}/share/setlist/${setlistId}/${shareId}`;
}

// Export a setlist to a specified format
export function exportSetlist(setlistId, format) {
  // In a real implementation, this would call a server endpoint or use
  // client-side libraries to generate the file in the specified format
  console.log(`Exporting setlist ${setlistId} in ${format} format`);
  
  // Mock implementation - returns a fake file path
  return `/exports/setlist_${setlistId}.${format}`;
}

// Share a setlist via email
export function shareViaEmail(setlistId, email) {
  // In a real implementation, this would use the Web Share API or call a server endpoint
  console.log(`Sharing setlist ${setlistId} via email to ${email}`);
  
  // Mock implementation - always returns success
  return true;
}

// Generate a QR code for a link
export function generateQRCode(link) {
  // In a real implementation, this would use a QR code library like qrcode.js
  console.log(`Generating QR code for link: ${link}`);
  
  // Mock implementation - returns a fake data URI
  return "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAUA...";
}

// Copy text to clipboard
export function copyToClipboard(text) {
  // Try to use the Clipboard API if available
  if (navigator.clipboard && navigator.clipboard.writeText) {
    navigator.clipboard.writeText(text)
      .then(() => {
        console.log('Text copied to clipboard');
        // Show a notification to the user
        showNotification('Copied to clipboard!');
        return true;
      })
      .catch(err => {
        console.error('Failed to copy text: ', err);
        return false;
      });
  } else {
    // Fallback method for older browsers
    try {
      const textArea = document.createElement('textarea');
      textArea.value = text;
      
      // Make the textarea out of viewport
      textArea.style.position = 'fixed';
      textArea.style.left = '-999999px';
      textArea.style.top = '-999999px';
      document.body.appendChild(textArea);
      
      textArea.focus();
      textArea.select();
      
      const successful = document.execCommand('copy');
      document.body.removeChild(textArea);
      
      if (successful) {
        showNotification('Copied to clipboard!');
      }
      
      return successful;
    } catch (err) {
      console.error('Fallback: Could not copy text: ', err);
      return false;
    }
  }
  
  return false;
}

// Helper function to show a notification
function showNotification(message, duration = 2000) {
  const notification = document.createElement('div');
  notification.className = 'setlist-notification';
  notification.textContent = message;
  
  // Style the notification
  notification.style.position = 'fixed';
  notification.style.bottom = '20px';
  notification.style.right = '20px';
  notification.style.backgroundColor = '#4a86e8';
  notification.style.color = 'white';
  notification.style.padding = '10px 20px';
  notification.style.borderRadius = '4px';
  notification.style.boxShadow = '0 2px 10px rgba(0,0,0,0.2)';
  notification.style.zIndex = '9999';
  notification.style.transition = 'opacity 0.3s ease-in-out';
  
  document.body.appendChild(notification);
  
  // Remove the notification after the specified duration
  setTimeout(() => {
    notification.style.opacity = '0';
    setTimeout(() => {
      document.body.removeChild(notification);
    }, 300);
  }, duration);
} 