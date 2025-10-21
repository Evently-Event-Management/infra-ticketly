import { Rate, Trend } from 'k6/metrics';

// Store iteration counters per VU
let iterationCounters = {};

import { getAuthToken } from './lib/auth.js';
import { simulateTicketPurchaseQueryFlow, simulateOrderServiceFlow } from './lib/workflows.js';
import { applyEnvironment } from './config.js';

// Apply environment overrides during init so all modules see the correct endpoints
const initEnvironmentKey = (typeof __ENV !== 'undefined' ? (__ENV.ENV || '') : '').toLowerCase();
if (initEnvironmentKey) {
  applyEnvironment(initEnvironmentKey);
}

// Import test scenarios
import { smokeTestScenario } from './scenarios/smoke.js';
import { loadTestScenario } from './scenarios/load.js';
import { stressTestScenario } from './scenarios/stress.js';
import { soakTestScenario } from './scenarios/soak.js';
import { spikeTestScenario } from './scenarios/spike.js';
import { breakpointTestScenario } from './scenarios/breakpoint.js';
import { debugTestScenario } from './scenarios/debug.js';
import { orderRaceTestScenario } from './scenarios/order-race.js';
import { stepUpLoadScenario } from './scenarios/query-step-up.js';

// Define metrics
export const errorRate = new Rate('errors');
export const eventSearchTrend = new Trend('event_search');
export const eventDetailsTrend = new Trend('event_details');
export const sessionDetailsTrend = new Trend('session_details');
export const trendingEventsTrend = new Trend('trending_events');
export const eventSessionsTrend = new Trend('event_sessions');
export const seatingMapTrend = new Trend('seating_map');
export const orderRequestTrend = new Trend('order_request');
export const orderSuccessRate = new Rate('order_success');

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
      stepUp: stepUpLoadScenario,
      stress: stressTestScenario,
      soak: soakTestScenario,
      spike: spikeTestScenario,
      breakpoint: breakpointTestScenario,
      debug: debugTestScenario,
      orderRace: orderRaceTestScenario,
    },
  thresholds: {
    'http_req_duration': ['p(95)<1000'], // 95% of requests should be below 1s
    'http_req_failed': ['rate<0.05'],     // Error rate should be below 5%
    'event_search': ['p(95)<1500'],       // 95% of event search requests should be below 1.5s
    'trending_events': ['p(95)<800'],     // 95% of trending events requests should be below 800ms
    'event_sessions': ['p(95)<1200'],     // 95% of session list requests should be below 1.2s
    'seating_map': ['p(95)<1200'],        // 95% of seating map requests should be below 1.2s
  }
};

// k6 setup function (runs once per VU initialization)
export function setup() {
  console.log('Starting load test setup');
  const environmentKey = (__ENV.ENV || '').toLowerCase();
  applyEnvironment(environmentKey);
  const authToken = getAuthToken();
  console.log('Authentication completed');
  return { authToken };
}

// k6 default function (runs for each VU iteration)
export default function (data) {
  // Select a scenario based on the environment variable or run all endpoints
  const scenarioName = __ENV.SCENARIO || 'default';
  const serviceUnderTest = (__ENV.SERVICE || 'query').toLowerCase();

  // Get auth token from setup
  const authToken = data.authToken;

  // Use the VU ID to track iterations per virtual user
  const vuId = __VU || 'shared';

  // Initialize counter for this VU if it doesn't exist
  if (!iterationCounters[vuId]) {
    iterationCounters[vuId] = 0;
    // Only log on first iteration of each VU
    console.log(`Running ${scenarioName} scenario targeting ${serviceUnderTest} service`);
  }

  // Increment the counter
  iterationCounters[vuId]++;

  try {
    if (serviceUnderTest === 'query') {
      simulateTicketPurchaseQueryFlow(authToken, {
        trends: {
          trendingEvents: trendingEventsTrend,
          eventSearch: eventSearchTrend,
          eventDetails: eventDetailsTrend,
          eventSessions: eventSessionsTrend,
          sessionDetails: sessionDetailsTrend,
          seatingMap: seatingMapTrend,
        },
      });
    } else if (serviceUnderTest === 'order') {
      simulateOrderServiceFlow(authToken, {
        metrics: {
          requestTrend: orderRequestTrend,
          successRate: orderSuccessRate,
        },
      });
    } else {
      throw new Error(`Unsupported service target "${serviceUnderTest}"`);
    }
  } catch (error) {
    console.error(`Error in ${serviceUnderTest} service execution: ${error.message}`);
    errorRate.add(1);
  }
}

export function teardown(data) {
  console.log('Completed load test');
}