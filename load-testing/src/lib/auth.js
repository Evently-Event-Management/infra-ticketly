import http from 'k6/http';
import { config } from '../config.js';

/**
 * Gets an OAuth2 token from Keycloak using client credentials or password grant
 * @param {string} clientId - OAuth client ID
 * @param {string} clientSecret - OAuth client secret
 * @param {string} username - Optional username for password grant
 * @param {string} password - Optional password for password grant
 * @returns {{ access_token: string, expires_in: number, expires_at: number }} Token data
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
  
  console.log(`Authenticating with ${tokenUrl} using client ${clientId} and user ${username}`);
  
  const response = http.post(tokenUrl, formData, params);
  
  if (response.status !== 200) {
    console.error(`Authentication failed: ${response.status} ${response.body}`);
    throw new Error('Authentication failed');
  }
  
  const tokenResponse = JSON.parse(response.body);
  console.log(`Successfully obtained token, expires in ${tokenResponse.expires_in} seconds`);
  
  // Check if the token looks valid (should be a long string)
  if (!tokenResponse.access_token || tokenResponse.access_token.length < 20) {
    console.error(`Received suspicious token: ${tokenResponse.access_token}`);
    throw new Error('Received invalid token');
  }
  
  // Calculate expiration time (subtract 30 seconds as buffer)
  const expiresAt = Date.now() + ((tokenResponse.expires_in - 30) * 1000);
  
  return {
    access_token: tokenResponse.access_token,
    expires_in: tokenResponse.expires_in,
    expires_at: expiresAt,
  };
}

/**
 * Gets a valid auth token, refreshing if necessary
 * @param {{ access_token: string, expires_at: number }} tokenData - Current token data
 * @returns {{ access_token: string, expires_in: number, expires_at: number }} Valid token data
 */
export function getValidToken(tokenData) {
  // Check if token is expired or will expire soon
  if (!tokenData || !tokenData.expires_at || Date.now() >= tokenData.expires_at) {
    if (__VU <= 1 || __ENV.SCENARIO === 'debug') {
      console.log('Token expired or missing, refreshing...');
    }
    return getAuthToken();
  }
  
  return tokenData;
}