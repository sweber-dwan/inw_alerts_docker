# GDELT PostgreSQL Setup Script for Windows
# This script automates the setup process

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "GDELT PostgreSQL Database Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Docker is running
Write-Host "Checking Docker..." -ForegroundColor Yellow
try {
    docker --version | Out-Null
    Write-Host "✓ Docker is installed" -ForegroundColor Green
} catch {
    Write-Host "✗ Docker is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Docker Desktop from https://www.docker.com/products/docker-desktop" -ForegroundColor Red
    exit 1
}

# Check if docker-compose is available
Write-Host "Checking Docker Compose..." -ForegroundColor Yellow
try {
    docker-compose --version | Out-Null
    Write-Host "✓ Docker Compose is installed" -ForegroundColor Green
} catch {
    Write-Host "✗ Docker Compose is not installed" -ForegroundColor Red
    exit 1
}

# Check if Python is installed
Write-Host "Checking Python..." -ForegroundColor Yellow
try {
    $pythonVersion = python --version 2>&1
    Write-Host "✓ $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Python is not installed" -ForegroundColor Red
    Write-Host "Please install Python from https://www.python.org/downloads/" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Step 1: Starting Services" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Start docker-compose
docker-compose up -d

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Services started successfully" -ForegroundColor Green
    Write-Host "  - PostgreSQL database" -ForegroundColor White
    Write-Host "  - Streamlit dashboard" -ForegroundColor White
} else {
    Write-Host "✗ Failed to start services" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Waiting for services to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

# Check if containers are healthy
$postgresStatus = docker-compose ps --format json | ConvertFrom-Json | Where-Object { $_.Service -eq "postgres" }
$streamlitStatus = docker-compose ps --format json | ConvertFrom-Json | Where-Object { $_.Service -eq "streamlit" }

if ($postgresStatus) {
    Write-Host "✓ PostgreSQL is running" -ForegroundColor Green
} else {
    Write-Host "⚠ PostgreSQL might still be starting up" -ForegroundColor Yellow
}

if ($streamlitStatus) {
    Write-Host "✓ Streamlit is running" -ForegroundColor Green
} else {
    Write-Host "⚠ Streamlit might still be starting up" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Step 2: Installing Python Dependencies" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Install Python dependencies
pip install -r requirements.txt --quiet

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Python dependencies installed successfully" -ForegroundColor Green
} else {
    Write-Host "✗ Failed to install Python dependencies" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. To ingest the GDELT data, run:" -ForegroundColor White
Write-Host "   python ingest_data.py" -ForegroundColor Green
Write-Host ""
Write-Host "2. Access the Streamlit Dashboard:" -ForegroundColor White
Write-Host "   http://localhost:8501" -ForegroundColor Green
Write-Host ""
Write-Host "3. To run example queries, run:" -ForegroundColor White
Write-Host "   python query_examples.py" -ForegroundColor Green
Write-Host ""
Write-Host "4. To access the database directly:" -ForegroundColor White
Write-Host "   docker exec -it gdelt_postgres psql -U gdelt_user -d gdelt_db" -ForegroundColor Green
Write-Host ""
Write-Host "5. To stop all services:" -ForegroundColor White
Write-Host "   docker-compose down" -ForegroundColor Green
Write-Host ""
Write-Host "Connection Details:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Streamlit Dashboard:" -ForegroundColor Cyan
Write-Host "    URL: http://localhost:8501" -ForegroundColor White
Write-Host ""
Write-Host "  PostgreSQL Database:" -ForegroundColor Cyan
Write-Host "    Host: localhost" -ForegroundColor White
Write-Host "    Port: 5432" -ForegroundColor White
Write-Host "    Database: gdelt_db" -ForegroundColor White
Write-Host "    Username: gdelt_user" -ForegroundColor White
Write-Host "    Password: gdelt_password" -ForegroundColor White
Write-Host ""

