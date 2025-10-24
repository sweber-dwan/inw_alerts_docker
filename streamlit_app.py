#!/usr/bin/env python3
"""
GDELT Data Visualization Dashboard
Interactive Streamlit app for exploring GDELT events data
"""

import os
import streamlit as st
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from plotly.subplots import make_subplots
import psycopg2
from datetime import datetime
from country_codes import get_country_name, get_country_code, COUNTRY_CODES

# Page configuration
st.set_page_config(
    page_title="GDELT Data Explorer",
    page_icon="🌍",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Database configuration
DB_CONFIG = {
    'host': os.getenv('POSTGRES_HOST', 'postgres'),
    'port': os.getenv('POSTGRES_PORT', '5432'),
    'database': os.getenv('POSTGRES_DB', 'gdelt_db'),
    'user': os.getenv('POSTGRES_USER', 'gdelt_user'),
    'password': os.getenv('POSTGRES_PASSWORD', 'gdelt_password')
}


@st.cache_resource
def get_db_connection():
    """Create and cache database connection."""
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        return conn
    except Exception as e:
        st.error(f"Database connection failed: {e}")
        return None


@st.cache_data(ttl=600)
def get_countries():
    """Get list of unique countries from the database with full names."""
    conn = get_db_connection()
    if not conn:
        return []
    
    query = """
        SELECT DISTINCT actiongeocountrycode 
        FROM gdelt_events 
        WHERE actiongeocountrycode IS NOT NULL
        ORDER BY actiongeocountrycode
    """
    df = pd.read_sql_query(query, conn)
    
    # Map codes to country names
    country_codes = df['actiongeocountrycode'].tolist()
    country_names = [get_country_name(code) for code in country_codes]
    
    # Return list of tuples: (country_name, country_code)
    countries = list(zip(country_names, country_codes))
    # Sort by country name
    countries.sort(key=lambda x: x[0])
    
    return countries


@st.cache_data(ttl=600)
def get_country_stats(country):
    """Get overall statistics for a country."""
    conn = get_db_connection()
    if not conn:
        return None
    
    query = """
        SELECT 
            COUNT(*) as total_events,
            MIN(sqldate) as first_event,
            MAX(sqldate) as last_event,
            ROUND(AVG(goldsteinscale)::numeric, 2) as avg_goldstein,
            ROUND(AVG(avgtone)::numeric, 2) as avg_tone,
            COUNT(DISTINCT acled_category) as num_categories
        FROM gdelt_events
        WHERE actiongeocountrycode = %s
    """
    df = pd.read_sql_query(query, conn, params=(country,))
    return df.iloc[0] if len(df) > 0 else None


@st.cache_data(ttl=600)
def get_events_timeline(country, start_date=None, end_date=None):
    """Get events timeline data for a country."""
    conn = get_db_connection()
    if not conn:
        return pd.DataFrame()
    
    query = """
        SELECT 
            sqldate,
            COUNT(*) as event_count,
            ROUND(AVG(goldsteinscale)::numeric, 2) as avg_goldstein,
            ROUND(AVG(avgtone)::numeric, 2) as avg_tone
        FROM gdelt_events
        WHERE actiongeocountrycode = %s
    """
    params = [country]
    
    if start_date and end_date:
        query += " AND sqldate >= %s AND sqldate <= %s"
        params.extend([start_date, end_date])
    
    query += """
        GROUP BY sqldate
        ORDER BY sqldate
    """
    
    df = pd.read_sql_query(query, conn, params=tuple(params))
    if len(df) > 0:
        df['date'] = pd.to_datetime(df['sqldate'].astype(str), format='%Y%m%d')
    return df


@st.cache_data(ttl=600)
def get_events_by_category(country, start_date=None, end_date=None):
    """Get events grouped by category."""
    conn = get_db_connection()
    if not conn:
        return pd.DataFrame()
    
    query = """
        SELECT 
            acled_category,
            COUNT(*) as event_count,
            ROUND(AVG(goldsteinscale)::numeric, 2) as avg_goldstein,
            ROUND(AVG(avgtone)::numeric, 2) as avg_tone
        FROM gdelt_events
        WHERE actiongeocountrycode = %s
        AND acled_category IS NOT NULL
    """
    params = [country]
    
    if start_date and end_date:
        query += " AND sqldate >= %s AND sqldate <= %s"
        params.extend([start_date, end_date])
    
    query += """
        GROUP BY acled_category
        ORDER BY event_count DESC
    """
    
    df = pd.read_sql_query(query, conn, params=tuple(params))
    return df


@st.cache_data(ttl=600)
def get_monthly_trends(country):
    """Get monthly aggregated trends."""
    conn = get_db_connection()
    if not conn:
        return pd.DataFrame()
    
    query = """
        SELECT 
            year,
            monthyear,
            COUNT(*) as event_count,
            ROUND(AVG(goldsteinscale)::numeric, 2) as avg_goldstein,
            ROUND(AVG(avgtone)::numeric, 2) as avg_tone
        FROM gdelt_events
        WHERE actiongeocountrycode = %s
        GROUP BY year, monthyear
        ORDER BY monthyear
    """
    
    df = pd.read_sql_query(query, conn, params=(country,))
    if len(df) > 0:
        df['month_date'] = pd.to_datetime(df['monthyear'].astype(str), format='%Y%m')
    return df


@st.cache_data(ttl=600)
def get_top_event_types(country, limit=10):
    """Get top event types for a country."""
    conn = get_db_connection()
    if not conn:
        return pd.DataFrame()
    
    query = """
        SELECT 
            eventcode,
            cameocodedescription,
            COUNT(*) as event_count,
            ROUND(AVG(goldsteinscale)::numeric, 2) as avg_goldstein
        FROM gdelt_events
        WHERE actiongeocountrycode = %s
        AND eventcode IS NOT NULL
        GROUP BY eventcode, cameocodedescription
        ORDER BY event_count DESC
        LIMIT %s
    """
    
    df = pd.read_sql_query(query, conn, params=(country, limit))
    return df


@st.cache_data(ttl=600)
def get_actor_networks(country, limit=15):
    """Get most common actors involved in events."""
    conn = get_db_connection()
    if not conn:
        return pd.DataFrame()
    
    query = """
        SELECT 
            actor1name as actor,
            actor1countrycode as country_code,
            COUNT(*) as event_count
        FROM gdelt_events
        WHERE actiongeocountrycode = %s
        AND actor1name IS NOT NULL
        AND actor1name != ''
        GROUP BY actor1name, actor1countrycode
        ORDER BY event_count DESC
        LIMIT %s
    """
    
    df = pd.read_sql_query(query, conn, params=(country, limit))
    return df


def plot_timeline(df):
    """Create an interactive timeline plot."""
    if df.empty:
        st.warning("No data available for the selected period.")
        return
    
    fig = make_subplots(
        rows=2, cols=1,
        subplot_titles=('Daily Event Count', 'Average Sentiment Indicators'),
        vertical_spacing=0.15,
        row_heights=[0.5, 0.5]
    )
    
    # Event count timeline
    fig.add_trace(
        go.Scatter(
            x=df['date'],
            y=df['event_count'],
            mode='lines+markers',
            name='Event Count',
            line=dict(color='#1f77b4', width=2),
            marker=dict(size=4)
        ),
        row=1, col=1
    )
    
    # Goldstein scale
    fig.add_trace(
        go.Scatter(
            x=df['date'],
            y=df['avg_goldstein'],
            mode='lines',
            name='Goldstein Scale',
            line=dict(color='#ff7f0e', width=2)
        ),
        row=2, col=1
    )
    
    # Average tone
    fig.add_trace(
        go.Scatter(
            x=df['date'],
            y=df['avg_tone'],
            mode='lines',
            name='Average Tone',
            line=dict(color='#2ca02c', width=2)
        ),
        row=2, col=1
    )
    
    fig.update_xaxes(title_text="Date", row=2, col=1)
    fig.update_yaxes(title_text="Count", row=1, col=1)
    fig.update_yaxes(title_text="Score", row=2, col=1)
    
    fig.update_layout(
        height=700,
        showlegend=True,
        hovermode='x unified',
        template='plotly_white'
    )
    
    st.plotly_chart(fig, use_container_width=True)


def plot_monthly_trends(df):
    """Create monthly trends visualization."""
    if df.empty:
        st.warning("No monthly data available.")
        return
    
    fig = go.Figure()
    
    fig.add_trace(go.Bar(
        x=df['month_date'],
        y=df['event_count'],
        name='Event Count',
        marker_color='#1f77b4'
    ))
    
    fig.update_layout(
        title='Monthly Event Count',
        xaxis_title='Month',
        yaxis_title='Number of Events',
        height=400,
        template='plotly_white'
    )
    
    st.plotly_chart(fig, use_container_width=True)


def plot_category_distribution(df):
    """Create category distribution charts."""
    if df.empty:
        st.warning("No category data available.")
        return
    
    col1, col2 = st.columns(2)
    
    with col1:
        # Pie chart
        fig = px.pie(
            df,
            values='event_count',
            names='acled_category',
            title='Event Distribution by Category'
        )
        fig.update_traces(textposition='inside', textinfo='percent+label')
        st.plotly_chart(fig, use_container_width=True)
    
    with col2:
        # Bar chart
        fig = px.bar(
            df,
            x='event_count',
            y='acled_category',
            orientation='h',
            title='Event Count by Category',
            color='avg_goldstein',
            color_continuous_scale='RdYlGn'
        )
        fig.update_layout(yaxis={'categoryorder': 'total ascending'})
        st.plotly_chart(fig, use_container_width=True)


def plot_event_types(df):
    """Plot top event types."""
    if df.empty:
        st.warning("No event type data available.")
        return
    
    fig = px.bar(
        df,
        x='event_count',
        y='cameocodedescription',
        orientation='h',
        title='Top Event Types (CAMEO Codes)',
        color='avg_goldstein',
        color_continuous_scale='RdYlGn',
        hover_data=['eventcode']
    )
    fig.update_layout(
        yaxis={'categoryorder': 'total ascending'},
        height=500
    )
    st.plotly_chart(fig, use_container_width=True)


def main():
    """Main application."""
    
    # Header
    st.title("🌍 GDELT Data Explorer")
    st.markdown("Interactive visualization of global events, language, and tone data")
    
    # Sidebar
    st.sidebar.header("🔧 Configuration")
    
    # Country selection
    countries = get_countries()
    if not countries:
        st.error("Unable to load countries. Please check database connection.")
        return
    
    # Get country names for dropdown
    country_names = [name for name, code in countries]
    country_dict = {name: code for name, code in countries}
    
    # Find default index (Afghanistan if available)
    default_country = "Afghanistan"
    default_index = country_names.index(default_country) if default_country in country_names else 0
    
    selected_country_name = st.sidebar.selectbox(
        "Select Country",
        country_names,
        index=default_index
    )
    
    # Convert selected country name back to code for database queries
    selected_country = country_dict[selected_country_name]
    
    # Date range selection
    st.sidebar.subheader("📅 Date Range Filter")
    use_date_filter = st.sidebar.checkbox("Enable date filter", value=False)
    
    start_date = None
    end_date = None
    
    if use_date_filter:
        col1, col2 = st.sidebar.columns(2)
        with col1:
            start_year = st.number_input("Start Year", min_value=2000, max_value=2025, value=2016)
            start_month = st.number_input("Start Month", min_value=1, max_value=12, value=1)
        with col2:
            end_year = st.number_input("End Year", min_value=2000, max_value=2025, value=2016)
            end_month = st.number_input("End Month", min_value=1, max_value=12, value=12)
        
        start_date = int(f"{start_year}{start_month:02d}01")
        end_date = int(f"{end_year}{end_month:02d}31")
    
    # Main content
    st.header(f"📊 Analysis for {selected_country_name} ({selected_country})")
    
    # Country statistics
    stats = get_country_stats(selected_country)
    if stats is not None:
        col1, col2, col3, col4, col5 = st.columns(5)
        
        with col1:
            st.metric("Total Events", f"{stats['total_events']:,}")
        with col2:
            st.metric("First Event", str(stats['first_event']))
        with col3:
            st.metric("Last Event", str(stats['last_event']))
        with col4:
            st.metric("Avg Goldstein Scale", stats['avg_goldstein'])
        with col5:
            st.metric("Avg Tone", stats['avg_tone'])
    
    # Tabs for different visualizations
    tab1, tab2, tab3, tab4, tab5 = st.tabs([
        "📈 Timeline",
        "📊 Monthly Trends",
        "🏷️ Categories",
        "🎯 Event Types",
        "👥 Key Actors"
    ])
    
    with tab1:
        st.subheader("Event Timeline")
        timeline_df = get_events_timeline(selected_country, start_date, end_date)
        plot_timeline(timeline_df)
        
        with st.expander("📋 View Raw Data"):
            st.dataframe(timeline_df, use_container_width=True)
    
    with tab2:
        st.subheader("Monthly Trends")
        monthly_df = get_monthly_trends(selected_country)
        plot_monthly_trends(monthly_df)
        
        if not monthly_df.empty:
            col1, col2 = st.columns(2)
            with col1:
                fig = px.line(
                    monthly_df,
                    x='month_date',
                    y='avg_goldstein',
                    title='Goldstein Scale Trend',
                    markers=True
                )
                st.plotly_chart(fig, use_container_width=True)
            
            with col2:
                fig = px.line(
                    monthly_df,
                    x='month_date',
                    y='avg_tone',
                    title='Average Tone Trend',
                    markers=True
                )
                st.plotly_chart(fig, use_container_width=True)
    
    with tab3:
        st.subheader("Event Categories")
        category_df = get_events_by_category(selected_country, start_date, end_date)
        plot_category_distribution(category_df)
        
        with st.expander("📋 View Category Data"):
            st.dataframe(category_df, use_container_width=True)
    
    with tab4:
        st.subheader("Top Event Types")
        event_types_df = get_top_event_types(selected_country, limit=15)
        plot_event_types(event_types_df)
        
        with st.expander("📋 View Event Types Data"):
            st.dataframe(event_types_df, use_container_width=True)
    
    with tab5:
        st.subheader("Key Actors")
        actors_df = get_actor_networks(selected_country, limit=20)
        
        if not actors_df.empty:
            fig = px.bar(
                actors_df,
                x='event_count',
                y='actor',
                orientation='h',
                title='Most Active Actors',
                color='event_count',
                color_continuous_scale='Blues'
            )
            fig.update_layout(
                yaxis={'categoryorder': 'total ascending'},
                height=600
            )
            st.plotly_chart(fig, use_container_width=True)
            
            with st.expander("📋 View Actor Data"):
                st.dataframe(actors_df, use_container_width=True)
        else:
            st.warning("No actor data available.")
    
    # Footer
    st.sidebar.markdown("---")
    st.sidebar.markdown("### ℹ️ About")
    st.sidebar.markdown("""
    **GDELT Data Explorer**
    
    This dashboard visualizes data from the Global Database of Events, 
    Language, and Tone (GDELT) project.
    
    **Metrics:**
    - **Goldstein Scale**: Impact score (-10 to +10)
    - **Average Tone**: Sentiment (-100 to +100)
    - **Event Count**: Number of recorded events
    """)


if __name__ == "__main__":
    main()

