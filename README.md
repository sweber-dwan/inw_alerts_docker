# GDELT Data PostgreSQL Ingestion & Visualization

This project provides a dockerized PostgreSQL database setup with an interactive Streamlit dashboard for ingesting, analyzing, and visualizing GDELT (Global Database of Events, Language, and Tone) data.

## 📋 Prerequisites

- Docker and Docker Compose
- Python 3.8+ (for data ingestion script)
- GDELT CSV files in the `gdeltDataMerged/` directory

## 🚀 Quick Start

### 1. Start the Complete Stack (PostgreSQL + Streamlit Dashboard)

```bash
docker-compose up -d
```

This will:
- Create a PostgreSQL 15 container
- Initialize the database with the GDELT schema
- Create necessary indexes and views
- Mount the `gdeltDataMerged/` directory for data access
- Start the Streamlit visualization dashboard

**Access the dashboard at:** http://localhost:8501

### 2. Verify Database is Running

```bash
docker-compose ps
```

Check the health status:
```bash
docker-compose logs postgres
```

### 3. Install Python Dependencies

```bash
pip install -r requirements.txt
```

### 4. Configure Environment Variables (Optional)

The default configuration is:
- **Database**: gdelt_db
- **User**: gdelt_user
- **Password**: gdelt_password
- **Port**: 5432
- **Host**: localhost

To customize, set these environment variables before running the ingestion script:
```bash
# Windows PowerShell
$env:POSTGRES_USER="your_user"
$env:POSTGRES_PASSWORD="your_password"
$env:POSTGRES_DB="your_db"
$env:POSTGRES_HOST="localhost"
$env:POSTGRES_PORT="5432"
```

Or create a `.env` file:
```env
POSTGRES_USER=gdelt_user
POSTGRES_PASSWORD=gdelt_password
POSTGRES_DB=gdelt_db
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
DATA_DIR=./gdeltDataMerged
```

### 5. Ingest the Data

```bash
python ingest_data.py
```

The script will:
- Process all CSV files in the `gdeltDataMerged/` directory
- Insert data in batches for efficient processing
- Log progress and handle errors gracefully
- Track which file each record came from

### 6. Explore Data with the Dashboard

Once data is ingested, open your browser to:

**🌐 http://localhost:8501**

The interactive dashboard provides:
- **Timeline visualizations** - Event counts and trends over time
- **Category analysis** - Distribution of event types
- **Sentiment tracking** - Goldstein scale and tone metrics
- **Actor networks** - Key players involved in events
- **Country filtering** - Focus on specific geographic regions
- **Date range filters** - Analyze specific time periods

## 📊 Database Schema

### Main Table: `gdelt_events`

The table includes:
- **Event identifiers**: globaleventid, sqldate, year, monthyear
- **Actor information**: Two actors with country codes, names, types, religions, ethnic groups
- **Event details**: CAMEO event codes, descriptions, Goldstein scale, tone
- **Geographic data**: Latitude/longitude for both actors and action location
- **Source metadata**: URLs, dates, ACLED categories
- **Import tracking**: source_file, imported_at timestamp

### Indexes

Optimized indexes for common queries:
- `globaleventid`, `sqldate`, `year`
- `actor1countrycode`, `actor2countrycode`
- `eventcode`, `actiongeocountrycode`
- `acled_category`, `datetime_of_article`

### Views

**`gdelt_events_summary`**: Aggregated view showing event counts and average metrics grouped by:
- Year and month
- Actor countries
- Action geography
- ACLED category

## 📊 Streamlit Visualization Dashboard

### Features

The interactive Streamlit dashboard provides comprehensive data visualization capabilities:

#### 📈 Timeline View
- Daily event counts over time
- Goldstein scale trends (impact measurement)
- Average tone tracking (sentiment analysis)
- Interactive date range selection

#### 📊 Monthly Trends
- Aggregated monthly event counts
- Long-term sentiment patterns
- Comparative analysis across time periods

#### 🏷️ Category Analysis
- Event distribution by ACLED category
- Pie charts and bar graphs
- Average impact scores per category

#### 🎯 Event Types
- Top CAMEO event codes
- Event type descriptions
- Frequency analysis with sentiment coloring

#### 👥 Key Actors
- Most active actors in events
- Country-based actor analysis
- Participation frequency charts

### Using the Dashboard

1. **Start the services:**
   ```bash
   docker-compose up -d
   ```

2. **Access the dashboard:**
   - Open http://localhost:8501 in your browser

3. **Select a country:**
   - Use the sidebar dropdown to choose a country code

4. **Apply filters:**
   - Enable date range filtering for specific time periods
   - Set start and end years/months

5. **Explore visualizations:**
   - Navigate through tabs for different analysis views
   - Hover over charts for detailed information
   - Expand data tables to see raw numbers

### Dashboard Configuration

The Streamlit app connects to PostgreSQL using these environment variables:
- `POSTGRES_HOST`: postgres (internal Docker network)
- `POSTGRES_PORT`: 5432
- `POSTGRES_DB`: gdelt_db
- `POSTGRES_USER`: gdelt_user
- `POSTGRES_PASSWORD`: gdelt_password

To change the Streamlit port, set `STREAMLIT_PORT` in your environment or `.env` file:
```env
STREAMLIT_PORT=8080
```

### Performance Notes

- Data is cached for 10 minutes to improve performance
- Large date ranges may take longer to process
- Charts are rendered client-side using Plotly for interactivity

## 🔍 Accessing the Database

### Using psql (PostgreSQL CLI)

