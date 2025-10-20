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

  console.log(`Authenticating with Keycloak at: ${config.keycloakTokenUrl}`);
  
  try {
    const response = await axios.post(config.keycloakTokenUrl, params);
    return response.data.access_token;
  } catch (error) {
    console.error('Keycloak authentication failed:');
    if (error.config) {
      console.error(`URL attempted: ${error.config.url}`);
    }
    throw error;
  }
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

export async function formDataRequest(url: string, jsonData: string | object, token: string, imageFilePath?: string): Promise<any> {
    const form = new FormData();
    
    // Add the JSON data
    if (typeof jsonData === 'string') {
        form.append('request', jsonData);
    } else {
        form.append('request', JSON.stringify(jsonData));
    }
    
    // Add image file if provided
    if (imageFilePath) {
        const fs = require('fs');
        const path = require('path');
        const fileName = path.basename(imageFilePath);
        // Using 'coverImages' key as expected by the backend
        form.append('coverImages', fs.createReadStream(imageFilePath), { filename: fileName });
    }
    
    try {
        // Log the form data keys for debugging
        console.log(`Form data parts: ${Object.keys(form).join(', ')}`);
        if (imageFilePath) {
            console.log(`Uploading image as 'coverImages' part`);
        }
        
        const response = await axios.post(url, form, {
            headers: { 
                'Authorization': `Bearer ${token}`, 
                ...form.getHeaders(),
                // Ensure proper content type is set
                'Content-Type': 'multipart/form-data'
            },
        });
        return response.data;
    } catch (error) {
        console.error('Error in formDataRequest:');
        if (imageFilePath) {
            console.error(`Failed to upload image: ${imageFilePath}`);
        }
        handleAxiosError(error as AxiosError, url, 'post');
        throw error; // re-throw after logging
    }
}