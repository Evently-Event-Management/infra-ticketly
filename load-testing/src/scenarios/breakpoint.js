// Breakpoint test scenario - find system breaking point
export const breakpointTestScenario = {
  executor: 'ramping-arrival-rate',
  startRate: 1,
  timeUnit: '1s',
  preAllocatedVUs: 100,
  maxVUs: 500,
  stages: [
    { duration: '2m', target: 10 },   // 10 requests per second
    { duration: '2m', target: 20 },   // 20 requests per second
    { duration: '2m', target: 30 },   // 30 requests per second
    { duration: '2m', target: 40 },   // 40 requests per second
    { duration: '2m', target: 50 },   // 50 requests per second
    { duration: '2m', target: 60 },   // 60 requests per second
    { duration: '2m', target: 70 },   // 70 requests per second
    { duration: '2m', target: 80 },   // 80 requests per second
    { duration: '2m', target: 90 },   // 90 requests per second
    { duration: '2m', target: 100 },  // 100 requests per second
  ],
  tags: {
    scenario: 'breakpoint'
  },
};

// Description: Tests to determine the maximum load the system can handle before failure.
// Use case: Capacity planning and identifying bottlenecks.
// Load level: Gradually increasing load until system performance degrades beyond acceptable limits.
// Acceptance criteria:
// - Identify the point at which response times exceed SLAs
// - Identify the point at which errors start to occur
// - Document system behavior at breaking point (which components fail first)
// - Determine maximum throughput the system can handle