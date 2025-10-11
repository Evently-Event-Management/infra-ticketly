import axios from 'axios';
import { config } from '../config/environment';

export async function getKeycloakToken(username: string, password: string): Promise<string> {
  try {
    const params = new URLSearchParams();
    params.append('client_id', config.keycloakClientId);
    params.append('username', username);
    params.append('password', password);
    params.append('grant_type', 'password');

    const response = await axios.post(config.keycloakTokenUrl, params, {
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
    });

    return response.data.access_token;
  } catch (error) {
    console.error('Error getting Keycloak token:', error);
    throw error;
  }
}

export async function makeAuthenticatedRequest(
  method: 'get' | 'post' | 'put' | 'delete',
  url: string,
  token: string,
  data?: any,
  headers?: Record<string, string>
) {
  try {
    const response = await axios({
      method,
      url,
      data,
      headers: {
        Authorization: `Bearer ${token}`,
        ...headers,
      },
    });
    return response.data;
  } catch (error) {
    console.error(`Error making ${method.toUpperCase()} request to ${url}:`, error);
    throw error;
  }
}

export function formDataRequest(url: string, jsonData: any, token: string) {
  const formDataHeader = 'Content-Type: multipart/form-data; boundary=----geckoformboundary7c228b1d5f37fcaafaf06038c0d051b8';
  const formDataPayload = `------geckoformboundary7c228b1d5f37fcaafaf06038c0d051b8\r\nContent-Disposition: form-data; name="request"\r\n\r\n${JSON.stringify(jsonData)}\r\n------geckoformboundary7c228b1d5f37fcaafaf06038c0d051b8--`;

  return axios.post(url, formDataPayload, {
    headers: {
      'Content-Type': 'multipart/form-data; boundary=----geckoformboundary7c228b1d5f37fcaafaf06038c0d051b8',
      'Authorization': `Bearer ${token}`
    }
  });
}