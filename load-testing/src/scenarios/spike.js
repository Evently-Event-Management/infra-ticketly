// Spike test scenario - sudden burst of traffic
export const spikeTestScenario = {
  executor: 'ramping-vus',
  startVUs: 0,
  stages: [
    { duration: '10s', target: 30 },   // Rapid ramp up to 30 users in 10 seconds
    { duration: '30s', target: 30 },   // Stay at 30 users for 30 seconds
    { duration: '10s', target: 0 },    // Rapid ramp down to 0 users in 10 seconds
  ],
  tags: {
    scenario: 'spike'
  }
};

// Description: Tests how the system responds to a sudden spike in traffic.
// Use case: Simulate sudden high traffic events like ticket sales opening for popular events.
// Load level: Very high - Rapidly increasing to 100 concurrent users within 10 seconds.
// Acceptance criteria:
// - System should remain available (may have degraded performance)
// - Critical operations should continue to function
// - System should recover quickly after load decreases
// - No data corruption or inconsistency should occur