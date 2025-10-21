// Stress test scenario - progressive ramp to find system limits
export const stressTestScenario = {
  executor: 'ramping-vus',
  startVUs: 0,
  stages: [
    { duration: '1m', target: 250 },     // Ramp to 250 users
    { duration: '1m', target: 500 },    // Ramp to 500 users
    { duration: '2m', target: 500 },    // Hold at 500 for 2m
    { duration: '1m', target: 1000 },   // Ramp to 1000 users
    { duration: '2m', target: 1000 },   // Hold at 1000 for 2m
    { duration: '30s', target: 0 },     // Ramp down gracefully
  ],
  gracefulRampDown: '30s',
  tags: {
    scenario: 'query_stress'
  }
};

// Description: Progressive stress test ramping from 500 to 2000 concurrent users
// Use case: Find system breaking point and observe behavior under extreme load
// Load level: Very High - Tests system stability at 500/1000/1500/2000 VUs
// Total duration: ~12 minutes
// Acceptance criteria:
// - p95 response time < 1500ms
// - Error rate < 1%
// - System remains responsive throughout all stages
// - Graceful degradation under peak load