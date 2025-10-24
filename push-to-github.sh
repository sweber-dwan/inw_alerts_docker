#!/bin/bash
# Bash Script to Push Code to GitHub
# Repository: https://github.com/sweber-dwan/inw_alerts_docker

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}Push to GitHub Repository${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

REPO_URL="https://github.com/sweber-dwan/inw_alerts_docker.git"

# Step 1: Check if git is initialized
echo -e "${YELLOW}Step 1: Checking Git repository...${NC}"
if [ -d ".git" ]; then
    echo -e "${GREEN}✓ Git repository already initialized${NC}"
else
    echo -e "${YELLOW}Initializing Git repository...${NC}"
    git init
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Git repository initialized${NC}"
    else
        echo -e "${RED}✗ Failed to initialize Git repository${NC}"
        exit 1
    fi
fi

echo ""

# Step 2: Check git config
echo -e "${YELLOW}Step 2: Checking Git configuration...${NC}"
USER_NAME=$(git config user.name)
USER_EMAIL=$(git config user.email)

if [ -z "$USER_NAME" ]; then
    echo -e "${YELLOW}Please enter your Git username:${NC}"
    read USER_NAME
    git config user.name "$USER_NAME"
fi

if [ -z "$USER_EMAIL" ]; then
    echo -e "${YELLOW}Please enter your Git email:${NC}"
    read USER_EMAIL
    git config user.email "$USER_EMAIL"
fi

echo -e "${GREEN}✓ Git user: $USER_NAME <$USER_EMAIL>${NC}"
echo ""

# Step 3: Add remote
echo -e "${YELLOW}Step 3: Setting up remote repository...${NC}"
if git remote | grep -q "^origin$"; then
    EXISTING_URL=$(git remote get-url origin)
    if [ "$EXISTING_URL" == "$REPO_URL" ]; then
        echo -e "${GREEN}✓ Remote 'origin' already configured correctly${NC}"
    else
        echo -e "${YELLOW}Remote 'origin' exists but points to different URL${NC}"
        echo -e "${WHITE}  Current: $EXISTING_URL${NC}"
        echo -e "${WHITE}  Expected: $REPO_URL${NC}"
        echo -e "${YELLOW}Updating remote URL...${NC}"
        git remote set-url origin $REPO_URL
    fi
else
    echo -e "${YELLOW}Adding remote 'origin'...${NC}"
    git remote add origin $REPO_URL
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Remote added successfully${NC}"
    else
        echo -e "${RED}✗ Failed to add remote${NC}"
        exit 1
    fi
fi

echo ""

# Step 4: Check what will be committed
echo -e "${YELLOW}Step 4: Preparing files...${NC}"
echo -e "${WHITE}Files to be committed:${NC}"
git add .
git status --short

echo ""
echo -e "${WHITE}Files that will be IGNORED (from .gitignore):${NC}"
echo -e "${GRAY}  - gdeltDataMerged/ (CSV data files)${NC}"
echo -e "${GRAY}  - venv/ (Python virtual environment)${NC}"
echo -e "${GRAY}  - .env (environment variables)${NC}"
echo -e "${GRAY}  - __pycache__/ (Python cache)${NC}"

echo ""

# Step 5: Confirm before committing
echo -e "${YELLOW}Ready to commit and push to GitHub${NC}"
echo -e "${CYAN}Repository: $REPO_URL${NC}"
echo ""
read -p "Continue? (y/n): " CONFIRM

if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo -e "${YELLOW}Aborted by user${NC}"
    exit 0
fi

echo ""

# Step 6: Create commit
echo -e "${YELLOW}Step 5: Creating commit...${NC}"
COMMIT_MESSAGE="Initial commit: GDELT PostgreSQL Docker setup with Streamlit dashboard

Features:
- PostgreSQL 15 database with GDELT schema
- Streamlit interactive dashboard
- Python data ingestion scripts
- Docker Compose orchestration
- Country code mapping for user-friendly UI
- Automated setup scripts for Windows and Linux
"

git commit -m "$COMMIT_MESSAGE"
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Changes committed successfully${NC}"
else
    echo -e "${RED}✗ Failed to commit changes${NC}"
    echo -e "${YELLOW}Note: This is normal if there are no changes to commit${NC}"
fi

echo ""

# Step 7: Push to GitHub
echo -e "${YELLOW}Step 6: Pushing to GitHub...${NC}"
echo ""
echo -e "${CYAN}You may be prompted for GitHub authentication:${NC}"
echo -e "${WHITE}  Username: sweber-dwan${NC}"
echo -e "${WHITE}  Password: Use a Personal Access Token (not your password)${NC}"
echo ""
echo -e "${CYAN}To create a token:${NC}"
echo -e "${WHITE}  1. Go to: https://github.com/settings/tokens${NC}"
echo -e "${WHITE}  2. Generate new token (classic)${NC}"
echo -e "${WHITE}  3. Select 'repo' scope${NC}"
echo -e "${WHITE}  4. Copy and paste the token when prompted for password${NC}"
echo ""

git branch -M main
git push -u origin main

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}Success!${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    echo -e "${GREEN}Your code has been pushed to GitHub!${NC}"
    echo ""
    echo -e "${YELLOW}View your repository:${NC}"
    echo -e "${CYAN}  https://github.com/sweber-dwan/inw_alerts_docker${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo -e "${WHITE}  1. Visit the repository and verify all files are there${NC}"
    echo -e "${WHITE}  2. Add repository topics: gdelt, postgresql, streamlit, docker${NC}"
    echo -e "${WHITE}  3. Set repository description${NC}"
    echo ""
else
    echo ""
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}Push Failed${NC}"
    echo -e "${RED}========================================${NC}"
    echo ""
    echo -e "${YELLOW}Common issues:${NC}"
    echo -e "${WHITE}  1. Authentication failed - Use a Personal Access Token${NC}"
    echo -e "${WHITE}  2. No write access - Verify you own the repository${NC}"
    echo -e "${WHITE}  3. Network issue - Check your internet connection${NC}"
    echo ""
    echo -e "${CYAN}For help, see: PUSH_TO_GITHUB.md${NC}"
    echo ""
fi

