import { Rate, Trend, Counter } from 'k6/metrics';
import { getAuthToken, getValidToken } from './src/lib/auth.js';
import { simulateOrderServiceFlow } from './src/lib/workflows.js';
import { applyEnvironment, config } from './src/config.js';

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
export const successfulBookings = new Counter('successful_bookings');
export const failedBookings = new Counter('failed_bookings');
export const seatLocked400 = new Counter('seat_locked_400'); // 400 - Seat already locked/booked
export const conflict409 = new Counter('conflict_409'); // 409 - Conflict
export const locked423 = new Counter('locked_423'); // 423 - Locked
export const serverErrors5xx = new Counter('server_errors_5xx'); // 5xx - Server errors

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
  
  const seats = config.order.seatIds;
  const totalVUs = orderRaceTestScenario.vus;
  const totalRequests = seats.length * totalVUs;
  const expectedSuccesses = seats.length;
  const expectedFailures = totalRequests - expectedSuccesses;
  
  console.log(`\n========================================`);
  console.log(`Order Race Test Configuration`);
  console.log(`========================================`);
  console.log(`Total VUs: ${totalVUs}`);
  console.log(`Total seats to test: ${seats.length}`);
  console.log(`Total requests: ${totalRequests} (${totalVUs} VUs × ${seats.length} seats)`);
  console.log(`Expected successes: ${expectedSuccesses} (1 per seat)`);
  console.log(`Expected failures: ${expectedFailures} (${totalVUs - 1} per seat)`);
  console.log(`\nSeats to test:`);
  seats.forEach((seat, idx) => {
    console.log(`  ${idx + 1}. ${seat}`);
  });
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

  if (!iterationCounters[vuId]) {
    iterationCounters[vuId] = 0;
  }

  const currentIteration = iterationCounters[vuId];
  iterationCounters[vuId]++;

  // Each VU goes through seats sequentially
  // Iteration 0: all VUs try seat 0
  // Iteration 1: all VUs try seat 1
  // Iteration 2: all VUs try seat 2
  // Iteration 3: all VUs try seat 3
  const seatIndex = currentIteration % seats.length;
  const targetSeat = seats[seatIndex];
  
  // Log spawning message once when first iteration starts
  if (currentIteration === 0 && vuId === 1) {
    console.log(`\n🚀 Spawned ${orderRaceTestScenario.vus} VUs - Starting race for seat ${seatIndex + 1} (${targetSeat})`);
  }
  
  // Log when moving to next seat
  if (vuId === 1 && currentIteration > 0) {
    console.log(`\n🏁 Moving to seat ${seatIndex + 1} (${targetSeat})`);
  }

  try {
    // Override the seat ID for this specific attempt
    __ENV.ORDER_SEAT_ID = targetSeat;
    
    const result = simulateOrderServiceFlow(authToken, {
      metrics: {
        requestTrend: orderRequestTrend,
        successRate: orderSuccessRate,
      },
    });
    
    if (result.success) {
      successfulBookings.add(1);
      console.log(`✓ SUCCESS - VU ${vuId} booked seat ${seatIndex + 1} (${targetSeat}) - Order: ${result.responseBody?.order_id || 'N/A'}`);
    } else {
      failedBookings.add(1);
      
      // Categorize failure by status code
      if (result.response.status === 400) {
        seatLocked400.add(1);
      } else if (result.response.status === 409) {
        conflict409.add(1);
      } else if (result.response.status === 423) {
        locked423.add(1);
      } else if (result.response.status >= 500) {
        serverErrors5xx.add(1);
      }
      
      // Only show a few failures for visibility, not all 99
      if (vuId <= 3 || __ENV.SCENARIO === 'debug') {
        const errorMsg = result.responseBody?.message || result.response.body;
        console.log(`✗ FAILED - VU ${vuId} seat ${seatIndex + 1} (${targetSeat}) - Status ${result.response.status}: ${errorMsg}`);
      }
    }
  } catch (error) {
    console.error(`Error in order service execution (VU ${vuId}, seat ${targetSeat}): ${error.message}`);
    errorRate.add(1);
    failedBookings.add(1);
  }
}

export function teardown(data) {
  const seats = data.seats;
  const totalVUs = orderRaceTestScenario.vus;
  const totalRequests = seats.length * totalVUs;
  const expectedSuccesses = seats.length;
  const expectedFailures = totalRequests - expectedSuccesses;
  
  console.log('\n========================================');
  console.log('Order Race Test Results Summary');
  console.log('========================================');
  console.log(`Total VUs: ${totalVUs}`);
  console.log(`Total seats tested: ${seats.length}`);
  console.log(`Total requests: ${totalRequests}`);
  console.log('----------------------------------------');
  console.log(`Expected successes: ${expectedSuccesses} (1 per seat)`);
  console.log(`Expected failures: ${expectedFailures} (${totalVUs - 1} per seat)`);
  console.log('========================================');
  console.log('Execution pattern:');
  console.log(`  1. Spawn ${totalVUs} VUs`);
  console.log(`  2. All ${totalVUs} VUs compete for Seat 1`);
  console.log(`  3. All ${totalVUs} VUs compete for Seat 2`);
  console.log(`  4. All ${totalVUs} VUs compete for Seat 3`);
  console.log(`  5. All ${totalVUs} VUs compete for Seat 4`);
  console.log('----------------------------------------');
  console.log('Metrics to verify:');
  console.log(`  ✓ successful_bookings = ${expectedSuccesses}`);
  console.log(`  ✗ failed_bookings = ${expectedFailures}`);
  console.log('  📊 Failure breakdown by status code:');
  console.log('     - seat_locked_400 (seat already locked/booked)');
  console.log('     - conflict_409 (conflict response)');
  console.log('     - locked_423 (resource locked)');
  console.log('     - server_errors_5xx (server errors - should be 0)');
  console.log('========================================\n');
}
