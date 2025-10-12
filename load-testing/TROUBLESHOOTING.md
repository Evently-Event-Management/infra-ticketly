## Troubleshooting

### Authentication Error

If you see an authentication error like this:

```
ERRO[0000] Authentication failed: 401 {"error":"invalid_client","error_description":"Invalid client or Invalid client credentials"}
```

You need to:

1. Set up a Keycloak client for load testing. Use the provided script:
   ```
   ./setup-keycloak.sh
   ```

2. Or manually create a client in Keycloak with the following settings:
   - Client ID: ticketly-load-test
   - Client Secret: load-test-secret (or choose your own)
   - Client Protocol: openid-connect
   - Access Type: confidential
   - Service Accounts Enabled: ON
   - Direct Access Grants Enabled: ON

3. Update the config.js file with the correct authentication details:
   ```javascript
   auth: {
     tokenUrl: 'http://auth.ticketly.com:8080/realms/event-ticketing/protocol/openid-connect/token',
     clientId: 'ticketly-load-test',
     clientSecret: 'your-client-secret', // Update this
     username: 'load-test-user',         // Optional for client_credentials flow
     password: 'load-test-password',      // Optional for client_credentials flow
     scope: 'internal-api'
   }
   ```

### "systemTags" Error

If you see an error like:
```
ERRO[0000] could not initialize 'src/main.js': could not load JS test 'file:///path/to/src/main.js': json: unknown field "systemTags"
```

This has been fixed by replacing `options: { systemTags: [...] }` with `tags: { scenario: '...' }` in all scenario files.

### Missing Imports

If you see errors related to missing imports, check that you're using the correct k6 version (>=0.30.0) and that all files are correctly placed in the project structure.

### SSL/TLS Issues

If you encounter SSL/TLS verification issues, you can modify the request parameters in the lib files to include:

```javascript
const params = {
  headers: { ... },
  insecureSkipTLSVerify: true // Only for testing environments
};
```