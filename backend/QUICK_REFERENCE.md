# Quick Reference: Database Setup Issues

## Current Status ✓

- ✅ npm audit fixed (nodemailer updated to 7.0.12)
- ✅ New modular backend structure created
- ⏳ PostgreSQL setup script ready for use

## What Was Wrong

You were trying to run SQL commands directly in PowerShell:
```powershell
# ❌ This doesn't work - PowerShell interprets it
CREATE DATABASE salon_db

# ✓ Correct way - Use psql or Node.js script
npm run setup:db
```

## Quick Start

### 1. Ensure PostgreSQL is Running

**Check if PostgreSQL service is running:**
```powershell
Get-Service postgresql-x64-* | Select-Object Status, DisplayName
```

**If not running, start it:**
```powershell
Start-Service postgresql-x64-15  # Adjust version number if needed
```

### 2. Update .env File

Edit `D:\Aztrosys\backend\.env`:
```env
DB_PASSWORD=your_postgres_password_here
```

### 3. Run Database Setup

```powershell
cd D:\Aztrosys\backend
npm run setup:db
```

**Expected Output:**
```
✓ Connected to admin database
✓ Database "salon_db" created successfully
✓ Connected to main database
✓ Executed X schema statements
✓ Successfully created 8 tables:
  • appointments
  • experts
  • expert_services
  • service_categories
  • services
  • users
  • audit_logs
  • settings
✨ Database setup completed successfully!
```

## Common Errors & Solutions

| Error | Cause | Solution |
|-------|-------|----------|
| `ECONNREFUSED` | PostgreSQL not running | `Start-Service postgresql-x64-15` |
| `28P01` | Wrong password | Check `DB_PASSWORD` in `.env` |
| `42P01` (relation does not exist) | Tables not created | Run `npm run setup:db` |
| `FATAL: database does not exist` | Database not created | Run `npm run setup:db` |

## Testing the Connection

After setup, verify the database:

```powershell
# Connect to the database
psql -U postgres -d salon_db -c "\dt"

# List all tables
psql -U postgres -d salon_db -c "SELECT table_name FROM information_schema.tables WHERE table_schema='public';"

# Check a specific table
psql -U postgres -d salon_db -c "SELECT * FROM service_categories LIMIT 1;"
```

## Next Steps

1. ✅ Run `npm run setup:db` to create the database
2. 🚀 Start the development server: `npm run dev`
3. 🧪 Test API endpoints at `http://localhost:5000/api/v1`
4. 📝 Check API docs in SETUP_GUIDE.md

## Useful Links

- PostgreSQL Documentation: https://www.postgresql.org/docs/
- PostgreSQL Windows Installation: https://www.postgresql.org/download/windows/
- Node.js pg package: https://www.npmjs.com/package/pg
