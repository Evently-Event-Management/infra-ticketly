// Load test scenario - normal expected load
export const loadTestScenario = {
  executor: 'ramping-vus',
  startVUs: 2,
  stages: [
    { duration: '30s', target: 5 },   // Ramp up to 5 users over 30 seconds
    { duration: '1m', target: 5 },    // Stay at 5 users for 1 minute
    { duration: '30s', target: 10 },  // Ramp up to 10 users over 30 seconds
    { duration: '1m', target: 10 },   // Stay at 10 users for 1 minute
    { duration: '30s', target: 0 },   // Ramp down to 0 users over 30 seconds
  ],
  tags: {
    scenario: 'load'
  }
};

// Description: Tests how the system behaves under normal expected load conditions.
// Use case: Verify system performance under typical production traffic.
// Load level: Moderate - 10 concurrent users for 3 minutes with ramp-up and cool-down periods.
// Acceptance criteria: 
// - 95% of requests should respond within 1 second
// - Error rate should be less than 1%
// - All business transactions should complete successfully