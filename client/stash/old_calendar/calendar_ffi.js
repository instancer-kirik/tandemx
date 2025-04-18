import { toList } from "./gleam.mjs";
import * as mayanCalendar from './mayan_calendar.js';
import * as calendarTranslation from './calendar_translation.js';

// Current calendar system (can be changed by user)
let currentCalendarSystem = calendarTranslation.CALENDAR_SYSTEMS.MAYAN; // Default to Mayan

/**
 * Get the current calendar system
 * @returns {String} Current calendar system identifier
 */
export function getCurrentCalendarSystem() {
  return currentCalendarSystem;
}

/**
 * Set the current calendar system
 * @param {String} system - Calendar system to use
 * @returns {Boolean} Success status
 */
export function setCalendarSystem(system) {
  if (Object.values(calendarTranslation.CALENDAR_SYSTEMS).includes(system)) {
    currentCalendarSystem = system;
    return true;
  }
  return false;
}

/**
 * Get date in the current calendar system
 * @param {Date} date - JavaScript Date object
 * @returns {Object} Date in the current calendar system
 */
export function getDateInCurrentSystem(date) {
  return calendarTranslation.fromGregorian(date, currentCalendarSystem);
}

/**
 * Format date in the current calendar system
 * @param {Date} date - JavaScript Date object
 * @param {Object} options - Formatting options
 * @returns {String} Formatted date string
 */
export function formatDateInCurrentSystem(date, options = {}) {
  return calendarTranslation.formatDate(date, currentCalendarSystem, options);
}

/**
 * Get Mayan date information for a specific date
 * @param {String} dateStr - Date string in YYYY-MM-DD format
 * @returns {Object} Mayan date information
 */
export function getMayanDate(dateStr) {
  const date = new Date(dateStr);
  return mayanCalendar.gregorianToMayan(date);
}

/**
 * Get a list of all calendar systems for a specific date
 * @param {String} dateStr - Date string in YYYY-MM-DD format
 * @returns {Object} Date information in all calendar systems
 */
export function getAllCalendarSystems(dateStr) {
  const date = new Date(dateStr);
  return calendarTranslation.getAllCalendarSystems(date);
}

/**
 * Get the Mayan day glyph for a specific date
 * @param {String} dateStr - Date string in YYYY-MM-DD format
 * @returns {String} Mayan day glyph
 */
export function getMayanDayGlyph(dateStr) {
  const date = new Date(dateStr);
  return mayanCalendar.getDayGlyph(date);
}

/**
 * Get energies for all days in a month in the Mayan calendar
 * @param {Number} year - Gregorian year
 * @param {Number} month - Gregorian month (1-12)
 * @returns {Array} Array of daily Mayan energies for the month
 */
export function getMayanMonthEnergies(year, month) {
  return mayanCalendar.getMonthMayanEnergies(year, month);
}

/**
 * Initialize the calendar with Mayan support
 * This attaches Mayan date information to each day cell
 */
export function initMayanCalendar() {
  // Get all day cells
  const dayCells = document.querySelectorAll('.day');
  
  dayCells.forEach(cell => {
    const dateStr = cell.getAttribute('data-date');
    if (dateStr) {
      // Get Mayan date information
      const mayanDate = getMayanDate(dateStr);
      
      // Create Mayan date info elements
      const mayanInfo = document.createElement('div');
      mayanInfo.className = 'mayan-day-info';
      
      const tzolkin = document.createElement('div');
      tzolkin.className = 'mayan-tzolkin';
      tzolkin.textContent = mayanDate.tzolkin;
      
      const haab = document.createElement('div');
      haab.className = 'mayan-haab';
      haab.textContent = mayanDate.haab;
      
      const glyph = document.createElement('div');
      glyph.className = 'mayan-glyph';
      glyph.textContent = mayanCalendar.getDayGlyph(new Date(dateStr));
      
      // Add info to the day cell
      mayanInfo.appendChild(tzolkin);
      mayanInfo.appendChild(haab);
      cell.appendChild(mayanInfo);
      cell.appendChild(glyph);
    }
  });
}

// Function to convert calendar system on existing grid
export function convertCalendarDisplay(toSystem) {
  // Set the current calendar system
  setCalendarSystem(toSystem);
  
  // Get all day cells
  const dayCells = document.querySelectorAll('.day');
  
  dayCells.forEach(cell => {
    const dateStr = cell.getAttribute('data-date');
    if (dateStr) {
      const date = new Date(dateStr);
      
      // Get date in the target system
      const convertedDate = calendarTranslation.fromGregorian(date, toSystem);
      
      // Find or create the system-specific info element
      let systemInfo = cell.querySelector(`.${toSystem}-day-info`);
      if (!systemInfo) {
        systemInfo = document.createElement('div');
        systemInfo.className = `${toSystem}-day-info`;
        cell.appendChild(systemInfo);
      }
      
      // Update with formatted date information
      systemInfo.innerHTML = calendarTranslation.formatDate(date, toSystem, { format: 'short' });
      
      // Toggle visibility of different calendar system infos
      const allSystemInfos = cell.querySelectorAll('[class$="-day-info"]');
      allSystemInfos.forEach(info => {
        info.style.display = 'none';
      });
      systemInfo.style.display = 'block';
    }
  });
  
  // Update the calendar header to show current system
  const calendarHeader = document.querySelector('.calendar-header h1');
  if (calendarHeader) {
    calendarHeader.textContent = `Calendar (${toSystem.charAt(0).toUpperCase() + toSystem.slice(1)})`;
  }
  
  return { type: 'none' };
}

