/**
 * Calendar Translation Utility
 * Provides functionality to translate between different calendar systems:
 * - Gregorian (standard)
 * - Mayan
 * - Julian
 * - Hebrew
 * - Islamic
 * - Persian/Solar Hijri
 */

import * as mayanCalendar from './mayan_calendar.js';

// Calendar system types
export const CALENDAR_SYSTEMS = {
  GREGORIAN: 'gregorian',
  MAYAN: 'mayan',
  JULIAN: 'julian',
  HEBREW: 'hebrew',
  ISLAMIC: 'islamic',
  PERSIAN: 'persian'
};

/**
 * Convert a date from one calendar system to another
 * @param {Date|Object} date - Date to convert (JS Date object or system-specific format)
 * @param {String} fromSystem - Source calendar system
 * @param {String} toSystem - Target calendar system
 * @returns {Object} Date in the target calendar system
 */
export function translateDate(date, fromSystem, toSystem) {
  // If source and target systems are the same, return a clone of the date
  if (fromSystem === toSystem) {
    return cloneDate(date, fromSystem);
  }
  
  // Convert to Gregorian as an intermediate step
  const gregorianDate = toGregorian(date, fromSystem);
  
  // Convert from Gregorian to the target system
  return fromGregorian(gregorianDate, toSystem);
}

/**
 * Convert a date from any calendar system to Gregorian
 * @param {Date|Object} date - Date in source calendar system
 * @param {String} fromSystem - Source calendar system
 * @returns {Date} JavaScript Date object (Gregorian)
 */
export function toGregorian(date, fromSystem) {
  switch (fromSystem) {
    case CALENDAR_SYSTEMS.GREGORIAN:
      return date instanceof Date ? new Date(date) : new Date(date.year, date.month - 1, date.day);
      
    case CALENDAR_SYSTEMS.MAYAN:
      if (date instanceof Date) {
        return new Date(date);
      } else if (typeof date === 'object' && 'baktun' in date) {
        return mayanCalendar.mayanToGregorian(
          date.baktun, 
          date.katun, 
          date.tun, 
          date.uinal, 
          date.kin
        );
      } else if (typeof date === 'string') {
        // Parse long count format
        const components = mayanCalendar.parseLongCount(date);
        return mayanCalendar.mayanToGregorian(
          components.baktun,
          components.katun,
          components.tun,
          components.uinal,
          components.kin
        );
      }
      break;
      
    case CALENDAR_SYSTEMS.JULIAN:
      return julianToGregorian(date);
      
    case CALENDAR_SYSTEMS.HEBREW:
      return hebrewToGregorian(date);
      
    case CALENDAR_SYSTEMS.ISLAMIC:
      return islamicToGregorian(date);
      
    case CALENDAR_SYSTEMS.PERSIAN:
      return persianToGregorian(date);
      
    default:
      throw new Error(`Unsupported calendar system: ${fromSystem}`);
  }
}

/**
 * Convert a Gregorian date to another calendar system
 * @param {Date} date - JavaScript Date object (Gregorian)
 * @param {String} toSystem - Target calendar system
 * @returns {Object} Date in the target calendar system
 */
export function fromGregorian(date, toSystem) {
  switch (toSystem) {
    case CALENDAR_SYSTEMS.GREGORIAN:
      return new Date(date);
      
    case CALENDAR_SYSTEMS.MAYAN:
      return mayanCalendar.gregorianToMayan(date);
      
    case CALENDAR_SYSTEMS.JULIAN:
      return gregorianToJulian(date);
      
    case CALENDAR_SYSTEMS.HEBREW:
      return gregorianToHebrew(date);
      
    case CALENDAR_SYSTEMS.ISLAMIC:
      return gregorianToIslamic(date);
      
    case CALENDAR_SYSTEMS.PERSIAN:
      return gregorianToPersian(date);
      
    default:
      throw new Error(`Unsupported calendar system: ${toSystem}`);
  }
}

/**
 * Format a date according to the specified calendar system
 * @param {Date|Object} date - Date to format
 * @param {String} system - Calendar system to use for formatting
 * @param {Object} options - Formatting options
 * @returns {String} Formatted date string
 */
export function formatDate(date, system, options = {}) {
  switch (system) {
    case CALENDAR_SYSTEMS.GREGORIAN:
      return formatGregorianDate(date, options);
      
    case CALENDAR_SYSTEMS.MAYAN:
      return formatMayanDate(date, options);
      
    case CALENDAR_SYSTEMS.JULIAN:
      return formatJulianDate(date, options);
      
    case CALENDAR_SYSTEMS.HEBREW:
      return formatHebrewDate(date, options);
      
    case CALENDAR_SYSTEMS.ISLAMIC:
      return formatIslamicDate(date, options);
      
    case CALENDAR_SYSTEMS.PERSIAN:
      return formatPersianDate(date, options);
      
    default:
      throw new Error(`Unsupported calendar system: ${system}`);
  }
}

/**
 * Create a copy of a date in the specified calendar system
 * @param {Date|Object} date - Date to clone
 * @param {String} system - Calendar system
 * @returns {Object} Cloned date
 */
