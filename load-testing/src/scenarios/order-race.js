// Order race scenario - concurrent seat reservation attempts
// This scenario spawns 100 VUs and makes them compete for each seat sequentially
import { config } from '../config.js';

const parsedVUs = Number(__ENV.ORDER_VUS);
const defaultVUs = Number.isFinite(parsedVUs) && parsedVUs > 0 ? parsedVUs : 100;

// Each VU will attempt to book ALL seats sequentially
// Total iterations = number of seats (dynamically determined from config)
const totalSeats = config.order.seatIds.length;

export const orderRaceTestScenario = {
  executor: 'per-vu-iterations',
  vus: defaultVUs,
  iterations: totalSeats, // Dynamic: each VU tries to book all seats
  maxDuration: '10m', // Safety timeout (increased for more seats)
  gracefulStop: '30s',
  tags: {
    scenario: 'order_race',
  },
};

// Description: 100 VUs compete for each seat sequentially.
// Execution flow:
//   1. Spawn 100 VUs
//   2. All 100 VUs compete for Seat 1 simultaneously → 1 succeeds, 99 fail
//   3. All 100 VUs compete for Seat 2 simultaneously → 1 succeeds, 99 fail
//   ... continues for all seats in config
// Expected: (total_seats × 100) total requests, total_seats successes, rest failures
// Load level: Configurable via ORDER_VUS (default 100 concurrent VUs)