// When scheduling a meeting, add Mayan calendar information
const originalScheduleMeeting = window.scheduleMeeting || function() {};
export function scheduleMeeting(meeting) {
  // Get Mayan date information
  const mayanDate = getMayanDate(meeting.date);
  
  // Add Mayan information to meeting data
  const meetingWithMayanInfo = {
    ...meeting,
    mayanDate: {
      longCount: mayanDate.longCount,
      tzolkin: mayanDate.tzolkin,
      haab: mayanDate.haab
    }
  };
  
  console.log('Scheduling meeting with Mayan date info:', meetingWithMayanInfo);
  
  // Add Mayan significance to meeting description if not already set
  if (!meeting.description || meeting.description.trim() === '') {
    const tzolkinDay = mayanDate.tzolkinDay;
    const significance = getMayanDaySignificance(tzolkinDay);
    meetingWithMayanInfo.description = 
      `Meeting on Mayan date: ${mayanDate.longCount} ${mayanDate.tzolkin} ${mayanDate.haab}\n\n` +
      `Day energy: ${significance}`;
  }
  
  // Call original scheduling function with enhanced data
  if (typeof originalScheduleMeeting === 'function') {
    return originalScheduleMeeting(meetingWithMayanInfo);
  }
  
  // Show a loading indicator
  const submitBtn = document.getElementById('schedule-meeting-btn');
  if (submitBtn) {
    submitBtn.disabled = true;
    submitBtn.textContent = 'Scheduling...';
  }
  
  // Find the day cell for this meeting date
  const dayCell = findDayCell(meeting.date);
  
  // Create the email content
  let emailSubject = `Meeting: ${meetingWithMayanInfo.title}`;
  let emailBody = `
    Meeting: ${meetingWithMayanInfo.title}
    Date: ${formatDate(meetingWithMayanInfo.date)} (${mayanDate.longCount} ${mayanDate.tzolkin} ${mayanDate.haab})
    Time: ${formatTime(meetingWithMayanInfo.start_time)} (${meetingWithMayanInfo.timezone || getTimezone()})
    Duration: ${meetingWithMayanInfo.duration_minutes} minutes
    Description: ${meetingWithMayanInfo.description}
    Attendees: ${Array.isArray(meetingWithMayanInfo.attendees) ? meetingWithMayanInfo.attendees.join(', ') : meetingWithMayanInfo.attendees}
  `;
  
  // Add location details to the email body
  if (meetingWithMayanInfo.location_type.type === 'Virtual' || 
      (meetingWithMayanInfo.location_type && meetingWithMayanInfo.location_type.type === 'Virtual')) {
    emailBody += `\nVirtual Meeting Link: ${meetingWithMayanInfo.location}`;
  } else {
    emailBody += `\nMeeting Location: ${meetingWithMayanInfo.location}`;
  }
  
  // Make API call to the server - ensure all required data is sent as JSON
  fetch('/api/schedule-meeting', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(meetingWithMayanInfo)
  })
  .then(response => {
    if (!response.ok) {
      throw new Error(`HTTP error! Status: ${response.status}`);
    }
    return response.json();
  })
  .then(data => {
    console.log('Server response:', data);
    
    // Format attendee list for the notification
    const attendeeList = Array.isArray(meetingWithMayanInfo.attendees) 
      ? meetingWithMayanInfo.attendees.join(', ') 
      : meetingWithMayanInfo.attendees;
    
    // Show success message with specific details including Mayan date
    showNotification(
      `Meeting "${meetingWithMayanInfo.title}" scheduled for ${formatDate(meetingWithMayanInfo.date)} (${mayanDate.tzolkin}) at ${formatTime(meetingWithMayanInfo.start_time)}. Email notifications sent to: ${attendeeList}`, 
      'success'
    );
    
    // Reset button state
    if (submitBtn) {
      submitBtn.disabled = false;
      submitBtn.textContent = 'Schedule Meeting';
    }
    
    // Close both dialogs - use display:none to properly hide them
    const schedulerDialog = document.querySelector('.scheduler-dialog');
    const dayView = document.querySelector('.day-view');
    
    if (schedulerDialog) {
      schedulerDialog.style.display = 'none';
      
      // Reset the form for next use
      const form = schedulerDialog.querySelector('.meeting-form');
      if (form) {
        form.reset();
        // Regenerate meeting link for next time
        const virtualLocationInput = document.getElementById('virtual-location');
        if (virtualLocationInput) {
          virtualLocationInput.value = generateMeetingLink('google');
        }
      }
    }
    
    if (dayView) {
      dayView.style.display = 'none';
    }
    
    // Add meeting to the calendar view
    if (typeof addMeetingToCalendarView === 'function') {
      addMeetingToCalendarView(meetingWithMayanInfo);
    }
    
    // Add meeting directly to the day cell
    if (dayCell && typeof addMeetingToDayCell === 'function') {
      console.log('Adding meeting to day cell for date:', meetingWithMayanInfo.date);
      addMeetingToDayCell(dayCell, meetingWithMayanInfo);
    }
  })
  .catch(error => {
    console.error('Error scheduling meeting:', error);
    showNotification('Error scheduling meeting. Please try again.', 'error');
    
    // Reset button state
    if (submitBtn) {
      submitBtn.disabled = false;
      submitBtn.textContent = 'Schedule Meeting';
    }
  });
  
  return { type: 'none' };
}

/**
 * Get the significance description for a Tzolkin day
 * @param {String} tzolkinDay - Tzolkin day name
 * @returns {String} Significance description
 */
function getMayanDaySignificance(tzolkinDay) {
  const tzolkinDaySignificance = {
    'Imix': 'Imix represents primordial earth and nurturing energy. A good day for new beginnings and maternal activities.',
    'Ik': 'Ik represents wind, breath, and spirit. A good day for communication and inspiration.',
    'Akbal': 'Akbal represents darkness, the night, and the dreamworld. A good day for introspection and dream work.',
    'Kan': 'Kan represents seed, abundance, and lizard. A good day for planting seeds and starting projects.',
    'Chicchan': 'Chicchan represents serpent and life force energy. A good day for spiritual work and healing.',
    'Cimi': 'Cimi represents death, transformation, and letting go. A good day for releasing what no longer serves you.',
    'Manik': 'Manik represents deer, hand, and grasping knowledge. A good day for skilled work and healing with hands.',
    'Lamat': 'Lamat represents star, abundance, and rabbit. A good day for fertility and harmony.',
    'Muluc': 'Muluc represents water, offering, and moon. A good day for emotional work and making offerings.',
    'Oc': 'Oc represents dog, loyalty, and guidance. A good day for friendship and working with communities.',
    'Chuen': 'Chuen represents monkey, artistry, and weaving. A good day for creative work and play.',
    'Eb': 'Eb represents the human journey and road of life. A good day for making travel plans and community endeavors.',
    'Ben': 'Ben represents corn, abundance, and personal growth. A good day for home and family matters.',
    'Ix': 'Ix represents jaguar, shaman, and earth magic. A good day for working with sacred energies.',
    'Men': 'Men represents eagle, vision, and higher perspective. A good day for seeing the bigger picture.',
    'Cib': 'Cib represents owl, wisdom, and introspection. A good day for seeking inner wisdom.',
    'Caban': 'Caban represents earth, movement, and synchronicity. A good day for connection with earth energies.',
    'Etznab': 'Etznab represents mirror, flint, and truth-telling. A good day for clarity and honest reflection.',
    'Cauac': 'Cauac represents storm, thunder, and purification. A good day for cleansing and renewal.',
    'Ahau': 'Ahau represents sun, enlightenment, and completion. A good day for celebration and spiritual awareness.'
  };
  
  return tzolkinDaySignificance[tzolkinDay] || `${tzolkinDay} energy brings special qualities for this day.`;
}

// Get today's date in YYYY-MM-DD format
export function getTodayDate() {
  const now = new Date();
  // Ensure we're using the local timezone
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, '0');
  const day = String(now.getDate()).padStart(2, '0');
  console.log('Today is:', `${year}-${month}-${day}`);
  return `${year}-${month}-${day}`;
}

// Get current year and month
export function getCurrentDate() {
  const now = new Date();
  // Return as array for compatibility with existing Gleam code
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

// Standard weekday names (for reference)
const WEEKDAY_NAMES = [
  'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun' // Duplicate for rotation
];

// Map numeric day to standard name
function getStandardWeekdayName(dayIndex, offset = 0) {
  // Adjust index based on offset and get the appropriate name
  const adjustedIndex = (dayIndex + offset) % 7;
  return WEEKDAY_NAMES[adjustedIndex];
}

// Get days data for a month
export function getMonthData(year, month, system) {
  const firstDay = new Date(year, month - 1, 1);
  const lastDay = new Date(year, month, 0);
  const today = new Date();
  
  // Default values if system is not provided
  const week_offset = system ? system.week_offset : 0;
  const week_length = system ? system.week_length : 7;
  
  console.log('Generating month data with week_length:', week_length, 'and week_offset:', week_offset);
  
  // Get days from previous month to fill first week
  let firstWeekday = firstDay.getDay(); // 0 = Sunday, 1 = Monday, etc.
  
  // Adjust for week offset (0 = Monday as first day of week)
  // Convert Sunday (0) to 7 for consistency
  if (firstWeekday === 0) firstWeekday = 7;
  
  // Apply the week offset
  firstWeekday = (firstWeekday + week_offset) % week_length;
  if (firstWeekday === 0) firstWeekday = week_length;
  
  // Calculate how many days we need from the previous month
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
      is_working_day: isWorkingDay(new Date(date), system),
      events: toList([]),
      reminders: toList([])
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
      is_working_day: isWorkingDay(new Date(date), system),
      events: toList([]),
      reminders: toList([])
    });
  }
  
  // Calculate remaining days needed to complete the grid
  const totalDays = days.length;
  const weeksNeeded = Math.ceil(totalDays / week_length);
  const totalCells = weeksNeeded * week_length;
  const remainingDays = totalCells - totalDays;
  
  console.log('Calendar grid calculation:', {
    totalDays,
    weeksNeeded,
    totalCells,
    remainingDays,
    week_length
  });
  
  // Add days from next month
  const nextMonth = month === 12 ? 1 : month + 1;
  const nextYear = month === 12 ? year + 1 : year;
  
  for (let day = 1; day <= remainingDays; day++) {
    const date = `${nextYear}-${String(nextMonth).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
    days.push({
      date,
      is_today: false,
      is_current_month: false,
      is_working_day: isWorkingDay(new Date(date), system),
      events: toList([]),
      reminders: toList([])
    });
  }
  
  return toList(days);
}

// Helper function to check if a day is a working day
function isWorkingDay(date, system) {
  if (!system || !system.working_days) {
    return true; // Default to working day if no system or working_days defined
  }
  
  const day = date.getDay();
  // Convert Sunday (0) to 7 to match Gleam's system
  const adjustedDay = day === 0 ? 7 : day;
  
  // Convert the Gleam list to a JavaScript array if it's not already
  const workingDaysArray = Array.isArray(system.working_days) 
    ? system.working_days 
    : (system.working_days.values || []);
  
  // For custom week lengths, we need to adjust the day to fit within the week length
  const week_length = system.week_length || 7;
  const week_offset = system.week_offset || 0;
  
  // Apply the week offset and modulo to get the day within our custom week
  const customDay = ((adjustedDay - 1 + week_offset) % week_length) + 1;
  
  // Check if the adjusted day is in the working days array
  return workingDaysArray.some(workingDay => workingDay === customDay);
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

// Auto-generate a meeting link
export function generateMeetingLink(type = 'google') {
  if (type === 'google') {
    // Generate a Google Meet link
    const meetId = Math.random().toString(36).substring(2, 12);
    return `https://meet.google.com/${meetId}`;
  } else if (type === 'zoom') {
    // Generate a zoom link (note: real Zoom links would need API integration)
    const meetingId = Math.floor(Math.random() * 1000000000).toString().padStart(9, '0');
    const password = Math.random().toString(36).substring(2, 10);
    return `https://zoom.us/j/${meetingId}?pwd=${password}`;
  }
  return '';
}

