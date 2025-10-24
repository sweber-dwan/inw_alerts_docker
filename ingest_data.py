#!/usr/bin/env python3
"""
GDELT Data Ingestion Script
This script reads CSV files from the gdeltDataMerged directory and loads them into PostgreSQL.
"""

import os
import sys
import glob
import pandas as pd
import psycopg2
from psycopg2.extras import execute_batch
from datetime import datetime
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Database configuration
DB_CONFIG = {
    'host': os.getenv('POSTGRES_HOST', 'localhost'),
    'port': os.getenv('POSTGRES_PORT', '5432'),
    'database': os.getenv('POSTGRES_DB', 'gdelt_db'),
    'user': os.getenv('POSTGRES_USER', 'gdelt_user'),
    'password': os.getenv('POSTGRES_PASSWORD', 'gdelt_password')
}

# CSV data directory
DATA_DIR = os.getenv('DATA_DIR', './gdeltDataMerged')

# Batch size for inserts
BATCH_SIZE = 1000


def get_db_connection():
    """Create and return a database connection."""
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        logger.info("Successfully connected to PostgreSQL database")
        return conn
    except psycopg2.Error as e:
        logger.error(f"Unable to connect to database: {e}")
        sys.exit(1)


def parse_datetime(dt_str):
    """Parse datetime string, return None if invalid."""
    if pd.isna(dt_str) or dt_str == '':
        return None
    try:
        return pd.to_datetime(dt_str)
    except:
        return None


def clean_value(val):
    """Clean and prepare value for database insertion."""
    if pd.isna(val) or val == '':
        return None
    return val


