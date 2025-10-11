// Stress test scenario - higher than normal load
export const stressTestScenario = {
  executor: 'ramping-vus',
  startVUs: 10,
  stages: [
    { duration: '1m', target: 20 },   // Ramp up to 20 users over 1 minute
    { duration: '2m', target: 50 },   // Ramp up to 50 users over 2 minutes
    { duration: '5m', target: 50 },   // Stay at 50 users for 5 minutes
    { duration: '2m', target: 0 },    // Ramp down to 0 users over 2 minutes
  ],
  tags: {
    scenario: 'stress'
  }
};

// Description: Tests how the system behaves under higher than normal load conditions.
// Use case: Determine system behavior during peak traffic periods like event sales openings.
// Load level: High - Gradually increases to 50 concurrent users for 5 minutes.
// Acceptance criteria:
// - 95% of requests should respond within 3 seconds
// - Error rate should be less than 5%
// - System should recover after load is reduced