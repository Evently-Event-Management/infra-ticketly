import http from 'k6/http';
import { check } from 'k6';
import { config } from '../config.js';
import { errorRate } from '../main.js';

/**
 * Makes API requests to test the analytics endpoints
 * @param {string} authToken - Authentication token
 * @param {string} eventId - Event ID
 * @param {string} sessionId - Session ID
 */
export function testAnalytics(authToken, eventId, sessionId) {
  if (!eventId) {
    throw new Error('eventId is required for analytics testing');
  }
  const params = {
    headers: {
      'Authorization': `Bearer ${authToken}`,
      'Content-Type': 'application/json',
    },
  };
  
  // Test event analytics
  let response = http.get(`${config.query.baseUrl}/v1/analytics/events/${eventId}`, params);
  
  check(response, {
    'event analytics status is 200': (r) => r.status === 200,
  }) || errorRate.add(1);
  
  // Test session analytics for event
  response = http.get(`${config.query.baseUrl}/v1/analytics/events/${eventId}/sessions`, params);
  
  check(response, {
    'event sessions analytics status is 200': (r) => r.status === 200,
  }) || errorRate.add(1);
  
  // Test specific session analytics
  if (!sessionId) {
    throw new Error('sessionId is required for session analytics testing');
  }

  response = http.get(`${config.query.baseUrl}/v1/analytics/events/${eventId}/sessions/${sessionId}`, params);
  
  check(response, {
    'session analytics status is 200': (r) => r.status === 200,
  }) || errorRate.add(1);
  
  return response;
}