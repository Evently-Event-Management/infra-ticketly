#!/usr/bin/env node

// Script to test environment configuration loading
const path = require('path');
const fs = require('fs');

// Set the environment variable
const env = process.env.ENV || 'dev';
console.log(`Testing with environment: ${env}`);

// Read the config file directly
const configPath = path.join(__dirname, '../src/config/environments/config.ts');
const configContent = fs.readFileSync(configPath, 'utf8');

// Extract the correct config based on environment
const envConfig = env === 'prod' ? 'prodConfig' : 'devConfig';

// Run with ts-node to test the actual configuration
const { spawn } = require('child_process');
const tsNodePath = path.join(__dirname, '../node_modules/.bin/ts-node');

const tester = spawn(tsNodePath, ['-e', `
import { environments } from '../src/config/environments/config';

const env = process.env.ENV || 'dev';
const config = environments[env];

console.log('=== Environment Configuration ===');
console.log(\`Environment: \${env} (default: dev)\`);
console.log('\\nAPI Endpoints:');
console.log(\`Event Command Service: \${config.eventCommandServiceUrl}\`);
console.log(\`Event Query Service: \${config.eventQueryServiceUrl}\`);
console.log(\`Tickets Order Service: \${config.ticketsOrderServiceUrl}\`);

console.log('\\nAuthentication:');
console.log(\`Keycloak Token URL: \${config.keycloakTokenUrl}\`);
console.log(\`Keycloak Client ID: \${config.keycloakClientId}\`);

console.log('\\nSeeding Configuration:');
console.log(\`Image Directory: \${config.imagesDir}\`);
console.log(\`Seed Data Output: \${config.seedDataOutputPath}\`);
console.log(\`Event Count: \${config.eventCount}\`);
`], { 
  env: process.env,
  stdio: 'inherit'
});

// Handle process completion
tester.on('close', (code) => {
  process.exit(code);
});