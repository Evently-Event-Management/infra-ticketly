// Step-up load test scenario - demonstrates performance at increasing levels
export const stepUpLoadScenario = {
  executor: 'ramping-vus',
  startVUs: 0,
  stages: [
    // Step 1: Establish a baseline
    { duration: '30s', target: 150 },   // Ramp up to 150 users
    { duration: '1m', target: 150 },    // Hold for 1 minute

    // Step 2: Increase to a medium load
    { duration: '30s', target: 300 },   // Ramp up to 300 users
    { duration: '1m', target: 300 },    // Hold for 1 minute
    
    // Step 3: Ramp to the peak demo load
    { duration: '30s', target: 500 },   // Ramp up to 500 users
    
    // Hold the peak load long enough to show stability
    { duration: '2m', target: 500 },    
    
    // Ramp down
    { duration: '30s', target: 0 },   
  ],
  gracefulRampDown: '30s',
  tags: {
    scenario: 'query_step_up'
  }
};

// Description: A progressive "step-up" test to 500 VUs.
// Use case: Show how the k8s cluster scales and stabilizes at different load levels.
// Load level: Ramps from Low to High.
// Total duration: ~6 minutes
// Acceptance criteria:
// - p95 response time remains low (e.g., < 800ms) at all steps.
// - Error rate = 0%.
// - Observe k8s HPA (Horizontal Pod Autoscaler) if configured, as load passes each step.