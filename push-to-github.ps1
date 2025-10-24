# PowerShell Script to Push Code to GitHub
# Repository: https://github.com/sweber-dwan/inw_alerts_docker

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Push to GitHub Repository" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$repoUrl = "https://github.com/sweber-dwan/inw_alerts_docker.git"

# Step 1: Check if git is initialized
Write-Host "Step 1: Checking Git repository..." -ForegroundColor Yellow
if (Test-Path ".git") {
    Write-Host "✓ Git repository already initialized" -ForegroundColor Green
} else {
    Write-Host "Initializing Git repository..." -ForegroundColor Yellow
    git init
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Git repository initialized" -ForegroundColor Green
    } else {
        Write-Host "✗ Failed to initialize Git repository" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""

# Step 2: Check git config
Write-Host "Step 2: Checking Git configuration..." -ForegroundColor Yellow
$userName = git config user.name
$userEmail = git config user.email

if (-not $userName) {
    Write-Host "Please enter your Git username:" -ForegroundColor Yellow
    $userName = Read-Host
    git config user.name "$userName"
}

if (-not $userEmail) {
    Write-Host "Please enter your Git email:" -ForegroundColor Yellow
    $userEmail = Read-Host
    git config user.email "$userEmail"
}

Write-Host "✓ Git user: $userName <$userEmail>" -ForegroundColor Green
Write-Host ""

# Step 3: Add remote
Write-Host "Step 3: Setting up remote repository..." -ForegroundColor Yellow
$remotes = git remote
if ($remotes -contains "origin") {
    $existingUrl = git remote get-url origin
    if ($existingUrl -eq $repoUrl) {
        Write-Host "✓ Remote 'origin' already configured correctly" -ForegroundColor Green
    } else {
        Write-Host "Remote 'origin' exists but points to different URL" -ForegroundColor Yellow
        Write-Host "  Current: $existingUrl" -ForegroundColor White
        Write-Host "  Expected: $repoUrl" -ForegroundColor White
        Write-Host "Updating remote URL..." -ForegroundColor Yellow
        git remote set-url origin $repoUrl
    }
} else {
    Write-Host "Adding remote 'origin'..." -ForegroundColor Yellow
    git remote add origin $repoUrl
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Remote added successfully" -ForegroundColor Green
    } else {
        Write-Host "✗ Failed to add remote" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""

# Step 4: Check what will be committed
Write-Host "Step 4: Preparing files..." -ForegroundColor Yellow
Write-Host "Files to be committed:" -ForegroundColor White
git add .
git status --short

Write-Host ""
Write-Host "Files that will be IGNORED (from .gitignore):" -ForegroundColor White
Write-Host "  - gdeltDataMerged/ (CSV data files)" -ForegroundColor Gray
Write-Host "  - venv/ (Python virtual environment)" -ForegroundColor Gray
Write-Host "  - .env (environment variables)" -ForegroundColor Gray
Write-Host "  - __pycache__/ (Python cache)" -ForegroundColor Gray

Write-Host ""

# Step 5: Confirm before committing
Write-Host "Ready to commit and push to GitHub" -ForegroundColor Yellow
Write-Host "Repository: $repoUrl" -ForegroundColor Cyan
Write-Host ""
$confirm = Read-Host "Continue? (y/n)"

if ($confirm -ne "y" -and $confirm -ne "Y") {
    Write-Host "Aborted by user" -ForegroundColor Yellow
    exit 0
}

Write-Host ""

# Step 6: Create commit
Write-Host "Step 5: Creating commit..." -ForegroundColor Yellow
$commitMessage = "Initial commit: GDELT PostgreSQL Docker setup with Streamlit dashboard

Features:
- PostgreSQL 15 database with GDELT schema
- Streamlit interactive dashboard
- Python data ingestion scripts
- Docker Compose orchestration
- Country code mapping for user-friendly UI
- Automated setup scripts for Windows and Linux
"

git commit -m $commitMessage
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Changes committed successfully" -ForegroundColor Green
} else {
    Write-Host "✗ Failed to commit changes" -ForegroundColor Red
    Write-Host "Note: This is normal if there are no changes to commit" -ForegroundColor Yellow
}

Write-Host ""

# Step 7: Push to GitHub
Write-Host "Step 6: Pushing to GitHub..." -ForegroundColor Yellow
Write-Host ""
Write-Host "You may be prompted for GitHub authentication:" -ForegroundColor Cyan
Write-Host "  Username: sweber-dwan" -ForegroundColor White
Write-Host "  Password: Use a Personal Access Token (not your password)" -ForegroundColor White
Write-Host ""
Write-Host "To create a token:" -ForegroundColor Cyan
Write-Host "  1. Go to: https://github.com/settings/tokens" -ForegroundColor White
Write-Host "  2. Generate new token (classic)" -ForegroundColor White
Write-Host "  3. Select 'repo' scope" -ForegroundColor White
Write-Host "  4. Copy and paste the token when prompted for password" -ForegroundColor White
Write-Host ""

git branch -M main
git push -u origin main

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Success!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Your code has been pushed to GitHub!" -ForegroundColor Green
    Write-Host ""
    Write-Host "View your repository:" -ForegroundColor Yellow
    Write-Host "  https://github.com/sweber-dwan/inw_alerts_docker" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "  1. Visit the repository and verify all files are there" -ForegroundColor White
    Write-Host "  2. Add repository topics: gdelt, postgresql, streamlit, docker" -ForegroundColor White
    Write-Host "  3. Set repository description" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "Push Failed" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Common issues:" -ForegroundColor Yellow
    Write-Host "  1. Authentication failed - Use a Personal Access Token" -ForegroundColor White
    Write-Host "  2. No write access - Verify you own the repository" -ForegroundColor White
    Write-Host "  3. Network issue - Check your internet connection" -ForegroundColor White
    Write-Host ""
    Write-Host "For help, see: PUSH_TO_GITHUB.md" -ForegroundColor Cyan
    Write-Host ""
}

