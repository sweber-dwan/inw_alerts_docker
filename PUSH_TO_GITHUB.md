# Push Code to GitHub Repository

## 📦 Repository Information
**Repository URL**: https://github.com/sweber-dwan/inw_alerts_docker

## 🚀 Steps to Push Your Code

### Step 1: Initialize Git Repository

```bash
# Navigate to your project directory
cd /mnt/c/Users/user/Documents/github/inw_alerts_docker

# Initialize git if not already initialized
git init

# Set your git identity (if not already set)
git config user.name "Your Name"
git config user.email "your.email@example.com"
```

### Step 2: Add Remote Repository

```bash
# Add the GitHub repository as remote
git remote add origin https://github.com/sweber-dwan/inw_alerts_docker.git

# Verify the remote was added
git remote -v
```

### Step 3: Add Files to Git

```bash
# Check current status
git status

# Add all files (respecting .gitignore)
git add .

# Verify what will be committed
git status
```

### Step 4: Create Initial Commit

```bash
# Commit your changes
git commit -m "Initial commit: GDELT PostgreSQL Docker setup with Streamlit dashboard"
```

### Step 5: Push to GitHub

```bash
# Push to main branch
git branch -M main
git push -u origin main
```

If you encounter authentication issues, you may need to use a Personal Access Token (PAT).

## 🔐 GitHub Authentication

### Option 1: Using Personal Access Token (Recommended)

1. **Generate a token**:
   - Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
   - Click "Generate new token (classic)"
   - Select scopes: `repo` (full control of private repositories)
   - Copy the token

2. **Use token when pushing**:
   ```bash
   git push -u origin main
   # Username: sweber-dwan
   # Password: [paste your token]
   ```

### Option 2: Using GitHub CLI

```bash
# Install GitHub CLI (if not installed)
# For Ubuntu/Debian:
sudo apt install gh

# Authenticate
gh auth login

# Push using gh
git push -u origin main
```

### Option 3: Configure Git Credential Manager

```bash
# For WSL2, use Git Credential Manager from Windows
git config --global credential.helper "/mnt/c/Program\ Files/Git/mingw64/bin/git-credential-manager.exe"
```

## 📋 What Will Be Pushed

Based on your `.gitignore`, these files will be pushed:
- ✅ `docker-compose.yml`
- ✅ `Dockerfile.streamlit`
- ✅ `streamlit_app.py`
- ✅ `country_codes.py`
- ✅ `ingest_data.py`
- ✅ `query_examples.py`
- ✅ `init-db/01-create-schema.sql`
- ✅ `requirements.txt`
- ✅ `requirements-streamlit.txt`
- ✅ `setup.sh`
- ✅ `setup.ps1`
- ✅ `README.md`
- ✅ `QUICK_START.md`
- ✅ All other documentation files

**Will NOT be pushed** (from `.gitignore`):
- ❌ `gdeltDataMerged/` directory (large CSV files)
- ❌ `venv/` directory (virtual environment)
- ❌ `.env` file (credentials)
- ❌ `__pycache__/` directories

## 🔍 Verify Before Pushing

Check what files will be included:

```bash
# See what will be committed
git status

# See which files are being tracked
git ls-files

# See which files are ignored
git status --ignored
```

## 🐛 Troubleshooting

### Error: "remote origin already exists"
```bash
# Remove existing remote and re-add
git remote remove origin
git remote add origin https://github.com/sweber-dwan/inw_alerts_docker.git
```

### Error: "failed to push some refs"
```bash
# If the remote has changes you don't have locally
git pull origin main --rebase
git push -u origin main
```

### Error: "Permission denied"
- Make sure you're authenticated with GitHub
- Use a Personal Access Token instead of password
- Verify you have write access to the repository

### Large files being rejected
```bash
# Check file sizes
find . -type f -size +50M

# If needed, add large files to .gitignore
echo "path/to/large/file" >> .gitignore
```

## ✅ Verify Push Success

After pushing, visit:
**https://github.com/sweber-dwan/inw_alerts_docker**

You should see:
- All your project files
- README.md displayed on the main page
- Commit history

## 📝 Recommended: Add a .gitattributes File

This ensures consistent line endings:

```bash
# Create .gitattributes
cat > .gitattributes << 'EOF'
# Auto detect text files and perform LF normalization
* text=auto

# Shell scripts should use LF
*.sh text eol=lf

# Windows scripts should use CRLF
*.ps1 text eol=crlf
*.bat text eol=crlf

# Docker files should use LF
Dockerfile* text eol=lf
docker-compose.yml text eol=lf
EOF

# Add and commit
git add .gitattributes
git commit -m "Add .gitattributes for consistent line endings"
git push
```

## 🎉 Next Steps

After pushing:

1. **Add a GitHub Actions workflow** (optional) for CI/CD
2. **Enable GitHub Pages** (optional) for documentation
3. **Add repository topics** for discoverability: `gdelt`, `postgresql`, `streamlit`, `docker`, `data-visualization`
4. **Set repository description**: "Dockerized PostgreSQL database with Streamlit dashboard for GDELT data analysis"

## 📚 Future Updates

When making changes:

```bash
# Make your changes
# ...

# Stage changes
git add .

# Commit with meaningful message
git commit -m "Add feature: XYZ"

# Push to GitHub
git push
```

