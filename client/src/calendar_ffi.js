// Get current year and month
export function getCurrentDate() {
  const now = new Date();
  return [now.getFullYear(), now.getMonth() + 1];
}

// Get day number from date string (YYYY-MM-DD)
export function getDayNumber(dateStr) {
  return new Date(dateStr).getDate();
}

// Get weekday (1-7, Monday-Sunday) from date string
export function getWeekday(dateStr) {
  const day = new Date(dateStr).getDay();
  // Convert Sunday (0) to 7, shift all days to make Monday (1)
  return day === 0 ? 7 : day;
}

// Get days data for a month
export function getMonthData(year, month) {
  const firstDay = new Date(year, month - 1, 1);
  const lastDay = new Date(year, month, 0);
  const today = new Date();
  
  // Get days from previous month to fill first week
  const firstWeekday = firstDay.getDay() || 7; // Convert Sunday (0) to 7
  const prevMonthDays = firstWeekday - 1;
  
  const daysInMonth = lastDay.getDate();
  const days = [];
  
  // Add days from previous month
  const prevMonth = month === 1 ? 12 : month - 1;
  const prevYear = month === 1 ? year - 1 : year;
  const prevMonthLastDay = new Date(prevYear, prevMonth, 0).getDate();
  
  for (let i = prevMonthDays - 1; i >= 0; i--) {
    const day = prevMonthLastDay - i;
    const date = `${prevYear}-${String(prevMonth).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
    days.push({
      date,
      is_today: false,
      is_current_month: false,
      events: [],
      reminders: []
    });
  }
  
  // Add days from current month
  for (let day = 1; day <= daysInMonth; day++) {
    const date = `${year}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
    days.push({
      date,
      is_today: today.getFullYear() === year && 
                today.getMonth() === month - 1 && 
                today.getDate() === day,
      is_current_month: true,
      events: [],
      reminders: []
    });
  }
  
  // Add days from next month to complete the grid
  const remainingDays = 42 - days.length; // Always show 6 weeks
  const nextMonth = month === 12 ? 1 : month + 1;
  const nextYear = month === 12 ? year + 1 : year;
  
  for (let day = 1; day <= remainingDays; day++) {
    const date = `${nextYear}-${String(nextMonth).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
    days.push({
      date,
      is_today: false,
      is_current_month: false,
      events: [],
      reminders: []
    });
  }
  
  return days;
}

// Generate a unique ID
export function generateId() {
  return 'meeting_' + Math.random().toString(36).substr(2, 9);
}

// Get user's timezone
export function getTimezone() {
  return Intl.DateTimeFormat().resolvedOptions().timeZone;
}

// Format date for display (e.g., "March 21, 2024")
export function formatDate(dateStr) {
  return new Date(dateStr).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  });
}

// Format time for display (e.g., "2:30 PM")
export function formatTime(timeStr) {
  const [hours, minutes] = timeStr.split(':');
  return new Date(0, 0, 0, hours, minutes).toLocaleTimeString('en-US', {
    hour: 'numeric',
    minute: '2-digit',
    hour12: true
  });
}

// Format time from hour and minute
export function formatTimeFromParts(hour, minute) {
  return `${hour.toString().padStart(2, '0')}:${minute.toString().padStart(2, '0')}`;
}

// Convert time to EST
export function convertToEst(dateStr, timeStr) {
  const [hours, minutes] = timeStr.split(':');
  const date = new Date(dateStr);
  date.setHours(hours, minutes);
  
  const estTime = new Date(date.toLocaleString('en-US', { timeZone: 'America/New_York' }));
  return estTime.toLocaleTimeString('en-US', {
    hour: 'numeric',
    minute: '2-digit',
    hour12: true,
    timeZone: 'America/New_York'
  });
}

// Schedule meeting and send emails
export function scheduleMeeting(meeting) {
  // Send meeting details to server
  fetch('/api/schedule-meeting', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(meeting)
  })
  .then(response => response.json())
  .then(data => {
    console.log('Meeting scheduled:', data);
  })
  .catch(error => {
    console.error('Error scheduling meeting:', error);
  });
  
  return { type: 'none' }; // Return Effect.none()
}

// Get form data helper
export function getFormData(form) {
  const formData = new FormData(form);
  return Object.fromEntries(formData.entries());
} 