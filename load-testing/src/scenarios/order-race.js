// Order race scenario - concurrent seat reservation attempts
// This scenario spawns 100 VUs and makes them compete for each seat sequentially
// For 4 seats: 100 VUs compete for seat 1, then seat 2, then seat 3, then seat 4
const parsedVUs = Number(__ENV.ORDER_VUS);
const defaultVUs = Number.isFinite(parsedVUs) && parsedVUs > 0 ? parsedVUs : 100;

// Each VU will attempt to book ALL seats sequentially
// Total iterations = number of seats (configured in config.js)
export const orderRaceTestScenario = {
  executor: 'per-vu-iterations',
  vus: defaultVUs,
  iterations: 4, // Number of seats - each VU tries to book all 4 seats
  maxDuration: '5m', // Safety timeout
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
//   4. All 100 VUs compete for Seat 3 simultaneously → 1 succeeds, 99 fail
//   5. All 100 VUs compete for Seat 4 simultaneously → 1 succeeds, 99 fail
// Expected: 400 total requests, 4 successes, 396 failures
// Load level: Configurable via ORDER_VUS (default 100 concurrent VUs)
