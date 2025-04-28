/**
 * Calendar System Selector Component
 * This module provides UI components for selecting and displaying different calendar systems.
 */

import { CALENDAR_SYSTEMS } from './calendar_translation.js';
import * as calendarFfi from './calendar_ffi.js';

/**
 * Create a calendar system selector element
 * @param {Function} onChangeCallback - Callback function when system is changed
 * @returns {HTMLElement} Calendar system selector element
 */
export function createCalendarSystemSelector(onChangeCallback) {
  // Create container
  const container = document.createElement('div');
  container.className = 'calendar-system-selector';
  
  // Create label
  const label = document.createElement('label');
  label.textContent = 'Calendar System:';
  label.htmlFor = 'calendar-system-select';
  
  // Create select element
  const select = document.createElement('select');
  select.id = 'calendar-system-select';
  select.className = 'system-select';
  
  // Add options for each calendar system
  const systems = [
    { id: CALENDAR_SYSTEMS.MAYAN, name: 'Mayan' },
    { id: CALENDAR_SYSTEMS.GREGORIAN, name: 'Gregorian' },
    { id: CALENDAR_SYSTEMS.JULIAN, name: 'Julian' },
    { id: CALENDAR_SYSTEMS.HEBREW, name: 'Hebrew' },
    { id: CALENDAR_SYSTEMS.ISLAMIC, name: 'Islamic' },
    { id: CALENDAR_SYSTEMS.PERSIAN, name: 'Persian' }
  ];
  
  systems.forEach(system => {
    const option = document.createElement('option');
    option.value = system.id;
    option.textContent = system.name;
    
    // Set Mayan as default selected
    if (system.id === CALENDAR_SYSTEMS.MAYAN) {
      option.selected = true;
    }
    
    select.appendChild(option);
  });
  
  // Add change event listener
  select.addEventListener('change', (event) => {
    const selectedSystem = event.target.value;
    calendarFfi.setCalendarSystem(selectedSystem);
    
    if (typeof onChangeCallback === 'function') {
      onChangeCallback(selectedSystem);
    }
    
    // Update display based on selection
    calendarFfi.convertCalendarDisplay(selectedSystem);
  });
  
  // Assemble container
  container.appendChild(label);
  container.appendChild(select);
  
  return container;
}

/**
 * Create a calendar date info panel that shows the current date in all calendar systems
 * @param {Date} date - Date to display
 * @returns {HTMLElement} Calendar date info panel
 */
export function createCalendarInfoPanel(date) {
  // Create container
  const container = document.createElement('div');
  container.className = 'calendar-info-panel';
  
  // Create header
  const header = document.createElement('h3');
  header.textContent = 'Calendar Systems';
  container.appendChild(header);
  
  // Get date in all calendar systems
  const allSystems = calendarFfi.getAllCalendarSystems(date.toISOString().split('T')[0]);
  
  // Create info for each system
  Object.entries(allSystems).forEach(([systemId, systemData]) => {
    const systemContainer = document.createElement('div');
    systemContainer.className = `calendar-system-info ${systemId}`;
    
    const systemHeader = document.createElement('h4');
    systemHeader.textContent = systemId.charAt(0).toUpperCase() + systemId.slice(1);
    
    const systemDate = document.createElement('div');
    systemDate.className = 'system-date';
    systemDate.textContent = systemData.formatted;
    
    systemContainer.appendChild(systemHeader);
    systemContainer.appendChild(systemDate);
    container.appendChild(systemContainer);
    
    // Add special handling for Mayan calendar
    if (systemId === CALENDAR_SYSTEMS.MAYAN) {
      const mayanData = systemData.date;
      
      // Add Long Count
      const longCount = document.createElement('div');
      longCount.className = 'mayan-longcount';
      longCount.textContent = `Long Count: ${mayanData.longCount}`;
      systemContainer.appendChild(longCount);
      
      // Add Tzolkin
      const tzolkin = document.createElement('div');
      tzolkin.className = 'mayan-tzolkin-info';
      tzolkin.textContent = `Tzolkin: ${mayanData.tzolkin}`;
      systemContainer.appendChild(tzolkin);
      
      // Add Haab
      const haab = document.createElement('div');
      haab.className = 'mayan-haab-info';
      haab.textContent = `Haab: ${mayanData.haab}`;
      systemContainer.appendChild(haab);
      
      // Add day glyph
      const glyph = document.createElement('div');
      glyph.className = 'mayan-glyph-large';
      glyph.textContent = calendarFfi.getMayanDayGlyph(date.toISOString().split('T')[0]);
      systemContainer.appendChild(glyph);
    }
  });
  
  return container;
}

/**
 * Initialize calendar system UI
 * @param {HTMLElement} container - Container element to add UI components to
 */
export function initCalendarSystemUI(container) {
  // Create system selector
  const selector = createCalendarSystemSelector((system) => {
    console.log('Calendar system changed to:', system);
  });
  
  // Create calendar info panel for today
  const today = new Date();
  const infoPanel = createCalendarInfoPanel(today);
  
  // Add components to container
  container.appendChild(selector);
  container.appendChild(infoPanel);
  
  // Initialize the calendar with Mayan display
  setTimeout(() => {
    calendarFfi.initMayanCalendar();
  }, 500);
}

export default {
  createCalendarSystemSelector,
  createCalendarInfoPanel,
  initCalendarSystemUI
}; 