# Updating Streamlit Dashboard

## 🎯 What Changed

The Streamlit dashboard now displays **full country names** instead of 2-character FIPS codes in the dropdown menu, making it more user-friendly.

### Before:
- Dropdown showed: `AF`, `SY`, `MA`, etc.

### After:
- Dropdown shows: `Afghanistan`, `Syria`, `Madagascar`, etc.
- The country code is still shown in the header: `Analysis for Afghanistan (AF)`

## 🔄 How to Apply Changes

Since the Streamlit app runs in a Docker container, you need to rebuild it:

### Option 1: Rebuild Streamlit Container (Recommended)

```bash
# Rebuild and restart just the Streamlit container
docker-compose up -d --build streamlit
```

This will:
- ✅ Build a new image with the updated code
- ✅ Include the new `country_codes.py` mapping file
- ✅ Restart the Streamlit container
- ✅ Keep PostgreSQL running (no data loss)

### Option 2: Rebuild Everything

```bash
# Stop all services
docker-compose down

# Rebuild and start all services
docker-compose up -d --build
```

### Option 3: Quick Test (Without Docker)

If you want to test locally first:

```bash
# Make sure virtual environment is active
source venv/bin/activate

# Install Streamlit requirements
pip install -r requirements-streamlit.txt

# Run Streamlit locally
streamlit run streamlit_app.py
```

Then open http://localhost:8501

## ✅ Verify Changes

After rebuilding:

1. **Open the dashboard**: http://localhost:8501

2. **Check the sidebar**: The country dropdown should now show full names like:
   - Afghanistan
   - Albania  
   - Algeria
   - etc.

3. **Select a country**: The header will show both the name and code:
   - `📊 Analysis for Afghanistan (AF)`

4. **Verify functionality**: All queries and visualizations should work exactly as before

## 📝 What Was Modified

### New Files:
- `country_codes.py` - Complete FIPS code to country name mapping (240+ countries)

### Modified Files:
- `streamlit_app.py` - Updated to use country names in UI
- `Dockerfile.streamlit` - Added country_codes.py to image
- `.dockerignore` - Ensured country_codes.py is included

## 🗺️ Country Code Mapping

The mapping includes all FIPS country codes:
- **AF** → Afghanistan
- **SY** → Syria
- **MA** → Madagascar
- **BM** → Burma (Myanmar)
- **UV** → Burkina Faso
- And 200+ more...

## 🔍 Behind the Scenes

The dropdown displays country names, but the database queries still use the original 2-character codes. This means:
- ✅ No database changes needed
- ✅ All existing data works as-is
- ✅ Queries remain fast (using indexed codes)
- ✅ UI is now more user-friendly

## 🐛 Troubleshooting

### Container won't rebuild
```bash
# Force rebuild without cache
docker-compose build --no-cache streamlit
docker-compose up -d streamlit
```

### Changes not showing up
```bash
# Check if container is using new image
docker-compose ps

# View Streamlit logs
docker-compose logs streamlit

# Hard restart
docker-compose restart streamlit
```

### Import error for country_codes
```bash
# Verify file is in container
docker exec gdelt_streamlit ls -la /app/

# Should see both files:
# - streamlit_app.py
# - country_codes.py
```

## 🎉 Done!

Your Streamlit dashboard now has a much more user-friendly interface with full country names while maintaining all the performance benefits of indexed code-based queries!

