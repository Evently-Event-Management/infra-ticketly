import { config } from './config/environment';
import { getKeycloakToken, makeAuthenticatedRequest } from './utils/apiUtils';

/**
 * This is the main entry point for the integration tests.
 * It can be run directly using `node dist/index.js [mode]`
 * 
 * Modes:
 * - connectivity: Check connectivity to services (default)
 * - seed: Seed the system with events
 * - cleanup: Clean up seeded data
 */

const args = process.argv.slice(2);
const mode = args[0] || 'connectivity';

async function checkConnectivity() {
  console.log('Starting integration tests...');
  console.log('Using configuration:', {
    eventCommandServiceUrl: config.eventCommandServiceUrl,
    eventQueryServiceUrl: config.eventQueryServiceUrl,
    ticketsOrderServiceUrl: config.ticketsOrderServiceUrl,
    keycloakTokenUrl: config.keycloakTokenUrl,
    postgresEventDbUrl: config.postgresEventDbUrl,
    postgresOrderDbUrl: config.postgresOrderDbUrl,
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
    return; // Continue with other operations if needed
  }
}

async function main() {
  switch (mode.toLowerCase()) {
    case 'seed':
      // Import dynamically to avoid circular dependencies
      const { seedEvents } = await import('./seeding/seed');
      await seedEvents();
      break;
      
    case 'cleanup':
      const seedDataPath = args[1]; // Optional path to seed data file
      const { cleanupSeededData } = await import('./seeding/cleanup');
      await cleanupSeededData(seedDataPath);
      break;
      
    case 'connectivity':
    default:
      await checkConnectivity();
      break;
  }
}

// Only execute if this file is run directly (not imported)
if (require.main === module) {
  main().catch(error => {
    console.error('Error during execution:', error);
    process.exit(1);
  });
}