# Database Management Script
# Sử dụng: .\scripts\database.ps1 [command]

param(
    [Parameter(Position=0)]
    [ValidateSet("migrate", "update", "reset", "seed", "list", "remove", "help")]
    [string]$Command = "help"
)

$ProjectPath = Join-Path $PSScriptRoot ".."
$ProjectPath = Resolve-Path $ProjectPath

Write-Host "=== Database Management Script ===" -ForegroundColor Cyan
Write-Host "Project Path: $ProjectPath" -ForegroundColor Gray
Write-Host ""

switch ($Command) {
    "migrate" {
        Write-Host "Creating new migration..." -ForegroundColor Yellow
        $migrationName = Read-Host "Enter migration name (or press Enter for 'InitDatabase')"
        if ([string]::IsNullOrWhiteSpace($migrationName)) {
            $migrationName = "InitDatabase"
        }
        
        Push-Location $ProjectPath
        try {
            dotnet ef migrations add $migrationName --project .
            Write-Host "Migration created successfully!" -ForegroundColor Green
        }
        catch {
            Write-Host "Error creating migration: $_" -ForegroundColor Red
        }
        finally {
            Pop-Location
        }
    }
    
    "update" {
        Write-Host "Updating database (applying migrations)..." -ForegroundColor Yellow
        Write-Host "⚠️  This will NOT delete existing data" -ForegroundColor Yellow
        
        $confirm = Read-Host "Continue? (y/n)"
        if ($confirm -ne "y") {
            Write-Host "Cancelled." -ForegroundColor Red
            return
        }
        
        Push-Location $ProjectPath
        try {
            dotnet ef database update --project .
            Write-Host "Database updated successfully!" -ForegroundColor Green
        }
        catch {
            Write-Host "Error updating database: $_" -ForegroundColor Red
        }
        finally {
            Pop-Location
        }
    }
    
    "reset" {
        Write-Host "⚠️  WARNING: This will DELETE ALL DATA in the database!" -ForegroundColor Red
        Write-Host "This action cannot be undone!" -ForegroundColor Red
        
        $confirm = Read-Host "Are you sure? Type 'yes' to continue"
        if ($confirm -ne "yes") {
            Write-Host "Cancelled." -ForegroundColor Yellow
            return
        }
        
        Push-Location $ProjectPath
        try {
            Write-Host "Dropping database..." -ForegroundColor Yellow
            dotnet ef database drop --project . --force
            
            Write-Host "Creating database..." -ForegroundColor Yellow
            dotnet ef database update --project .
            
            Write-Host "Database reset successfully!" -ForegroundColor Green
            Write-Host "You can now seed data using: .\scripts\database.ps1 seed" -ForegroundColor Cyan
        }
        catch {
            Write-Host "Error resetting database: $_" -ForegroundColor Red
        }
        finally {
            Pop-Location
        }
    }
    
    "seed" {
        Write-Host "Seeding database..." -ForegroundColor Yellow
        Write-Host "This will add sample data if database is empty." -ForegroundColor Gray
        
        $force = Read-Host "Force seed (overwrite existing data)? (y/n)"
        $forceParam = if ($force -eq "y") { "?force=true" } else { "?force=false" }
        
        Write-Host ""
        Write-Host "Calling API endpoint: POST /api/admin/seed-data$forceParam" -ForegroundColor Cyan
        Write-Host "Make sure the API is running!" -ForegroundColor Yellow
        Write-Host ""
        
        $baseUrl = Read-Host "Enter API base URL (or press Enter for http://localhost:5134)"
        if ([string]::IsNullOrWhiteSpace($baseUrl)) {
            $baseUrl = "http://localhost:5134"
        }
        
        try {
            $url = "$baseUrl/api/admin/seed-data$forceParam"
            $response = Invoke-RestMethod -Uri $url -Method Post -ContentType "application/json"
            Write-Host "Seed completed successfully!" -ForegroundColor Green
            Write-Host "Response: $($response | ConvertTo-Json)" -ForegroundColor Gray
        }
        catch {
            Write-Host "Error seeding database: $_" -ForegroundColor Red
            Write-Host "Make sure the API is running and accessible." -ForegroundColor Yellow
        }
    }
    
    "list" {
        Write-Host "Listing migrations..." -ForegroundColor Yellow
        Push-Location $ProjectPath
        try {
            dotnet ef migrations list --project .
        }
        catch {
            Write-Host "Error listing migrations: $_" -ForegroundColor Red
        }
        finally {
            Pop-Location
        }
    }
    
    "remove" {
        Write-Host "Removing last migration (if not applied)..." -ForegroundColor Yellow
        Push-Location $ProjectPath
        try {
            dotnet ef migrations remove --project .
            Write-Host "Migration removed successfully!" -ForegroundColor Green
        }
        catch {
            Write-Host "Error removing migration: $_" -ForegroundColor Red
        }
        finally {
            Pop-Location
        }
    }
    
    "help" {
        Write-Host "Available commands:" -ForegroundColor Cyan
        Write-Host "  migrate  - Create a new migration" -ForegroundColor White
        Write-Host "  update   - Apply migrations to database (keeps existing data)" -ForegroundColor White
        Write-Host "  reset    - Drop and recreate database (DELETES ALL DATA)" -ForegroundColor Red
        Write-Host "  seed     - Seed sample data via API" -ForegroundColor White
        Write-Host "  list     - List all migrations" -ForegroundColor White
        Write-Host "  remove   - Remove last migration (if not applied)" -ForegroundColor White
        Write-Host "  help     - Show this help message" -ForegroundColor White
        Write-Host ""
        Write-Host "Usage: .\scripts\database.ps1 [command]" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Examples:" -ForegroundColor Cyan
        Write-Host "  .\scripts\database.ps1 migrate" -ForegroundColor Gray
        Write-Host "  .\scripts\database.ps1 update" -ForegroundColor Gray
        Write-Host "  .\scripts\database.ps1 reset" -ForegroundColor Gray
        Write-Host "  .\scripts\database.ps1 seed" -ForegroundColor Gray
    }
}

Write-Host ""

