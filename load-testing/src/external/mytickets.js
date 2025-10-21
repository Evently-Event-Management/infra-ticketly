import http from 'k6/http';
import { check, sleep } from 'k6';

// Step-up load scenario configuration
export const options = {
  scenarios: {
    stepUpLoadScenario: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '30s', target: 150 },  // Ramp to 150 VUs
        { duration: '1m', target: 150 },   // Hold
        { duration: '30s', target: 300 },  // Ramp to 300
        { duration: '1m', target: 300 },   // Hold
        { duration: '30s', target: 500 },  // Ramp to 500
        { duration: '2m', target: 500 },   // Hold
        { duration: '30s', target: 0 },    // Ramp down
      ],
      gracefulRampDown: '30s',
      tags: { scenario: 'query_step_up' },
    },
  },
  thresholds: {
    http_req_failed: ['rate==0'],              // No request should fail
    http_req_duration: ['p(95)<800'],          // 95% of requests < 800ms
  },
};

// Endpoint under test
const url = 'https://api.mytickets.lk/event-svc/v1/events?page=1&limit=10&filter[repeatable.end_time]=gte(2025-10-21)&include=creator,organizer,repeatable.location->(city<-cities),repeatable.artists,repeatable.deals&secondaryFilter[repeatable.deals.name]=exists(true)&secondaryFilter[or]=repeatable.deals.expires_at=exists(false),repeatable.deals.expires_at=gte(2025-10-22T00:05:36+05:30)&sort[repeatable.start_time]=1';

// Test function executed by each virtual user
export default function () {
  const res = http.get(url);

  check(res, {
    'status is 200': (r) => r.status === 200,
    'response time < 800ms': (r) => r.timings.duration < 800,
  });

  sleep(1); // Small wait between iterations
}
