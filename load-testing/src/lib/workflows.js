import http from 'k6/http';
import { sleep, check } from 'k6';
import { config } from '../config.js';
import { getRandomItem } from './utils.js';

function toQueryString(params) {
  const parts = [];
  for (const [key, value] of Object.entries(params)) {
    if (value === undefined || value === null) {
      continue;
    }
    parts.push(`${encodeURIComponent(key)}=${encodeURIComponent(String(value))}`);
  }
  return parts.join('&');
}

function recordTrend(trends, key, response) {
  if (!trends || !trends[key] || !response || typeof response.timings?.duration !== 'number') {
    return;
  }
  trends[key].add(response.timings.duration);
}

function parseJson(body, description, response = null) {
  try {
    return JSON.parse(body);
  } catch (error) {
    console.error(`Failed to parse ${description}: ${error.message}`);
    if (response) {
      console.error(`Response status: ${response.status}`);
      console.error(`Response body (first 500 chars): ${String(body).substring(0, 500)}`);
      console.error(`Response headers: ${JSON.stringify(response.headers)}`);
    } else {
      console.error(`Response body (first 500 chars): ${String(body).substring(0, 500)}`);
    }
    throw new Error(`Invalid JSON response for ${description}`);
  }
}

function ensureId(value, description) {
  if (value) {
    return value;
  }
  console.error(`Missing ${description} in API response`);
  throw new Error(`Missing ${description}`);
}

/**
 * Simulates core read-only user interactions with the query service.
 * Steps
 * 1. Fetch trending events
 * 2. Search for events
 * 3. Load event details
 * 4. Fetch event sessions
 * 5. Load session details
 * 6. Fetch the seating map
 *
 * @param {string} authToken - JWT access token string
 * @param {{ trends?: Record<string, import('k6/metrics').Trend> }} [dependencies]
 * @returns {{ eventId: string, sessionId: string, seatIds: string[] }}
 */
