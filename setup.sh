#!/bin/bash
# GDELT PostgreSQL Setup Script for Linux/Mac
# This script automates the setup process

echo "========================================"
echo "GDELT PostgreSQL Database Setup"
echo "========================================"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Check if Docker is running
echo -e "${YELLOW}Checking Docker...${NC}"
if command -v docker &> /dev/null; then
    echo -e "${GREEN}✓ Docker is installed${NC}"
else
    echo -e "${RED}✗ Docker is not installed${NC}"
    echo -e "${RED}Please install Docker from https://www.docker.com/get-docker${NC}"
    exit 1
fi

# Check if docker-compose is available
echo -e "${YELLOW}Checking Docker Compose...${NC}"
if command -v docker-compose &> /dev/null; then
    echo -e "${GREEN}✓ Docker Compose is installed${NC}"
else
    echo -e "${RED}✗ Docker Compose is not installed${NC}"
    exit 1
fi

# Check if Python is installed
echo -e "${YELLOW}Checking Python...${NC}"
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    echo -e "${GREEN}✓ $PYTHON_VERSION${NC}"
else
    echo -e "${RED}✗ Python is not installed${NC}"
    echo -e "${RED}Please install Python from https://www.python.org/downloads/${NC}"
    exit 1
fi

echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}Step 1: Starting Services${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# Start docker-compose
docker-compose up -d

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Services started successfully${NC}"
    echo -e "  - PostgreSQL database"
    echo -e "  - Streamlit dashboard"
else
    echo -e "${RED}✗ Failed to start services${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}Waiting for services to be ready...${NC}"
sleep 15

# Check if containers are healthy
if docker-compose ps | grep -q "postgres"; then
    echo -e "${GREEN}✓ PostgreSQL is running${NC}"
else
    echo -e "${YELLOW}⚠ PostgreSQL might still be starting up${NC}"
fi

if docker-compose ps | grep -q "streamlit"; then
    echo -e "${GREEN}✓ Streamlit is running${NC}"
else
    echo -e "${YELLOW}⚠ Streamlit might still be starting up${NC}"
fi

echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}Step 2: Setting up Python Environment${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# Check if we need a virtual environment (for externally-managed Python)
if python3 -m pip install --help > /dev/null 2>&1; then
    # Try to install directly first
    echo -e "${YELLOW}Installing Python dependencies...${NC}"
    pip3 install -r requirements.txt 2>/dev/null
    
    if [ $? -ne 0 ]; then
        echo -e "${YELLOW}Creating virtual environment (system Python is externally managed)...${NC}"
        
        # Create virtual environment if it doesn't exist
        if [ ! -d "venv" ]; then
            python3 -m venv venv
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✓ Virtual environment created${NC}"
            else
                echo -e "${RED}✗ Failed to create virtual environment${NC}"
                echo -e "${YELLOW}You can manually install with: python3 -m venv venv && source venv/bin/activate && pip install -r requirements.txt${NC}"
                exit 1
            fi
        fi
        
        # Install in virtual environment
        echo -e "${YELLOW}Installing dependencies in virtual environment...${NC}"
        source venv/bin/activate
        pip install --upgrade pip
        pip install -r requirements.txt
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Python dependencies installed in virtual environment${NC}"
        else
            echo -e "${RED}✗ Failed to install Python dependencies${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}✓ Python dependencies installed successfully${NC}"
    fi
else
    echo -e "${RED}✗ pip is not available${NC}"
    exit 1
fi

echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}Setup Complete!${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo ""
if [ -d "venv" ]; then
    echo -e "1. Activate the virtual environment:"
    echo -e "   ${GREEN}source venv/bin/activate${NC}"
    echo ""
    echo -e "2. To ingest the GDELT data, run:"
    echo -e "   ${GREEN}python3 ingest_data.py${NC}"
    echo ""
else
    echo -e "1. To ingest the GDELT data, run:"
    echo -e "   ${GREEN}python3 ingest_data.py${NC}"
    echo ""
fi
echo -e "2. Access the Streamlit Dashboard:"
echo -e "   ${GREEN}http://localhost:8501${NC}"
echo ""
echo -e "3. To run example queries, run:"
echo -e "   ${GREEN}python3 query_examples.py${NC}"
echo ""
echo -e "4. To access the database directly:"
echo -e "   ${GREEN}docker exec -it gdelt_postgres psql -U gdelt_user -d gdelt_db${NC}"
echo ""
echo -e "5. To stop all services:"
echo -e "   ${GREEN}docker-compose down${NC}"
echo ""
echo -e "${YELLOW}Connection Details:${NC}"
echo ""
echo -e "${CYAN}  Streamlit Dashboard:${NC}"
echo "    URL: http://localhost:8501"
echo ""
echo -e "${CYAN}  PostgreSQL Database:${NC}"
echo "    Host: localhost"
echo "    Port: 5432"
echo "    Database: gdelt_db"
echo "    Username: gdelt_user"
echo "    Password: gdelt_password"
echo ""
if [ -d "venv" ]; then
    echo -e "${YELLOW}Note: Virtual environment created. Activate it before running Python scripts:${NC}"
    echo -e "${GREEN}source venv/bin/activate${NC}"
    echo ""
fi

