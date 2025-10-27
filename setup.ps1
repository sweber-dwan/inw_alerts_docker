# GDELT PostgreSQL Setup Script for Windows
# This script automates the setup process

Write-Host "========================================"
Write-Host "GDELT PostgreSQL Database Setup"
Write-Host "========================================"
Write-Host ""

# Check if Docker is running
Write-Host "Checking Docker..." -ForegroundColor Yellow
try {
    docker --version | Out-Null
    Write-Host "✓ Docker is installed" -ForegroundColor Green
} catch {
    Write-Host "✗ Docker is not installed" -ForegroundColor Red
    Write-Host "Please install Docker from https://www.docker.com/get-docker" -ForegroundColor Red
    exit 1
}

# Check if docker-compose is available
Write-Host "Checking Docker Compose..." -ForegroundColor Yellow
# Check for Docker Compose v2 (docker compose) or v1 (docker-compose)
$dockerComposeV2 = docker compose version 2>&1
if ($LASTEXITCODE -eq 0) {
    $global:DOCKER_COMPOSE = "docker compose"
    Write-Host "✓ Docker Compose v2 is installed" -ForegroundColor Green
} else {
    try {
        docker-compose --version | Out-Null
        $global:DOCKER_COMPOSE = "docker-compose"
        Write-Host "✓ Docker Compose v1 is installed" -ForegroundColor Green
    } catch {
        Write-Host "✗ Docker Compose is not installed" -ForegroundColor Red
        Write-Host "Please install Docker Compose from https://docs.docker.com/compose/install/" -ForegroundColor Red
        exit 1
    }
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
Invoke-Expression "$DOCKER_COMPOSE up -d"

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Services started successfully" -ForegroundColor Green
    Write-Host "  - PostgreSQL database"
    Write-Host "  - Streamlit dashboard"
} else {
    Write-Host "✗ Failed to start services" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Waiting for services to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

# Check if containers are healthy
$containers = Invoke-Expression "$DOCKER_COMPOSE ps"
if ($containers -match "postgres") {
    Write-Host "✓ PostgreSQL is running" -ForegroundColor Green
} else {
    Write-Host "⚠ PostgreSQL might still be starting up" -ForegroundColor Yellow
}

if ($containers -match "streamlit") {
    Write-Host "✓ Streamlit is running" -ForegroundColor Green
} else {
    Write-Host "⚠ Streamlit might still be starting up" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Step 2: Setting up Python Environment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if we need a virtual environment
Write-Host "Installing Python dependencies..." -ForegroundColor Yellow

# Try to install directly first
$installResult = pip install -r requirements.txt 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Creating virtual environment..." -ForegroundColor Yellow
    
    # Create virtual environment if it doesn't exist
    if (-not (Test-Path "venv")) {
        python -m venv venv
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Virtual environment created" -ForegroundColor Green
        } else {
            Write-Host "✗ Failed to create virtual environment" -ForegroundColor Red
            Write-Host "You can manually install with: python -m venv venv && .\venv\Scripts\Activate.ps1 && pip install -r requirements.txt" -ForegroundColor Yellow
            exit 1
        }
    }
    
    # Install in virtual environment
    Write-Host "Installing dependencies in virtual environment..." -ForegroundColor Yellow
    & .\venv\Scripts\Activate.ps1
    pip install --upgrade pip
    pip install -r requirements.txt
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Python dependencies installed in virtual environment" -ForegroundColor Green
    } else {
        Write-Host "✗ Failed to install Python dependencies" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "✓ Python dependencies installed successfully" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host ""

if (Test-Path "venv") {
    Write-Host "1. Activate the virtual environment:" 
    Write-Host "   .\venv\Scripts\Activate.ps1" -ForegroundColor Green
    Write-Host ""
    Write-Host "2. To ingest the GDELT data, run:"
    Write-Host "   python ingest_data.py" -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host "1. To ingest the GDELT data, run:"
    Write-Host "   python ingest_data.py" -ForegroundColor Green
    Write-Host ""
}

Write-Host "2. Access the Streamlit Dashboard:"
Write-Host "   http://localhost:8501" -ForegroundColor Green
Write-Host ""
Write-Host "3. To run example queries, run:"
Write-Host "   python query_examples.py" -ForegroundColor Green
Write-Host ""
Write-Host "4. To access the database directly:"
Write-Host "   docker exec -it gdelt_postgres psql -U gdelt_user -d gdelt_db" -ForegroundColor Green
Write-Host ""
Write-Host "5. To stop all services:"
Write-Host "   docker compose down (or docker-compose down if using v1)" -ForegroundColor Green
Write-Host ""
Write-Host "Connection Details:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Streamlit Dashboard:" -ForegroundColor Cyan
Write-Host "    URL: http://localhost:8501"
Write-Host ""
Write-Host "  PostgreSQL Database:" -ForegroundColor Cyan
Write-Host "    Host: localhost"
Write-Host "    Port: 5432"
Write-Host "    Database: gdelt_db"
Write-Host "    Username: gdelt_user"
Write-Host "    Password: gdelt_password"
Write-Host ""

if (Test-Path "venv") {
    Write-Host "Note: Virtual environment created. Activate it before running Python scripts:" -ForegroundColor Yellow
    Write-Host ".\venv\Scripts\Activate.ps1" -ForegroundColor Green
    Write-Host ""
}