// Toggle location fields based on location type
export function toggleLocationFields(locationType) {
  console.log('Toggling location fields for:', locationType);
  
  const virtualGroup = document.getElementById('virtual-location-group');
  const physicalGroup = document.getElementById('physical-location-group');
  
  if (!virtualGroup || !physicalGroup) {
    console.warn('Location groups not found in DOM');
    return { type: 'none' };
  }
  
  if (locationType === 'virtual') {
    virtualGroup.style.display = 'block';
    physicalGroup.style.display = 'none';
    
    // Auto-generate a meeting link if the field is empty
    const virtualLocationInput = document.getElementById('virtual-location');
    if (virtualLocationInput && !virtualLocationInput.value) {
      virtualLocationInput.value = generateMeetingLink('google');
    }
  } else if (locationType === 'in-person') {
    virtualGroup.style.display = 'none';
    physicalGroup.style.display = 'block';
  }
  
  return { type: 'none' };
}

// Get form data helper
export function getFormData(form) {
  const formData = new FormData(form);
  return Object.fromEntries(formData.entries());
}

// Display dialogs based on application state
function initDialogs() {
  console.log('Running initDialogs function');
  
  // The day view and scheduler dialogs are shown and hidden by the Gleam application
  // After the HTML is rendered, we need to set the correct display property
  const dayViewDialog = document.querySelector('.day-view-dialog') || document.querySelector('.day-view');
  const schedulerDialog = document.querySelector('.scheduler-dialog');
  
  // Initially hide both dialogs if they exist
  if (dayViewDialog) {
    dayViewDialog.style.display = 'none';
    console.log('Day view dialog hidden');
  } else {
    console.log('Day view dialog not found in the DOM yet');
  }
  
  if (schedulerDialog) {
    schedulerDialog.style.display = 'none';
    console.log('Scheduler dialog hidden');
  } else {
    console.log('Scheduler dialog not found in the DOM yet');
  }
  
  // When the Gleam app updates the DOM, we need to check if the dialogs should be shown
  const observer = new MutationObserver((mutations) => {
    for (const mutation of mutations) {
      if (mutation.type === 'childList' && mutation.addedNodes.length > 0) {
        console.log('DOM mutation detected with added nodes');
        
        // When new dialogs are added to the DOM, check if they should be shown
        const newSchedulerDialog = document.querySelector('.scheduler-dialog');
        const newDayViewDialog = document.querySelector('.day-view-dialog') || document.querySelector('.day-view');
        
        if (newSchedulerDialog && newSchedulerDialog.style.display !== 'block') {
          newSchedulerDialog.style.display = 'block';
          console.log('Showing scheduler dialog');
          
          // Prefill the attendees field with instance.select@gmail.com
          setTimeout(() => {
            const attendeesField = document.getElementById('meeting-attendees');
            if (attendeesField) {
              attendeesField.value = 'instance.select@gmail.com';
              console.log('Prefilled attendees field with:', attendeesField.value);
              
              // Add direct event listener to the schedule button
              const scheduleButton = document.getElementById('schedule-meeting-btn');
              if (scheduleButton) {
                // Remove existing event listeners by cloning the node
                const newButton = scheduleButton.cloneNode(true);
                scheduleButton.parentNode.replaceChild(newButton, scheduleButton);
                
                newButton.addEventListener('click', function(e) {
                  e.preventDefault();
                  console.log('Schedule button clicked directly');
                  
                  // Get form data
                  const formData = document.querySelector('.meeting-form');
                  const titleInput = document.getElementById('meeting-title');
                  const descriptionInput = document.getElementById('meeting-description');
                  const attendeesInput = document.getElementById('meeting-attendees');
                  const durationSelect = document.getElementById('meeting-duration');
                  
                  console.log('Form elements on click:', {
                    titleInput,
                    descriptionInput,
                    attendeesInput,
                    durationSelect
                  });
                  
                  // Get time info from the dialog
                  const timeInfo = document.querySelector('.time-info');
                  let dateStr = '';
                  let timeStr = '';
                  
                  if (timeInfo) {
                    const text = timeInfo.textContent;
                    console.log('Time info text:', text);
                    
                    // Parse date and time
                    const dateMatch = text.match(/Meeting on ([^at]+) at ([^EST]+)/);
                    if (dateMatch) {
                      dateStr = dateMatch[1].trim();
                      timeStr = dateMatch[2].trim();
                      console.log('Parsed date and time:', { dateStr, timeStr });
                    }
                  }
                  
                  // Create meeting data
                  let title = titleInput ? titleInput.value : '';
                  if (!title) {
                    title = "Default Meeting";
                    if (titleInput) titleInput.value = title;
                  }
                  
                  let attendeesStr = attendeesInput ? attendeesInput.value : '';
                  if (!attendeesStr) {
                    attendeesStr = "instance.select@gmail.com";
                    if (attendeesInput) attendeesInput.value = attendeesStr;
                  }
                  
                  const attendees = attendeesStr.split(',')
                    .map(email => email.trim())
                    .filter(email => email.length > 0);
                  
                  const meetingData = {
                    id: generateId(),
                    title: title,
                    description: descriptionInput ? descriptionInput.value : '',
                    date: dateStr,
                    start_time: timeStr,
                    duration_minutes: durationSelect ? parseInt(durationSelect.value, 10) : 30,
                    attendees: attendees.length > 0 ? attendees : ['instance.select@gmail.com'],
                    timezone: getTimezone(),
                    location_type: { type: document.getElementById('location-type').value === 'virtual' ? 'Virtual' : 'InPerson' },
                    location: document.getElementById('location-type').value === 'virtual' ? 
                      document.getElementById('virtual-location').value : 
                      document.getElementById('physical-location').value
                  };
                  
                  console.log('Created meeting data:', meetingData);
                  
                  // Schedule the meeting with the collected data
                  scheduleMeeting(meetingData);
                });
                console.log('Added click handler to schedule button');
              }
            }
          }, 100);
        }
        
        if (newDayViewDialog && newDayViewDialog.style.display !== 'block') {
          newDayViewDialog.style.display = 'block';
          console.log('Showing day view dialog');
        }
      }
    }
  });
  
  // Start observing the document body
  observer.observe(document.body, { childList: true, subtree: true });
  console.log('Started mutation observer');
  
  // Configure the location type selector to auto-generate meeting links
  const locationTypeSelect = document.getElementById('location-type');
  if (locationTypeSelect) {
    locationTypeSelect.addEventListener('change', function() {
      toggleLocationFields(this.value);
      console.log('Location type changed to:', this.value);
    });
    console.log('Added event listener to location type selector');
  }
  
  // Fix for day action buttons
  document.body.addEventListener('click', (event) => {
    // Check if the click was on a day-action-btn or its parent
    const actionBtn = event.target.closest('.day-action-btn');
    if (actionBtn) {
      console.log('Day action button clicked');
      
      // Prevent the event from bubbling to the day element
      event.stopPropagation();
      
      // Hide day view when scheduling
      const dayViewDialog = document.querySelector('.day-view-dialog') || document.querySelector('.day-view');
      if (dayViewDialog) {
        dayViewDialog.style.display = 'none';
        console.log('Day view dialog hidden');
      } else {
        console.log('Day view dialog not found when clicking day action button');
      }
      
      // Show the scheduler dialog
      const schedulerDialog = document.querySelector('.scheduler-dialog');
      if (schedulerDialog) {
        schedulerDialog.style.display = 'block';
        console.log('Scheduler dialog shown');
        
        // Prefill the attendees field with instance.select@gmail.com
        setTimeout(() => {
          const attendeesField = document.getElementById('meeting-attendees');
          if (attendeesField) {
            attendeesField.value = 'instance.select@gmail.com';
            console.log('Prefilled attendees with:', attendeesField.value);
          }
        }, 100);
      } else {
        console.log('Scheduler dialog not found when clicking day action button');
      }
    }
  }, true);
  
  console.log('initDialogs function completed');
}