function cloneDate(date, system) {
  if (system === CALENDAR_SYSTEMS.GREGORIAN && date instanceof Date) {
    return new Date(date);
  }
  
  // For other systems, create a shallow copy of the object
  return { ...date };
}

/**
 * Format a Gregorian date
 * @param {Date} date - JavaScript Date object
 * @param {Object} options - Formatting options
 * @returns {String} Formatted date string
 */
function formatGregorianDate(date, options = {}) {
  const dateObj = date instanceof Date ? date : new Date(date.year, date.month - 1, date.day);
  
  const format = options.format || 'long';
  const locale = options.locale || 'en-US';
  
  switch (format) {
    case 'short':
      return dateObj.toLocaleDateString(locale, { 
        year: 'numeric', 
        month: 'numeric', 
        day: 'numeric' 
      });
    
    case 'medium':
      return dateObj.toLocaleDateString(locale, { 
        year: 'numeric', 
        month: 'short', 
        day: 'numeric' 
      });
    
    case 'long':
    default:
      return dateObj.toLocaleDateString(locale, { 
        year: 'numeric', 
        month: 'long', 
        day: 'numeric' 
      });
  }
}

/**
 * Format a Mayan date
 * @param {Object} date - Mayan date object
 * @param {Object} options - Formatting options
 * @returns {String} Formatted Mayan date string
 */
function formatMayanDate(date, options = {}) {
  let mayanDate;
  
  if (date instanceof Date) {
    mayanDate = mayanCalendar.gregorianToMayan(date);
  } else if (typeof date === 'object' && 'baktun' in date) {
    mayanDate = date;
  } else {
    throw new Error('Invalid Mayan date format');
  }
  
  const format = options.format || 'long';
  
  switch (format) {
    case 'longCount':
      return mayanDate.longCount;
    
    case 'tzolkin':
      return mayanDate.tzolkin;
    
    case 'haab':
      return mayanDate.haab;
    
    case 'short':
      return `${mayanDate.longCount}`;
    
    case 'long':
    default:
      return `${mayanDate.longCount} ${mayanDate.tzolkin} ${mayanDate.haab}`;
  }
}

// Julian calendar conversions
// The Julian calendar was used until 1582 when it was replaced by the Gregorian calendar
// There's a difference of about 10-13 days between the two calendars

/**
 * Convert Julian date to Gregorian
 * @param {Object|Date} date - Date in Julian calendar
 * @returns {Date} Date in Gregorian calendar
 */
function julianToGregorian(date) {
  // Simple implementation for modern dates
  // For accurate historical conversion, more complex logic would be needed
  const julianDate = date instanceof Date ?
    { year: date.getFullYear(), month: date.getMonth() + 1, day: date.getDate() } : date;
  
  // Calculate Julian day number
  let a = Math.floor((14 - julianDate.month) / 12);
  let y = julianDate.year + 4800 - a;
  let m = julianDate.month + 12 * a - 3;
  
  let jdn = julianDate.day + Math.floor((153 * m + 2) / 5) + 365 * y + Math.floor(y / 4) - 32083;
  
  // Convert to Gregorian
  let b = 0;
  
  // Check if after Gregorian adoption (1582-10-15)
  if (jdn > 2299160) {
    // Adjust for Gregorian calendar
    let c = Math.floor((jdn - 2299160) / 36524.25);
    b = jdn + 1 + c - Math.floor(c / 4);
  } else {
    b = jdn;
  }
  
  let c = b + 32082;
  let d = Math.floor((4 * c + 3) / 1461);
  let e = c - Math.floor((1461 * d) / 4);
  let m2 = Math.floor((5 * e + 2) / 153);
  
  let day = e - Math.floor((153 * m2 + 2) / 5) + 1;
  let month = m2 + 3 - 12 * Math.floor(m2 / 10);
  let year = d - 4800 + Math.floor(m2 / 10);
  
  return new Date(year, month - 1, day);
}

/**
 * Convert Gregorian date to Julian
 * @param {Date} date - Date in Gregorian calendar
 * @returns {Object} Date in Julian calendar
 */
function gregorianToJulian(date) {
  // Simple implementation for modern dates
  const year = date.getFullYear();
  const month = date.getMonth() + 1;
  const day = date.getDate();
  
  // Calculate Julian day number for Gregorian date
  let a = Math.floor((14 - month) / 12);
  let y = year + 4800 - a;
  let m = month + 12 * a - 3;
  
  let jdn = day + Math.floor((153 * m + 2) / 5) + 365 * y + 
            Math.floor(y / 4) - Math.floor(y / 100) + Math.floor(y / 400) - 32045;
  
  // Check if before Gregorian adoption (1582-10-15)
  if (year < 1582 || (year === 1582 && month < 10) || (year === 1582 && month === 10 && day < 15)) {
    // Before adoption, Julian and Gregorian are the same
    return { year, month, day };
  }
  
  // Calculate Julian date from JDN
  let b = jdn + 32082;
  let c = Math.floor((4 * b + 3) / 1461);
  let d = b - Math.floor((1461 * c) / 4);
  let e = Math.floor((5 * d + 2) / 153);
  
  let julianDay = d - Math.floor((153 * e + 2) / 5) + 1;
  let julianMonth = e + 3 - 12 * Math.floor(e / 10);
  let julianYear = c - 4800 + Math.floor(e / 10);
  
  return { year: julianYear, month: julianMonth, day: julianDay };
}

