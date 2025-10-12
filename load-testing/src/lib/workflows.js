import http from 'k6/http';
import { sleep, check } from 'k6';
import { config } from '../config.js';
import { errorRate } from '../main.js';

/**
 * Simulates a complete user flow through the ticketing system
 * - Browse trending events
 * - Search for events
 * - View event details
 * - Check event sessions
 * - Select a session
 * - View seating map
 * - Validate seats
 * - Validate pre-order (with discount if applicable)
 * 
 * @param {string} authToken - Authentication token
 */
export function simulateTicketPurchaseFlow(authToken) {
  const params = {
    headers: {
      'Authorization': `Bearer ${authToken}`,
      'Content-Type': 'application/json',
    },
  };
  
  // Step 1: Browse trending events
  console.log('Step 1: Browsing trending events');
  let response = http.get(`${config.baseUrl}/v1/events/trending?limit=10`, params);
  
  check(response, {
    'trending events status is 200': (r) => r.status === 200,
  }) || errorRate.add(1);
  
  // Get a sample event ID from the trending events
  let eventId = config.sampleEventId; // Default to the sample ID
  if (response.status === 200) {
    try {
      const events = JSON.parse(response.body);
      if (events && events.length > 0) {
        eventId = events[0].id;
      }
    } catch (e) {
      console.error('Failed to parse trending events response');
    }
  }
  
  sleep(Math.random() * 2 + 1); // User thinking time
  
  // Step 2: View event details
  console.log(`Step 2: Viewing details for event ${eventId}`);
  response = http.get(`${config.baseUrl}/v1/events/${eventId}/basic-info`, params);
  
  check(response, {
    'event details status is 200': (r) => r.status === 200,
  }) || errorRate.add(1);
  
  sleep(Math.random() * 3 + 2); // User reading event details
  
  // Step 3: Check event sessions
  console.log(`Step 3: Checking sessions for event ${eventId}`);
  response = http.get(`${config.baseUrl}/v1/events/${eventId}/sessions?pageable.page=0&pageable.size=10`, params);
  
  check(response, {
    'event sessions status is 200': (r) => r.status === 200,
  }) || errorRate.add(1);
  
  // Get a session ID
  let sessionId = config.sampleSessionId; // Default to the sample ID
  if (response.status === 200) {
    try {
      const sessionsData = JSON.parse(response.body);
      if (sessionsData && sessionsData.content && sessionsData.content.length > 0) {
        sessionId = sessionsData.content[0].id;
      }
    } catch (e) {
      console.error('Failed to parse sessions response');
    }
  }
  
  sleep(Math.random() * 2 + 1); // User selecting a session
  
  // Step 4: View session details
  console.log(`Step 4: Viewing details for session ${sessionId}`);
  response = http.get(`${config.baseUrl}/v1/sessions/${sessionId}/basic-info`, params);
  
  check(response, {
    'session details status is 200': (r) => r.status === 200,
  }) || errorRate.add(1);
  
  sleep(Math.random() * 2 + 1); // User viewing session details
  
  // Step 5: View seating map
  console.log(`Step 5: Viewing seating map for session ${sessionId}`);
  response = http.get(`${config.baseUrl}/v1/sessions/${sessionId}/seating-map`, params);
  
  check(response, {
    'seating map status is 200': (r) => r.status === 200,
  }) || errorRate.add(1);
  
  // Extract seats from seating map
  let seatIds = config.sampleSeatIds; // Default to sample IDs
  if (response.status === 200) {
    try {
      const seatingMap = JSON.parse(response.body);
      const extractedIds = [];
      
      // Extract up to 3 seat IDs from the seating map
      if (seatingMap && seatingMap.layout && seatingMap.layout.blocks) {
        for (const block of seatingMap.layout.blocks) {
          if (block.seats) {
            for (const seat of block.seats) {
              if (seat.status === 'AVAILABLE' && extractedIds.length < 3) {
                extractedIds.push(seat.id);
              }
            }
          }
        }
      }
      
      if (extractedIds.length > 0) {
        seatIds = extractedIds;
      }
    } catch (e) {
      console.error('Failed to parse seating map or extract seats');
    }
  }
  
  sleep(Math.random() * 3 + 2); // User selecting seats
  
  // Step 6: Validate seats
  console.log(`Step 6: Validating seats ${seatIds.join(', ')}`);
  const seatValidationPayload = {
    event_id: eventId,
    session_id: sessionId,
    seat_ids: seatIds
  };
  
  response = http.post(
    `${config.baseUrl}/internal/v1/sessions/${sessionId}/seats/validate`, 
    JSON.stringify(seatValidationPayload), 
    params
  );
  
  check(response, {
    'seat validation status is 200': (r) => r.status === 200,
  }) || errorRate.add(1);
  
  sleep(Math.random() * 2 + 1); // User proceeding to checkout
  
  // Step 7: Validate pre-order
  console.log(`Step 7: Validating pre-order for event ${eventId}, session ${sessionId}`);
  const preOrderPayload = {
    event_id: eventId,
    session_id: sessionId,
    seat_ids: seatIds
  };
  
  response = http.post(
    `${config.baseUrl}/internal/v1/validate-pre-order`, 
    JSON.stringify(preOrderPayload), 
    params
  );
  
  check(response, {
    'pre-order validation status is 200': (r) => r.status === 200,
  }) || errorRate.add(1);
  
  // Simulation complete
  console.log('Ticket purchase flow simulation completed');
}