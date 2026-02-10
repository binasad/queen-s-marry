# Services Import Guide

## Overview

The Services Import feature allows you to bulk import all hardcoded services from the salon-app Flutter application into the admin-web database.

## Total Services to Import

- **Hair Services**: 29 services (Hair Cutting: 14, Hair Color: 7, Hair Treatment: 8)
- **Makeup Services**: 9 services
- **Facial Services**: 11 services (Facial: 7, Treatment: 4)
- **Massage Services**: 9 services
- **Mehndi Services**: 5 services
- **Waxing Services**: 8 services
- **PhotoShoot Services**: 3 services

**Total: 74 services**

## How to Use

### Step 1: Access the Import Page

1. Navigate to the Services page (`/services`)
2. Click the "📥 Import Services" button (green button)
3. You'll be redirected to `/services/import`

### Step 2: Map Categories

1. The import page will automatically load all existing categories from the database
2. For each service category (Hair Services, Makeup Services, etc.), select the corresponding database category from the dropdown
3. The system will try to auto-map categories by name, but you can adjust if needed

**Important:** If you don't have categories in the database yet, you need to create them first:
- Go back to Services page
- Create categories like "Hair Services", "Makeup Services", "Facial Services", etc.
- Then return to the import page

### Step 3: Import Services

1. Once all categories are mapped, click "Import [74] Services" button
2. The import process will:
   - Show a progress bar
   - Import services one by one
   - Skip duplicates (if a service with the same name already exists)
   - Display success/error counts at the end

3. After completion, you'll be redirected to the Services page to view all imported services

## Features

- **Progress Tracking**: Real-time progress bar showing current/total services
- **Error Handling**: Gracefully handles errors and continues with remaining services
- **Duplicate Detection**: Skips services that already exist
- **Category Mapping**: Visual interface to map service categories
- **Duration Parsing**: Automatically converts duration strings (e.g., "60–90 mins", "2 hrs") to minutes

## Duration Conversion

The import automatically converts duration strings to minutes:
- "40 mins" → 40 minutes
- "60–90 mins" → 75 minutes (average)
- "2 hrs" → 120 minutes
- "2–3 hrs" → 150 minutes (average)

## Service Data Structure

Each imported service includes:
- **Name**: Service name
- **Price**: Price in PKR (Pakistani Rupees)
- **Duration**: Converted to minutes
- **Description**: Full service description
- **Category**: Mapped to database category
- **Tags**: Sub-category tags (for nested categories like Hair Services)

## Troubleshooting

### No Categories Found
- **Problem**: "No categories found!" message appears
- **Solution**: Create categories first in the Services page, then return to import

### Import Fails
- **Problem**: Import button is disabled or shows errors
- **Solution**: 
  - Ensure you're logged in as admin (`admin@salon.com` / `admin123`)
  - Check that all categories are mapped
  - Verify backend API is running

### Some Services Failed
- **Problem**: Import shows some services failed
- **Solution**: 
  - Check browser console for error details
  - Failed services might be duplicates (which are skipped)
  - Network errors will be logged

## Notes

- Services are imported with `is_active = TRUE` by default
- Image URLs are set to `null` (you can add images later via the edit feature)
- Tags are preserved for sub-categories (e.g., "Hair Cutting", "Hair Color" as tags)
- The import process includes a 100ms delay between each service to avoid overwhelming the server

## After Import

Once services are imported:
1. Review them in the Services page
2. Edit services to add images if needed
3. Verify all services are correctly categorized
4. Services will now be available in the salon-app when it fetches from the API
