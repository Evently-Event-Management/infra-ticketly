import http from 'k6/http';
import { sleep, check } from 'k6';
import { config } from '../config.js';
import { errorRate, eventDetailsTrend, eventSearchTrend, sessionDetailsTrend, trendingEventsTrend } from '../main.js';

/**
 * Makes API requests to test the trending events endpoint
 * @param {string} authToken - Authentication token
 */
export function testTrendingEvents(authToken) {
  const params = {
    headers: {
      'Authorization': `Bearer ${authToken}`,
      'Content-Type': 'application/json',
    },
  };
  
  const response = http.get(`${config.baseUrl}/v1/events/trending?limit=10`, params);
  
  check(response, {
    'trending events status is 200': (r) => r.status === 200,
    'trending events response has events': (r) => {
      try {
        const events = JSON.parse(r.body);
        return Array.isArray(events) && events.length > 0;
      } catch (e) {
        return false;
      }
    },
  }) || errorRate.add(1);
  
  trendingEventsTrend.add(response.timings.duration);
  return response;
}

/**
 * Makes API requests to test the event search endpoint
 * @param {string} authToken - Authentication token
 * @param {Object} searchParams - Search parameters
 */
export function testEventSearch(authToken, searchParams = {}) {
  const params = {
    headers: {
      'Authorization': `Bearer ${authToken}`,
      'Content-Type': 'application/json',
    },
  };
  
  // Default search parameters
  const defaultParams = {
    'pageable.page': 0,
    'pageable.size': 10
  };
  
  // Combine default and provided parameters
  const combinedParams = { ...defaultParams, ...searchParams };
  
  const searchUrl = `${config.baseUrl}/v1/events/search?` + new URLSearchParams(combinedParams).toString();
  
  const response = http.get(searchUrl, params);
  
  check(response, {
    'search events status is 200': (r) => r.status === 200,
    'search events response is valid': (r) => {
      try {
        const data = JSON.parse(r.body);
        return data && typeof data.totalElements !== 'undefined';
      } catch (e) {
        return false;
      }
    },
  }) || errorRate.add(1);
  
  eventSearchTrend.add(response.timings.duration);
  return response;
}

/**
 * Makes API requests to test the event details endpoint
 * @param {string} authToken - Authentication token
 * @param {string} eventId - Event ID
 */
export function testEventDetails(authToken, eventId = config.sampleEventId) {
  const params = {
    headers: {
      'Authorization': `Bearer ${authToken}`,
      'Content-Type': 'application/json',
    },
  };
  
  const response = http.get(`${config.baseUrl}/v1/events/${eventId}/basic-info`, params);
  
  check(response, {
    'event details status is 200': (r) => r.status === 200,
    'event details response is valid': (r) => {
      try {
        const event = JSON.parse(r.body);
        return event && event.id === eventId;
      } catch (e) {
        return false;
      }
    },
  }) || errorRate.add(1);
  
  eventDetailsTrend.add(response.timings.duration);
  return response;
}

/**
 * Makes API requests to test the session details endpoint
 * @param {string} authToken - Authentication token
 * @param {string} sessionId - Session ID
 */
export function testSessionDetails(authToken, sessionId = config.sampleSessionId) {
  const params = {
    headers: {
      'Authorization': `Bearer ${authToken}`,
      'Content-Type': 'application/json',
    },
  };
  
  const response = http.get(`${config.baseUrl}/v1/sessions/${sessionId}/basic-info`, params);
  
  check(response, {
    'session details status is 200': (r) => r.status === 200,
    'session details response is valid': (r) => {
      try {
        const session = JSON.parse(r.body);
        return session && session.id === sessionId;
      } catch (e) {
        return false;
      }
    },
  }) || errorRate.add(1);
  
  sessionDetailsTrend.add(response.timings.duration);
  return response;
}

/**
 * Makes API requests to test the event sessions endpoint
 * @param {string} authToken - Authentication token
 * @param {string} eventId - Event ID
 */
export function testEventSessions(authToken, eventId = config.sampleEventId) {
  const params = {
    headers: {
      'Authorization': `Bearer ${authToken}`,
      'Content-Type': 'application/json',
    },
  };
  
  const response = http.get(`${config.baseUrl}/v1/events/${eventId}/sessions?pageable.page=0&pageable.size=10`, params);
  
  check(response, {
    'event sessions status is 200': (r) => r.status === 200,
    'event sessions response is valid': (r) => {
      try {
        const sessionsData = JSON.parse(r.body);
        return sessionsData && Array.isArray(sessionsData.content);
      } catch (e) {
        return false;
      }
    },
  }) || errorRate.add(1);
  
  return response;
}

/**
 * Makes API requests to test the seating map endpoint
 * @param {string} authToken - Authentication token
 * @param {string} sessionId - Session ID
 */
export function testSessionSeatingMap(authToken, sessionId = config.sampleSessionId) {
  const params = {
    headers: {
      'Authorization': `Bearer ${authToken}`,
      'Content-Type': 'application/json',
    },
  };
  
  const response = http.get(`${config.baseUrl}/v1/sessions/${sessionId}/seating-map`, params);
  
  check(response, {
    'seating map status is 200': (r) => r.status === 200,
    'seating map response is valid': (r) => {
      try {
        const seatingMap = JSON.parse(r.body);
        return seatingMap && seatingMap.layout;
      } catch (e) {
        return false;
      }
    },
  }) || errorRate.add(1);
  
  return response;
}

/**
 * Makes API requests to test the categories endpoint
 * @param {string} authToken - Authentication token
 */
export function testCategories(authToken) {
  const params = {
    headers: {
      'Authorization': `Bearer ${authToken}`,
      'Content-Type': 'application/json',
    },
  };
  
  const response = http.get(`${config.baseUrl}/v1/categories`, params);
  
  check(response, {
    'categories status is 200': (r) => r.status === 200,
    'categories response is valid': (r) => {
      try {
        const categories = JSON.parse(r.body);
        return Array.isArray(categories);
      } catch (e) {
        return false;
      }
    },
  }) || errorRate.add(1);
  
  return response;
}