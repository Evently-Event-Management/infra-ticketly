import { config } from '../config/environment';
import { getKeycloakToken, makeAuthenticatedRequest, formDataRequest } from '../utils/apiUtils';
import { queryPostgres, queryMongoDB } from '../utils/dbUtils';
import { readRequestFile, updateRequestData } from '../utils/fileUtils';
import { TestReporter, TestStatus } from '../utils/testReporter';

describe('Event Ticketing System Integration Tests', () => {
  let userToken: string;
  let adminToken: string;
  let organizationId: string;
  let organizationName: string;
  let categoryId: string;
  let eventId: string;
  let sessionId: string;
  
  const reporter = new TestReporter();

  beforeAll(async () => {
    try {
      // Get user token for initial requests
      console.log('Getting user authentication token...');
      userToken = await getKeycloakToken(config.username, config.password);
      expect(userToken).toBeTruthy();
      reporter.addResult('Initial Authentication', TestStatus.PASSED);
    } catch (error) {
      console.error('Failed to authenticate:', error);
      reporter.addResult('Initial Authentication', TestStatus.FAILED, 'Failed to get authentication token');
      // Stop tests if we can't even authenticate
      throw error;
    }
  });
  
  afterAll(() => {
    reporter.printSummary();
  });

  test('A1. Creating an organization', async () => {
    // Read organization request data
    const orgData = readRequestFile('org/create-organization.json');
    
    // Create organization
    const response = await makeAuthenticatedRequest(
      'post',
      `${config.eventCommandServiceUrl}/v1/organizations`,
      userToken,
      orgData
    );
    
    expect(response).toBeTruthy();
    expect(response.id).toBeTruthy();
    
    // Store organization data for future tests
    organizationId = response.id;
    organizationName = response.name;
    
    console.log(`Created organization: ${organizationName} with ID: ${organizationId}`);
  });

  test('A2. Verify organization in PostgreSQL database', async () => {
    // Query only necessary columns from the database
    const query = 'SELECT id, name, created_at FROM organizations WHERE id = $1';
    const results = await queryPostgres(query, [organizationId]);
    
    expect(results).toHaveLength(1);
    expect(results[0].id).toBe(organizationId);
    expect(results[0].name).toBe(organizationName);
  });

  test('A3. Fetching categories and selecting one subcategory', async () => {
    const categories = await makeAuthenticatedRequest(
      'get',
      `${config.eventCommandServiceUrl}/v1/categories`,
      userToken
    );
    
    expect(categories).toBeTruthy();
    expect(categories.length).toBeGreaterThan(0);
    
    // Find a subcategory to use
    let foundSubcategory = false;
    for (const category of categories) {
      if (category.subcategories && category.subcategories.length > 0) {
        categoryId = category.subcategories[0].id;
        foundSubcategory = true;
        break;
      }
    }
    
    expect(foundSubcategory).toBe(true);
    console.log(`Selected category ID: ${categoryId}`);
  });

  test('A4. Creating an event', async () => {
    // Read event request data
    let eventData = readRequestFile('event/create-event.json');
    
    // Update with our organization and category IDs
    eventData = updateRequestData(eventData, {
      'organizationId': organizationId,
      'categoryId': categoryId
    });
    
    // Create event using form data format
    const eventUrl = `${config.eventCommandServiceUrl}/v1/events`;
    const response = await formDataRequest(eventUrl, eventData, userToken);
    
    expect(response.status).toBe(200);
    expect(response.data).toBeTruthy();
    expect(response.data.id).toBeTruthy();
    
    // Store event ID for future tests
    eventId = response.data.id;
    console.log(`Created event with ID: ${eventId}`);
  });

  test('A5. Verify event in PostgreSQL database with PENDING status', async () => {
    // Query only necessary columns from the database
    const query = 'SELECT id, title, status, organization_id FROM events WHERE id = $1';
    const results = await queryPostgres(query, [eventId]);
    
    expect(results).toHaveLength(1);
    expect(results[0].id).toBe(eventId);
    expect(results[0].status).toBe('PENDING');
    expect(results[0].organization_id).toBe(organizationId);
  });

  test('A6. Verify event is not present in MongoDB database', async () => {
    const events = await queryMongoDB('event-seating', 'events', { _id: eventId });
    expect(events).toHaveLength(0);
  });

  test('A7. Approve event as admin', async () => {
    // Get admin token
    adminToken = await getKeycloakToken(config.adminUsername, config.adminPassword);
    expect(adminToken).toBeTruthy();
    
    // Approve the event
    const response = await makeAuthenticatedRequest(
      'post',
      `${config.eventCommandServiceUrl}/v1/events/${eventId}/approve`,
      adminToken
    );
    
    expect(response).toBeDefined();
  });

  test('A8. Verify event in PostgreSQL database with APPROVED status', async () => {
    // Query only necessary columns from the database
    const query = 'SELECT id, title, status FROM events WHERE id = $1';
    const results = await queryPostgres(query, [eventId]);
    
    expect(results).toHaveLength(1);
    expect(results[0].id).toBe(eventId);
    expect(results[0].status).toBe('APPROVED');
  });

  test('A9. Login as user again and verify event is present in MongoDB', async () => {
    // Get user token again
    userToken = await getKeycloakToken(config.username, config.password);
    expect(userToken).toBeTruthy();
    
    // Check MongoDB
    const events = await queryMongoDB('event-seating', 'events', { _id: eventId });
    expect(events).toHaveLength(1);
    expect(events[0]._id).toBe(eventId);
  });

  test('A10. Fetch event using event-query-service', async () => {
    const eventInfo = await makeAuthenticatedRequest(
      'get',
      `${config.eventQueryServiceUrl}/v1/events/${eventId}/basic-info`,
      userToken
    );
    
    expect(eventInfo).toBeTruthy();
    expect(eventInfo.id).toBe(eventId);
    expect(eventInfo.title).toBe('An Example Event');
  });

  test('A11. Fetch event sessions', async () => {
    const sessions = await makeAuthenticatedRequest(
      'get',
      `${config.eventQueryServiceUrl}/v1/events/${eventId}/sessions`,
      userToken
    );
    
    expect(sessions).toBeTruthy();
    expect(sessions.length).toBeGreaterThan(0);
    
    // Store session ID
    sessionId = sessions[0].id;
    expect(sessionId).toBeTruthy();
    console.log(`Using session ID: ${sessionId}`);
  });

  test('A12. Put session ON_SALE', async () => {
    const response = await makeAuthenticatedRequest(
      'put',
      `${config.eventCommandServiceUrl}/v1/sessions/${sessionId}/status`,
      userToken,
      { status: 'ON_SALE' }
    );
    
    expect(response).toBeTruthy();
    expect(response.id).toBe(sessionId);
    expect(response.status).toBe('ON_SALE');
  });

  test('A13. Fetch session seating map', async () => {
    const seatingMap = await makeAuthenticatedRequest(
      'get',
      `${config.eventQueryServiceUrl}/v1/sessions/${sessionId}/seating-map`,
      userToken
    );
    
    expect(seatingMap).toBeTruthy();
    expect(seatingMap.id).toBe(sessionId);
    // Verify seating map contains blocks and layout data
    expect(seatingMap.layoutData).toBeTruthy();
    expect(seatingMap.layoutData.layout).toBeTruthy();
    expect(Array.isArray(seatingMap.layoutData.layout.blocks)).toBe(true);
  });
});