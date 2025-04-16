// Generate unique IDs for setlists
export function generateId() {
  return 'setlist-' + Math.random().toString(36).substring(2, 15);
}

// Get the current timestamp in ISO format
export function getCurrentTimestamp() {
  return new Date().toISOString();
}