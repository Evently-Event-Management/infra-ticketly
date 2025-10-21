export const config = {
  auth: {
    tokenUrl: 'http://auth.ticketly.com:8080/realms/event-ticketing/protocol/openid-connect/token',
    clientId: 'login-testing',
    username: 'user@yopmail.com',
    password: 'user123',
    scope: 'internal-api'
  },
  query: {
    baseUrl: 'http://localhost:8082/api/event-query',
    searchTerms: [
      'tech summit',
      'colombo jazz',
      'heritage exhibition',
      'kandy perahera',
      'digital marketing',
      'beach volleyball',
      'food festival',
      'startup weekend',
      'film festival',
      'wellness retreat',
      'photography exhibition',
      'tea celebration',
      'literary festival',
      'fashion week',
      'edm night',
      'cricket tournament',
      'handloom market',
      'temple music',
      'conservation summit',
      'dance performance',
      'buddhist art',
      'entrepreneurship masterclass',
      'poetry slam',
      'night market',
      'jewelry exhibition',
      'vesak lantern',
      'eco-tourism',
      'jaffna cultural',
      'yoga day',
      'marine conservation'
    ]
  },

  order: {
    baseUrl: 'http://localhost:8084/api/order',
    eventId: '79955f7b-3735-4dce-a112-ba0ef29d36bd',
    sessionId: '0c63685e-cf9c-428c-a383-7b1b2d26a43c',
    organizationId: 'fac50f39-1180-4e1c-94f3-ebb4ea223f17',
    seatIds: [
      'seat-101',
      'seat-102',
      'seat-103',
      'seat-104',
      'seat-105'
    ]
  },
  // Configure SSL/TLS settings
  tls: {
    rejectUnauthorized: false // Set to true in production
  }
};

// Environment-specific configurations
export const environments = {
  dev: {
    query: {
      baseUrl: 'http://localhost:8082/api/event-query'
    },
    order: {
      baseUrl: 'http://localhost:8084/api/order'
    },
    auth: {
      tokenUrl: 'http://auth.ticketly.com:8080/realms/event-ticketing/protocol/openid-connect/token'
    }
  },
  prod: {
    query: {
      baseUrl: 'https://api.dpiyumal.me/api/event-query'
    },
    order: {
      baseUrl: 'https://api.dpiyumal.me/api/order'
    },
    auth: {
      tokenUrl: 'https://auth.dpiyumal.me/realms/event-ticketing/protocol/openid-connect/token'
    }
  }
};

export function applyEnvironment(environmentKey) {
  if (!environmentKey || environmentKey === 'local') {
    return;
  }

  const overrides = environments[environmentKey];
  if (!overrides) {
    console.warn(`No environment overrides found for "${environmentKey}"; using base configuration.`);
    return;
  }

  if (overrides.auth?.tokenUrl) {
    config.auth.tokenUrl = overrides.auth.tokenUrl;
  }

  if (overrides.query?.baseUrl) {
    config.query.baseUrl = overrides.query.baseUrl;
  }

  if (overrides.order?.baseUrl) {
    config.order.baseUrl = overrides.order.baseUrl;
  }
}