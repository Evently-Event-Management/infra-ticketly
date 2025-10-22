import { Rate, Trend, Counter } from 'k6/metrics';
import { getAuthToken, getValidToken } from './src/lib/auth.js';
import { simulateOrderStressFlow } from './src/lib/workflows.js';
import { applyEnvironment, config } from './src/config.js';

// Apply environment overrides during init
const initEnvironmentKey = (typeof __ENV !== 'undefined' ? (__ENV.ENV || '') : '').toLowerCase();
if (initEnvironmentKey) {
  applyEnvironment(initEnvironmentKey);
}

// Import order stress scenario
import { orderStressScenario } from './src/scenarios/order-stress.js';

// Define metrics
export const errorRate = new Rate('errors');
export const orderRequestTrend = new Trend('order_request');
export const orderSuccessRate = new Rate('order_success'); // 201 responses
export const orderExpectedRate = new Rate('order_expected'); // 201 + 400 responses
export const successfulBookings = new Counter('successful_bookings'); // 201
export const seatAlreadyLocked = new Counter('seat_already_locked'); // 400
export const unexpectedFailures = new Counter('unexpected_failures'); // Other errors
export const conflict409 = new Counter('conflict_409'); // 409 - Conflict
export const locked423 = new Counter('locked_423'); // 423 - Locked
export const serverErrors5xx = new Counter('server_errors_5xx'); // 5xx - Server errors

// Test scenarios configuration
export const options = {
  scenarios: {
    orderStress: orderStressScenario,
  },
  thresholds: {
    'http_req_duration': ['p(95)<3000'], // Allow higher latency under stress
    'order_expected': ['rate>0.95'], // 95% should be either 201 or 400 (expected responses)
    'order_request': ['p(95)<3000'],
    'server_errors_5xx': ['count<10'], // Very few server errors acceptable
  }
};

// Store token data per VU to allow refreshing
let tokenCache = {};

export function setup() {
  console.log('Starting order service stress test setup');
  const environmentKey = (__ENV.ENV || '').toLowerCase();
  applyEnvironment(environmentKey);
  const tokenData = getAuthToken();
  console.log('Authentication completed');
  
  const seats = config.order.seatIds;
  
  console.log(`\n========================================`);
  console.log(`Order Stress Test Configuration`);
  console.log(`========================================`);
  console.log(`Test seats: ${seats.length}`);
  console.log(`VUs: ${orderStressScenario.stages[1].target} (base load)`);
  console.log(`Peak VUs: ${orderStressScenario.stages[3].target}`);
  console.log(`Duration: ~16 minutes total`);
  console.log(`\nExpected responses:`);
  console.log(`  ✓ 201 - Successful booking`);
  console.log(`  ✓ 400 - Seat already locked (expected)`);
  console.log(`  ✗ 5xx - Server errors (should be minimal)`);
  console.log(`\nSeats being tested:`);
  seats.slice(0, 5).forEach((seat, idx) => {
    console.log(`  ${idx + 1}. ${seat}`);
  });
  if (seats.length > 5) {
    console.log(`  ... and ${seats.length - 5} more seats`);
  }
  console.log(`========================================\n`);
  
  return { tokenData, seats };
}

export default function (data) {
  const vuId = __VU || 'shared';
  const seats = data.seats;

  // Initialize or refresh token for this VU
  if (!tokenCache[vuId]) {
    tokenCache[vuId] = data.tokenData;
  }
  
  // Check and refresh token if needed (with error handling)
  try {
    tokenCache[vuId] = getValidToken(tokenCache[vuId]);
  } catch (error) {
    console.error(`Failed to get valid token for VU ${vuId}: ${error.message}`);
    errorRate.add(1);
    return; // Skip this iteration
  }
  
  const authToken = tokenCache[vuId].access_token;

  // Randomly select a seat from the available seats
  const seatIndex = Math.floor(Math.random() * seats.length);
  const targetSeat = seats[seatIndex];

  try {
    const result = simulateOrderStressFlow(authToken, targetSeat, {
      metrics: {
        requestTrend: orderRequestTrend,
        successRate: orderSuccessRate,
        expectedRate: orderExpectedRate,
      },
    });
    
    // Categorize response by status code
    if (result.response.status === 201 || result.response.status === 200) {
      // Successful booking
      successfulBookings.add(1);
      orderExpectedRate.add(1);
      orderSuccessRate.add(1);
      
      if (vuId <= 2 || __ENV.SCENARIO === 'debug') {
        console.log(`✓ BOOKING SUCCESS - VU ${vuId} booked seat ${seatIndex + 1} - Order: ${result.responseBody?.order_id || 'N/A'}`);
      }
    } else if (result.response.status === 400) {
      // Seat already locked/booked - expected in stress test
      seatAlreadyLocked.add(1);
      orderExpectedRate.add(1);
      orderSuccessRate.add(0);
      
      if (vuId <= 2 || __ENV.SCENARIO === 'debug') {
        console.log(`✓ EXPECTED - VU ${vuId} seat ${seatIndex + 1} already locked (400)`);
      }
    } else if (result.response.status === 409) {
      // Conflict - also somewhat expected under high load
      conflict409.add(1);
      orderExpectedRate.add(0);
      orderSuccessRate.add(0);
    } else if (result.response.status === 423) {
      // Resource locked - expected under contention
      locked423.add(1);
      orderExpectedRate.add(0);
      orderSuccessRate.add(0);
    } else if (result.response.status >= 500) {
      // Server error - problematic
      serverErrors5xx.add(1);
      unexpectedFailures.add(1);
      orderExpectedRate.add(0);
      orderSuccessRate.add(0);
      
      console.error(`✗ SERVER ERROR - VU ${vuId} got ${result.response.status}: ${result.responseBody?.message || result.response.body}`);
    } else {
      // Other unexpected failure
      unexpectedFailures.add(1);
      orderExpectedRate.add(0);
      orderSuccessRate.add(0);
      
      if (vuId <= 3) {
        console.warn(`✗ UNEXPECTED - VU ${vuId} got ${result.response.status}: ${result.responseBody?.message || result.response.body}`);
      }
    }
  } catch (error) {
    console.error(`Error in order stress execution (VU ${vuId}, seat ${targetSeat}): ${error.message}`);
    errorRate.add(1);
    unexpectedFailures.add(1);
    orderExpectedRate.add(0);
    orderSuccessRate.add(0);
  }
}

export function teardown(data) {
  console.log('\n========================================');
  console.log('Order Stress Test Results Summary');
  console.log('========================================');
  console.log('Expected behavior under stress:');
  console.log('  ✓ Mix of 201 (bookings) and 400 (already locked)');
  console.log('  ✓ Very few 5xx errors');
  console.log('  ✓ System remains stable under load');
  console.log('========================================');
  console.log('Check metrics:');
  console.log('  - successful_bookings (201 responses)');
  console.log('  - seat_already_locked (400 responses)');
  console.log('  - order_expected rate (should be >95%)');
  console.log('  - server_errors_5xx (should be <10)');
  console.log('========================================\n');
}
