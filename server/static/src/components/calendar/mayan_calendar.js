/**
 * Mayan Calendar Implementation
 * This module provides utilities for working with the Mayan calendar system
 * and translating between Mayan dates and Gregorian dates.
 */

// Constants for Mayan calendar cycles
const TZOLKIN_DAYS = [
  'Imix', 'Ik', 'Akbal', 'Kan', 'Chicchan', 
  'Cimi', 'Manik', 'Lamat', 'Muluc', 'Oc', 
  'Chuen', 'Eb', 'Ben', 'Ix', 'Men', 
  'Cib', 'Caban', 'Etznab', 'Cauac', 'Ahau'
];

const TZOLKIN_NUMBERS = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13];

const HAAB_MONTHS = [
  'Pop', 'Uo', 'Zip', 'Zotz', 'Tzec', 
  'Xul', 'Yaxkin', 'Mol', 'Chen', 'Yax', 
  'Zac', 'Ceh', 'Mac', 'Kankin', 'Muan', 
  'Pax', 'Kayab', 'Cumku', 'Uayeb'
];

// The correlation constant (number of days between Jan 1, 1970 and the Mayan date 0.0.0.0.0)
// Using the Goodman-Martinez-Thompson (GMT) correlation: 584283
const MAYAN_EPOCH_OFFSET = 584283 + 719163; // Days from Unix epoch (Jan 1, 1970) to Mayan epoch

// Number of days in each Mayan calendar cycle
const DAYS_IN_KIN = 1;
const DAYS_IN_UINAL = 20;
const DAYS_IN_TUN = 360;
const DAYS_IN_KATUN = 7200; // 20 tuns
const DAYS_IN_BAKTUN = 144000; // 20 katuns

/**
 * Convert a Gregorian date to a Long Count Mayan date
 * @param {Date} date - JavaScript Date object
 * @returns {Object} Mayan date in Long Count, Tzolkin, and Haab
 */
export function gregorianToMayan(date) {
  // Calculate days since Unix epoch (Jan 1, 1970)
  const unixEpoch = new Date(1970, 0, 1);
  let daysSinceUnixEpoch = Math.floor((date - unixEpoch) / (1000 * 60 * 60 * 24));
  
  // Calculate days since Mayan epoch
  let daysSinceMayanEpoch = daysSinceUnixEpoch + MAYAN_EPOCH_OFFSET;
  
  // Calculate the Long Count
  let baktun = Math.floor(daysSinceMayanEpoch / DAYS_IN_BAKTUN);
  daysSinceMayanEpoch %= DAYS_IN_BAKTUN;
  
  let katun = Math.floor(daysSinceMayanEpoch / DAYS_IN_KATUN);
  daysSinceMayanEpoch %= DAYS_IN_KATUN;
  
  let tun = Math.floor(daysSinceMayanEpoch / DAYS_IN_TUN);
  daysSinceMayanEpoch %= DAYS_IN_TUN;
  
  let uinal = Math.floor(daysSinceMayanEpoch / DAYS_IN_UINAL);
  daysSinceMayanEpoch %= DAYS_IN_UINAL;
  
  let kin = daysSinceMayanEpoch;
  
  // Calculate Tzolkin date
  // The Tzolkin date consists of a number (1-13) and a day name (0-19)
  let tzolkinDay = (daysSinceUnixEpoch + MAYAN_EPOCH_OFFSET + 19) % 20;
  let tzolkinNumber = (daysSinceUnixEpoch + MAYAN_EPOCH_OFFSET + 3) % 13 + 1;
  
  // Calculate Haab date
  // The Haab date consists of a position (0-19) and a month (0-18)
  let dayOfHaabYear = (daysSinceUnixEpoch + MAYAN_EPOCH_OFFSET + 348) % 365;
  let haabMonth = Math.floor(dayOfHaabYear / 20);
  let haabDay = dayOfHaabYear % 20;
  
  return {
    longCount: `${baktun}.${katun}.${tun}.${uinal}.${kin}`,
    tzolkin: `${tzolkinNumber} ${TZOLKIN_DAYS[tzolkinDay]}`,
    haab: `${haabDay} ${HAAB_MONTHS[haabMonth]}`,
    baktun,
    katun,
    tun,
    uinal,
    kin,
    tzolkinDay: TZOLKIN_DAYS[tzolkinDay],
    tzolkinNumber,
    haabDay,
    haabMonth: HAAB_MONTHS[haabMonth]
  };
}

