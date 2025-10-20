export const seedConfig = {
    eventCommandServiceUrl: 'http://localhost:8081/api/event-seating',
    eventQueryServiceUrl: 'http://localhost:8082/api/event-query',
    ticketsOrderServiceUrl: 'http://localhost:8084/api/order',
    keycloakTokenUrl: 'http://localhost:8080/realms/event-ticketing/protocol/openid-connect/token',
    keycloakClientId: 'login-testing',
    username: 'test_user@yopmail.com',
    password: 'test123',
    adminUsername: 'admin@yopmail.com',
    adminPassword: 'admin123',
    // Seeding specific configurations
    eventCount: 30,
    seedDataOutputPath: '/home/dpiyumal/projects/ticketly/infra-ticketly/integration-tests/seed-data.json',
    imagesDir: '/home/dpiyumal/projects/ticketly/infra-ticketly/integration-tests/assets',
};