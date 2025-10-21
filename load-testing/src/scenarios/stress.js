// Stress test scenario - progressive ramp to find system limits
export const stressTestScenario = {
  executor: 'ramping-vus',
  startVUs: 0,
  stages: [
    { duration: '30s', target: 500 },     
    { duration: '1m', target: 500 },    
    { duration: '30s', target: 1000 },    
    { duration: '1m', target: 1000 },  
    { duration: '30s', target: 2000 },
    { duration: '1m', target: 2000 },
    { duration: '1m', target: 0 }
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