/**
 * Convert a Long Count Mayan date to a Gregorian date
 * @param {Number} baktun - The baktun count
 * @param {Number} katun - The katun count
 * @param {Number} tun - The tun count
 * @param {Number} uinal - The uinal count
 * @param {Number} kin - The kin count
 * @returns {Date} JavaScript Date object
 */
export function mayanToGregorian(baktun, katun, tun, uinal, kin) {
  // Calculate days since Mayan epoch
  let daysSinceMayanEpoch = 
    baktun * DAYS_IN_BAKTUN +
    katun * DAYS_IN_KATUN +
    tun * DAYS_IN_TUN +
    uinal * DAYS_IN_UINAL +
    kin;
  
  // Calculate days since Unix epoch
  let daysSinceUnixEpoch = daysSinceMayanEpoch - MAYAN_EPOCH_OFFSET;
  
  // Create a new Date starting from Unix epoch and add the days
  let unixEpoch = new Date(1970, 0, 1);
  unixEpoch.setDate(unixEpoch.getDate() + daysSinceUnixEpoch);
  
  return unixEpoch;
}

/**
 * Get the Mayan date representation as a formatted string
 * @param {Date} date - JavaScript Date object
 * @returns {String} Formatted Mayan date string
 */
export function formatMayanDate(date) {
  const mayanDate = gregorianToMayan(date);
  return `${mayanDate.longCount} ${mayanDate.tzolkin} ${mayanDate.haab}`;
}

/**
 * Parse a Long Count Mayan date string
 * @param {String} longCount - The Long Count date in format "baktun.katun.tun.uinal.kin"
 * @returns {Object} The parsed Mayan date components
 */
export function parseLongCount(longCount) {
  const parts = longCount.split('.');
  if (parts.length !== 5) {
    throw new Error('Invalid Long Count format. Expected baktun.katun.tun.uinal.kin');
  }
  
  return {
    baktun: parseInt(parts[0], 10),
    katun: parseInt(parts[1], 10),
    tun: parseInt(parts[2], 10),
    uinal: parseInt(parts[3], 10),
    kin: parseInt(parts[4], 10)
  };
}

/**
 * Calculate the Mayan calendar round position
 * @param {Date} date - JavaScript Date object
 * @returns {String} Calendar round position (Tzolkin + Haab)
 */
export function getCalendarRound(date) {
  const mayanDate = gregorianToMayan(date);
  return `${mayanDate.tzolkin} ${mayanDate.haab}`;
}

/**
 * Get the name of the current day in the Tzolkin calendar
 * @param {Date} date - JavaScript Date object
 * @returns {String} Current Tzolkin day name
 */
export function getTzolkinDay(date) {
  const mayanDate = gregorianToMayan(date);
  return mayanDate.tzolkinDay;
}

/**
 * Get the Haab date representation
 * @param {Date} date - JavaScript Date object
 * @returns {String} Current Haab date
 */
export function getHaabDate(date) {
  const mayanDate = gregorianToMayan(date);
  return `${mayanDate.haabDay} ${mayanDate.haabMonth}`;
}

/**
 * Check if two dates fall on the same day in the Mayan calendar
 * @param {Date} date1 - First JavaScript Date object
 * @param {Date} date2 - Second JavaScript Date object
 * @returns {Boolean} True if the dates fall on the same Mayan day
 */
export function isSameMayanDay(date1, date2) {
  const mayan1 = gregorianToMayan(date1);
  const mayan2 = gregorianToMayan(date2);
  
  return mayan1.longCount === mayan2.longCount;
}

/**
 * Generate a name for an event based on the Mayan calendar date
 * @param {Date} date - JavaScript Date object
 * @returns {String} A name based on the Mayan calendar energies
 */
export function generateMayanEventName(date) {
  const mayanDate = gregorianToMayan(date);
  return `${mayanDate.tzolkinNumber} ${mayanDate.tzolkinDay} / ${mayanDate.haabDay} ${mayanDate.haabMonth}`;
}

/**
 * Calculate the Mayan date for the next significant cycle completion
 * @param {Date} fromDate - Starting date
 * @returns {Object} Next significant date in both Mayan and Gregorian calendars
 */
