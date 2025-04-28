/**
 * Gleam runtime support functions for JavaScript
 * This file provides helper functions for Gleam-generated JavaScript code
 */

/**
 * Convert a JavaScript array to a Gleam list
 * @param {Array} array - JavaScript array to convert
 * @returns {Object} - Gleam list representation
 */
export function toList(array) {
  let list = { type: "Nil" };
  
  for (let i = array.length - 1; i >= 0; i--) {
    list = { 
      type: "Cons", 
      head: array[i], 
      tail: list 
    };
  }
  
  return list;
}

/**
 * Convert a Gleam list to a JavaScript array
 * @param {Object} list - Gleam list to convert
 * @returns {Array} - JavaScript array
 */
export function toArray(list) {
  const array = [];
  let current = list;
  
  while (current.type === "Cons") {
    array.push(current.head);
    current = current.tail;
  }
  
  return array;
}

/**
 * Check if a value is null or undefined
 * @param {any} value - Value to check
 * @returns {boolean} - True if the value is null or undefined
 */
export function isNil(value) {
  return value === null || value === undefined;
}

/**
 * Create a Result.Ok value
 * @param {any} value - The value to wrap
 * @returns {Object} - Result.Ok object
 */
export function Ok(value) {
  return { type: "Ok", value };
}

/**
 * Create a Result.Error value
 * @param {any} error - The error value
 * @returns {Object} - Result.Error object
 */
export function Error(error) {
  return { type: "Error", error };
}

/**
 * Create a tuple of two values
 * @param {any} first - First value
 * @param {any} second - Second value
 * @returns {Array} - Tuple as a JavaScript array
 */
export function tuple(first, second) {
  return [first, second];
}

/**
 * Identity function - returns the input value unchanged
 * @param {any} x - Input value
 * @returns {any} - Same value
 */
export function identity(x) {
  return x;
} 