// Get meeting details from form
export function getMeetingDetails() {
  console.log('getMeetingDetails called');
  
  // Get form elements directly
  const titleInput = document.getElementById('meeting-title');
  const descriptionInput = document.getElementById('meeting-description');
  const attendeesInput = document.getElementById('meeting-attendees');
  const durationSelect = document.getElementById('meeting-duration');
  const locationTypeSelect = document.getElementById('location-type');
  
  console.log('Direct form element access:', {
    titleInput: titleInput,
    attendeesInput: attendeesInput
  });
  
  // Force defaults for critical fields and log the values
  let title = titleInput ? titleInput.value : '';
  if (!title && titleInput) {
    title = "Meeting " + new Date().toLocaleTimeString();
    titleInput.value = title;
    console.log('SET DEFAULT TITLE:', title);
  }
  
  let attendeesStr = attendeesInput ? attendeesInput.value : '';
  if (!attendeesStr && attendeesInput) {
    attendeesStr = 'instance.select@gmail.com';
    attendeesInput.value = attendeesStr;
    console.log('SET DEFAULT ATTENDEES:', attendeesStr);
    
    // Trigger an input event to ensure frameworks detect the change
    const event = new Event('input', { bubbles: true });
    attendeesInput.dispatchEvent(event);
  }
  
  // Get remaining values
  const description = descriptionInput ? descriptionInput.value : '';
  const duration = durationSelect ? parseInt(durationSelect.value, 10) : 30;
  const locationType = locationTypeSelect ? locationTypeSelect.value : 'virtual';
  
  let location = '';
  if (locationType === 'virtual') {
    const virtualLocationInput = document.getElementById('virtual-location');
    let virtualLocation = virtualLocationInput ? virtualLocationInput.value : '';
    
    if (!virtualLocation) {
      virtualLocation = generateMeetingLink('google');
      if (virtualLocationInput) virtualLocationInput.value = virtualLocation;
    }
    
    location = virtualLocation;
  } else {
    const physicalLocationInput = document.getElementById('physical-location');
    location = physicalLocationInput ? physicalLocationInput.value : '';
  }
  
  // Parse attendees with robust fallback
  const attendees = attendeesStr ? 
    attendeesStr.split(',').map(email => email.trim()).filter(email => email.length > 0) :
    ['instance.select@gmail.com'];
  
  const finalAttendees = attendees.length > 0 ? attendees : ['instance.select@gmail.com'];
  
  // Log final values for debugging
  console.log('FINAL meeting details:', { 
    title: title || "Default Meeting", 
    description, 
    attendees: finalAttendees,
    location_type: { type: locationType === 'virtual' ? 'Virtual' : 'InPerson' },
    location
  });
  
  // Return the message to set meeting details
  return {
    type: 'SetMeetingDetails',
    title: title || "Default Meeting",
    description: description,
    attendees: finalAttendees,
    location_type: { type: locationType === 'virtual' ? 'Virtual' : 'InPerson' },
    location
  };
}

// Helper function to find the day cell for a specific date
function findDayCell(date) {
  console.log('Finding day cell for date:', date);
  const dayCells = document.querySelectorAll('.day');
  let foundCell = null;
  
  dayCells.forEach(cell => {
    const dateAttr = cell.getAttribute('data-date');
    console.log('Checking cell date:', dateAttr);
    if (dateAttr === date) {
      foundCell = cell;
      console.log('Found matching day cell!');
    }
  });
  
  if (!foundCell) {
    console.warn('Could not find day cell for date:', date);
  }
  
  return foundCell;
}

// Helper function to add a meeting directly to a day cell
function addMeetingToDayCell(dayCell, meeting) {
  if (!dayCell) {
    console.error('Cannot add meeting - no day cell provided');
    return;
  }
  
  console.log('Adding meeting to day cell:', meeting);
  
  // Find or create the meetings container
  let meetingsContainer = dayCell.querySelector('.day-meetings');
  if (!meetingsContainer) {
    console.log('Creating meetings container');
    meetingsContainer = document.createElement('div');
    meetingsContainer.className = 'day-meetings';
    dayCell.appendChild(meetingsContainer);
  }
  
  // Create a new meeting element
  const meetingElement = document.createElement('div');
  meetingElement.className = 'meeting';
  meetingElement.setAttribute('data-meeting-id', meeting.id);
  
  // Create a title element
  const titleElement = document.createElement('div');
  titleElement.className = 'meeting-title';
  titleElement.textContent = meeting.title;
  
  // Create a time element
  const timeElement = document.createElement('div');
  timeElement.className = 'meeting-time';
  timeElement.textContent = formatTime(meeting.start_time);
  
  // Add elements to the meeting
  meetingElement.appendChild(titleElement);
  meetingElement.appendChild(timeElement);
  
  // Add the meeting to the container
  meetingsContainer.appendChild(meetingElement);
  
  // Force a reflow to ensure the cell updates visually
  dayCell.style.display = 'none';
  dayCell.offsetHeight; // Force reflow
  dayCell.style.display = '';
  
  console.log('Successfully added meeting to day cell');
}