export function getNextSignificantDate(fromDate) {
  const mayanDate = gregorianToMayan(fromDate);
  
  // We'll look for the next completion of a tun, katun, or baktun
  let nextSignificantMayanDate;
  let significance;
  
  if (mayanDate.uinal === 17 && mayanDate.kin === 19) {
    // About to complete a tun
    nextSignificantMayanDate = {
      baktun: mayanDate.baktun,
      katun: mayanDate.katun,
      tun: mayanDate.tun + 1,
      uinal: 0,
      kin: 0
    };
    significance = 'Tun completion';
  } else if (mayanDate.tun === 19 && mayanDate.uinal === 17 && mayanDate.kin === 19) {
    // About to complete a katun
    nextSignificantMayanDate = {
      baktun: mayanDate.baktun,
      katun: mayanDate.katun + 1,
      tun: 0,
      uinal: 0,
      kin: 0
    };
    significance = 'Katun completion';
  } else if (mayanDate.katun === 19 && mayanDate.tun === 19 && mayanDate.uinal === 17 && mayanDate.kin === 19) {
    // About to complete a baktun
    nextSignificantMayanDate = {
      baktun: mayanDate.baktun + 1,
      katun: 0,
      tun: 0,
      uinal: 0,
      kin: 0
    };
    significance = 'Baktun completion';
  } else {
    // Otherwise find next tun completion
    nextSignificantMayanDate = {
      baktun: mayanDate.baktun,
      katun: mayanDate.katun,
      tun: mayanDate.tun + 1,
      uinal: 0,
      kin: 0
    };
    significance = 'Tun completion';
  }
  
  const nextGregorianDate = mayanToGregorian(
    nextSignificantMayanDate.baktun,
    nextSignificantMayanDate.katun,
    nextSignificantMayanDate.tun,
    nextSignificantMayanDate.uinal,
    nextSignificantMayanDate.kin
  );
  
  return {
    mayan: `${nextSignificantMayanDate.baktun}.${nextSignificantMayanDate.katun}.${nextSignificantMayanDate.tun}.${nextSignificantMayanDate.uinal}.${nextSignificantMayanDate.kin}`,
    gregorian: nextGregorianDate,
    significance
  };
}

/**
 * Get a list of Mayan calendar energies for a given month
 * @param {Number} year - Gregorian year
 * @param {Number} month - Gregorian month (1-12)
 * @returns {Array} Array of daily energies for the month
 */
export function getMonthMayanEnergies(year, month) {
  const daysInMonth = new Date(year, month, 0).getDate();
  const energies = [];
  
  for (let day = 1; day <= daysInMonth; day++) {
    const date = new Date(year, month - 1, day);
    const mayanDate = gregorianToMayan(date);
    
    energies.push({
      gregorianDate: `${year}-${month.toString().padStart(2, '0')}-${day.toString().padStart(2, '0')}`,
      tzolkin: `${mayanDate.tzolkinNumber} ${mayanDate.tzolkinDay}`,
      haab: `${mayanDate.haabDay} ${mayanDate.haabMonth}`,
      longCount: mayanDate.longCount
    });
  }
  
  return energies;
}

/**
 * Get the Mayan day glyph (simplified text representation) for a given date
 * @param {Date} date - JavaScript Date object
 * @returns {String} Text representation of Mayan day glyph
 */
export function getDayGlyph(date) {
  const mayanDate = gregorianToMayan(date);
  const tzolkinDayMapping = {
    'Imix': '🐊', // Crocodile/Water Lily/Primordial Earth
    'Ik': '💨', // Wind/Breath/Spirit
    'Akbal': '🌑', // Night/Darkness/House
    'Kan': '🌽', // Seed/Corn/Lizard
    'Chicchan': '🐍', // Serpent
    'Cimi': '💀', // Death/Transformation
    'Manik': '🦌', // Deer/Hand
    'Lamat': '⭐', // Venus/Rabbit/Star
    'Muluc': '💧', // Water/Rain/Moon/Offering
    'Oc': '🐕', // Dog/Guide
    'Chuen': '🐒', // Monkey/Artisan
    'Eb': '🦷', // Tooth/Human/Road
    'Ben': '🌽', // Corn/Reed/Green
    'Ix': '🐆', // Jaguar/Shaman
    'Men': '🦅', // Eagle/Bird
    'Cib': '🦉', // Owl/Wisdom
    'Caban': '🌎', // Earth/Movement
    'Etznab': '🔪', // Flint/Mirror/Knife
    'Cauac': '🌩️', // Storm/Rain
    'Ahau': '☀️'  // Sun/Lord/Flower
  };
  
  return tzolkinDayMapping[mayanDate.tzolkinDay] || mayanDate.tzolkinDay;
}

export default {
  gregorianToMayan,
  mayanToGregorian,
  formatMayanDate,
  parseLongCount,
  getCalendarRound,
  getTzolkinDay,
  getHaabDate,
  isSameMayanDay,
  generateMayanEventName,
  getNextSignificantDate,
  getMonthMayanEnergies,
  getDayGlyph,
  TZOLKIN_DAYS,
  TZOLKIN_NUMBERS,
  HAAB_MONTHS
}; 