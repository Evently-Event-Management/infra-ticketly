export const config = {
  eventCommandServiceUrl: process.env.EVENT_COMMAND_SERVICE_URL || 'http://localhost:8081/api/event-seating',
  eventQueryServiceUrl: process.env.EVENT_QUERY_SERVICE_URL || 'http://localhost:8082/api/event-query',
  ticketsOrderServiceUrl: process.env.TICKETS_ORDER_SERVICE_URL || 'http://localhost:8084/api/order',
  keycloakTokenUrl: process.env.KEYCLOAK_TOKEN_URL || 'http://localhost:8080/realms/event-ticketing/protocol/openid-connect/token',
  keycloakClientId: process.env.KEYCLOAK_CLIENT_ID || 'login-testing',
  username: process.env.USERNAME || 'test_user@yopmail.com',
  password: process.env.PASSWORD || 'test123',
  adminUsername: process.env.ADMIN_USERNAME || 'admin@yopmail.com',
  adminPassword: process.env.ADMIN_PASSWORD || 'admin123',
  postgresqlAddress: process.env.POSTGRESQL_ADDRESS || 'postgres://ticketly:ticketly@localhost:5432',
  mongodbAddress: process.env.MONGODB_ADDRESS || 'mongodb://localhost:27017',
  redisAddress: process.env.REDIS_ADDRESS || 'redis://localhost:6379',
};