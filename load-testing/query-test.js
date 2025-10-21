import { Rate, Trend } from 'k6/metrics';
import { getAuthToken, getValidToken } from './src/lib/auth.js';
import { simulateTicketPurchaseQueryFlow } from './src/lib/workflows.js';
import { applyEnvironment } from './src/config.js';

// Apply environment overrides during init
const initEnvironmentKey = (typeof __ENV !== 'undefined' ? (__ENV.ENV || '') : '').toLowerCase();
if (initEnvironmentKey) {
    applyEnvironment(initEnvironmentKey);
}

// Import test scenarios
import { smokeTestScenario } from './src/scenarios/smoke.js';
import { loadTestScenario } from './src/scenarios/load.js';
import { stressTestScenario } from './src/scenarios/stress.js';
import { soakTestScenario } from './src/scenarios/soak.js';
import { spikeTestScenario } from './src/scenarios/spike.js';
import { breakpointTestScenario } from './src/scenarios/breakpoint.js';
import { debugTestScenario } from './src/scenarios/debug.js';
import { stepUpLoadScenario } from './src/scenarios/query-step-up.js';

// Define metrics
export const errorRate = new Rate('errors');
export const eventSearchTrend = new Trend('event_search');
export const eventDetailsTrend = new Trend('event_details');
export const sessionDetailsTrend = new Trend('session_details');
export const trendingEventsTrend = new Trend('trending_events');
export const eventSessionsTrend = new Trend('event_sessions');
export const seatingMapTrend = new Trend('seating_map');

// Test scenarios configuration
const scenarioMap = {
    'smoke': smokeTestScenario,
    'load': loadTestScenario,
    'step-up': stepUpLoadScenario,
    'stress': stressTestScenario,
    'soak': soakTestScenario,
    'spike': spikeTestScenario,
    'breakpoint': breakpointTestScenario,
    'debug': debugTestScenario,
};

export const options = {
    scenarios: __ENV.ONLY_SCENARIO ?
        {
            [__ENV.SCENARIO]: scenarioMap[__ENV.SCENARIO]
        }
        : scenarioMap,
    thresholds: {
        'http_req_duration': ['p(95)<1500'],
        'http_req_failed': ['rate<0.01'],
        'event_search': ['p(95)<2000'],
        'trending_events': ['p(95)<1500'],
        'event_sessions': ['p(95)<1800'],
        'seating_map': ['p(95)<1800'],
    }
};

// Store iteration counters per VU
let iterationCounters = {};

// Store token data per VU to allow refreshing
let tokenCache = {};

export function setup() {
    console.log('Starting query service load test setup');
    const environmentKey = (__ENV.ENV || '').toLowerCase();
    applyEnvironment(environmentKey);
    const tokenData = getAuthToken();
    console.log('Authentication completed');
    return { tokenData };
}

export default function (data) {
    const scenarioName = __ENV.SCENARIO || 'default';
    const vuId = __VU || 'shared';

    // Initialize or refresh token for this VU
    if (!tokenCache[vuId]) {
        tokenCache[vuId] = data.tokenData;
    }
    
    // Check and refresh token if needed
    tokenCache[vuId] = getValidToken(tokenCache[vuId]);
    const authToken = tokenCache[vuId].access_token;

    if (!iterationCounters[vuId]) {
        iterationCounters[vuId] = 0;
    }

    iterationCounters[vuId]++;

    try {
        simulateTicketPurchaseQueryFlow(authToken, {
            trends: {
                trendingEvents: trendingEventsTrend,
                eventSearch: eventSearchTrend,
                eventDetails: eventDetailsTrend,
                eventSessions: eventSessionsTrend,
                sessionDetails: sessionDetailsTrend,
                seatingMap: seatingMapTrend,
            },
        });
    } catch (error) {
        console.error(`Error in query service execution: ${error.message}`);
        errorRate.add(1);
    }
}

export function teardown(data) {
    console.log('Completed query service load test');
}
