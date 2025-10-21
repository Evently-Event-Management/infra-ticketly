import { Rate, Trend } from 'k6/metrics';
import { getAuthToken, getValidToken } from './src/lib/auth.js';
import { simulateOrderServiceFlow } from './src/lib/workflows.js';
import { applyEnvironment } from './src/config.js';

// Apply environment overrides during init
const initEnvironmentKey = (typeof __ENV !== 'undefined' ? (__ENV.ENV || '') : '').toLowerCase();
if (initEnvironmentKey) {
  applyEnvironment(initEnvironmentKey);
}

// Import order test scenario
import { orderRaceTestScenario } from './src/scenarios/order-race.js';

// Define metrics
export const errorRate = new Rate('errors');
export const orderRequestTrend = new Trend('order_request');
export const orderSuccessRate = new Rate('order_success');

// Test scenarios configuration
export const options = {
  scenarios: {
    orderRace: orderRaceTestScenario,
  },
  thresholds: {
    'http_req_duration': ['p(95)<2000'],
    'http_req_failed': ['rate<0.99'], // Most should fail due to contention
    'order_request': ['p(95)<2000'],
    'order_success': ['rate>0'], // At least one should succeed
  }
};

// Store iteration counters per VU
let iterationCounters = {};

// Store token data per VU to allow refreshing
let tokenCache = {};

export function setup() {
  console.log('Starting order service contention test setup');
  const environmentKey = (__ENV.ENV || '').toLowerCase();
  applyEnvironment(environmentKey);
  const tokenData = getAuthToken();
  console.log('Authentication completed');
  return { tokenData };
}

export default function (data) {
  const vuId = __VU || 'shared';

  // Initialize or refresh token for this VU
  if (!tokenCache[vuId]) {
    tokenCache[vuId] = data.tokenData;
  }
  
  // Check and refresh token if needed
  tokenCache[vuId] = getValidToken(tokenCache[vuId]);
  const authToken = tokenCache[vuId].access_token;

  if (!iterationCounters[vuId]) {
    iterationCounters[vuId] = 0;
    console.log(`Running order contention scenario (VU ${vuId})`);
  }

  iterationCounters[vuId]++;

  try {
    simulateOrderServiceFlow(authToken, {
      metrics: {
        requestTrend: orderRequestTrend,
        successRate: orderSuccessRate,
      },
    });
  } catch (error) {
    console.error(`Error in order service execution: ${error.message}`);
    errorRate.add(1);
  }
}

export function teardown(data) {
  console.log('Completed order service contention test');
}