// Helper function to add a meeting to the calendar view
function addMeetingToCalendarView(meeting) {
  console.log('Adding meeting to calendar view:', meeting);
  
  // First try to find the day cell directly
  const dayCell = findDayCell(meeting.date);
  
  if (dayCell) {
    // We found the day cell, add the meeting directly
    addMeetingToDayCell(dayCell, meeting);
    return;
  }
  
  // If we couldn't find the cell directly, try the old way
  console.warn('Could not find day cell for date directly:', meeting.date);
  console.log('Attempting to find day through querySelectorAll');
  
  // Find the day cell for this meeting
  const dayCells = document.querySelectorAll('.day');
  let targetDay = null;
  
  for (const day of dayCells) {
    const dateAttr = day.getAttribute('data-date');
    if (dateAttr === meeting.date) {
      targetDay = day;
      console.log('Found target day through query:', dateAttr);
      break;
    }
  }
  
  // If we found the day, add the meeting to it
  if (targetDay) {
    console.log('Adding meeting to day:', targetDay);
    const meetingsContainer = targetDay.querySelector('.day-meetings');
    
    if (meetingsContainer) {
      // Create a new meeting element
      const meetingElement = document.createElement('div');
      meetingElement.className = 'meeting';
      meetingElement.setAttribute('data-meeting-id', meeting.id);
      
      // Create meeting content
      const meetingContent = document.createElement('div');
      meetingContent.textContent = `${meeting.title} (${formatTime(meeting.start_time)})`;
      
      // Create location element
      const locationElement = document.createElement('div');
      locationElement.className = 'meeting-location';
      
      if (meeting.location_type.type === 'Virtual') {
        locationElement.textContent = `Virtual: ${meeting.location}`;
      } else {
        locationElement.textContent = `Location: ${meeting.location}`;
      }
      
      // Add elements to the meeting
      meetingElement.appendChild(meetingContent);
      meetingElement.appendChild(locationElement);
      
      // Add the meeting to the container
      meetingsContainer.appendChild(meetingElement);
      console.log('Meeting added successfully');
    } else {
      console.warn('No meetings container found in day cell');
    }
  } else {
    console.warn('Could not find day cell for date:', meeting.date);
    // Log all day cells for debugging
    console.log('Available day cells:');
    dayCells.forEach(day => {
      console.log(`Day cell: ${day.getAttribute('data-date')}`);
    });
  }
}

// Show notification
function showNotification(message, type = 'success') {
  // Remove any existing notifications
  const existingNotifications = document.querySelectorAll('.notification');
  existingNotifications.forEach(notification => {
    notification.remove();
  });
  
  // Create new notification
  const notification = document.createElement('div');
  notification.className = `notification ${type}`;
  
  // Create notification content
  const content = document.createElement('div');
  content.className = 'notification-content';
  content.textContent = message;
  
  // Create close button
  const closeBtn = document.createElement('button');
  closeBtn.className = 'notification-close';
  closeBtn.textContent = '×';
  closeBtn.addEventListener('click', () => {
    notification.style.transform = 'translateY(-20px)';
    notification.style.opacity = '0';
    setTimeout(() => notification.remove(), 300);
  });
  
  // Add content and close button to notification
  notification.appendChild(content);
  notification.appendChild(closeBtn);
  
  // Add notification to document
  document.body.appendChild(notification);
  
  // Animate in
  setTimeout(() => {
    notification.style.transform = 'translateY(0)';
    notification.style.opacity = '1';
  }, 10);
  
  // Remove after delay
  setTimeout(() => {
    notification.style.transform = 'translateY(-20px)';
    notification.style.opacity = '0';
    
    setTimeout(() => {
      notification.remove();
    }, 300);
  }, 5000);
}

// Initialize the calendar functionality when the DOM is fully loaded
if (typeof document !== 'undefined') {
  document.addEventListener('DOMContentLoaded', function() {
    console.log('Calendar DOM content loaded');
    
    // Force prefill attendees on any dialog visibility change
    const prefillAttendees = () => {
      console.log('Forcing attendees prefill');
      const attendeesField = document.getElementById('meeting-attendees');
      if (attendeesField) {
        // Force the value and use an input event to ensure it's registered
        attendeesField.value = 'instance.select@gmail.com';
        // Dispatch an input event to ensure the value is recognized by any framework
        const event = new Event('input', { bubbles: true });
        attendeesField.dispatchEvent(event);
        console.log('FORCED attendees value:', attendeesField.value);
      }
    };
    
    // Set direct listener for scheduler dialog appearance
    const checkForDialogs = () => {
      const schedulerDialog = document.querySelector('.scheduler-dialog');
      if (schedulerDialog && window.getComputedStyle(schedulerDialog).display === 'block') {
        prefillAttendees();
        
        // Add direct click handler to the schedule button
        const scheduleButton = document.getElementById('schedule-meeting-btn');
        if (scheduleButton) {
          // Clone to remove existing listeners
          const newButton = scheduleButton.cloneNode(true);
          scheduleButton.parentNode.replaceChild(newButton, scheduleButton);
          
          newButton.addEventListener('click', function(e) {
            e.preventDefault();
            e.stopPropagation();
            console.log('Schedule button clicked - DIRECT HANDLER');
            
            // Get values directly from DOM with robust fallbacks
            const titleInput = document.getElementById('meeting-title');
            let title = titleInput ? titleInput.value : '';
            if (!title) {
              title = "Meeting " + new Date().toLocaleTimeString();
              if (titleInput) titleInput.value = title;
            }
            
            const attendeesInput = document.getElementById('meeting-attendees');
            let attendeesStr = attendeesInput ? attendeesInput.value : '';
            if (!attendeesStr) {
              attendeesStr = 'instance.select@gmail.com';
              if (attendeesInput) attendeesInput.value = attendeesStr;
            }
            
            // Get other form values
            const descriptionInput = document.getElementById('meeting-description');
            const description = descriptionInput ? descriptionInput.value : '';
            
            const durationSelect = document.getElementById('meeting-duration');
            const duration = durationSelect ? parseInt(durationSelect.value, 10) : 30;
            
            const locationTypeSelect = document.getElementById('location-type');
            const locationType = locationTypeSelect ? locationTypeSelect.value : 'virtual';
            
            // Get location based on type
            let location = '';
            if (locationType === 'virtual') {
              location = document.getElementById('virtual-location').value;
            } else {
              location = document.getElementById('physical-location').value;
            }
            
            // Get time info from the dialog
            const timeInfo = document.querySelector('.time-info');
            let dateStr = new Date().toISOString().split('T')[0]; // Default to today
            let timeStr = '09:00'; // Default to 9am
            
            if (timeInfo) {
              const text = timeInfo.textContent;
              console.log('Time info text:', text);
              
              // Parse date and time
              const dateMatch = text.match(/Meeting on ([^at]+) at ([^EST]+)/);
              if (dateMatch) {
                dateStr = dateMatch[1].trim();
                timeStr = dateMatch[2].trim();
              }
            }
            
            // Format attendees
            const attendees = attendeesStr.split(',')
              .map(email => email.trim())
              .filter(email => email.length > 0);
            
            const finalAttendees = attendees.length > 0 ? attendees : ['instance.select@gmail.com'];
            
            // Create the meeting data object
            const meetingData = {
              id: generateId(),
              title: title,
              description: description,
              date: dateStr,
              start_time: timeStr,
              duration_minutes: duration,
              attendees: finalAttendees,
              timezone: getTimezone(),
              location_type: { type: locationType === 'virtual' ? 'Virtual' : 'InPerson' },
              location: location
            };
            
            console.log('DIRECT HANDLER created meeting data:', meetingData);
            
            // Call the scheduleMeeting function with the meeting data
            scheduleMeeting(meetingData);
          });
          console.log('Added DIRECT click handler to schedule button');
        }
      }
    };
    
    // Check for dialogs periodically
    const dialogCheckInterval = setInterval(checkForDialogs, 500);
    
    // Also run dialog checks on any DOM mutations
    const observer = new MutationObserver(() => {
      checkForDialogs();
    });
    observer.observe(document.body, { childList: true, subtree: true });
    
    // Use a small timeout to ensure the DOM is fully rendered
    setTimeout(() => {
      try {
        console.log('Initializing calendar dialogs');
        initDialogs();
        
        // Force set up our direct handlers after initialization
        setTimeout(checkForDialogs, 100);
        
        console.log('Calendar dialogs initialized successfully');
      } catch (error) {
        console.error('Error initializing calendar dialogs:', error);
      }
      
      // Force the field values when input events occur
      document.addEventListener('input', (e) => {
        // When title is empty and loses focus, set a default
        if (e.target.id === 'meeting-title' && !e.target.value) {
          e.target.value = "Meeting " + new Date().toLocaleTimeString();
        }
        
        // When attendees is empty and loses focus, set the default email
        if (e.target.id === 'meeting-attendees' && !e.target.value) {
          e.target.value = 'instance.select@gmail.com';
        }
      });
      
      console.log('Calendar initialization complete');
    }, 300);
  });
}

