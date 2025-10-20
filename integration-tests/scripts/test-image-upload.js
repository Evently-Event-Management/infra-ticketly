#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const axios = require('axios');
const FormData = require('form-data');

// Import config
const { config } = require('../src/config/environment');

// Import auth utilities
const { getKeycloakToken } = require('../src/utils/apiUtils');

// Function to test image upload
async function testImageUpload() {
  try {
    console.log('Starting image upload test...');
    
    // 1. Get auth token
    console.log('Authenticating user...');
    const token = await getKeycloakToken(config.username, config.password);
    console.log('Authentication successful!');
    
    // 2. Find an image to test with
    const imagesDir = config.imagesDir || path.join(process.cwd(), 'assets');
    console.log(`Looking for images in: ${imagesDir}`);
    
    if (!fs.existsSync(imagesDir)) {
      console.error(`Image directory not found: ${imagesDir}`);
      process.exit(1);
    }
    
    const imageFiles = fs.readdirSync(imagesDir)
      .filter(file => /\.(jpg|jpeg|png|gif)$/i.test(file))
      .map(file => path.join(imagesDir, file));
    
    if (imageFiles.length === 0) {
      console.error('No image files found');
      process.exit(1);
    }
    
    const testImagePath = imageFiles[0];
    console.log(`Using test image: ${path.basename(testImagePath)}`);
    console.log(`Full path: ${testImagePath}`);
    console.log(`File size: ${(fs.statSync(testImagePath).size / 1024).toFixed(2)} KB`);
    
    // 3. Create minimal test data
    const testEventData = {
      title: "Image Upload Test Event",
      description: "This is a test event for verifying image uploads",
      organizationId: "00000000-0000-0000-0000-000000000000", // Will be ignored in test mode
      categoryId: "00000000-0000-0000-0000-000000000000"      // Will be ignored in test mode
    };
    
    // 4. Create form data with image
    const form = new FormData();
    form.append('request', JSON.stringify(testEventData));
    form.append('coverImages', fs.createReadStream(testImagePath), {
      filename: path.basename(testImagePath)
    });
    
    console.log('Form data created successfully');
    console.log(`Form parts: request, coverImages`);
    
    // 5. Upload to test endpoint
    console.log('Sending test request...');
    try {
      // Use test endpoint if available, otherwise use the regular endpoint
      const testUrl = `${config.eventCommandServiceUrl}/v1/events/test-upload`;
      const response = await axios.post(testUrl, form, {
        headers: { 
          'Authorization': `Bearer ${token}`,
          ...form.getHeaders()
        },
      });
      
      console.log('SUCCESS! Server received the image upload');
      console.log('Response:', response.data);
    } catch (error) {
      console.error('Upload failed:');
      if (error.response) {
        console.error(`Status: ${error.response.status}`);
        console.error('Response:', error.response.data);
      } else {
        console.error(error.message);
      }
      
      console.log('\nFalling back to checking if endpoint exists...');
      try {
        // Check if the endpoint exists
        await axios.options(`${config.eventCommandServiceUrl}/v1/events`, {
          headers: { 'Authorization': `Bearer ${token}` }
        });
        console.log('Event endpoint exists and responds to OPTIONS request.');
      } catch (optionsError) {
        console.error('Failed to check endpoint:', optionsError.message);
      }
    }
    
  } catch (error) {
    console.error('Test failed:', error.message);
    process.exit(1);
  }
}

// Run the test
testImageUpload();