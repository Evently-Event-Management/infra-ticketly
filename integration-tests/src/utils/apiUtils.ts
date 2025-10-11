import axios, { AxiosError, Method } from 'axios';
import { config } from '../config/environment';


function handleAxiosError(error: AxiosError, url: string, method: Method) {
  if (error.response) {
    // The request was made and the server responded with a status code
    // that falls out of the range of 2xx
    console.error(`Error: ${method.toUpperCase()} ${url} failed with status ${error.response.status}`);
    console.error('Response Data:', JSON.stringify(error.response.data, null, 2));
  } else if (error.request) {
    // The request was made but no response was received
    console.error(`Error: No response received for ${method.toUpperCase()} ${url}`);
  } else {
    // Something happened in setting up the request that triggered an Error
    console.error('Error:', error.message);
  }
  throw error;
}


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
    handleAxiosError(error as AxiosError, url, method);
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