# Event Ticketing Integration Tests

This project contains integration tests for the event ticketing system, following the CQRS flow.

## What is Tested

The integration tests cover the main event ticketing flow, including:

- Authentication via Keycloak (OAuth2)
- Organization creation and verification in PostgreSQL
- Category and subcategory selection
- Event creation and verification in PostgreSQL and MongoDB
- Event approval by admin and status propagation
- Session management and status updates (ON_SALE, CLOSED)
- Seat map retrieval and seat selection
- Placing orders for seats and verifying order status in PostgreSQL
- Ticket verification and seat locking in Redis
- Seat status updates in MongoDB
- Event and organization deletion and cleanup

If any step fails, the testing process stops immediately.

## Future Test Plans

Additional integration tests will be added for:

- Seat booking flows
- Seat check-in processes
- Event updates and modifications
- Seat cancellation and refund scenarios

These will help ensure the robustness of the ticketing system for more advanced use cases.

## Setup

1. Install dependencies:
   ```bash
   npm install
   ```

2. Build the TypeScript files:
   ```bash
   npm run build
   ```

## Running Tests

You can use the provided shell script to check service availability and run the tests:
```bash
./run-tests.sh
```

Or you can run the commands individually:

1. Check connectivity to required services:
```bash
npm run connectivity
```

2. Run the CQRS flow tests:
```bash
npm run test:cqrs
```

3. Or run all tests:
```bash
npm test
```

## Environment Variables

You can customize the test environment by setting the following environment variables:

```bash
# Service URLs
EVENT_COMMAND_SERVICE_URL=http://localhost:8081/api/event-seating
EVENT_QUERY_SERVICE_URL=http://localhost:8082/api/event-query
TICKETS_ORDER_SERVICE_URL=http://localhost:8084/api/order

# Keycloak
KEYCLOAK_TOKEN_URL=http://localhost:8080/realms/event-ticketing/protocol/openid-connect/token
KEYCLOAK_CLIENT_ID=login-testing

# Authentication
USERNAME=test_user@yopmail.com
PASSWORD=test123
ADMIN_USERNAME=admin@yopmail.com
ADMIN_PASSWORD=admin123

# Databases
POSTGRESQL_ADDRESS=postgres://ticketly:ticketly@localhost:5432
MONGODB_ADDRESS=mongodb://localhost:27017
REDIS_ADDRESS=redis://localhost:6379
```

## Test Flow

The tests follow this sequence:

1. Create an organization
2. Verify organization in PostgreSQL
3. Fetch categories and select a subcategory
4. Create an event
5. Verify event in PostgreSQL with PENDING status
6. Verify event is not present in MongoDB
7. Approve event as admin
8. Verify event has APPROVED status in PostgreSQL
9. Verify event is present in MongoDB
10. Fetch event details using query service
11. Fetch event sessions
12. Put a session ON_SALE
13. Fetch session seating map
14. Place an order for an available seat
15. Verify order in PostgreSQL
16. Verify ticket and seat lock in Redis
17. Confirm seat status is LOCKED in MongoDB
18. (Payment implementation skipped)
19. Change session status to CLOSED
20. Verify session status in PostgreSQL and MongoDB
21. Delete the event and organization, and verify deletion in databases

_Future tests will expand on seat booking, check-in, event update, and cancellation flows._