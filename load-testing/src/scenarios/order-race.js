// Order race scenario - concurrent seat reservation attempts
const parsedVUs = Number(__ENV.ORDER_VUS);
const defaultVUs = Number.isFinite(parsedVUs) && parsedVUs > 0 ? parsedVUs : 100;
const defaultDuration = (__ENV.ORDER_DURATION && typeof __ENV.ORDER_DURATION === 'string') ? __ENV.ORDER_DURATION : '30s';

export const orderRaceTestScenario = {
  executor: 'constant-vus',
  vus: defaultVUs,
  duration: defaultDuration,
  gracefulStop: '5s',
  tags: {
    scenario: 'order_race',
  },
};

// Description: Drives simultaneous booking attempts for a single seat to observe conflict handling.
// Use case: Validate idempotency and locking around seat reservations under heavy contention.
// Load level: Configurable via ORDER_VUS (default 100) for the specified duration.
