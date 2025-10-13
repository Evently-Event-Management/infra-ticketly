import { config } from '../config/environment';
import { getKeycloakToken, makeAuthenticatedRequest, formDataRequest } from '../utils/apiUtils';
import { queryEventDB, queryOrderDB, queryMongoDB, checkRedisKey } from '../utils/dbUtils';
import { readRequestFile, updateRequestData } from '../utils/fileUtils';
import { pollUntil, wait } from '../utils/helpers';
import { logStep, logStepComplete, logHeader, logSuccess, logInfo } from '../utils/logger'

describe('Event Ticketing System - Full Lifecycle Test', () => {
  // Increase the Jest timeout to accommodate all the waiting periods
  jest.setTimeout(300000); // 5 minutes

  test('should execute the full create, approve, order, and cleanup flow', async () => {
    let userToken: string, adminToken: string, organizationId: string, eventId: string, sessionId: string, availableSeatId: string, orderId: string;
    const STEP_INTERVAL = 1000; // 1 second interval between steps

    logHeader('STARTING FULL LIFECYCLE TEST');

    // --- Step 1: Acquire User Token ---
    logStep('Authenticating user');
    userToken = await getKeycloakToken(config.username, config.password);
    expect(userToken).toBeTruthy();
    logStepComplete('User authenticated successfully');
    await wait(STEP_INTERVAL);

    // --- Step 2 & 3: Create Organization and Verify in PostgreSQL ---
    logStep('Creating organization');
    const orgData = readRequestFile('org/create-organization.json');
    const orgResponse = await makeAuthenticatedRequest('post', `${config.eventCommandServiceUrl}/v1/organizations`, userToken, orgData);
    organizationId = orgResponse.id;
    logStepComplete(`Organization created successfully (ID: ${organizationId})`);
    
    logStep('Verifying organization in command database (PostgreSQL)');
    const pgOrg = await queryEventDB('SELECT id FROM organizations WHERE id = $1', [organizationId]);
    expect(pgOrg).toHaveLength(1);
    logStepComplete('Organization record exists in PostgreSQL');
    await wait(STEP_INTERVAL);

    // --- Step 4: Fetch Categories ---
    logStep('Fetching event categories');
    const categories = await makeAuthenticatedRequest('get', `${config.eventCommandServiceUrl}/v1/categories`, userToken);
    const categoryId = categories[0]?.subCategories[0]?.id;
    expect(categoryId).toBeTruthy();
    logStepComplete(`Categories retrieved, using subcategory ID: ${categoryId}`);
    await wait(STEP_INTERVAL);

    // --- Step 5 & 6: Create Event and Verify PENDING in PostgreSQL ---
    logStep('Creating event');
    let eventData = readRequestFile('event/create-event.json');
    eventData = updateRequestData(eventData, { organizationId: organizationId, categoryId: categoryId });
    const eventResponse = await formDataRequest(`${config.eventCommandServiceUrl}/v1/events`, eventData, userToken);
    eventId = eventResponse.id;
    expect(eventId).toBeTruthy();
    logStepComplete(`Event created successfully (ID: ${eventId})`);
    
    logStep('Verifying event PENDING status in command database (PostgreSQL)');
    const pgEventPending = await queryEventDB('SELECT status FROM events WHERE id = $1', [eventId]);
    expect(pgEventPending[0]?.status).toBe('PENDING');
    logStepComplete('Event has PENDING status in PostgreSQL');
    await wait(STEP_INTERVAL);

    // --- Step 7: Verify Event NOT in MongoDB ---
    logStep('Verifying event is not yet in query database (MongoDB)');
    const mongoEventMissing = await queryMongoDB('event-seating', 'events', { _id: eventId });
    expect(mongoEventMissing).toHaveLength(0);
    logStepComplete('CQRS verification: Event not present in MongoDB while in PENDING status');
    await wait(STEP_INTERVAL);

    // --- Step 8 & 9: Approve Event and Verify APPROVED in PostgreSQL ---
    logStep('Approving event as admin');
    adminToken = await getKeycloakToken(config.adminUsername, config.adminPassword);
    await makeAuthenticatedRequest('post', `${config.eventCommandServiceUrl}/v1/events/${eventId}/approve`, adminToken);
    logStepComplete('Event approval request sent');
    
    logStep('Verifying event APPROVED status in command database (PostgreSQL)');
    const pgEventApproved = await queryEventDB('SELECT status FROM events WHERE id = $1', [eventId]);
    expect(pgEventApproved[0]?.status).toBe('APPROVED');
    logStepComplete('Event has APPROVED status in PostgreSQL');
    await wait(STEP_INTERVAL);

    // --- Step 10: Verify Event IS in MongoDB (Polling) ---
    logStep('Verifying event propagation to query database (MongoDB)');
    await pollUntil(async () => (await queryMongoDB('event-seating', 'events', { _id: eventId })).length === 1);
    logStepComplete('CQRS verification: Event successfully propagated to MongoDB');
    await wait(STEP_INTERVAL);

    // --- Step 11 & 12: Fetch Event Info and Sessions from Query Service ---
    logStep('Fetching event details from query service');
    await makeAuthenticatedRequest('get', `${config.eventQueryServiceUrl}/v1/events/${eventId}/basic-info`, userToken);
    logStepComplete('Event details retrieved from query service');
    
    logStep('Fetching event sessions from query service');
    const sessionsResponse = await makeAuthenticatedRequest('get', `${config.eventQueryServiceUrl}/v1/events/${eventId}/sessions`, userToken);
    sessionId = sessionsResponse.content[0].id;
    expect(sessionId).toBeTruthy();
    logStepComplete(`Session information retrieved (Session ID: ${sessionId})`);
    await wait(STEP_INTERVAL);

    // --- Step 13 & 14: Set Session to ON_SALE and Find a Seat ---
    logStep('Setting session status to ON_SALE');
    await makeAuthenticatedRequest('put', `${config.eventCommandServiceUrl}/v1/sessions/${sessionId}/status`, userToken, { status: 'ON_SALE' });
    logStepComplete('Session status updated to ON_SALE');
    await wait(STEP_INTERVAL); // Extra wait after status change
    
    logStep('Fetching seating map to find available seats');
    const seatingMap = await makeAuthenticatedRequest('get', `${config.eventQueryServiceUrl}/v1/sessions/${sessionId}/seating-map`, userToken);
    const availableSeat = seatingMap.layout.blocks.flatMap((b: any) => b.rows).flatMap((r: any) => r.seats).find((s: any) => s.status === 'AVAILABLE');
    availableSeatId = availableSeat.id;
    expect(availableSeatId).toBeTruthy();
    logStepComplete(`Found available seat (ID: ${availableSeatId})`);
    await wait(STEP_INTERVAL);

    // --- Step 15-19: Place Order and Verify All States ---
    logStep('Placing order for seat');
    const orderResponse = await makeAuthenticatedRequest('post', `${config.ticketsOrderServiceUrl}`, userToken, { event_id: eventId, session_id: sessionId, seat_ids: [availableSeatId] , organization_id: organizationId });
    orderId = orderResponse.order_id;
    expect(orderId).toBeTruthy();
    logStepComplete(`Order placed successfully (ID: ${orderId})`);
    await wait(STEP_INTERVAL);
    
    logStep('Verifying order in command database (PostgreSQL)');
    const pgOrder = await queryOrderDB('SELECT status FROM orders WHERE order_id = $1', [orderId]);
    expect(pgOrder[0]?.status).toBe('pending');
    logStepComplete('Order record exists with pending status in PostgreSQL');
    await wait(STEP_INTERVAL);
    
    logStep('Verifying seat lock in cache layer (Redis)');
    const redisLock = await checkRedisKey(`seat_lock:${availableSeatId}`);
    expect(redisLock).toBe(1);
    logStepComplete('Seat lock exists in Redis');
    await wait(STEP_INTERVAL);
    
    logStep('Verifying seat status update in query database (MongoDB)');
    await pollUntil(async () => {
        const mongoEvent = await queryMongoDB('event-seating', 'events', { _id: eventId });
        const seat = mongoEvent[0]?.sessions[0]?.layoutData.layout.blocks.flatMap((b: any) => b.rows).flatMap((r: any) => r.seats).find((s: any) => s._id === availableSeatId);
        return seat?.status === 'LOCKED';
    });
    logStepComplete('CQRS verification: Seat status updated to LOCKED in MongoDB');
    await wait(STEP_INTERVAL);

    // --- Step 20: Skip Payment ---
    logStep('Processing payment');
    logInfo('Payment implementation is skipped in this test');
    logStepComplete('Payment step bypassed');
    await wait(STEP_INTERVAL);

    // --- Step 21-23: Cleanup - Close Session and Verify ---
    logStep('Closing session (setting status to CLOSED)');
    await makeAuthenticatedRequest('put', `${config.eventCommandServiceUrl}/v1/sessions/${sessionId}/status`, userToken, { status: 'CLOSED' });
    logStepComplete('Session close request sent');
    await wait(STEP_INTERVAL);
    
    logStep('Verifying session CLOSED status in command database (PostgreSQL)');
    const pgSessionClosed = await queryEventDB('SELECT status FROM event_sessions WHERE id = $1', [sessionId]);
    expect(pgSessionClosed[0]?.status).toBe('CLOSED');
    logStepComplete('Session has CLOSED status in PostgreSQL');
    await wait(STEP_INTERVAL);
    
    logStep('Verifying session CLOSED status in query database (MongoDB)');
    await pollUntil(async () => {
        const mongoEvent = await queryMongoDB('event-seating', 'events', { _id: eventId });
        return mongoEvent[0]?.sessions[0]?.status === 'CLOSED';
    });
    logStepComplete('CQRS verification: Session status updated to CLOSED in MongoDB');
    await wait(STEP_INTERVAL);

    // --- Step 24-26: Cleanup - Delete Event and Verify ---
    logStep('Deleting event');
    await makeAuthenticatedRequest('delete', `${config.eventCommandServiceUrl}/v1/events/${eventId}`, userToken);
    logStepComplete('Event deletion request sent');
    await wait(STEP_INTERVAL);
    
    logStep('Verifying event removal from command database (PostgreSQL)');
    const pgEventDeleted = await queryEventDB('SELECT id FROM events WHERE id = $1', [eventId]);
    expect(pgEventDeleted).toHaveLength(0);
    logStepComplete('Event no longer exists in PostgreSQL');
    await wait(STEP_INTERVAL);
    
    logStep('Verifying event removal from query database (MongoDB)');
    await pollUntil(async () => (await queryMongoDB('event-seating', 'events', { _id: eventId })).length === 0);
    logStepComplete('CQRS verification: Event successfully removed from MongoDB');
    await wait(STEP_INTERVAL);

    // --- Step 27: Cleanup - Delete Organization ---
    logStep('Deleting organization');
    await makeAuthenticatedRequest('delete', `${config.eventCommandServiceUrl}/v1/organizations/${organizationId}`, userToken);
    logStepComplete('Organization deletion request sent');
    await wait(STEP_INTERVAL);
    
    logStep('Verifying organization removal from command database (PostgreSQL)');
    const pgOrgDeleted = await queryEventDB('SELECT id FROM organizations WHERE id = $1', [organizationId]);
    expect(pgOrgDeleted).toHaveLength(0);
    logStepComplete('Organization no longer exists in PostgreSQL');
    await wait(STEP_INTERVAL);

    logSuccess('FULL LIFECYCLE TEST COMPLETED SUCCESSFULLY');
  });
});