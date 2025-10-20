/**
 * Consolidated environment configuration for Ticketly integration tests
 * 
 * This file contains all environment configurations (dev and prod)
 * to avoid duplication across different config files.
 */

// Development environment configuration (local)
export const devConfig = {
    // API endpoints
    eventCommandServiceUrl: 'http://localhost:8081/api/event-seating',
    eventQueryServiceUrl: 'http://localhost:8082/api/event-query',
    ticketsOrderServiceUrl: 'http://localhost:8084/api/order',
    
    // Authentication
    keycloakTokenUrl: 'http://localhost:8080/realms/event-ticketing/protocol/openid-connect/token',
    keycloakClientId: 'login-testing',
    username: 'test_user@yopmail.com',
    password: 'test123',
    adminUsername: 'admin@yopmail.com',
    adminPassword: 'admin123',
    
    // Database connections
    postgresEventDbUrl: 'postgres://ticketly:ticketly@localhost:5432/event_service',
    postgresOrderDbUrl: 'postgres://ticketly:ticketly@localhost:5432/order_service',
    mongodbAddress: 'mongodb://localhost:27017',
    redisAddress: 'redis://localhost:6379',
    
    // Seeding specific configurations
    eventCount: 30,
    seedDataOutputPath: '/home/dpiyumal/projects/ticketly/infra-ticketly/integration-tests/seed-data.json',
    imagesDir: '/home/dpiyumal/projects/ticketly/infra-ticketly/integration-tests/assets',
};

// Production environment configuration
export const prodConfig = {
    // API endpoints
    eventCommandServiceUrl: 'https://api.dpiyumal.me/api/event-seating',
    eventQueryServiceUrl: 'https://api.dpiyumal.me/api/event-query',
    ticketsOrderServiceUrl: 'https://api.dpiyumal.me/api/order',
    
    // Authentication
    keycloakTokenUrl: 'https://auth.dpiyumal.me/realms/event-ticketing/protocol/openid-connect/token',
    keycloakClientId: 'login-testing',
    username: 'test_user@yopmail.com',
    password: 'test123',
    adminUsername: 'admin@yopmail.com',
    adminPassword: 'admin123',
    
    // Database connections
    postgresEventDbUrl: 'postgres://ticketly:ticketly@db.ticketly.com:5432/event_service',
    postgresOrderDbUrl: 'postgres://ticketly:ticketly@db.ticketly.com:5432/order_service',
    mongodbAddress: 'mongodb://mongodb.ticketly.com:27017',
    redisAddress: 'redis://redis.ticketly.com:6379',
    
    // Seeding specific configurations
    eventCount: 30,
    seedDataOutputPath: '/home/dpiyumal/projects/ticketly/infra-ticketly/integration-tests/seed-data.json',
    imagesDir: '/home/dpiyumal/projects/ticketly/infra-ticketly/integration-tests/assets',
};

// Export environments map for easy selection
export const environments = {
    dev: devConfig,
    prod: prodConfig
};