// Main function to initialize the calendar module
export function main() {
  console.log('Initializing calendar module');
  
  if (typeof document === 'undefined') {
    console.log('Document not available. Skipping calendar DOM operations.');
    return;
  }
  
  // Check if we're in SPA mode
    const appDiv = document.getElementById('app');
  const calendarRoot = document.getElementById('calendar-root');
  
  if (appDiv && calendarRoot) {
    console.log('Calendar: Found app div and calendar root, initializing in SPA mode');
  setupCalendar();
  return { type: 'none' };
}

  // Direct page mode
  console.log('Calendar: Initializing in direct page mode');
  const directRoot = document.getElementById('direct-calendar-root');
  if (directRoot) {
    setupCalendar();
    return { type: 'none' };
  }
  
  // Create calendar root if needed
  const newRoot = document.createElement('div');
  newRoot.id = 'calendar-root';
  newRoot.className = 'calendar-container';
  document.body.appendChild(newRoot);
  setupCalendar();
  
    return { type: 'none' };
  }
  
// Initialize calendar UI
export function setupCalendar() {
  const calendarRoot = document.getElementById("calendar-root");
  if (!calendarRoot) {
    console.error("Calendar root element not found");
    return;
  }

  // Initialize calendar UI
  const calendarGrid = document.getElementById("calendar-grid");
  const currentMonth = document.querySelector(".current-month");
  const prevMonthBtn = document.querySelector(".prev-month");
  const nextMonthBtn = document.querySelector(".next-month");

  if (!calendarGrid || !currentMonth || !prevMonthBtn || !nextMonthBtn) {
    console.error("Required calendar elements not found");
    return;
  }

  // Set up event listeners
  prevMonthBtn.addEventListener("click", () => {
    window.dispatchEvent(new CustomEvent("calendar:changeMonth", { detail: "prev" }));
  });

  nextMonthBtn.addEventListener("click", () => {
    window.dispatchEvent(new CustomEvent("calendar:changeMonth", { detail: "next" }));
  });

  // Initialize calendar state
  const today = new Date();
  updateCalendar(today);
}

function updateCalendar(date) {
  const calendarGrid = document.getElementById("calendar-grid");
  const currentMonth = document.querySelector(".current-month");
  
  if (!calendarGrid || !currentMonth) return;

  // Update month display
  currentMonth.textContent = date.toLocaleString('default', { month: 'long', year: 'numeric' });

  // Clear existing calendar
  calendarGrid.innerHTML = '';

  // Add day headers
  const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  days.forEach(day => {
    const dayHeader = document.createElement('div');
    dayHeader.className = 'calendar-day-header';
    dayHeader.textContent = day;
    calendarGrid.appendChild(dayHeader);
  });

  // Add calendar days
  const firstDay = new Date(date.getFullYear(), date.getMonth(), 1);
  const lastDay = new Date(date.getFullYear(), date.getMonth() + 1, 0);
  const startingDay = firstDay.getDay();

  // Add empty cells for days before the first day of the month
  for (let i = 0; i < startingDay; i++) {
    const emptyDay = document.createElement('div');
    emptyDay.className = 'calendar-day empty';
    calendarGrid.appendChild(emptyDay);
  }

  // Add days of the month
  for (let day = 1; day <= lastDay.getDate(); day++) {
    const dayCell = document.createElement('div');
    dayCell.className = 'calendar-day';
    dayCell.textContent = day;
    calendarGrid.appendChild(dayCell);
  }
}

// Initialize calendar when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
  const calendarRoot = document.getElementById("calendar-root");
  if (calendarRoot) {
    setupCalendar();
  }
});

// Setup calendar grid for a specific month and year
export function setupCalendarGrid(year, month) {
  if (typeof document === 'undefined') {
    console.log('Document not available. Skipping setupCalendarGrid.');
    return;
  }
  
  console.log(`Setting up calendar grid for ${month}/${year}`);
  
  // Update the month title
  const monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  
  const currentMonthElem = document.getElementById('current-month');
  if (currentMonthElem) {
    currentMonthElem.textContent = `${monthNames[month-1]} ${year}`;
  }
  
  // Get the grid container
  const calendarGrid = document.getElementById('calendar-grid');
  if (!calendarGrid) {
    console.error('Cannot find calendar grid element');
    return { type: 'none' };
  }
  
  // Clear existing content
  calendarGrid.innerHTML = '';
  
  // Add day headers
  const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  dayNames.forEach(day => {
    const dayHeader = document.createElement('div');
    dayHeader.className = 'day-header';
    dayHeader.textContent = day;
    calendarGrid.appendChild(dayHeader);
  });
  
  // Get the first day of the month
  const firstDay = new Date(year, month - 1, 1);
  const startingDay = firstDay.getDay(); // 0 = Sunday
  
  // Get the number of days in the month
  const lastDay = new Date(year, month, 0);
  const totalDays = lastDay.getDate();
  
  // Get the number of days in the previous month
  const prevMonthLastDay = new Date(year, month - 1, 0);
  const prevMonthDays = prevMonthLastDay.getDate();
  
  // Get today's date for highlighting
  const today = new Date();
  const todayDate = today.getDate();
  const todayMonth = today.getMonth() + 1;
  const todayYear = today.getFullYear();
  
  // Calculate total cells needed (days in month + starting day offset)
  const totalCells = 42; // 6 rows of 7 days
  
  // Create calendar cells
  for (let i = 0; i < totalCells; i++) {
    const dayCell = document.createElement('div');
    dayCell.className = 'day-cell';
    
    // Previous month days
    if (i < startingDay) {
      const prevMonthDate = prevMonthDays - startingDay + i + 1;
      dayCell.innerHTML = `<div class="date-number">${prevMonthDate}</div>`;
      dayCell.classList.add('other-month');
      
      // Calculate the previous month and year
      const prevMonth = month - 1 === 0 ? 12 : month - 1;
      const prevYear = month - 1 === 0 ? year - 1 : year;
      
      // Set data attribute for the date
      const dateStr = `${prevYear}-${String(prevMonth).padStart(2, '0')}-${String(prevMonthDate).padStart(2, '0')}`;
      dayCell.dataset.date = dateStr;
      
    } 
    // Current month days
    else if (i < startingDay + totalDays) {
      const date = i - startingDay + 1;
      dayCell.innerHTML = `<div class="date-number">${date}</div>`;
      
      // Set data attribute for the date
      const dateStr = `${year}-${String(month).padStart(2, '0')}-${String(date).padStart(2, '0')}`;
      dayCell.dataset.date = dateStr;
      
      // Highlight today
      if (date === todayDate && month === todayMonth && year === todayYear) {
        dayCell.classList.add('today');
      }
      
      // Add a div for events
      const eventsDiv = document.createElement('div');
      eventsDiv.className = 'events';
      dayCell.appendChild(eventsDiv);
    } 
    // Next month days
    else {
      const nextMonthDate = i - (startingDay + totalDays) + 1;
      dayCell.innerHTML = `<div class="date-number">${nextMonthDate}</div>`;
      dayCell.classList.add('other-month');
      
      // Calculate the next month and year
      const nextMonth = month + 1 === 13 ? 1 : month + 1;
      const nextYear = month + 1 === 13 ? year + 1 : year;
      
      // Set data attribute for the date
      const dateStr = `${nextYear}-${String(nextMonth).padStart(2, '0')}-${String(nextMonthDate).padStart(2, '0')}`;
      dayCell.dataset.date = dateStr;
    }
    
    calendarGrid.appendChild(dayCell);
  }
  
  return { type: 'none' };
}

