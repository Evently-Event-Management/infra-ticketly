import { SharedArray } from 'k6/data';
import { uuidv4 } from 'https://jslib.k6.io/k6-utils/1.4.0/index.js';

/**
 * Generate a random UUID
 * @returns {string} UUID v4 string
 */
export function generateUUID() {
  return uuidv4();
}

/**
 * Get a random item from an array
 * @param {Array} array - The array to select from
 * @returns {*} A random item from the array
 */
export function getRandomItem(array) {
  if (!array || array.length === 0) {
    return null;
  }
  return array[Math.floor(Math.random() * array.length)];
}

/**
 * Get a random number between min and max (inclusive)
 * @param {number} min - Minimum value
 * @param {number} max - Maximum value
 * @returns {number} Random number between min and max
 */
export function getRandomNumber(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

/**
 * Format date for API requests
 * @param {Date} date - Date object
 * @returns {string} Formatted date string
 */
export function formatDate(date) {
  return date.toISOString();
}

/**
 * Generate a random date within a range from now
 * @param {number} minDays - Minimum days from now
 * @param {number} maxDays - Maximum days from now
 * @returns {Date} Random date
 */
export function randomFutureDate(minDays = 1, maxDays = 30) {
  const now = new Date();
  const randomDays = getRandomNumber(minDays, maxDays);
  now.setDate(now.getDate() + randomDays);
  return now;
}

/**
 * Generate payload for seat validation request
 * @param {string} eventId - Event ID
 * @param {string} sessionId - Session ID
 * @param {Array<string>} seatIds - Array of seat IDs
 * @returns {Object} Payload object
 */
export function generateSeatValidationPayload(eventId, sessionId, seatIds) {
  return {
    event_id: eventId,
    session_id: sessionId,
    seat_ids: seatIds
  };
}

/**
 * Generate payload for pre-order validation request
 * @param {string} eventId - Event ID
 * @param {string} sessionId - Session ID
 * @param {Array<string>} seatIds - Array of seat IDs
 * @param {string} discountId - Optional discount ID
 * @returns {Object} Payload object
 */
export function generatePreOrderPayload(eventId, sessionId, seatIds, discountId = null) {
  const payload = {
    event_id: eventId,
    session_id: sessionId,
    seat_ids: seatIds
  };
  
  if (discountId) {
    payload.discount_id = discountId;
  }
  
  return payload;
}