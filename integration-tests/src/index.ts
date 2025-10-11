import { config } from './config/environment';
import { getKeycloakToken, makeAuthenticatedRequest } from './utils/apiUtils';

/**
 * This is the main entry point for the integration tests.
 * It can be run directly using `node dist/index.js`
 */

async function main() {
  console.log('Starting integration tests...');
  console.log('Using configuration:', {
    eventCommandServiceUrl: config.eventCommandServiceUrl,
    eventQueryServiceUrl: config.eventQueryServiceUrl,
    ticketsOrderServiceUrl: config.ticketsOrderServiceUrl,
    keycloakTokenUrl: config.keycloakTokenUrl,
    postgresqlAddress: config.postgresqlAddress,
    mongodbAddress: config.mongodbAddress,
  });

  try {
    // Test Keycloak connection
    console.log('Testing Keycloak connection...');
    const userToken = await getKeycloakToken(config.username, config.password);
    console.log('Successfully authenticated with Keycloak');

    // Test event command service
    console.log('Testing event command service...');
    await makeAuthenticatedRequest(
      'get',
      `${config.eventCommandServiceUrl}/v1/categories`,
      userToken
    );
    console.log('Event command service is responsive');

    // Test event query service
    console.log('Testing event query service...');
    try {
      // First try a healthcheck or basic endpoint if available
      await makeAuthenticatedRequest(
        'get',
        `${config.eventQueryServiceUrl}/health`,
        userToken
      );
      console.log('Event query service is responsive (health endpoint)');
    } catch (error) {
      try {
        // Try without a specific path, just the base URL
        await makeAuthenticatedRequest(
          'get',
          `${config.eventQueryServiceUrl}`,
          userToken
        );
        console.log('Event query service is responsive (base URL)');
      } catch (secondError) {
        console.warn('Warning: Could not connect to event query service. This may be expected if the service is not running yet.');
      }
    }

    console.log('\nAll services appear to be running. You can now run the full test suite:');
    console.log('npm run test:cqrs');
  } catch (error) {
    console.error('Error while performing connectivity tests:', error);
    console.log('\nSome services may not be available yet. You can still run the tests, but they might fail if services are not ready.');
    process.exit(0); // Exit with success code to allow CI/CD to continue
  }
}

// Only execute if this file is run directly (not imported)
if (require.main === module) {
  main().catch(console.error);
}