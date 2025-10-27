# Quick Start Guide

## 🚀 One-Line Setup

### Windows PowerShell
```powershell
.\setup.ps1
```

### Linux/Mac
```bash
chmod +x setup.sh
./setup.sh
```

## 📝 Manual Setup (3 Steps)

### 1. Start All Services (PostgreSQL + Streamlit)
```bash
docker-compose up -d
```

This starts:
- PostgreSQL database on port 5432
- Streamlit dashboard on port 8501

### 2. Install Python Dependencies (for ingestion)
```bash
pip install -r requirements.txt
```

### 3. Ingest Data
```bash
python ingest_data.py
```

### 4. Access Dashboard
Open your browser to: **http://localhost:8501**

## ✅ Verify Setup

### Check Services are Running
```bash
docker-compose ps
```

You should see both `postgres` and `streamlit` running.

### Access the Dashboard
Open: **http://localhost:8501**

### Run Example Queries (Optional)
```bash
python query_examples.py
```

### Access Database Shell (Optional)
```bash
docker exec -it gdelt_postgres psql -U gdelt_user -d gdelt_db
```

## 🔌 Connection Info

### Streamlit Dashboard
- **URL**: http://localhost:8501

### PostgreSQL Database
- **Host**: localhost
- **Port**: 5432
- **Database**: gdelt_db
- **Username**: gdelt_user
- **Password**: gdelt_password

## 📊 Sample Query

```sql
SELECT 
    actiongeocountrycode,
    COUNT(*) as event_count
FROM gdelt_events
GROUP BY actiongeocountrycode
ORDER BY event_count DESC
LIMIT 10;
```

## 🛑 Stop Database

```bash
docker-compose down
```

## 📚 Full Documentation

See [README.md](README.md) for complete documentation.

