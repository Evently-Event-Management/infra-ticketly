// Smoke test scenario - minimal load to verify system works
export const smokeTestScenario = {
  executor: 'constant-vus',
  vus: 1,
  duration: '1m',
  tags: {
    scenario: 'smoke'
  }
};

// Description: Tests if the system functions under a low load, ensuring that all endpoints respond correctly.
// Use case: Initial verification that the system is operational after deployment.
// Load level: Very low - 1 VU (virtual user) running for 1 minute.
// Acceptance criteria: All endpoints should return successful responses with no errors.