# Quick Start: Import Services

## Problem
Services page at `http://localhost:3001/services` shows "No services found" because the hardcoded services from salon-app haven't been imported yet.

## Solution: Import Services

### Step 1: Access Import Page
1. Go to `http://localhost:3001/services`
2. Click the green **"📥 Import Services"** button
3. Or navigate directly to: `http://localhost:3001/services/import`

### Step 2: Map Categories
The import page will show all service categories that need to be mapped:
- Hair Services
- Makeup Services  
- Facial Services
- Massage Services
- Mehndi Services
- Waxing Services
- PhotoShoot Services

**If you see "No categories found":**
- You need to create categories first
- Go back to Services page
- Use "+ Add Service" to create a service (this will require a category)
- Or create categories directly in the database

### Step 3: Import
1. Select a database category for each service category from the dropdown
2. Click **"Import 74 Services"** button
3. Wait for the progress bar to complete
4. You'll be redirected to Services page where all services will appear

## Alternative: Create Categories First

If categories don't exist, you can create them via SQL or through the admin interface:

```sql
-- Example categories (adjust as needed)
INSERT INTO service_categories (name, description, is_active) VALUES
('Hair Services', 'Hair cutting, coloring, and treatment services', true),
('Makeup Services', 'Makeup and bridal services', true),
('Facial Services', 'Facial and skin treatment services', true),
('Massage Services', 'Body and relaxation massage services', true),
('Mehndi Services', 'Henna and mehndi application services', true),
('Waxing Services', 'Hair removal and waxing services', true),
('PhotoShoot Services', 'Photography and photoshoot services', true);
```

## Troubleshooting

### Services still not showing after import
1. Check browser console for errors
2. Verify backend API is running on port 5000
3. Check network tab to see API responses
4. Ensure you're logged in as admin (`admin@salon.com` / `admin123`)

### Import fails
1. Check that all categories are mapped
2. Verify backend is running and accessible
3. Check browser console for detailed error messages
4. Ensure database connection is working

### Categories not loading
1. Verify backend API endpoint: `GET /api/v1/categories`
2. Check database has `service_categories` table
3. Ensure at least one category exists in database
