#!/usr/bin/env node

import { seedEvents } from './seed';
import { cleanupSeededData } from './cleanup';

const args = process.argv.slice(2);

async function main() {
  const action = args[0]?.toLowerCase();
  const seedDataPath = args[1];
  
  switch (action) {
    case 'seed':
      console.log('=== SEEDING TICKETLY EVENTS ===');
      await seedEvents();
      break;
    
    case 'cleanup':
      console.log('=== CLEANING UP SEEDED DATA ===');
      await cleanupSeededData(seedDataPath);
      break;
    
    default:
      console.log(`
Usage: 
  - To seed events: npm run seeding seed
  - To clean up seeded data: npm run seeding cleanup [path-to-seed-data.json]

If no path is specified for cleanup, the default path from the configuration will be used.
`);
      process.exit(1);
  }
}

main().catch(err => {
  console.error('Error in seeding process:', err);
  process.exit(1);
});