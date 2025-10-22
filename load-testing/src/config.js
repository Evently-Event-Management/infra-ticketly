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
    eventId: '3471e132-69f2-4764-ac79-e5ad57111483',
    sessionId: '293bed3f-c670-42f6-9e28-628cd6fec57a',
    organizationId: '22a67f04-b918-44ac-9b63-49efe8d34356',
    // Each seat will be tested with 100 VUs attempting to book simultaneously
    // Only 1 VU should succeed per seat
    seatIds: [
      // Row A (Standard)
      '79cd17f8-e160-4e8b-9c8a-aefb59ee287a', // 1A
      '70910468-5a2d-4b0b-88d9-1427ae167237', // 2A
      'af24bb02-ad5a-4fda-9810-aa54bf86c840', // 3A
      '57c2fbf6-52de-4eaf-bc16-d335a9f9b54a', // 4A

      // Row B (Standard)
      'b583919f-d650-460b-af24-2864c9acf791', // 1B
      'd6aafba3-1d91-463a-8320-4671c8b00912', // 2B
      'f6b7a2ce-219b-49fb-a105-9609613ef1ca', // 3B
      'b2df57f9-1229-4e60-a92e-c364c0e5c9e6', // 4B

      // Row C (VIP)
      'a2858ab4-05a0-45e1-894c-fbf7e50b71c1', // 1C
      'c1c8a266-6118-4ac4-a9ae-7c84914460c4', // 2C
      'aecf880d-b9b9-4d15-b864-2ed786822933', // 3C
      '1231d06a-d5c9-49bb-9a26-29f3a313d6f1', // 4C

      // Row D (VIP)
      '87766d31-439f-406c-aa4d-6f2e0d17f1a2', // 1D
      '7ed51c1e-0c01-4d3e-a91d-ef0cdbe1e1b1', // 2D
      '3c6cf1f2-1fcc-44e3-b4b6-03827016fec2', // 3D
      '24162129-e174-439e-a68f-676c5bcd75b8'  // 4D
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