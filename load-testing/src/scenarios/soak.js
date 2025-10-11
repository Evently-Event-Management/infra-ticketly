// Soak test scenario - moderate load over extended period
export const soakTestScenario = {
  executor: 'ramping-vus',
  startVUs: 5,
  stages: [
    { duration: '2m', target: 20 },    // Ramp up to 20 users over 2 minutes
    { duration: '30m', target: 20 },   // Stay at 20 users for 30 minutes
    { duration: '2m', target: 0 },     // Ramp down to 0 users over 2 minutes
  ],
  tags: {
    scenario: 'soak'
  }
};

// Description: Tests how the system behaves under moderate load over an extended period.
// Use case: Identify potential memory leaks, resource exhaustion, or performance degradation over time.
// Load level: Moderate - 20 concurrent users sustained for 30 minutes.
// Acceptance criteria:
// - No degradation in response times over the test duration
// - No increase in error rates over time
// - System resources (CPU, memory, connections) remain stable or return to baseline
// - No memory leaks observed