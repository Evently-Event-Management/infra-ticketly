// Order stress test scenario - high load on order service
// Tests system behavior under sustained high load
// Considers both successful bookings (201) and seat-locked responses (400) as expected outcomes

const parsedVUs = Number(__ENV.ORDER_STRESS_VUS);
const defaultVUs = Number.isFinite(parsedVUs) && parsedVUs > 0 ? parsedVUs : 50;

export const orderStressScenario = {
  executor: 'ramping-vus',
  startVUs: 0,
  stages: [
    { duration: '30s', target: defaultVUs },      // Ramp up to target VUs
    { duration: '1m', target: defaultVUs },      // Stay at target for 1 minute
    { duration: '30s', target: defaultVUs * 1.5 }, // Increase by 50%
    { duration: '1m', target: defaultVUs * 1.5 }, // Hold increased load
    { duration: '30s', target: defaultVUs * 2 },      // Further increase load
    { duration: '1m', target: defaultVUs * 2 },      // Hold further increased load
    { duration: '1m', target: 0 },               // Ramp down
  ],
  gracefulRampDown: '30s',
  tags: {
    scenario: 'order_stress',
  },
};

// Description: Stress test for order service
// Simulates sustained high load with multiple users attempting seat bookings
// Expected outcomes:
//   - 201: Successful booking (seat was available)
//   - 400: Seat already locked/booked (expected when testing same seats)
// Both are considered successful responses (system working correctly)
// Load level: Configurable via ORDER_STRESS_VUS (default 50)
