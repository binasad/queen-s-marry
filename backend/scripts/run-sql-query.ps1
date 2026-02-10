# PowerShell script to run SQL queries in psql
# Usage: .\run-sql-query.ps1 -SqlFile "scripts\check-all-roles.sql"

param(
    [Parameter(Mandatory=$true)]
    [string]$SqlFile,
    
    [string]$Host = "localhost",
    [int]$Port = 5432,
    [string]$User = "postgres",
    [string]$Database = "salon_db"
)

$sqlPath = Join-Path $PSScriptRoot $SqlFile

if (-not (Test-Path $sqlPath)) {
    Write-Host "Error: SQL file not found: $sqlPath" -ForegroundColor Red
    exit 1
}

Write-Host "Running SQL file: $SqlFile" -ForegroundColor Green
Write-Host "Database: $Database on $Host`:$Port" -ForegroundColor Cyan

# Run psql with the SQL file
psql -h $Host -p $Port -U $User -d $Database -f $sqlPath
