import * as fs from 'fs';
import * as path from 'path';
import { config } from '../config/environment';
import { getKeycloakToken, makeAuthenticatedRequest } from '../utils/apiUtils';

interface SeedData {
  organizationId: string;
  events: {
    id: string;
    title: string;
    sessionId: string;
  }[];
}

async function cleanupSeededData(seedDataPath?: string): Promise<void> {
  // Default path if not provided
  const dataPath = seedDataPath || config.seedDataOutputPath || path.join(process.cwd(), 'seed-data.json');
  
  console.log(`Loading seed data from: ${dataPath}`);
  
  // Check if file exists
  if (!fs.existsSync(dataPath)) {
    console.error(`Seed data file not found: ${dataPath}`);
    return;
  }
  
  // Read the seed data file
  let seedData: SeedData;
  try {
    const fileContents = fs.readFileSync(dataPath, 'utf8');
    seedData = JSON.parse(fileContents);
  } catch (error) {
    console.error('Error reading seed data file:', error);
    return;
  }
  
  // Get authentication token
  console.log('Authenticating user...');
  const userToken = await getKeycloakToken(config.username, config.password);
  
  // Delete each event
  console.log(`Found ${seedData.events.length} events to delete.`);
  for (const event of seedData.events) {
    try {
      console.log(`Deleting event: ${event.title} (${event.id})`);
      await makeAuthenticatedRequest('delete', `${config.eventCommandServiceUrl}/v1/events/${event.id}`, userToken);
      console.log(`Event deleted: ${event.id}`);
    } catch (error) {
      console.error(`Failed to delete event ${event.id}:`, error);
    }
  }
  
  // Delete the organization
  if (seedData.organizationId) {
    try {
      console.log(`Deleting organization: ${seedData.organizationId}`);
      await makeAuthenticatedRequest('delete', `${config.eventCommandServiceUrl}/v1/organizations/${seedData.organizationId}`, userToken);
      console.log(`Organization deleted: ${seedData.organizationId}`);
    } catch (error) {
      console.error(`Failed to delete organization ${seedData.organizationId}:`, error);
    }
  }
  
  console.log('Cleanup completed!');
}

// Check if this is being run directly
if (require.main === module) {
  cleanupSeededData().catch(error => {
    console.error('Error during cleanup:', error);
    process.exit(1);
  });
}

export { cleanupSeededData };