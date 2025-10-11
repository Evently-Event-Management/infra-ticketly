import { config } from '../config/environment';
import { getKeycloakToken, makeAuthenticatedRequest, formDataRequest } from '../utils/apiUtils';
import { queryEventDB, queryOrderDB, queryMongoDB, checkRedisKey } from '../utils/dbUtils';
import { readRequestFile, updateRequestData } from '../utils/fileUtils';
import { pollUntil } from '../utils/helpers';

describe('Event Ticketing System - Full Lifecycle Test', () => {

  test('should execute the full create, approve, order, and cleanup flow', async () => {
    let userToken: string, adminToken: string, organizationId: string, eventId: string, sessionId: string, availableSeatId: string, orderId: string;

    console.log("--- STARTING FULL LIFECYCLE TEST ---");

    // --- Step 1: Acquire User Token ---
    console.log("\nStep 1: Acquiring user token...");
    userToken = await getKeycloakToken(config.username, config.password);
    expect(userToken).toBeTruthy();

    // --- Step 2 & 3: Create Organization and Verify in PostgreSQL ---
    console.log("Step 2 & 3: Creating organization and verifying...");
    const orgData = readRequestFile('org/create-organization.json');
    const orgResponse = await makeAuthenticatedRequest('post', `${config.eventCommandServiceUrl}/v1/organizations`, userToken, orgData);
    organizationId = orgResponse.id;
    expect(organizationId).toBeTruthy();
    const pgOrg = await queryEventDB('SELECT id FROM organizations WHERE id = $1', [organizationId]);
    expect(pgOrg).toHaveLength(1);

    // --- Step 4: Fetch Categories ---
    console.log("Step 4: Fetching categories...");
    const categories = await makeAuthenticatedRequest('get', `${config.eventCommandServiceUrl}/v1/categories`, userToken);
    const categoryId = categories[0]?.subCategories[0]?.id;
    expect(categoryId).toBeTruthy();

    // --- Step 5 & 6: Create Event and Verify PENDING in PostgreSQL ---
    console.log("Step 5 & 6: Creating event and verifying PENDING...");
    let eventData = readRequestFile('event/create-event.json');
    eventData = updateRequestData(eventData, { org_id: organizationId, cat_id: categoryId });
    const eventResponse = await formDataRequest(`${config.eventCommandServiceUrl}/v1/events`, eventData, userToken);
    eventId = eventResponse.id;
    expect(eventId).toBeTruthy();
    const pgEventPending = await queryEventDB('SELECT status FROM events WHERE id = $1', [eventId]);
    expect(pgEventPending[0]?.status).toBe('PENDING');

    // --- Step 7: Verify Event NOT in MongoDB ---
    console.log("Step 7: Verifying event not in MongoDB...");
    const mongoEventMissing = await queryMongoDB('event-seating', 'events', { _id: eventId });
    expect(mongoEventMissing).toHaveLength(0);

    // --- Step 8 & 9: Approve Event and Verify APPROVED in PostgreSQL ---
    console.log("Step 8 & 9: Approving event and verifying APPROVED...");
    adminToken = await getKeycloakToken(config.adminUsername, config.adminPassword);
    await makeAuthenticatedRequest('post', `${config.eventCommandServiceUrl}/v1/events/${eventId}/approve`, adminToken);
    const pgEventApproved = await queryEventDB('SELECT status FROM events WHERE id = $1', [eventId]);
    expect(pgEventApproved[0]?.status).toBe('APPROVED');

    // --- Step 10: Verify Event IS in MongoDB (Polling) ---
    console.log("Step 10: Verifying event sync to MongoDB (polling)...");
    await pollUntil(async () => (await queryMongoDB('event-seating', 'events', { _id: eventId })).length === 1);

    // --- Step 11 & 12: Fetch Event Info and Sessions from Query Service ---
    console.log("Step 11 & 12: Fetching event details and sessions...");
    await makeAuthenticatedRequest('get', `${config.eventQueryServiceUrl}/v1/events/${eventId}/basic-info`, userToken);
    const sessionsResponse = await makeAuthenticatedRequest('get', `${config.eventQueryServiceUrl}/v1/events/${eventId}/sessions`, userToken);
    sessionId = sessionsResponse.content[0].id;
    expect(sessionId).toBeTruthy();

    // --- Step 13 & 14: Set Session to ON_SALE and Find a Seat ---
    console.log("Step 13 & 14: Setting session ON_SALE and finding an available seat...");
    await makeAuthenticatedRequest('put', `${config.eventCommandServiceUrl}/v1/sessions/${sessionId}/status`, userToken, { status: 'ON_SALE' });
    const seatingMap = await makeAuthenticatedRequest('get', `${config.eventQueryServiceUrl}/v1/sessions/${sessionId}/seating-map`, userToken);
    const availableSeat = seatingMap.layout.blocks.flatMap((b: any) => b.rows).flatMap((r: any) => r.seats).find((s: any) => s.status === 'AVAILABLE');
    availableSeatId = availableSeat.id;
    expect(availableSeatId).toBeTruthy();

    // --- Step 15-19: Place Order and Verify All States ---
    console.log("Step 15-19: Placing order and verifying states...");
    const orderResponse = await makeAuthenticatedRequest('post', `${config.ticketsOrderServiceUrl}`, userToken, { event_id: eventId, session_id: sessionId, seat_ids: [availableSeatId] });
    orderId = orderResponse.order_id;
    expect(orderId).toBeTruthy();
    const pgOrder = await queryOrderDB('SELECT status FROM orders WHERE order_id = $1', [orderId]);
    expect(pgOrder[0]?.status).toBe('pending');
    const redisLock = await checkRedisKey(`seat_lock:${availableSeatId}`);
    expect(redisLock).toBe(1);
    await pollUntil(async () => {
        const mongoEvent = await queryMongoDB('event-seating', 'events', { _id: eventId });
        const seat = mongoEvent[0]?.sessions[0]?.layoutData.layout.blocks.flatMap((b: any) => b.rows).flatMap((r: any) => r.seats).find((s: any) => s._id === availableSeatId);
        return seat?.status === 'LOCKED';
    });

    // --- Step 20: Skip Payment ---
    console.log("Step 20: SKIPPING PAYMENT IMPLEMENTATION.");

    // --- Step 21-23: Cleanup - Close Session and Verify ---
    console.log("Step 21-23: Closing session and verifying...");
    await makeAuthenticatedRequest('put', `${config.eventCommandServiceUrl}/v1/sessions/${sessionId}/status`, userToken, { status: 'CLOSED' });
    const pgSessionClosed = await queryEventDB('SELECT status FROM event_sessions WHERE id = $1', [sessionId]);
    expect(pgSessionClosed[0]?.status).toBe('CLOSED');
    await pollUntil(async () => {
        const mongoEvent = await queryMongoDB('event-seating', 'events', { _id: eventId });
        return mongoEvent[0]?.sessions[0]?.status === 'CLOSED';
    });

    // --- Step 24-26: Cleanup - Delete Event and Verify ---
    console.log("Step 24-26: Deleting event and verifying deletion...");
    await makeAuthenticatedRequest('delete', `${config.eventCommandServiceUrl}/v1/events/${eventId}`, adminToken); // Use admin token for deletion
    const pgEventDeleted = await queryEventDB('SELECT id FROM events WHERE id = $1', [eventId]);
    expect(pgEventDeleted).toHaveLength(0);
    await pollUntil(async () => (await queryMongoDB('event-seating', 'events', { _id: eventId })).length === 0);

    // --- Step 27: Cleanup - Delete Organization ---
    console.log("Step 27: Deleting organization...");
    await makeAuthenticatedRequest('delete', `${config.eventCommandServiceUrl}/v1/organizations/${organizationId}`, userToken);
    const pgOrgDeleted = await queryEventDB('SELECT id FROM organizations WHERE id = $1', [organizationId]);
    expect(pgOrgDeleted).toHaveLength(0);

    console.log("\n✅ --- FULL LIFECYCLE TEST COMPLETED SUCCESSFULLY --- ✅");
  });
});