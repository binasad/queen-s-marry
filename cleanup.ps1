# Memory Cleanup Script for Salon App Project
# Run this script to free up disk space on C drive

Write-Host "🧹 Starting Cleanup Process..." -ForegroundColor Cyan
Write-Host ""

# Flutter Cleanup
Write-Host "📱 Cleaning Flutter App..." -ForegroundColor Green
if (Test-Path "salon-app") {
    Set-Location salon-app
    flutter clean
    Write-Host "   ✓ Flutter build artifacts cleaned" -ForegroundColor Yellow
    Set-Location ..
} else {
    Write-Host "   ⚠ salon-app folder not found" -ForegroundColor Red
}

Write-Host ""

# Backend Cleanup
Write-Host "🔧 Cleaning Backend..." -ForegroundColor Green
if (Test-Path "backend") {
    Set-Location backend
    if (Test-Path "node_modules") {
        $size = (Get-ChildItem -Path "node_modules" -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB
        Remove-Item -Recurse -Force node_modules
        Write-Host "   ✓ Removed node_modules ($([math]::Round($size, 2)) MB)" -ForegroundColor Yellow
    }
    if (Test-Path "*.log") {
        Remove-Item -Force *.log
        Write-Host "   ✓ Removed log files" -ForegroundColor Yellow
    }
    if (Test-Path "logs") {
        Remove-Item -Recurse -Force logs
        Write-Host "   ✓ Removed logs folder" -ForegroundColor Yellow
    }
    Set-Location ..
} else {
    Write-Host "   ⚠ backend folder not found" -ForegroundColor Red
}

Write-Host ""

# Admin-Web Cleanup
Write-Host "🌐 Cleaning Admin-Web..." -ForegroundColor Green
if (Test-Path "admin-web") {
    Set-Location admin-web
    if (Test-Path "node_modules") {
        $size = (Get-ChildItem -Path "node_modules" -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB
        Remove-Item -Recurse -Force node_modules
        Write-Host "   ✓ Removed node_modules ($([math]::Round($size, 2)) MB)" -ForegroundColor Yellow
    }
    if (Test-Path ".next") {
        $size = (Get-ChildItem -Path ".next" -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB
        Remove-Item -Recurse -Force .next
        Write-Host "   ✓ Removed .next build folder ($([math]::Round($size, 2)) MB)" -ForegroundColor Yellow
    }
    Set-Location ..
} else {
    Write-Host "   ⚠ admin-web folder not found" -ForegroundColor Red
}

Write-Host ""
Write-Host "✅ Cleanup Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📝 Next Steps:" -ForegroundColor Cyan
Write-Host "   1. Run 'npm install' in backend/ and admin-web/ when needed" -ForegroundColor White
Write-Host "   2. Run 'flutter pub get' in salon-app/ when needed" -ForegroundColor White
Write-Host "   3. Optional: Clean Gradle cache: Remove-Item -Recurse -Force `$env:USERPROFILE\.gradle\caches" -ForegroundColor White
Write-Host ""