// Setup event listeners for calendar interactions
export function setupEventListeners() {
  if (typeof document === 'undefined') {
    console.log('Document not available. Skipping setupEventListeners.');
    return;
  }
  
  console.log('Setting up calendar event listeners');
  
  // Get UI elements
  const prevMonthBtn = document.getElementById('prev-month');
  const nextMonthBtn = document.getElementById('next-month');
  const calendarGrid = document.getElementById('calendar-grid');
  
  // Event listener for previous month button
  if (prevMonthBtn) {
    prevMonthBtn.addEventListener('click', () => {
      const currentMonth = document.getElementById('current-month');
      if (currentMonth) {
        const [monthName, year] = currentMonth.textContent.split(' ');
        const monthNames = [
          'January', 'February', 'March', 'April', 'May', 'June',
          'July', 'August', 'September', 'October', 'November', 'December'
        ];
        const month = monthNames.indexOf(monthName) + 1;
        
        let newMonth = month - 1;
        let newYear = parseInt(year);
        
        if (newMonth === 0) {
          newMonth = 12;
          newYear--;
        }
        
        setupCalendarGrid(newYear, newMonth);
      }
    });
  }
  
  // Event listener for next month button
  if (nextMonthBtn) {
    nextMonthBtn.addEventListener('click', () => {
      const currentMonth = document.getElementById('current-month');
      if (currentMonth) {
        const [monthName, year] = currentMonth.textContent.split(' ');
        const monthNames = [
          'January', 'February', 'March', 'April', 'May', 'June',
          'July', 'August', 'September', 'October', 'November', 'December'
        ];
        const month = monthNames.indexOf(monthName) + 1;
        
        let newMonth = month + 1;
        let newYear = parseInt(year);
        
        if (newMonth === 13) {
          newMonth = 1;
          newYear++;
        }
        
        setupCalendarGrid(newYear, newMonth);
      }
    });
  }
  
  // Event delegation for day cells
  if (calendarGrid) {
    calendarGrid.addEventListener('click', (event) => {
      // Find the day cell that was clicked
      const dayCell = event.target.closest('.day-cell');
      if (dayCell) {
        const date = dayCell.dataset.date;
        if (date) {
          console.log(`Day cell clicked: ${date}`);
          openScheduler(date);
        }
      }
    });
  }
  
  return { type: 'none' };
}

// Open the scheduler dialog for a specific date
export function openScheduler(date) {
  if (typeof document === 'undefined') {
    console.log('Document not available. Skipping openScheduler.');
    return;
  }
  
  console.log(`Opening scheduler for ${date}`);
  
  // Check if the scheduler dialog already exists
  let schedulerDialog = document.querySelector('.scheduler-dialog');
  if (!schedulerDialog) {
    // Create the scheduler dialog
    schedulerDialog = document.createElement('div');
    schedulerDialog.className = 'scheduler-dialog';
    schedulerDialog.innerHTML = `
      <h2>Schedule Meeting for ${date}</h2>
      <form class="meeting-form" id="meeting-form">
        <div class="form-group">
          <label for="meeting-title">Title</label>
          <input type="text" id="meeting-title" name="title" required>
        </div>
        <div class="form-group">
          <label for="meeting-description">Description</label>
          <textarea id="meeting-description" name="description" rows="3"></textarea>
        </div>
        <div class="form-group">
          <label for="meeting-time">Time</label>
          <input type="time" id="meeting-time" name="time" value="09:00" required>
        </div>
        <div class="form-group">
          <label for="meeting-duration">Duration (minutes)</label>
          <input type="number" id="meeting-duration" name="duration" value="30" min="15" step="15" required>
        </div>
        <div class="form-group">
          <label for="meeting-attendees">Attendees (comma separated emails)</label>
          <input type="text" id="meeting-attendees" name="attendees" placeholder="example@email.com, another@email.com">
        </div>
        <div class="form-group">
          <label for="meeting-location-type">Location Type</label>
          <select id="meeting-location-type" name="location_type">
            <option value="Virtual">Virtual Meeting</option>
            <option value="Physical">Physical Location</option>
          </select>
        </div>
        <div class="form-group" id="virtual-location-group">
          <label for="virtual-location">Meeting Link</label>
          <input type="text" id="virtual-location" name="location" value="${generateMeetingLink('google')}">
        </div>
        <div class="form-group" id="physical-location-group" style="display: none;">
          <label for="physical-location">Physical Location</label>
          <input type="text" id="physical-location" name="physical_location" placeholder="Office Room 101">
        </div>
        <div class="form-actions">
          <button type="button" class="cancel-btn" id="cancel-meeting-btn">Cancel</button>
          <button type="submit" class="submit-btn" id="schedule-meeting-btn">Schedule Meeting</button>
        </div>
      </form>
    `;
    document.body.appendChild(schedulerDialog);
    
    // Add event listeners for the location type selector
    const locationTypeSelect = document.getElementById('meeting-location-type');
    const virtualLocationGroup = document.getElementById('virtual-location-group');
    const physicalLocationGroup = document.getElementById('physical-location-group');
    
    if (locationTypeSelect) {
      locationTypeSelect.addEventListener('change', (e) => {
        if (e.target.value === 'Virtual') {
          virtualLocationGroup.style.display = 'block';
          physicalLocationGroup.style.display = 'none';
        } else {
          virtualLocationGroup.style.display = 'none';
          physicalLocationGroup.style.display = 'block';
        }
      });
    }
    
    // Add event listener for the cancel button
    const cancelBtn = document.getElementById('cancel-meeting-btn');
    if (cancelBtn) {
      cancelBtn.addEventListener('click', () => {
        closeScheduler();
      });
    }
    
    // Add event listener for form submission
    const meetingForm = document.getElementById('meeting-form');
    if (meetingForm) {
      meetingForm.addEventListener('submit', (e) => {
        e.preventDefault();
        
        // Get form data
        const title = document.getElementById('meeting-title').value;
        const description = document.getElementById('meeting-description').value;
        const time = document.getElementById('meeting-time').value;
        const duration = document.getElementById('meeting-duration').value;
        const attendees = document.getElementById('meeting-attendees').value;
        const locationType = document.getElementById('meeting-location-type').value;
        
        // Get location based on type
        let location = '';
        if (locationType === 'Virtual') {
          location = document.getElementById('virtual-location').value;
        } else {
          location = document.getElementById('physical-location').value;
        }
        
        // Create meeting object
        const meeting = {
          title: title,
          description: description,
          date: date,
          start_time: time,
          duration_minutes: parseInt(duration),
          attendees: attendees,
          location_type: { type: locationType },
          location: location
        };
        
        // Schedule the meeting
        scheduleMeeting(meeting);
      });
    }
  } else {
    // Update the date in the title
    const title = schedulerDialog.querySelector('h2');
    if (title) {
      title.textContent = `Schedule Meeting for ${date}`;
    }
    
    // Reset the form
    const form = schedulerDialog.querySelector('form');
    if (form) {
      form.reset();
      
      // Regenerate meeting link
      const virtualLocationInput = document.getElementById('virtual-location');
      if (virtualLocationInput) {
        virtualLocationInput.value = generateMeetingLink('google');
      }
    }
  }
  
  // Show the dialog
  schedulerDialog.style.display = 'block';
  
  return { type: 'none' };
}

// Close the scheduler dialog
export function closeScheduler() {
  if (typeof document === 'undefined') {
    console.log('Document not available. Skipping closeScheduler.');
    return;
  }
  
  const schedulerDialog = document.querySelector('.scheduler-dialog');
  if (schedulerDialog) {
    schedulerDialog.style.display = 'none';
  }
  
  return { type: 'none' };
}