/**
 * Format a Julian date
 * @param {Object} date - Julian date object
 * @param {Object} options - Formatting options
 * @returns {String} Formatted Julian date string
 */
function formatJulianDate(date, options = {}) {
  const julianDate = date instanceof Date ? gregorianToJulian(date) : date;
  const format = options.format || 'long';
  
  const monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  
  switch (format) {
    case 'short':
      return `${julianDate.day}/${julianDate.month}/${julianDate.year}`;
    
    case 'medium':
      return `${julianDate.day} ${monthNames[julianDate.month - 1].substring(0, 3)} ${julianDate.year}`;
    
    case 'long':
    default:
      return `${julianDate.day} ${monthNames[julianDate.month - 1]} ${julianDate.year} (Julian)`;
  }
}

// Hebrew calendar conversion placeholders
// The Hebrew calendar is a lunisolar calendar
function hebrewToGregorian(date) {
  // This would be a complex implementation
  // For this example, we return the original date
  console.warn('Hebrew calendar conversion not fully implemented');
  return date instanceof Date ? new Date(date) : new Date(date.year, date.month - 1, date.day);
}

function gregorianToHebrew(date) {
  // For demonstration purposes only
  console.warn('Hebrew calendar conversion not fully implemented');
  
  // Return a simple object with Hebrew date components
  // In a real implementation, this would do proper conversion
  return {
    year: 5783, // Example Hebrew year
    month: 1,
    day: 1,
    monthName: 'Tishrei',
    format: () => '1 Tishrei 5783'
  };
}

function formatHebrewDate(date, options = {}) {
  // Simplified for demonstration
  const hebrewDate = date instanceof Date ? gregorianToHebrew(date) : date;
  return hebrewDate.format ? hebrewDate.format() : '1 Tishrei 5783';
}

// Islamic calendar conversion placeholders
// The Islamic calendar is a lunar calendar
function islamicToGregorian(date) {
  console.warn('Islamic calendar conversion not fully implemented');
  return date instanceof Date ? new Date(date) : new Date(date.year, date.month - 1, date.day);
}

function gregorianToIslamic(date) {
  console.warn('Islamic calendar conversion not fully implemented');
  
  // Return a simple object with Islamic date components
  return {
    year: 1444, // Example Islamic year
    month: 1,
    day: 1,
    monthName: 'Muharram',
    format: () => '1 Muharram 1444 AH'
  };
}

function formatIslamicDate(date, options = {}) {
  const islamicDate = date instanceof Date ? gregorianToIslamic(date) : date;
  return islamicDate.format ? islamicDate.format() : '1 Muharram 1444 AH';
}

// Persian calendar conversion placeholders
// The Persian calendar (Solar Hijri) is a solar calendar
function persianToGregorian(date) {
  console.warn('Persian calendar conversion not fully implemented');
  return date instanceof Date ? new Date(date) : new Date(date.year, date.month - 1, date.day);
}

function gregorianToPersian(date) {
  console.warn('Persian calendar conversion not fully implemented');
  
  // Return a simple object with Persian date components
  return {
    year: 1401, // Example Persian year
    month: 1,
    day: 1,
    monthName: 'Farvardin',
    format: () => '1 Farvardin 1401'
  };
}

function formatPersianDate(date, options = {}) {
  const persianDate = date instanceof Date ? gregorianToPersian(date) : date;
  return persianDate.format ? persianDate.format() : '1 Farvardin 1401';
}

/**
 * Get information about a date in all supported calendar systems
 * @param {Date} date - JavaScript Date object
 * @returns {Object} Date information in all calendar systems
 */
export function getAllCalendarSystems(date) {
  return {
    [CALENDAR_SYSTEMS.GREGORIAN]: {
      date: new Date(date),
      formatted: formatGregorianDate(date)
    },
    [CALENDAR_SYSTEMS.MAYAN]: {
      date: mayanCalendar.gregorianToMayan(date),
      formatted: formatMayanDate(date)
    },
    [CALENDAR_SYSTEMS.JULIAN]: {
      date: gregorianToJulian(date),
      formatted: formatJulianDate(date)
    },
    [CALENDAR_SYSTEMS.HEBREW]: {
      date: gregorianToHebrew(date),
      formatted: formatHebrewDate(date)
    },
    [CALENDAR_SYSTEMS.ISLAMIC]: {
      date: gregorianToIslamic(date),
      formatted: formatIslamicDate(date)
    },
    [CALENDAR_SYSTEMS.PERSIAN]: {
      date: gregorianToPersian(date),
      formatted: formatPersianDate(date)
    }
  };
}

export default {
  CALENDAR_SYSTEMS,
  translateDate,
  toGregorian,
  fromGregorian,
  formatDate,
  getAllCalendarSystems
}; 