export function simulateTicketPurchaseQueryFlow(authToken, { trends } = {}) {
  const queryConfig = config.query;
  const baseUrl = queryConfig.baseUrl;

  const params = {
    headers: {
      Authorization: `Bearer ${authToken}`,
      'Content-Type': 'application/json',
    },
    timeout: '10s',
  };

  // Only log in first VU or in debug scenario
  if (__VU <= 1 || __ENV.SCENARIO === 'debug') {
    console.log('Step 1: Browsing trending events');
  }
  const trendingResponse = http.get(`${baseUrl}/v1/events/trending?limit=10`, params);
  recordTrend(trends, 'trendingEvents', trendingResponse);

  const trendingEvents = parseJson(trendingResponse.body, 'trending events', trendingResponse);
  const trendingSuccess = check(trendingResponse, {
    'trending events status is 200': (r) => r.status === 200,
    'trending events list is not empty': () => Array.isArray(trendingEvents) && trendingEvents.length > 0,
  });

  if (!trendingSuccess) {
    throw new Error('Trending events request failed');
  }

  let eventId = ensureId(trendingEvents[0]?.id, 'event id');

  sleep(Math.random() * 2 + 1);

  if (__VU <= 1 || __ENV.SCENARIO === 'debug') {
    console.log('Step 2: Searching for events');
  }
  const searchTerm = getRandomItem(queryConfig.searchTerms) || 'event';
  const searchParams = toQueryString({
    searchTerm,
    'pageable.page': '0',
    'pageable.size': '10',
  });

  const searchResponse = http.get(`${baseUrl}/v1/events/search?${searchParams}`, params);
  recordTrend(trends, 'eventSearch', searchResponse);

  const searchData = parseJson(searchResponse.body, 'event search', searchResponse);
  const searchSuccess = check(searchResponse, {
    'search events status is 200': (r) => r.status === 200,
    'search results contain content': () => Array.isArray(searchData?.content) && searchData.content.length > 0,
  });

  if (!searchSuccess) {
    throw new Error('Event search request failed');
  }

  if (!eventId) {
  eventId = ensureId(searchData.content[0]?.id, 'event id from search');
  }

  sleep(Math.random() * 3 + 2);

  if (__VU <= 1 || __ENV.SCENARIO === 'debug') {
    console.log(`Step 3: Viewing details for event ${eventId}`);
  }
  const eventDetailsResponse = http.get(`${baseUrl}/v1/events/${eventId}/basic-info`, params);
  recordTrend(trends, 'eventDetails', eventDetailsResponse);

  const eventDetails = parseJson(eventDetailsResponse.body, 'event details', eventDetailsResponse);
  const eventDetailsSuccess = check(eventDetailsResponse, {
    'event details status is 200': (r) => r.status === 200,
    'event details match id': () => eventDetails?.id === eventId,
  });

  if (!eventDetailsSuccess) {
    throw new Error('Event details request failed');
  }

  sleep(Math.random() * 2 + 1);

  if (__VU <= 1 || __ENV.SCENARIO === 'debug') {
    console.log(`Step 4: Fetching sessions for event ${eventId}`);
  }
  const sessionsResponse = http.get(`${baseUrl}/v1/events/${eventId}/sessions?pageable.page=0&pageable.size=10`, params);
  recordTrend(trends, 'eventSessions', sessionsResponse);

  const sessionsData = parseJson(sessionsResponse.body, 'event sessions', sessionsResponse);
  const sessionsSuccess = check(sessionsResponse, {
    'event sessions status is 200': (r) => r.status === 200,
    'event sessions list is not empty': () => Array.isArray(sessionsData?.content) && sessionsData.content.length > 0,
  });

  if (!sessionsSuccess) {
    throw new Error('Event sessions request failed');
  }

  const sessionId = ensureId(sessionsData.content[0]?.id, 'session id');

  sleep(Math.random() * 2 + 1);

  if (__VU <= 1 || __ENV.SCENARIO === 'debug') {
    console.log(`Step 5: Viewing details for session ${sessionId}`);
  }
  const sessionDetailsResponse = http.get(`${baseUrl}/v1/sessions/${sessionId}/basic-info`, params);
  recordTrend(trends, 'sessionDetails', sessionDetailsResponse);

  const sessionDetails = parseJson(sessionDetailsResponse.body, 'session details', sessionDetailsResponse);
  const sessionDetailsSuccess = check(sessionDetailsResponse, {
    'session details status is 200': (r) => r.status === 200,
    'session details match id': () => sessionDetails?.id === sessionId,
  });

  if (!sessionDetailsSuccess) {
    throw new Error('Session details request failed');
  }

  sleep(Math.random() * 2 + 1);

  if (__VU <= 1 || __ENV.SCENARIO === 'debug') {
    console.log(`Step 6: Fetching seating map for session ${sessionId}`);
  }
  const seatingMapResponse = http.get(`${baseUrl}/v1/sessions/${sessionId}/seating-map`, params);
  recordTrend(trends, 'seatingMap', seatingMapResponse);

  const seatingMap = parseJson(seatingMapResponse.body, 'seating map', seatingMapResponse);
  const seatingMapSuccess = check(seatingMapResponse, {
    'seating map status is 200': (r) => r.status === 200,
    'seating map contains layout information': () => Boolean(seatingMap?.layout),
  });

  if (!seatingMapSuccess) {
    throw new Error('Seating map request failed');
  }

  if (__VU <= 1 || __ENV.SCENARIO === 'debug') {
    console.log('Ticket query flow simulation completed');
  }
  return { eventId, sessionId };
}

/**
 * Simulates order stress testing flow where users randomly attempt to book
 * different seats. Both 201 (success) and 400 (seat locked) are considered
 * expected responses during stress testing.
 */
