export const config = {
  baseUrl: 'http://localhost:8082/api/event-query',
  auth: {
    tokenUrl: 'http://auth.ticketly.com:8080/realms/event-ticketing/protocol/openid-connect/token',
    clientId: 'login-testing',
    username: 'user@yopmail.com',
    password: 'user123',
    scope: 'internal-api'
  },
  // Sample IDs for testing in case we can't get real ones from API responses
  sampleEventId: '79955f7b-3735-4dce-a112-ba0ef29d36bd',
  sampleSessionId: '0c63685e-cf9c-428c-a383-7b1b2d26a43c',
  sampleSeatIds: [
    '76fad3f0-e7f9-4b55-a0eb-0b7a6743ad5d', 
    'c8007768-4334-40ef-a1b7-1f8fdc63da60', 
    '04cf511e-a6b2-4f83-b164-383f8139d825'
  ],
  // Test data for random selection
  categoryIds: [
    '36ffe7b4-89f1-4b8e-8d2a-655e1e967bfa',
    '3eb34120-90f2-4279-b290-aadc6359daa7',
    '08b80f14-421a-41fb-8c8e-bc74d4bb1b31'
  ],
  searchTerms: [
    'concert',
    'festival',
    'conference',
    'comedy',
    'theater',
    'sports',
    'music',
    'dazzling',
    'car',
    'sakura'
  ],
  // Configure SSL/TLS settings
  tls: {
    rejectUnauthorized: false // Set to true in production
  }
};

// Environment-specific configurations
export const environments = {
  local: {
    baseUrl: 'http://localhost:8082/api/event-query',
    auth: {
      tokenUrl: 'http://auth.ticketly.com:8080/realms/event-ticketing/protocol/openid-connect/token'
    }
  },
  dev: {
    baseUrl: 'https://dev-api.ticketly.com/event-query',
    auth: {
      tokenUrl: 'https://dev-auth.ticketly.com/realms/event-ticketing/protocol/openid-connect/token'
    }
  },
  staging: {
    baseUrl: 'https://staging-api.ticketly.com/event-query',
    auth: {
      tokenUrl: 'https://staging-auth.ticketly.com/realms/event-ticketing/protocol/openid-connect/token'
    }
  },
  prod: {
    baseUrl: 'https://api.ticketly.com/event-query',
    auth: {
      tokenUrl: 'https://auth.ticketly.com/realms/event-ticketing/protocol/openid-connect/token'
    }
  }
};