import axios, { AxiosError, AxiosRequestConfig, Method } from 'axios';
import { config } from '../config/environment';
import { URLSearchParams } from 'url';
import FormData from 'form-data';

function handleAxiosError(error: AxiosError, url: string, method: Method | 'post') {
  if (error.response) {
    console.error(`Error: ${method.toUpperCase()} ${url} failed with status ${error.response.status}`);
    console.error('Response Data:', JSON.stringify(error.response.data, null, 2));
  } else if (error.request) {
    console.error(`Error: No response received for ${method.toUpperCase()} ${url}`);
  } else {
    console.error('Error:', error.message);
  }
  throw error;
}

export async function getKeycloakToken(username: string, password: string): Promise<string> {
  const params = new URLSearchParams();
  params.append('client_id', config.keycloakClientId);
  params.append('username', username);
  params.append('password', password);
  params.append('grant_type', 'password');

  const response = await axios.post(config.keycloakTokenUrl, params);
  return response.data.access_token;
}

export async function makeAuthenticatedRequest(method: Method, url: string, token: string, data?: any): Promise<any> {
  try {
    const response = await axios({
        method,
        url,
        data,
        headers: { Authorization: `Bearer ${token}` },
    });
    return response.data;
  } catch (error) {
    handleAxiosError(error as AxiosError, url, method);
    throw error; // re-throw after logging
  }
}

export async function formDataRequest(url: string, jsonData: any, token: string): Promise<any> {
    const form = new FormData();
    form.append('request', JSON.stringify(jsonData), { contentType: 'application/json' });
    try {
        const response = await axios.post(url, form, {
            headers: { 'Authorization': `Bearer ${token}`, ...form.getHeaders() },
        });
        return response.data;
    } catch (error) {
        handleAxiosError(error as AxiosError, url, 'post');
        throw error; // re-throw after logging
    }
}