def ingest_csv_file(conn, csv_path):
    """Ingest a single CSV file into the database."""
    filename = os.path.basename(csv_path)
    logger.info(f"Processing file: {filename}")
    
    try:
        # Read CSV file in chunks to handle large files
        chunk_size = 10000
        total_rows = 0
        
        for chunk_num, chunk in enumerate(pd.read_csv(csv_path, chunksize=chunk_size, low_memory=False), 1):
            logger.info(f"Processing chunk {chunk_num} ({len(chunk)} rows)")
            
            # Prepare data for insertion
            records = []
            for _, row in chunk.iterrows():
                record = (
                    clean_value(row.get('index')),
                    clean_value(row.get('globaleventid')),
                    clean_value(row.get('sqldate')),
                    clean_value(row.get('monthyear')),
                    clean_value(row.get('year')),
                    clean_value(row.get('fractiondate')),
                    # Actor 1
                    clean_value(row.get('actor1code')),
                    clean_value(row.get('actor1name')),
                    clean_value(row.get('actor1countrycode')),
                    clean_value(row.get('actor1knowngroupcode')),
                    clean_value(row.get('actor1ethniccode')),
                    clean_value(row.get('actor1religion1code')),
                    clean_value(row.get('actor1religion2code')),
                    clean_value(row.get('actor1type1code')),
                    clean_value(row.get('actor1type2code')),
                    clean_value(row.get('actor1type3code')),
                    # Actor 2
                    clean_value(row.get('actor2code')),
                    clean_value(row.get('actor2name')),
                    clean_value(row.get('actor2countrycode')),
                    clean_value(row.get('actor2knowngroupcode')),
                    clean_value(row.get('actor2ethniccode')),
                    clean_value(row.get('actor2religion1code')),
                    clean_value(row.get('actor2religion2code')),
                    clean_value(row.get('actor2type1code')),
                    clean_value(row.get('actor2type2code')),
                    clean_value(row.get('actor2type3code')),
                    # Event
                    clean_value(row.get('isrootevent')),
                    clean_value(row.get('eventcode')),
                    clean_value(row.get('cameocodedescription')),
                    clean_value(row.get('eventbasecode')),
                    clean_value(row.get('eventrootcode')),
                    clean_value(row.get('quadclass')),
                    clean_value(row.get('goldsteinscale')),
                    clean_value(row.get('nummentions')),
                    clean_value(row.get('numsources')),
                    clean_value(row.get('numarticles')),
                    clean_value(row.get('avgtone')),
                    # Actor 1 geo
                    clean_value(row.get('actor1geotype')),
                    clean_value(row.get('actor1geofullname')),
                    clean_value(row.get('actor1geocountrycode')),
                    clean_value(row.get('actor1geoadm1code')),
                    clean_value(row.get('actor1geoadm2code')),
                    clean_value(row.get('actor1geolat')),
                    clean_value(row.get('actor1geolong')),
                    clean_value(row.get('actor1geofeatureid')),
                    # Actor 2 geo
                    clean_value(row.get('actor2geotype')),
                    clean_value(row.get('actor2geofullname')),
                    clean_value(row.get('actor2geocountrycode')),
                    clean_value(row.get('actor2geoadm1code')),
                    clean_value(row.get('actor2geoadm2code')),
                    clean_value(row.get('actor2geolat')),
                    clean_value(row.get('actor2geolong')),
                    clean_value(row.get('actor2geofeatureid')),
                    # Action geo
                    clean_value(row.get('actiongeotype')),
                    clean_value(row.get('actiongeofullname')),
                    clean_value(row.get('actiongeocountrycode')),
                    clean_value(row.get('actiongeoadm1code')),
                    clean_value(row.get('actiongeoadm2code')),
                    clean_value(row.get('actiongeolat')),
                    clean_value(row.get('actiongeolong')),
                    clean_value(row.get('actiongeofeatureid')),
                    # Source
                    clean_value(row.get('dateadded')),
                    clean_value(row.get('sourceurl')),
                    parse_datetime(row.get('datetime_of_article')),
                    clean_value(row.get('acled_category')),
                    # Metadata
                    filename
                )
                records.append(record)
            
            # Insert batch into database
            cursor = conn.cursor()
            insert_query = """
                INSERT INTO gdelt_events (
                    csv_index, globaleventid, sqldate, monthyear, year, fractiondate,
                    actor1code, actor1name, actor1countrycode, actor1knowngroupcode,
                    actor1ethniccode, actor1religion1code, actor1religion2code,
                    actor1type1code, actor1type2code, actor1type3code,
                    actor2code, actor2name, actor2countrycode, actor2knowngroupcode,
                    actor2ethniccode, actor2religion1code, actor2religion2code,
                    actor2type1code, actor2type2code, actor2type3code,
                    isrootevent, eventcode, cameocodedescription, eventbasecode,
                    eventrootcode, quadclass, goldsteinscale, nummentions,
                    numsources, numarticles, avgtone,
                    actor1geotype, actor1geofullname, actor1geocountrycode,
                    actor1geoadm1code, actor1geoadm2code, actor1geolat,
                    actor1geolong, actor1geofeatureid,
                    actor2geotype, actor2geofullname, actor2geocountrycode,
                    actor2geoadm1code, actor2geoadm2code, actor2geolat,
                    actor2geolong, actor2geofeatureid,
                    actiongeotype, actiongeofullname, actiongeocountrycode,
                    actiongeoadm1code, actiongeoadm2code, actiongeolat,
                    actiongeolong, actiongeofeatureid,
                    dateadded, sourceurl, datetime_of_article, acled_category,
                    source_file
                ) VALUES (
                    %s, %s, %s, %s, %s, %s, %s, %s, %s, %s,
                    %s, %s, %s, %s, %s, %s, %s, %s, %s, %s,
                    %s, %s, %s, %s, %s, %s, %s, %s, %s, %s,
                    %s, %s, %s, %s, %s, %s, %s, %s, %s, %s,
                    %s, %s, %s, %s, %s, %s, %s, %s, %s, %s,
                    %s, %s, %s, %s, %s, %s, %s, %s, %s, %s,
                    %s, %s, %s, %s, %s, %s
                )
            """
            
            execute_batch(cursor, insert_query, records, page_size=BATCH_SIZE)
            conn.commit()
            cursor.close()
            
            total_rows += len(records)
            logger.info(f"Inserted {len(records)} rows (total: {total_rows})")
        
        logger.info(f"Successfully ingested {filename}: {total_rows} total rows")
        return total_rows
        
    except Exception as e:
        logger.error(f"Error processing {filename}: {e}")
        conn.rollback()
        raise


def main():
    """Main function to orchestrate the data ingestion."""
    logger.info("Starting GDELT data ingestion")
    logger.info(f"Data directory: {DATA_DIR}")
    logger.info(f"Database: {DB_CONFIG['host']}:{DB_CONFIG['port']}/{DB_CONFIG['database']}")
    
    # Find all CSV files
    csv_files = glob.glob(os.path.join(DATA_DIR, "*.csv"))
    
    if not csv_files:
        logger.error(f"No CSV files found in {DATA_DIR}")
        sys.exit(1)
    
    logger.info(f"Found {len(csv_files)} CSV files to process")
    
    # Connect to database
    conn = get_db_connection()
    
    try:
        total_ingested = 0
        for csv_file in sorted(csv_files):
            rows = ingest_csv_file(conn, csv_file)
            total_ingested += rows
        
        logger.info(f"Data ingestion complete! Total rows ingested: {total_ingested}")
        
    except Exception as e:
        logger.error(f"Data ingestion failed: {e}")
        sys.exit(1)
    finally:
        conn.close()
        logger.info("Database connection closed")


if __name__ == "__main__":
    main()

