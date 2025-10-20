#!/usr/bin/env bash

# Simple script to test environment configuration

ENV=$1
if [ -z "$ENV" ]; then
  ENV="dev"
fi

echo "Testing environment configuration for: $ENV"
echo ""

cd "$(dirname "$0")/.."
npx ts-node -e "
import { environments } from './src/config/environments/config';

const env = '$ENV';
const config = environments[env];

console.log('=== Environment Configuration ===');
console.log(\`Environment: \${env}\`);
console.log('\\nAPI Endpoints:');
console.log(\`Event Command Service: \${config.eventCommandServiceUrl}\`);
console.log(\`Event Query Service: \${config.eventQueryServiceUrl}\`);
console.log(\`Tickets Order Service: \${config.ticketsOrderServiceUrl}\`);

console.log('\\nAuthentication:');
console.log(\`Keycloak Token URL: \${config.keycloakTokenUrl}\`);
console.log(\`Keycloak Client ID: \${config.keycloakClientId}\`);
"