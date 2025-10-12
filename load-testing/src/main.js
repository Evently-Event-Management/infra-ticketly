import { check } from 'k6';
import http from 'k6/http';
import { Rate } from 'k6/metrics';
import { sleep } from 'k6';
import { Trend } from 'k6/metrics';

// Import configuration and data
import { config } from './config.js';
import { getAuthToken } from './lib/auth.js';
import { getRandomItem } from './lib/utils.js';

// Import test scenarios
import { smokeTestScenario } from './scenarios/smoke.js';
import { loadTestScenario } from './scenarios/load.js';
import { stressTestScenario } from './scenarios/stress.js';
import { soakTestScenario } from './scenarios/soak.js';
import { spikeTestScenario } from './scenarios/spike.js';
import { breakpointTestScenario } from './scenarios/breakpoint.js';
import { debugTestScenario } from './scenarios/debug.js';

// Define metrics
export const errorRate = new Rate('errors');
export const eventSearchTrend = new Trend('event_search');
export const eventDetailsTrend = new Trend('event_details');
export const sessionDetailsTrend = new Trend('session_details');
export const trendingEventsTrend = new Trend('trending_events');
export const seatValidationTrend = new Trend('seat_validation');
export const preOrderValidationTrend = new Trend('pre_order_validation');

// Test scenarios configuration
export const options = {
  scenarios: __ENV.ONLY_SCENARIO ? 
    // If ONLY_SCENARIO is set, only include that scenario
    { 
      [__ENV.SCENARIO]: eval(`${__ENV.SCENARIO}TestScenario`) 
    } 
    // Otherwise include all scenarios
    : {
      smoke: smokeTestScenario,
      load: loadTestScenario,
      stress: stressTestScenario,
      soak: soakTestScenario,
      spike: spikeTestScenario,
      breakpoint: breakpointTestScenario,
      debug: debugTestScenario
    },
  thresholds: {
    // Set thresholds for key metrics
    'http_req_duration': ['p(95)<1000'], // 95% of requests should be below 1s
    'http_req_failed': ['rate<0.05'],     // Error rate should be below 5%
    'event_search': ['p(95)<1500'],       // 95% of event search requests should be below 1.5s
    'trending_events': ['p(95)<800'],     // 95% of trending events requests should be below 800ms
    'seat_validation': ['p(95)<1200'],    // 95% of seat validation requests should be below 1.2s
  }
};

// k6 setup function (runs once per VU initialization)
export function setup() {
  console.log('Starting load test setup');
  const authToken = getAuthToken(config.auth.clientId, config.auth.clientSecret);
  console.log('Authentication completed');
  return { authToken };
}

// k6 default function (runs for each VU iteration)
export default function(data) {
  // Select a scenario based on the environment variable or run all endpoints
  const scenarioName = __ENV.SCENARIO || 'default';
  
  // Get auth token from setup
  const authToken = data.authToken;
  
  // Log which scenario we're running
  console.log(`Running ${scenarioName} scenario`);
  
  try {
    // Always run the mixed test flow, regardless of scenario
    // This ensures we're making actual API calls for all scenarios
    testMixedFlow(authToken);
  } catch (error) {
    console.error(`Error in test execution: ${error.message}`);
    errorRate.add(1);
  }
}

// Mixed flow testing multiple endpoints
function testMixedFlow(authToken) {
  const baseUrl = config.baseUrl;
  const params = {
    headers: {
      'Authorization': `Bearer ${authToken}`,
      'Content-Type': 'application/json',
    },
    timeout: '10s', // Set a 10-second timeout for all requests
  };
  
  // Test trending events endpoint
  let response = http.get(`${baseUrl}/v1/events/trending?limit=10`, params);
  const trendingSuccess = check(response, {
    'trending events status is 200': (r) => r.status === 200,
  });
  
  if (!trendingSuccess) {
    console.error(`Trending events failed with status ${response.status}: ${response.body}`);
    errorRate.add(1);
  }
  trendingEventsTrend.add(response.timings.duration);
  
  // Get a sample event ID from the trending events (if available)
  let eventId = config.sampleEventId; // Default to the sample ID
  if (response.status === 200) {
    try {
      const events = JSON.parse(response.body);
      if (events && events.length > 0) {
        eventId = events[0].id;
      }
    } catch (e) {
      console.error('Failed to parse trending events response');
    }
  }
  
  // Test event details
  response = http.get(`${baseUrl}/v1/events/${eventId}/basic-info`, params);
  const eventDetailsSuccess = check(response, {
    'event details status is 200': (r) => r.status === 200,
  });
  
  if (!eventDetailsSuccess) {
    console.error(`Event details failed with status ${response.status}: ${response.body}`);
    errorRate.add(1);
  }
  eventDetailsTrend.add(response.timings.duration);
  
  // Test event sessions
  response = http.get(`${baseUrl}/v1/events/${eventId}/sessions?pageable.page=0&pageable.size=10`, params);
  const eventSessionsSuccess = check(response, {
    'event sessions status is 200': (r) => r.status === 200,
  });
  
  if (!eventSessionsSuccess) {
    console.error(`Event sessions failed with status ${response.status}: ${response.body}`);
    errorRate.add(1);
  }
  
  // Get a session ID if available
  let sessionId = config.sampleSessionId; // Default to the sample ID
  if (response.status === 200) {
    try {
      const sessionsData = JSON.parse(response.body);
      if (sessionsData && sessionsData.content && sessionsData.content.length > 0) {
        sessionId = sessionsData.content[0].id;
      }
    } catch (e) {
      console.error('Failed to parse sessions response');
    }
  }
  
  // Test session details
  response = http.get(`${baseUrl}/v1/sessions/${sessionId}/basic-info`, params);
  const sessionDetailsSuccess = check(response, {
    'session details status is 200': (r) => r.status === 200,
  });
  
  if (!sessionDetailsSuccess) {
    console.error(`Session details failed with status ${response.status}: ${response.body}`);
    errorRate.add(1);
  }
  sessionDetailsTrend.add(response.timings.duration);
  
  // Test search endpoint with different parameters
  const searchParams = {
    'searchTerm': getRandomItem(config.searchTerms),
    'pageable.page': 0,
    'pageable.size': 10
  };
  
  // Add optional parameters randomly
  if (Math.random() > 0.5) {
    searchParams.categoryId = getRandomItem(config.categoryIds);
  }
  
  if (Math.random() > 0.7) {
    searchParams.priceMin = Math.floor(Math.random() * 50);
    searchParams.priceMax = 50 + Math.floor(Math.random() * 200);
  }
  
  // Manually build the query string instead of using URLSearchParams
  let queryParams = [];
  for (const key in searchParams) {
    if (searchParams.hasOwnProperty(key)) {
      queryParams.push(`${encodeURIComponent(key)}=${encodeURIComponent(searchParams[key])}`);
    }
  }
  
  const searchUrl = `${baseUrl}/v1/events/search?${queryParams.join('&')}`;
  response = http.get(searchUrl, params);
  const searchSuccess = check(response, {
    'search events status is 200': (r) => r.status === 200,
  });
  
  if (!searchSuccess) {
    console.error(`Event search failed with status ${response.status}: ${response.body}`);
    errorRate.add(1);
  }
  eventSearchTrend.add(response.timings.duration);
  
  // Random sleep between requests to simulate user behavior (1-3 seconds)
  sleep(Math.random() * 2 + 1);
}

export function teardown(data) {
  console.log('Completed load test');
}