export function simulateOrderStressFlow(authToken, seatId, { metrics } = {}) {
  const orderConfig = config.order;
  const baseUrl = (__ENV.ORDER_BASE_URL || orderConfig.baseUrl).replace(/\/$/, '');

  const eventId = __ENV.ORDER_EVENT_ID || orderConfig.eventId;
  const sessionId = __ENV.ORDER_SESSION_ID || orderConfig.sessionId;
  const organizationId = __ENV.ORDER_ORGANIZATION_ID || orderConfig.organizationId;
  const discountId = Object.prototype.hasOwnProperty.call(__ENV, 'ORDER_DISCOUNT_ID')
    ? __ENV.ORDER_DISCOUNT_ID || null
    : null;

  if (!eventId || !sessionId || !organizationId) {
    throw new Error('Order workflow requires event, session, and organization identifiers.');
  }

  if (!seatId) {
    throw new Error('Order workflow requires a seat ID.');
  }

  const payload = {
    event_id: eventId,
    session_id: sessionId,
    seat_ids: [seatId],
    organization_id: organizationId,
    discount_id: discountId,
  };

  const params = {
    headers: {
      Authorization: `Bearer ${authToken}`,
      'Content-Type': 'application/json',
    },
    timeout: '10s',
  };

  const response = http.post(baseUrl, JSON.stringify(payload), params);

  if (metrics?.requestTrend && typeof response.timings?.duration === 'number') {
    metrics.requestTrend.add(response.timings.duration);
  }

  let responseBody;
  let isJsonResponse = false;
  
  try {
    if (response.body && response.body.trim()) {
      responseBody = JSON.parse(response.body);
      isJsonResponse = true;
    }
  } catch (error) {
    // Response is not JSON (likely plain text error message)
    responseBody = { message: response.body };
    isJsonResponse = false;
  }

  // For stress testing: 201 (success) and 400 (already locked) are both expected
  const isSuccess = response.status === 200 || response.status === 201;
  const isExpected = isSuccess || response.status === 400;

  if (metrics?.successRate) {
    metrics.successRate.add(isSuccess);
  }

  if (metrics?.expectedRate) {
    metrics.expectedRate.add(isExpected);
  }

  return { response, responseBody };
}

/**
 * Simulates a contention-heavy order placement flow where many users attempt
 * to book the same seat simultaneously. Expects most calls to fail while at
 * least one succeeds. Uses environment overrides when provided.
 */
export function simulateOrderServiceFlow(authToken, { metrics } = {}) {
  const orderConfig = config.order;
  const baseUrl = (__ENV.ORDER_BASE_URL || orderConfig.baseUrl).replace(/\/$/, '');

  const eventId = __ENV.ORDER_EVENT_ID || orderConfig.eventId;
  const sessionId = __ENV.ORDER_SESSION_ID || orderConfig.sessionId;
  const organizationId = __ENV.ORDER_ORGANIZATION_ID || orderConfig.organizationId;
  const discountId = Object.prototype.hasOwnProperty.call(__ENV, 'ORDER_DISCOUNT_ID')
    ? __ENV.ORDER_DISCOUNT_ID || null
    : null;

  const defaultSeat = Array.isArray(orderConfig.seatIds) ? orderConfig.seatIds[0] : undefined;
  const seatId = __ENV.ORDER_SEAT_ID || defaultSeat;

  if (!eventId || !sessionId || !organizationId) {
    throw new Error('Order workflow requires event, session, and organization identifiers.');
  }

  if (!seatId) {
    throw new Error('Order workflow requires a seat ID. Provide ORDER_SEAT_ID or configure config.order.seatIds.');
  }

  const payload = {
    event_id: eventId,
    session_id: sessionId,
    seat_ids: [seatId],
    organization_id: organizationId,
    discount_id: discountId,
  };

  const params = {
    headers: {
      Authorization: `Bearer ${authToken}`,
      'Content-Type': 'application/json',
    },
    timeout: '10s',
  };

  if (__VU <= 1 || __ENV.SCENARIO === 'debug') {
    console.log(`Attempting order for seat ${seatId} in session ${sessionId}`);
  }
  const response = http.post(baseUrl, JSON.stringify(payload), params);

  if (metrics?.requestTrend && typeof response.timings?.duration === 'number') {
    metrics.requestTrend.add(response.timings.duration);
  }

  let responseBody;
  let isJsonResponse = false;
  
  try {
    if (response.body && response.body.trim()) {
      responseBody = JSON.parse(response.body);
      isJsonResponse = true;
    }
  } catch (error) {
    // Response is not JSON (likely plain text error message)
    responseBody = { message: response.body };
    isJsonResponse = false;
    if (__VU <= 3 || __ENV.SCENARIO === 'debug') {
      console.log(`Order response is plain text (status ${response.status}): ${response.body}`);
    }
  }

  const success = response.status === 200 || response.status === 201;
  if (metrics?.successRate) {
    metrics.successRate.add(success);
  }

  if (__VU <= 3 || __ENV.SCENARIO === 'debug') {
    if (!success) {
      const errorMsg = isJsonResponse 
        ? JSON.stringify(responseBody) 
        : responseBody.message || response.body;
      console.warn(`Order attempt failed (${response.status}): ${errorMsg}`);
    } else if (responseBody?.order_id) {
      console.log(`Order succeeded with id ${responseBody.order_id}`);
    } else {
      console.log('Order succeeded (no order_id returned).');
    }
  }

  return { success, response, responseBody };
}