// Check if DOM is ready before initializing
export function checkReady(callback) {
  if (typeof document === 'undefined') {
    console.log('Document not available. Callback will not be executed.');
    return;
  }
  
  console.log("Calendar: Checking if DOM is ready for calendar initialization");
  
  // Function to check DOM state and run callback when ready
  const checkAndRunCallback = () => {
    try {
      console.log("Calendar: DOM check running at", new Date().toISOString());
      
      // First check if direct-calendar-root already exists (fastest path)
      const directRoot = document.getElementById('direct-calendar-root');
      if (directRoot) {
        console.log("Calendar: direct-calendar-root already exists, proceeding with initialization");
        callback();
        return;
      }
      
      // Check for the app-container structure from user's custom UI
      const appContainer = document.getElementById('app-container');
      const appDiv = document.getElementById('app');
      const mainContent = document.querySelector('.main-content');
      
      console.log("Calendar: Custom structure check:");
      console.log("  - app-container:", !!appContainer);
      console.log("  - app:", !!appDiv);
      console.log("  - main-content:", !!mainContent);
      
      // Check for calendar placeholder in custom structure
      if (appContainer && appDiv) {
        const placeholder = appDiv.querySelector('h1');
        
        if (placeholder && placeholder.textContent === 'Calendar') {
            console.log("Calendar: Found Calendar placeholder, replacing it and initializing");
            
            // Replace with direct-calendar-root
            const calendarRoot = document.createElement('div');
            calendarRoot.id = 'direct-calendar-root';
            calendarRoot.className = 'calendar-container';
            placeholder.parentNode.replaceChild(calendarRoot, placeholder);
            
            // Run callback immediately
            callback();
            return;
          } else {
          console.log("Calendar: Placeholder found but not for Calendar:", placeholder?.textContent);
        }
      }
      
      // Check if there's a placeholder page in main content
      if (mainContent) {
        const placeholder = mainContent.querySelector('.placeholder-page');
        if (placeholder && placeholder.querySelector('h1')?.textContent === 'Calendar') {
            console.log("Calendar: Found Calendar placeholder in main-content, replacing it");
            
            // Replace with direct-calendar-root
            const calendarRoot = document.createElement('div');
            calendarRoot.id = 'direct-calendar-root';
            calendarRoot.className = 'calendar-container';
            placeholder.parentNode.replaceChild(calendarRoot, placeholder);
          
          // Run callback immediately
          callback();
          return;
        }
      }
      
      // Check for standard calendar-root as fallback
      const calendarRoot = document.getElementById('calendar-root');
      if (calendarRoot) {
        console.log("Calendar: Found standard calendar-root, using it");
        callback();
        return;
      }
      
      // Last resort - create a calendar container if all else fails
      console.log("Calendar: No suitable container found, creating calendar root as last resort");
      createCalendarRoot();
      
      // Run the callback
      callback();
    } catch (err) {
      console.error("Calendar: Error during DOM check:", err);
      
      // Try to create a backup calendar root
      try {
        const calendarRoot = document.createElement('div');
        calendarRoot.id = 'direct-calendar-root';
        calendarRoot.style.position = 'fixed';
        calendarRoot.style.top = '0';
        calendarRoot.style.left = '0';
        calendarRoot.style.width = '100%';
        calendarRoot.style.height = '100%';
        calendarRoot.style.background = 'white';
        calendarRoot.style.zIndex = '1000';
        document.body.appendChild(calendarRoot);
        
        // Run callback with the error-fallback root
        callback();
      } catch (fallbackErr) {
        console.error("Calendar: Fatal error, couldn't create fallback root:", fallbackErr);
      }
    }
  };
  
  // First check if document is already ready
  if (document.readyState === 'complete' || document.readyState === 'interactive') {
    console.log("Calendar: Document already ready, checking DOM immediately");
    checkAndRunCallback();
  } else {
    // Otherwise wait for DOMContentLoaded
    console.log("Calendar: Document not ready, waiting for DOMContentLoaded");
    document.addEventListener('DOMContentLoaded', checkAndRunCallback);
    
    // Also set a timeout as a backup in case DOMContentLoaded doesn't fire
    setTimeout(checkAndRunCallback, 1000);
  }
}

// Check if the calendar root element exists
export function getCalendarRoot() {
  // First try to find the calendar root in the main content
  const mainContent = document.getElementById('main-content');
  if (mainContent) {
    const calendarRoot = mainContent.querySelector('#calendar-root');
    if (calendarRoot) {
      return calendarRoot;
    }
  }
  
  // Then try to find it directly in the document
  return document.getElementById('calendar-root');
}

// Create a calendar root element if needed
export function createCalendarRoot() {
  // First try to find the main content
  const mainContent = document.getElementById('main-content');
  if (mainContent) {
    // Create the calendar page structure
    mainContent.innerHTML = `
      <div class="calendar-page">
        <div class="calendar-header">
          <h1>Calendar</h1>
          <p>View and schedule your meetings</p>
        </div>
        <div id="calendar-root" class="calendar-container">
          <!-- Calendar will be initialized here -->
        </div>
      </div>
    `;
    return mainContent.querySelector('#calendar-root');
  }
  
  // Fallback to creating in body if no main content
  const root = document.createElement('div');
  root.id = 'calendar-root';
  root.className = 'calendar-container';
  document.body.appendChild(root);
  return root;
}

// Determine if we're in the main app or a standalone page
export function initCalendarWithAppEntrypoint() {
  console.log('Initializing calendar with app entrypoint');
  
  // Find or create the calendar root
  const calendarRoot = getCalendarRoot() || createCalendarRoot();
    
  if (!calendarRoot) {
    console.error('Failed to create calendar root');
    return;
  }
  
  console.log('Calendar root found/created:', calendarRoot);
  
  // Clear any existing content in the calendar root
  calendarRoot.innerHTML = '';
  
  // Initialize the calendar
  import('/build/dev/javascript/tandemx_client/calendar.mjs')
    .then(calendarModule => {
      console.log('Calendar module loaded, initializing');
      calendarModule.main();
    })
    .catch(err => {
      console.error('Error loading calendar module:', err);
    });
}

// Check if direct calendar root element exists
export function getDirectCalendarRoot() {
  if (typeof document === 'undefined') {
    console.log('Document not available. Returning null for getDirectCalendarRoot.');
    return null;
  }
  
  console.log("Calendar: Checking for direct-calendar-root");
  const directRoot = document.getElementById('direct-calendar-root');
  if (directRoot) {
    console.log("Calendar: Found direct-calendar-root");
    return true;
  }
  console.log("Calendar: No direct-calendar-root found");
  return false;
}

// Change the current month view
export function changeMonth(year, month) {
  if (typeof document === 'undefined') {
    console.log('Document not available. Skipping changeMonth.');
    return true;
  }
  
  console.log(`Changing calendar view to: ${year}-${month}`);
  setupCalendarGrid(year, month);
  return true;
}

// Load meetings from a backend or mock data
export function loadMeetings() {
  if (typeof document === 'undefined') {
    console.log('Document not available. Returning empty array for loadMeetings.');
    return [];
  }
  
  console.log('Loading meetings');
  return [];
}

// Select a specific date in the calendar
export function selectDate(dateStr) {
  if (typeof document === 'undefined') {
    console.log('Document not available. Skipping selectDate.');
    return true;
  }
  
  console.log(`Selecting date: ${dateStr}`);
  
  const dayCells = document.querySelectorAll('.day');
  dayCells.forEach(cell => {
    if (cell.dataset.date === dateStr) {
      cell.classList.add('selected');
    } else {
      cell.classList.remove('selected');
    }
  });
  
  return true;
}

// Load the calendar with initial data
export function loadCalendar() {
  if (typeof document === 'undefined') {
    console.log('Document not available. Skipping loadCalendar.');
    return true;
  }
  
  console.log('Loading calendar');
  const today = new Date();
  const currentMonth = today.getMonth() + 1;
  const currentYear = today.getFullYear();
  setupCalendarGrid(currentYear, currentMonth);
  return true;
}

// Get the current window width
export function getWindowWidth() {
  if (typeof window === 'undefined') return 800; // Default width if not in browser
  return window.innerWidth;
} 