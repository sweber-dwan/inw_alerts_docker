# Installing Python Dependencies

## 🐍 The Issue

Modern Linux distributions (including Ubuntu in WSL) use "externally-managed" Python environments. This means you cannot install packages directly with `pip` without using a virtual environment.

## ✅ Solution: Use a Virtual Environment

### Quick Fix (Current Situation)

Since your Docker services are already running, just set up the Python environment:

```bash
# Create virtual environment
python3 -m venv venv

# Activate it
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Now you can run the ingestion script
python3 ingest_data.py
```

### For Future Runs

**Option 1: Re-run the updated setup script**
```bash
./setup.sh
```
The script now automatically creates a virtual environment if needed.

**Option 2: Manual activation** (if venv already exists)
```bash
# Activate virtual environment
source venv/bin/activate

# Run your Python scripts
python3 ingest_data.py
python3 query_examples.py

# Deactivate when done
deactivate
```

---

## 🔧 Alternative: Use pipx or system packages

### Option A: Use pipx (for standalone tools)
```bash
sudo apt update
sudo apt install pipx
pipx install package-name
```

### Option B: Override system protection (NOT RECOMMENDED)
```bash
pip3 install -r requirements.txt --break-system-packages
```
⚠️ This can break your system Python installation!

---

## 🎯 Current Status

Your Docker services are running successfully! ✅
- **PostgreSQL**: localhost:5432
- **Streamlit Dashboard**: http://localhost:8501

You just need to set up the Python environment to run the ingestion script.

---

## 📝 Quick Reference

### Every time you want to use Python scripts:

```bash
# 1. Navigate to project
cd /mnt/c/Users/user/Documents/github/inw_alerts_docker

# 2. Activate virtual environment
source venv/bin/activate

# 3. Run your scripts
python3 ingest_data.py
# or
python3 query_examples.py

# 4. Deactivate when done (optional)
deactivate
```

### To check if virtual environment is active:
Your command prompt will show `(venv)` at the beginning when activated:
```bash
(venv) user@hostname:~/project$
```

---

## 🚀 Next Steps

1. **Create and activate virtual environment:**
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   ```

2. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

3. **Ingest your data:**
   ```bash
   python3 ingest_data.py
   ```

4. **Access the dashboard:**
   - Open http://localhost:8501 in your browser
   - Select a country and explore your data!

5. **When done, deactivate:**
   ```bash
   deactivate
   ```

---

## ✨ Pro Tips

- Add `source venv/bin/activate` to a shell alias for quick activation
- The virtual environment is local to your project and safe to delete
- Docker services don't need the virtual environment - they're already containerized!
- You can have multiple terminal windows, but each needs to activate the venv separately


