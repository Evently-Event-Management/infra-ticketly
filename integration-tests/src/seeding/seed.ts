import * as fs from 'fs';
import * as path from 'path';
import { config } from '../config/environment';
import { getKeycloakToken, makeAuthenticatedRequest, formDataRequest } from '../utils/apiUtils';
import { eventTitles, eventCategories, getRandomEventDescription, getRandomEventOverview } from './eventData';
import { sriLankaLocations } from './locations';

// UUID generation function (to avoid dependency)
function generateUUID(): string {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
    const r = Math.random() * 16 | 0;
    const v = c === 'x' ? r : (r & 0x3 | 0x8);
    return v.toString(16);
  });
}

interface SeedData {
  organizationId: string;
  events: {
    id: string;
    title: string;
    sessionId: string;
  }[];
}

async function wait(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function seedEvents(): Promise<void> {
  console.log('Starting event seeding process...');
  console.log(`Will create ${config.eventCount || 30} events.`);
  
  // Step 1: Get authentication tokens
  console.log('Authenticating user...');
  const userToken = await getKeycloakToken(config.username, config.password);
  const adminToken = await getKeycloakToken(config.adminUsername, config.adminPassword);
  
  // Step 2: Create organization
  console.log('Creating organization...');
  const orgData = { name: "Ticketly Seeded Organization" };
  const orgResponse = await makeAuthenticatedRequest('post', `${config.eventCommandServiceUrl}/v1/organizations`, userToken, orgData);
  const organizationId = orgResponse.id;
  console.log(`Organization created with ID: ${organizationId}`);
  
  // Step 3: Fetch categories
  console.log('Fetching event categories...');
  const categoriesResponse = await makeAuthenticatedRequest('get', `${config.eventCommandServiceUrl}/v1/categories`, userToken);
  
  // Extract available categories with subcategories
  const availableCategories: Array<{category: any, subCategory: any}> = [];
  categoriesResponse.forEach((category: any) => {
    if (category.subCategories && category.subCategories.length > 0) {
      category.subCategories.forEach((subCategory: any) => {
        availableCategories.push({
          category: {
            id: category.id,
            name: category.name
          },
          subCategory: {
            id: subCategory.id,
            name: subCategory.name
          }
        });
      });
    }
  });
  
  console.log(`Found ${availableCategories.length} available subcategories`);
  if (availableCategories.length === 0) {
    throw new Error('No subcategories found in the system. Cannot proceed with seeding.');
  }
  
  // Prepare data to track created events for cleanup
  const seedData: SeedData = {
    organizationId,
    events: []
  };
  
  // Step 4: Read image files from assets directory
  console.log('Reading image files from assets directory...');
  const imagesDir = config.imagesDir || path.join(process.cwd(), 'assets');
  let imageFiles: string[] = [];
  try {
    console.log(`Looking for images in: ${imagesDir}`);
    
    // Make sure directory exists
    if (!fs.existsSync(imagesDir)) {
      console.error(`Image directory does not exist: ${imagesDir}`);
      // Try looking in assets directory in current working directory
      const altPath = path.join(process.cwd(), 'assets');
      if (fs.existsSync(altPath)) {
        console.log(`Using alternative image path: ${altPath}`);
        imageFiles = fs.readdirSync(altPath)
          .filter(file => /\.(jpg|jpeg|png|gif)$/i.test(file))
          .map(file => path.join(altPath, file));
      }
    } else {
      imageFiles = fs.readdirSync(imagesDir)
        .filter(file => /\.(jpg|jpeg|png|gif)$/i.test(file))
        .map(file => path.join(imagesDir, file));
    }
    
    console.log(`Found ${imageFiles.length} image files.`);
    if (imageFiles.length > 0) {
      console.log(`First few images: ${imageFiles.slice(0, 3).map(f => path.basename(f)).join(', ')}`);
    }
  } catch (error) {
    console.error('Error reading image directory:', error);
    imageFiles = [];
  }

  // Calculate dates for events starting one week from now
  const today = new Date();
  const startDate = new Date(today);
  startDate.setDate(startDate.getDate() + 7); // Start events one week from today
  
  // Step 5: Create events
  const eventCount = Math.min(config.eventCount || 30, imageFiles.length || 30);
  console.log(`Creating ${eventCount} events...`);
  
  for (let i = 0; i < eventCount; i++) {
    try {
      // Pick random title, category, and location
      const title = eventTitles[i % eventTitles.length];
      
      // Select category from available system categories
      const selectedCategoryInfo = availableCategories[i % availableCategories.length];
      const categoryId = selectedCategoryInfo.subCategory.id;
      const categoryName = selectedCategoryInfo.subCategory.name;
      
      const location = sriLankaLocations[i % sriLankaLocations.length];
      
      // Calculate event date (one day apart starting from startDate)
      const eventDate = new Date(startDate);
      eventDate.setDate(eventDate.getDate() + i);
      
      // Event start and end time (2 hours duration)
      const startTime = new Date(eventDate);
      startTime.setHours(13, 30, 0, 0);
      const endTime = new Date(eventDate);
      endTime.setHours(15, 30, 0, 0);
      
      // Sales start time (60 mins from now)
      const salesStartTime = new Date();
      salesStartTime.setMinutes(salesStartTime.getMinutes() + 60);
      
      // Generate unique IDs
      const standardTierId = generateUUID();
      const vipTierId = generateUUID();
      const sessionId = generateUUID();
      const discountId = generateUUID();
      
      // Create event JSON template
      const eventData = {
        title,
        description: getRandomEventDescription(title),
        overview: getRandomEventOverview(title),
        organizationId,
        categoryId: categoryId,
        categoryName: categoryName,
        tiers: [
          {
            id: standardTierId,
            name: "Standard",
            price: 1000 + (i * 100), // Vary prices a bit
            color: "#3B82F6"
          },
          {
            id: vipTierId,
            name: "VIP",
            price: 2000 + (i * 150), // Higher price for VIP
            color: "#EF4444"
          }
        ],
        sessions: [
          {
            id: sessionId,
            startTime: startTime.toISOString(),
            endTime: endTime.toISOString(),
            salesStartTime: salesStartTime.toISOString(),
            sessionType: "PHYSICAL",
            venueDetails: {
              name: location.name + " Event Center",
              address: location.name,
              latitude: location.latitude,
              longitude: location.longitude
            },
            layoutData: {
              name: `${location.name} Layout`,
              layout: {
                blocks: [
                  {
                    id: generateUUID(),
                    name: "seating",
                    type: "seated_grid",
                    position: {
                      x: 86.6666259765625,
                      y: 133.33335876464844
                    },
                    rows: [
                      {
                        id: generateUUID(),
                        label: "A",
                        seats: [
                          {
                            id: generateUUID(),
                            label: "1A",
                            tierId: standardTierId,
                            status: "AVAILABLE"
                          },
                          {
                            id: generateUUID(),
                            label: "2A",
                            tierId: standardTierId,
                            status: "AVAILABLE"
                          },
                          {
                            id: generateUUID(),
                            label: "3A",
                            tierId: standardTierId,
                            status: "AVAILABLE"
                          },
                          {
                            id: generateUUID(),
                            label: "4A",
                            tierId: standardTierId,
                            status: "AVAILABLE"
                          }
                        ]
                      },
                      {
                        id: generateUUID(),
                        label: "B",
                        seats: [
                          {
                            id: generateUUID(),
                            label: "1B",
                            tierId: standardTierId,
                            status: "AVAILABLE"
                          },
                          {
                            id: generateUUID(),
                            label: "2B",
                            tierId: standardTierId,
                            status: "AVAILABLE"
                          },
                          {
                            id: generateUUID(),
                            label: "3B",
                            tierId: standardTierId,
                            status: "AVAILABLE"
                          },
                          {
                            id: generateUUID(),
                            label: "4B",
                            tierId: standardTierId,
                            status: "AVAILABLE"
                          }
                        ]
                      },
                      {
                        id: generateUUID(),
                        label: "C",
                        seats: [
                          {
                            id: generateUUID(),
                            label: "1C",
                            tierId: vipTierId,
                            status: "AVAILABLE"
                          },
                          {
                            id: generateUUID(),
                            label: "2C",
                            tierId: vipTierId,
                            status: "AVAILABLE"
                          },
                          {
                            id: generateUUID(),
                            label: "3C",
                            tierId: vipTierId,
                            status: "AVAILABLE"
                          },
                          {
                            id: generateUUID(),
                            label: "4C",
                            tierId: vipTierId,
                            status: "AVAILABLE"
                          }
                        ]
                      },
                      {
                        id: generateUUID(),
                        label: "D",
                        seats: [
                          {
                            id: generateUUID(),
                            label: "1D",
                            tierId: vipTierId,
                            status: "AVAILABLE"
                          },
                          {
                            id: generateUUID(),
                            label: "2D",
                            tierId: vipTierId,
                            status: "AVAILABLE"
                          },
                          {
                            id: generateUUID(),
                            label: "3D",
                            tierId: vipTierId,
                            status: "AVAILABLE"
                          },
                          {
                            id: generateUUID(),
                            label: "4D",
                            tierId: vipTierId,
                            status: "AVAILABLE"
                          }
                        ]
                      }
                    ],
                    capacity: null,
                    width: null,
                    height: null,
                    seats: []
                  },
                  {
                    id: generateUUID(),
                    name: "stage",
                    type: "non_sellable",
                    position: {
                      x: 25,
                      y: 25
                    },
                    rows: [],
                    capacity: null,
                    width: 325,
                    height: 80,
                    seats: []
                  }
                ]
              }
            }
          }
        ],
        discounts: Math.random() < 0.7 ? [ // 70% chance of having a discount
          {
            id: discountId,
            code: `SAVE${Math.floor(Math.random() * 16) + 5}`, // Random discount code SAVE5 to SAVE20
            maxUsage: null,
            currentUsage: 0,
            discountedTotal: 0,
            active: true,
            public: true,
            activeFrom: null,
            expiresAt: null,
            applicableTierIds: Math.random() < 0.5 ? 
              [standardTierId] : // 50% chance of standard tier only
              [standardTierId, vipTierId], // 50% chance of both tiers
            applicableSessionIds: [sessionId],
            parameters: {
              type: "PERCENTAGE",
              percentage: Math.floor(Math.random() * 16) + 5, // Random value between 5-20
              minSpend: Math.floor(Math.random() * 500) + 500, // Random min spend between 500-1000
              maxDiscount: null
            }
          }
        ] : []
      };
      
      // Create the event
      console.log(`Creating event ${i + 1}/${eventCount}: ${title}`);
      console.log(`Category: ${categoryName} (${categoryId})`);
      console.log(`Location: ${location.name}`);
      
      // Create event (with or without image)
      let eventResponse;
      try {
        if (imageFiles.length > 0) {
          const imageFile = imageFiles[i % imageFiles.length];
          console.log(`Using image: ${path.basename(imageFile)}`);
          console.log(`Image file path: ${imageFile}`);
          // Verify file exists before attempting upload
          if (fs.existsSync(imageFile)) {
            console.log(`Image file exists, size: ${(fs.statSync(imageFile).size / 1024).toFixed(2)} KB`);
            eventResponse = await formDataRequest(`${config.eventCommandServiceUrl}/v1/events`, eventData, userToken, imageFile);
          } else {
            console.warn(`Image file not found: ${imageFile}. Creating event without image.`);
            eventResponse = await formDataRequest(`${config.eventCommandServiceUrl}/v1/events`, eventData, userToken);
          }
        } else {
          console.log('No images available. Creating event without image.');
          eventResponse = await formDataRequest(`${config.eventCommandServiceUrl}/v1/events`, eventData, userToken);
        }
      } catch (uploadError) {
        console.error('Error uploading event with image:', uploadError);
        console.log('Attempting to create event without image as fallback...');
        eventResponse = await formDataRequest(`${config.eventCommandServiceUrl}/v1/events`, eventData, userToken);
      }
      
      const eventId = eventResponse.id;
      console.log(`Created event with ID: ${eventId}`);
      
      // Approve the event using admin token
      console.log(`Approving event: ${eventId}`);
      await makeAuthenticatedRequest('post', `${config.eventCommandServiceUrl}/v1/events/${eventId}/approve`, adminToken);
      console.log(`Event approved: ${eventId}`);
      
      // Store event data for later cleanup
      seedData.events.push({
        id: eventId,
        title,
        sessionId
      });
      

    } catch (error) {
      console.error(`Error creating event ${i + 1}:`, error);
    }
  }
  
  // Save seed data to file for cleanup
  const outputPath = config.seedDataOutputPath || path.join(process.cwd(), 'seed-data.json');
  fs.writeFileSync(outputPath, JSON.stringify(seedData, null, 2));
  console.log(`Seed data saved to ${outputPath}`);
  
  console.log('Event seeding completed!');
  console.log(`Created 1 organization and ${seedData.events.length} events.`);
}

// Check if this is being run directly
if (require.main === module) {
  seedEvents().catch(error => {
    console.error('Error during seeding:', error);
    process.exit(1);
  });
}

export { seedEvents };
