# Services API Integration Test Guide

## Admin-Web Services API Integration

The admin-web application has been integrated with the services API for creating and deleting services.

### Features Implemented:

1. **Create Service** ✅
   - Modal form with all required fields
   - Category selection
   - Name, description, price, duration
   - Image URL and tags support
   - Form validation
   - Success/error notifications

2. **Delete Service** ✅
   - Confirmation dialog
   - Soft delete (sets is_active = FALSE)
   - Automatic list refresh after deletion
   - Error handling

3. **Update Service** ✅
   - Edit existing services
   - Pre-filled form with current data
   - Same validation as create

4. **List Services** ✅
   - Real-time search
   - Category filtering
   - Loading states
   - Empty state handling

### API Endpoints Used:

- `GET /api/v1/services` - Get all services
- `POST /api/v1/services` - Create service (requires auth + services.manage permission)
- `PUT /api/v1/services/:id` - Update service (requires auth + services.manage permission)
- `DELETE /api/v1/services/:id` - Delete service (requires auth + services.manage permission)
- `GET /api/v1/categories` - Get all categories

### Testing Steps:

1. **Login as Admin:**
   - Email: `admin@salon.com`
   - Password: `admin123`

2. **Test Create Service:**
   - Navigate to Services page
   - Click "+ Add Service"
   - Fill in the form:
     - Select a category
     - Enter service name
     - Set price and duration
     - (Optional) Add description, image URL, tags
   - Click "Create Service"
   - Verify service appears in the grid

3. **Test Edit Service:**
   - Click "Edit" on any service
   - Modify fields
   - Click "Update Service"
   - Verify changes are reflected

4. **Test Delete Service:**
   - Click "Delete" on any service
   - Confirm deletion
   - Verify service is removed from the list

5. **Test Search:**
   - Type in search box
   - Verify services filter in real-time

### Backend Response Format:

```json
{
  "success": true,
  "data": {
    "services": [
      {
        "id": "uuid",
        "name": "Service Name",
        "description": "Description",
        "price": 1000.00,
        "duration": 60,
        "image_url": "https://...",
        "category_id": "uuid",
        "category_name": "Category Name",
        "is_active": true,
        "tags": ["tag1", "tag2"]
      }
    ]
  }
}
```

### Error Handling:

- Network errors show toast notifications
- Validation errors display specific messages
- 401/403 errors redirect to login
- Empty states handled gracefully

### Notes:

- Services are soft-deleted (is_active = FALSE) not hard-deleted
- Only active services (is_active = TRUE) are shown in the list
- All operations require authentication and `services.manage` permission
