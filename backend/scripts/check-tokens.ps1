# PowerShell script to check tokens in database
# Make sure PostgreSQL is installed and psql is in your PATH

$env:PGPASSWORD = "admin123"
$dbHost = "localhost"
$dbPort = "5432"
$dbName = "salon_db"
$dbUser = "postgres"

Write-Host "Checking tokens in database..." -ForegroundColor Cyan
Write-Host ""

# Run the SQL query
psql -h $dbHost -p $dbPort -U $dbUser -d $dbName -f "check-tokens.sql"

Write-Host ""
Write-Host "Done!" -ForegroundColor Green
