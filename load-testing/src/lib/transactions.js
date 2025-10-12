import http from 'k6/http';
import { sleep, check } from 'k6';
import { config } from '../config.js';
import { errorRate, seatValidationTrend, preOrderValidationTrend } from '../main.js';
import { generatePreOrderPayload, generateSeatValidationPayload } from '../utils.js';

/**
 * Makes API requests to test the seat validation endpoint
 * @param {string} authToken - Authentication token
 * @param {string} eventId - Event ID
 * @param {string} sessionId - Session ID
 * @param {Array<string>} seatIds - Array of seat IDs
 */
export function testSeatValidation(authToken, eventId = config.sampleEventId, 
                                  sessionId = config.sampleSessionId, 
                                  seatIds = config.sampleSeatIds) {
  const params = {
    headers: {
      'Authorization': `Bearer ${authToken}`,
      'Content-Type': 'application/json',
    },
  };
  
  const payload = generateSeatValidationPayload(eventId, sessionId, seatIds);
  
  const response = http.post(
    `${config.baseUrl}/internal/v1/sessions/${sessionId}/seats/validate`, 
    JSON.stringify(payload), 
    params
  );
  
  check(response, {
    'seat validation status is 200': (r) => r.status === 200,
    'seat validation response is valid': (r) => {
      try {
        const result = JSON.parse(r.body);
        return result && typeof result.allAvailable !== 'undefined';
      } catch (e) {
        return false;
      }
    },
  }) || errorRate.add(1);
  
  seatValidationTrend.add(response.timings.duration);
  return response;
}

/**
 * Makes API requests to test the seat details endpoint
 * @param {string} authToken - Authentication token
 * @param {string} eventId - Event ID
 * @param {string} sessionId - Session ID
 * @param {Array<string>} seatIds - Array of seat IDs
 */
export function testSeatDetails(authToken, eventId = config.sampleEventId, 
                               sessionId = config.sampleSessionId, 
                               seatIds = config.sampleSeatIds) {
  const params = {
    headers: {
      'Authorization': `Bearer ${authToken}`,
      'Content-Type': 'application/json',
    },
  };
  
  const payload = generateSeatValidationPayload(eventId, sessionId, seatIds);
  
  const response = http.post(
    `${config.baseUrl}/internal/v1/sessions/${sessionId}/seats/details`, 
    JSON.stringify(payload), 
    params
  );
  
  check(response, {
    'seat details status is 200': (r) => r.status === 200,
    'seat details response is valid': (r) => {
      try {
        const result = JSON.parse(r.body);
        return Array.isArray(result);
      } catch (e) {
        return false;
      }
    },
  }) || errorRate.add(1);
  
  return response;
}

/**
 * Makes API requests to test the pre-order validation endpoint
 * @param {string} authToken - Authentication token
 * @param {string} eventId - Event ID
 * @param {string} sessionId - Session ID
 * @param {Array<string>} seatIds - Array of seat IDs
 * @param {string} discountId - Optional discount ID
 */
export function testPreOrderValidation(authToken, eventId = config.sampleEventId, 
                                     sessionId = config.sampleSessionId, 
                                     seatIds = config.sampleSeatIds, 
                                     discountId = null) {
  const params = {
    headers: {
      'Authorization': `Bearer ${authToken}`,
      'Content-Type': 'application/json',
    },
  };
  
  const payload = generatePreOrderPayload(eventId, sessionId, seatIds, discountId);
  
  const response = http.post(
    `${config.baseUrl}/internal/v1/validate-pre-order`, 
    JSON.stringify(payload), 
    params
  );
  
  check(response, {
    'pre-order validation status is 200': (r) => r.status === 200,
    'pre-order validation response is valid': (r) => {
      try {
        const result = JSON.parse(r.body);
        return result && Array.isArray(result.seats);
      } catch (e) {
        return false;
      }
    },
  }) || errorRate.add(1);
  
  preOrderValidationTrend.add(response.timings.duration);
  return response;
}

/**
 * Makes API requests to test the trending score calculation endpoint
 * @param {string} authToken - Authentication token
 * @param {string} eventId - Event ID
 */
export function testTrendingScoreCalculation(authToken, eventId = config.sampleEventId) {
  const params = {
    headers: {
      'Authorization': `Bearer ${authToken}`,
      'Content-Type': 'application/json',
    },
  };
  
  const response = http.post(
    `${config.baseUrl}/internal/v1/trending/events/${eventId}/calculate`, 
    {},
    params
  );
  
  check(response, {
    'trending score calculation status is 200': (r) => r.status === 200,
  }) || errorRate.add(1);
  
  return response;
}

/**
 * Makes API requests to test the analytics endpoints
 * @param {string} authToken - Authentication token
 * @param {string} eventId - Event ID
 * @param {string} sessionId - Session ID
 */
export function testAnalytics(authToken, eventId = config.sampleEventId, sessionId = config.sampleSessionId) {
  const params = {
    headers: {
      'Authorization': `Bearer ${authToken}`,
      'Content-Type': 'application/json',
    },
  };
  
  // Test event analytics
  let response = http.get(`${config.baseUrl}/v1/analytics/events/${eventId}`, params);
  
  check(response, {
    'event analytics status is 200': (r) => r.status === 200,
  }) || errorRate.add(1);
  
  // Test session analytics for event
  response = http.get(`${config.baseUrl}/v1/analytics/events/${eventId}/sessions`, params);
  
  check(response, {
    'event sessions analytics status is 200': (r) => r.status === 200,
  }) || errorRate.add(1);
  
  // Test specific session analytics
  response = http.get(`${config.baseUrl}/v1/analytics/events/${eventId}/sessions/${sessionId}`, params);
  
  check(response, {
    'session analytics status is 200': (r) => r.status === 200,
  }) || errorRate.add(1);
  
  return response;
}