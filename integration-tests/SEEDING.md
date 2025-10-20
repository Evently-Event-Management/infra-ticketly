# Ticketly Event Seeding Guide

This guide explains how to use the event seeding tools to populate the Ticketly system with test events.

## Overview

The seeding tools allow you to:

1. Create a test organization
2. Create multiple events with randomized titles in different categories
3. Assign events to random Sri Lankan locations
4. Schedule events over a 30-day period
5. Include images for the events
6. Put events on sale automatically
7. Clean up seeded data when testing is complete

## Prerequisites

- All Ticketly services must be running (event-command, event-query, order-service)
- Keycloak should be properly configured with test users
- MongoDB, PostgreSQL, and Redis should be accessible
- Event images should be in the `assets` directory

## Environment Configuration

The seeding system supports multiple environments:

- `dev`: Local development environment (default)
- `prod`: Production environment
- `seed`: Special configuration for seeding operations

You can select an environment by setting the `ENV` variable:

```bash
# Use development environment
ENV=dev ./seed-events.sh seed

# Use production environment
ENV=prod ./seed-events.sh seed

# Use seed-specific configuration
ENV=seed ./seed-events.sh seed
```

## Seeding Events

To seed the system with events:

```bash
# Build and run the seeding script
./seed-events.sh seed
```

This will:
1. Create a "Ticketly Seeded Organization"
2. Create 30 events (or as many as there are images)
3. Assign random titles and categories to events
4. Schedule events starting one week from today, one per day
5. Set sales start time to 15 minutes from when script is run
6. Automatically approve events and put sessions on sale
7. Save event and organization IDs to `seed-data.json` for later cleanup

## Cleaning Up Seeded Data

To remove all seeded data:

```bash
# Clean up using data from default location
./seed-events.sh cleanup

# Clean up using data from a specific file
./seed-events.sh cleanup /path/to/seed-data.json
```

The cleanup process will:
1. Delete all events created during seeding
2. Delete the organization created during seeding

## Advanced Usage

### Modifying Seeded Data

You can customize seeded data by modifying:

- `src/seeding/eventData.ts`: Event titles, categories, descriptions
- `src/seeding/locations.ts`: Venue locations
- `src/config/environments/seed.ts`: Seeding configuration

### Setting Custom Paths

You can set custom paths for the seed data file and image directory in `src/config/environments/seed.ts`.

## Troubleshooting

If seeding fails:

1. Check that all services are running
2. Verify Keycloak authentication is working
3. Make sure you have images in the assets directory
4. Check network connectivity to databases
5. Verify image uploads work by running the test script

### Image Upload Testing

You can test image uploads specifically to help troubleshoot issues:

```bash
# Test image upload functionality
./scripts/seed-events.sh -t
```

This will attempt to upload a single image to verify the upload process works correctly.

### Verifying Images

To verify that the system can see and access the images:

```bash
# Only verify that images exist
./scripts/verify-images.sh
```

This checks that:
- The assets directory exists
- There are image files in the directory
- The image files are accessible and have proper permissions

### Common Image Upload Issues

1. **Missing Images**: Ensure you have image files in the `assets` directory
2. **Wrong Form Field Name**: The API expects images in the `coverImages` form field
3. **File Size**: Images may be rejected if they're too large (keep under 5MB)
4. **File Format**: Ensure images are in supported formats (JPG, PNG, GIF)
5. **Authentication**: Verify that your token has permission to upload images
5. Examine console output for specific errors

For persistent issues, run the connectivity test first:

```bash
npm run connectivity
```