#!/usr/bin/env python3
"""
Example queries for GDELT database
Demonstrates how to connect and query the PostgreSQL database
"""

import os
import psycopg2
import pandas as pd
from tabulate import tabulate

# Database configuration
DB_CONFIG = {
    'host': os.getenv('POSTGRES_HOST', 'localhost'),
    'port': os.getenv('POSTGRES_PORT', '5432'),
    'database': os.getenv('POSTGRES_DB', 'gdelt_db'),
    'user': os.getenv('POSTGRES_USER', 'gdelt_user'),
    'password': os.getenv('POSTGRES_PASSWORD', 'gdelt_password')
}


def get_connection():
    """Create database connection."""
    return psycopg2.connect(**DB_CONFIG)


def run_query(query, description):
    """Run a query and display results."""
    print(f"\n{'='*80}")
    print(f"📊 {description}")
    print(f"{'='*80}\n")
    
    try:
        conn = get_connection()
        df = pd.read_sql_query(query, conn)
        
        if len(df) == 0:
            print("No results found.")
        else:
            print(tabulate(df, headers='keys', tablefmt='psql', showindex=False))
            print(f"\nTotal rows: {len(df)}")
        
        conn.close()
    except Exception as e:
        print(f"Error: {e}")


def main():
    """Run example queries."""
    
    print("\n🔍 GDELT Database Query Examples")
    print("="*80)
    
    # Query 1: Database statistics
    run_query(
        """
        SELECT 
            COUNT(*) as total_events,
            COUNT(DISTINCT source_file) as total_files,
            MIN(year) as earliest_year,
            MAX(year) as latest_year
        FROM gdelt_events;
        """,
        "Database Statistics"
    )
    
    # Query 2: Events by country
    run_query(
        """
        SELECT 
            actiongeocountrycode as country,
            COUNT(*) as event_count
        FROM gdelt_events
        WHERE actiongeocountrycode IS NOT NULL
        GROUP BY actiongeocountrycode
        ORDER BY event_count DESC
        LIMIT 10;
        """,
        "Top 10 Countries by Event Count"
    )
    
    # Query 3: Events by category
    run_query(
        """
        SELECT 
            acled_category,
            COUNT(*) as count,
            ROUND(AVG(goldsteinscale)::numeric, 2) as avg_goldstein,
            ROUND(AVG(avgtone)::numeric, 2) as avg_tone
        FROM gdelt_events
        WHERE acled_category IS NOT NULL
        GROUP BY acled_category
        ORDER BY count DESC;
        """,
        "Events by ACLED Category"
    )
    
    # Query 4: Events over time
    run_query(
        """
        SELECT 
            year,
            COUNT(*) as event_count,
            ROUND(AVG(goldsteinscale)::numeric, 2) as avg_goldstein,
            ROUND(AVG(avgtone)::numeric, 2) as avg_tone
        FROM gdelt_events
        GROUP BY year
        ORDER BY year;
        """,
        "Events by Year"
    )
    
    # Query 5: Top event types
    run_query(
        """
        SELECT 
            eventcode,
            cameocodedescription,
            COUNT(*) as count
        FROM gdelt_events
        WHERE eventcode IS NOT NULL
        GROUP BY eventcode, cameocodedescription
        ORDER BY count DESC
        LIMIT 10;
        """,
        "Top 10 Event Types (CAMEO Codes)"
    )
    
    # Query 6: Sample of recent events
    run_query(
        """
        SELECT 
            sqldate,
            actor1name,
            actor2name,
            cameocodedescription,
            actiongeocountrycode as location,
            ROUND(goldsteinscale::numeric, 2) as goldstein,
            ROUND(avgtone::numeric, 2) as tone
        FROM gdelt_events
        ORDER BY sqldate DESC
        LIMIT 10;
        """,
        "Sample of Recent Events"
    )
    
    print("\n" + "="*80)
    print("✅ Query examples completed!")
    print("="*80 + "\n")


if __name__ == "__main__":
    main()

