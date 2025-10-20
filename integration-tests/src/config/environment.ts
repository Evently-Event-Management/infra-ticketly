import { devConfig } from './environments/dev';
import { prodConfig } from './environments/prod';
import { seedConfig } from './environments/seed';

// Determine which configuration to use based on environment flag
const getConfig = () => {
  const env = process.env.ENV || 'dev';
  
  switch (env.toLowerCase()) {
    case 'prod':
      return prodConfig;
    case 'seed':
      return seedConfig;
    case 'dev':
    default:
      return devConfig;
  }
};

// Allow overriding with environment variables
const overrideWithEnvVars = (config: any) => {
  return {
    ...config,
    eventCommandServiceUrl: process.env.EVENT_COMMAND_SERVICE_URL || config.eventCommandServiceUrl,
    eventQueryServiceUrl: process.env.EVENT_QUERY_SERVICE_URL || config.eventQueryServiceUrl,
    ticketsOrderServiceUrl: process.env.TICKETS_ORDER_SERVICE_URL || config.ticketsOrderServiceUrl,
    keycloakTokenUrl: process.env.KEYCLOAK_TOKEN_URL || config.keycloakTokenUrl,
    keycloakClientId: process.env.KEYCLOAK_CLIENT_ID || config.keycloakClientId,
    username: process.env.USERNAME || config.username,
    password: process.env.PASSWORD || config.password,
    adminUsername: process.env.ADMIN_USERNAME || config.adminUsername,
    adminPassword: process.env.ADMIN_PASSWORD || config.adminPassword,
    postgresEventDbUrl: process.env.POSTGRESQL_EVENT_DB_URL || config.postgresEventDbUrl,
    postgresOrderDbUrl: process.env.POSTGRESQL_ORDER_DB_URL || config.postgresOrderDbUrl,
    mongodbAddress: process.env.MONGODB_ADDRESS || config.mongodbAddress,
    redisAddress: process.env.REDIS_ADDRESS || config.redisAddress,
  };
};

export const config = overrideWithEnvVars(getConfig());