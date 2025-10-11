# Event Ticketing Integration Tests

This project contains integration tests for the event ticketing system, following the CQRS flow.

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