```bash
docker exec -it gdelt_postgres psql -U gdelt_user -d gdelt_db
```

### Common Queries

**Count total events:**
```sql
SELECT COUNT(*) FROM gdelt_events;
```

**Events by country:**
```sql
SELECT actiongeocountrycode, COUNT(*) as event_count
FROM gdelt_events
GROUP BY actiongeocountrycode
ORDER BY event_count DESC
LIMIT 10;
```

**Events by category:**
```sql
SELECT acled_category, COUNT(*) as count
FROM gdelt_events
GROUP BY acled_category
ORDER BY count DESC;
```

**Average tone by year:**
```sql
SELECT year, AVG(avgtone) as avg_tone, AVG(goldsteinscale) as avg_goldstein
FROM gdelt_events
GROUP BY year
ORDER BY year;
```

**Use the summary view:**
```sql
SELECT * FROM gdelt_events_summary
WHERE year = 2016
ORDER BY event_count DESC
LIMIT 20;
```

### Using Python

```python
import psycopg2
import pandas as pd

conn = psycopg2.connect(
    host='localhost',
    port=5432,
    database='gdelt_db',
    user='gdelt_user',
    password='gdelt_password'
)

# Query with pandas
df = pd.read_sql_query('SELECT * FROM gdelt_events LIMIT 1000', conn)
print(df.head())

conn.close()
```

### Using GUI Tools

Connect with tools like:
- **pgAdmin**: http://localhost:5432
- **DBeaver**
- **DataGrip**

Connection details:
- Host: `localhost`
- Port: `5432`
- Database: `gdelt_db`
- Username: `gdelt_user`
- Password: `gdelt_password`

## 🛠️ Management Commands

### Start all services (PostgreSQL + Streamlit)
```bash
docker-compose up -d
```

### Start only PostgreSQL
```bash
docker-compose up -d postgres
```

### Stop all services
```bash
docker-compose down
```

### Stop and remove all data (⚠️ destructive)
```bash
docker-compose down -v
```

### View logs
```bash
# All services
docker-compose logs -f

# PostgreSQL only
docker-compose logs -f postgres

# Streamlit only
docker-compose logs -f streamlit
```

### Rebuild Streamlit container (after code changes)
```bash
docker-compose up -d --build streamlit
```

### Backup the database
```bash
docker exec gdelt_postgres pg_dump -U gdelt_user gdelt_db > backup.sql
```

### Restore from backup
```bash
docker exec -i gdelt_postgres psql -U gdelt_user gdelt_db < backup.sql
```

### Access database shell
```bash
docker exec -it gdelt_postgres psql -U gdelt_user -d gdelt_db
```

## 📁 Project Structure

```
.
├── docker-compose.yml          # Docker Compose configuration
├── Dockerfile.streamlit        # Streamlit container definition
├── init-db/
│   └── 01-create-schema.sql   # Database schema and indexes
├── gdeltDataMerged/            # GDELT CSV data files
│   ├── AF.csv
│   ├── BM.csv
│   └── ...
├── streamlit_app.py            # Interactive visualization dashboard
├── ingest_data.py              # Python ingestion script
├── query_examples.py           # Example query scripts
├── requirements.txt            # Python dependencies (ingestion)
├── requirements-streamlit.txt  # Python dependencies (dashboard)
├── setup.ps1                   # Windows setup script
├── setup.sh                    # Linux/Mac setup script
├── QUICK_START.md              # Quick reference guide
└── README.md                   # This file
```

## 🐛 Troubleshooting

### Database won't start
Check if port 5432 is already in use:
```bash
# Windows
netstat -ano | findstr :5432
```

Change the port in `docker-compose.yml` if needed.

### Connection refused
Wait for the database to fully initialize (check with `docker-compose logs postgres`)

### Ingestion is slow
- The script processes large files in chunks
- Check system resources (memory, disk I/O)
- Consider increasing `BATCH_SIZE` in `ingest_data.py`
- Disable indexes during bulk insert, then recreate them

### Out of memory
Reduce chunk size in `ingest_data.py`:
```python
chunk_size = 5000  # Default is 10000
```

### Streamlit dashboard won't load
1. Check if the container is running:
   ```bash
   docker-compose ps streamlit
   ```

2. View Streamlit logs:
   ```bash
   docker-compose logs streamlit
   ```

3. Verify PostgreSQL is healthy:
   ```bash
   docker-compose ps postgres
   ```

4. Check if port 8501 is in use:
   ```bash
   # Windows
   netstat -ano | findstr :8501
   ```

### Streamlit shows "Connection refused"
- Wait for PostgreSQL to be fully initialized
- Check that data has been ingested (`SELECT COUNT(*) FROM gdelt_events;`)
- Verify network connectivity between containers

### Rebuild Streamlit after code changes
```bash
docker-compose up -d --build streamlit
```

## 📚 About GDELT Data

The GDELT Project monitors news media from around the world, identifying events, actors, locations, themes, emotions, and narratives. Each record represents a real-world event with rich metadata.

**Key metrics:**
- **Goldstein Scale**: Measures the theoretical impact of an event (-10 to +10)
- **Avg Tone**: Sentiment of coverage (-100 to +100)
- **CAMEO Codes**: Conflict and Mediation Event Observations event taxonomy

## 📝 License

This project setup is provided as-is for working with GDELT data. Please refer to the [GDELT Terms of Use](https://www.gdeltproject.org/about.html#termsofuse) for data usage terms.

## 🤝 Contributing

Feel free to submit issues or pull requests for improvements!

