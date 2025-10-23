import { environments } from './environments/config';

// Determine which configuration to use based on environment flag
const getConfig = () => {
  const env = process.env.ENV || 'dev';
  
  // Use the environment or fallback to dev if not found
  return environments[env.toLowerCase()] || environments.dev;
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
    username: process.env.SEED_USERNAME || config.username,
    password: process.env.SEED_PASSWORD || config.password,
    adminUsername: process.env.SEED_ADMIN_USERNAME || config.adminUsername,
    adminPassword: process.env.SEED_ADMIN_PASSWORD || config.adminPassword,
    postgresEventDbUrl: process.env.SEED_POSTGRESQL_EVENT_DB_URL || config.postgresEventDbUrl,
    postgresOrderDbUrl: process.env.SEED_POSTGRESQL_ORDER_DB_URL || config.postgresOrderDbUrl,
    mongodbAddress: process.env.MONGODB_ADDRESS || config.mongodbAddress,
    redisAddress: process.env.REDIS_ADDRESS || config.redisAddress,
  };
};

export const config = overrideWithEnvVars(getConfig());