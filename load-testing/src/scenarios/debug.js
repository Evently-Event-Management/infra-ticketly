// Debug test scenario - reduced load for troubleshooting
export const debugTestScenario = {
  executor: 'constant-vus',
  vus: 2,          // Just 2 virtual users
  duration: '1m',  // Short duration
  tags: {
    scenario: 'debug'
  }
};

// Description: Debug scenario for troubleshooting API failures
// Use case: Identify the exact cause of the high failure rate
// Load level: Very low - just 2 concurrent users for 1 minute
// Acceptance criteria: 
// - All API requests should succeed
// - Detailed error information should be logged for failed requests