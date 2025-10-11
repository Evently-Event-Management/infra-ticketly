import http from 'k6/http';
import { config } from '../config.js';

/**
 * Gets an OAuth2 token from Keycloak using client credentials or password grant
 * @param {string} clientId - OAuth client ID
 * @param {string} clientSecret - OAuth client secret
 * @param {string} username - Optional username for password grant
 * @param {string} password - Optional password for password grant
 * @returns {string} Access token
 */
export function getAuthToken(clientId = config.auth.clientId, clientSecret = config.auth.clientSecret, 
                            username = config.auth.username, password = config.auth.password) {
  
  const tokenUrl = config.auth.tokenUrl;
  const params = {
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    // Uncomment this for testing environments if needed
    // insecureSkipTLSVerify: true
  };
  
  // For login-testing client, we use password grant type as it's a public client
  let formData = {
    grant_type: 'password',
    client_id: clientId,
    username: username,
    password: password,
    scope: config.auth.scope || '',
  };
  
  const response = http.post(tokenUrl, formData, params);
  
  if (response.status !== 200) {
    console.error(`Authentication failed: ${response.status} ${response.body}`);
    throw new Error('Authentication failed');
  }
  
  const tokenResponse = JSON.parse(response.body);
  return tokenResponse.access_token;
}