import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.lines as mlines
from scipy.stats import genextreme
from scipy import stats

def get_fit_state_thresholds(chunk, state_thresholds):
    """
    Calculate state thresholds based on data distribution.
    Uses extreme value distribution if enough data, otherwise falls back to quantiles.
    
    Parameters:
    -----------
    chunk : DataFrame
        Data chunk to calculate thresholds from
    state_thresholds : list
        Quantile values for state boundaries
    
    Returns:
    --------
    list of threshold values
    """
    data = chunk['nummentions']
    
    # Filter out zeros
    data_nonzero = data[data > 0]
    
    # Check if we have enough data for extreme value fitting
    if len(data_nonzero) >= 30:
        try:
            # Try extreme value distribution fitting
            params = genextreme.fit(data_nonzero, loc=data_nonzero.mean(), scale=data_nonzero.std())
            c_param, loc, scale = params
            ci_max_vals = [int(round(stats.genextreme.interval(thresh, c_param, loc, scale)[1])) 
                          for thresh in state_thresholds]
            return ci_max_vals
        except (ValueError, RuntimeError):
            # Fall back to quantile-based approach if fitting fails
            pass
    
    # Use quantile-based approach (more robust)
    return chunk['nummentions'].quantile(state_thresholds).tolist()

def calc_activity_state(window_df, thresholds, state_names):
    """
    Calculate the activity state based on individual nummentions values and thresholds.
    States are determined by checking if ALL values in the window are below each threshold.
    
    Parameters:
    -----------
    window_df : DataFrame
        Window of data to calculate state for
    thresholds : list
        Threshold values for state boundaries
    state_names : list
        Names of states (including 'Extreme High' as the last state)
    
    Returns:
    --------
    tuple of (state_name, state_index)
    """
    data = window_df['nummentions']
    
    # Check for Extreme High first (if any value reaches 3x the Very High threshold)
    if len(thresholds) >= 4:  # Ensure we have at least the Very High threshold
        very_high_threshold = thresholds[-1]  # The 0.98 quantile threshold
        extreme_high_threshold = very_high_threshold * 3
        
        # If ANY value reaches the extreme high threshold
        if (data >= extreme_high_threshold).any():
            return state_names[-1], len(state_names) - 1  # Return Extreme High

    # Check regular states (all values below threshold)
    for i in range(len(thresholds)):
        thresh = thresholds[i]
        if (data < thresh).all():
            return state_names[i], i

    # If not all values are below the highest threshold, return the highest regular state
    return state_names[-2], len(state_names) - 2  # Return Very High (second to last)

def prepare_timeseries(df, timescale='1D'):
    """
    Aggregate data to specified timescale for analysis
    
    Parameters:
    -----------
    df : DataFrame
        Raw event data
    timescale : str
        Time aggregation scale (e.g., '1H', '6H', '1D', '1W', '1M')
        Default: '1D' (daily)
    
    Returns:
    --------
    DataFrame with aggregated counts at specified timescale
    """
    # Make sure datetime column is properly formatted
    df['datetime_of_article'] = pd.to_datetime(df['datetime_of_article'])
    
    # Check if nummentions column exists
    using_mentions = 'nummentions' in df.columns
    
    # Create a copy of the dataframe with just the necessary columns
    temp_df = df[['datetime_of_article']].copy()
    
    # Add the nummentions column (either from original data or create with all 1s)
    if using_mentions:
        temp_df['nummentions'] = df['nummentions']
    else:
        temp_df['nummentions'] = 1
    
    # Set the datetime column as index for resampling
    temp_df = temp_df.set_index('datetime_of_article')
    
    # Resample to the specified timescale and sum the nummentions
    resampled_df = temp_df.resample(timescale).sum().reset_index()
    
    # Rename the datetime index column to 'date' for consistency
    resampled_df = resampled_df.rename(columns={'datetime_of_article': 'date'})
    
    # Add a flag to indicate whether we're using mentions or event counts
    resampled_df['using_mentions'] = using_mentions
    
    # Sort by date
    resampled_df = resampled_df.sort_values('date')
    
    return resampled_df

def apply_fit_activity_state(df, state_thresholds = [0.70, 0.85, 0.92, 0.98], state_names = ['Very Low', 'Low', 'Moderate', 'High', 'Very High', 'Extreme High'], start_idx = 360, expanding_window = 60, rolling_window = 1460, state_time_windows = [14, 60], state_time_window_labels = ['7 day', '30 day']):
    # Create a copy to avoid modifying the original DataFrame
    df = df.copy()

    # df = df.set_index('date')

    window_end = start_idx

    threshold_col = []

    last = False
    first = True

    window_start = 0

    len_last = 0

    while window_end <= len(df):

        chunk = df.iloc[window_start:window_end]

        threshold_values = get_fit_state_thresholds(chunk, state_thresholds)

        threshold_col_temp = [threshold_values] * expanding_window

        if first:
            threshold_col = [threshold_values] * len(chunk)
            first = False
        elif last:
            threshold_col = threshold_col + [threshold_values] * len_last
        else:
            threshold_col = threshold_col + threshold_col_temp

        if(last):
            break

        if (window_end + expanding_window < len(df)):
            window_end += expanding_window
        else:
            len_last = len(df) - window_end
            window_end = len(df)
            last = True

        if ( (window_end - window_start) > rolling_window): 
            window_start = window_end - rolling_window

    df.loc[:, 'fit_state_thresholds'] = threshold_col

    for w in range(len(state_time_windows)):
        window = state_time_windows[w]
        window_label = state_time_window_labels[w]

        # initialize label column full of None
        labels = [None] * len(df)
        state_idxs = [None] * len(df)

        for i in range(start_idx, len(df) + 1):
            # make sure i-window >= 0 to avoid index error
            if i - window < 0:
                continue

            window_df = df.iloc[i - window:i]
            thresholds = window_df['fit_state_thresholds'].iloc[-1]
            
            # Calculate state based on individual values in the window
            label, state_idx = calc_activity_state(window_df, thresholds, state_names)

            # assign label at i-1 (end of the window)
            labels[i - 1] = label
            state_idxs[i-1] = state_idx
 
        df.loc[:, window_label + ' state'] = labels
        df.loc[:, window_label + ' state index'] = state_idxs

        # Alert when entering High, Very High, or Extreme High states (index >= 3)
        # and the state increased from the previous period
        df.loc[:, window_label + ' state change alert'] = (
            (df[window_label + ' state index'] >= 3) & 
            (df[window_label + ' state index'] > df[window_label + ' state index'].shift(1)) &
            (df[window_label + ' state index'].shift(1).notna())
        )
    
    return df

def trigger_timeline_state_change(df, country_name, timescale='1D'):
    # Determine if we're using mentions or just event counts
    metric_type = "Mentions" if df.get('using_mentions', False).any() else "Events"
    
    # Get a readable timescale label
    timescale_label = {
        '1H': 'Hourly', 
        '6H': '6-Hour', 
        '12H': '12-Hour',
        '1D': 'Daily', 
        '1W': 'Weekly', 
        '1M': 'Monthly'
    }.get(timescale, timescale)

    # Create single plot figure
    fig, ax = plt.subplots(1, 1, figsize=(16, 6))

    colour_map = {
        'Very Low': "#0fb300",      # Green
        'Low': "#FBFF00",           # Yellow
        'Moderate': "#ff9900",      # Orange
        'High': '#ff0000',          # Bright Red
        'Very High': '#aa0000',     # Medium Red
        'Extreme High': '#440000'   # Dark Red
    }

    # Identify segment boundaries — contiguous blocks of the same state (including NaN)
    state_change = (df['30 day state'].fillna('___NA___') != df['30 day state'].fillna('___NA___').shift()).cumsum()

    # Track legend entries
    plotted_states = set()
    unknown_plotted = False

    # Loop over contiguous segments
    for _, segment in df.groupby(state_change):
        state = segment['30 day state'].iloc[0]

        if pd.isna(state):
            color = 'gray'
            unknown_plotted = True
        else:
            color = colour_map.get(state, 'gray')
            plotted_states.add(state)

        ax.plot(
            segment['date'],
            segment['nummentions'],
            color=color,
            alpha=0.7,
            linewidth=2,
        )

    legend_handles = []

    # Add states in the defined order
    for state, color in colour_map.items():
        handle = mlines.Line2D([], [], color=color, label=state, linewidth=2)
        legend_handles.append(handle)

    # Add 'Unknown' entry for NaNs
    unknown_handle = mlines.Line2D([], [], color='gray', label='Unknown', linewidth=2)
    legend_handles.append(unknown_handle)

    df = df.reset_index()

    state_change_mask = df['30 day state change alert']

    if state_change_mask.any():
        ax.scatter(df[state_change_mask]['date'], df[state_change_mask]['nummentions'], 
                  color='purple', marker='*', s=150, label=f'State Change Alert', zorder=10)

    # Add legend
    triangle_handle = mlines.Line2D([], [], color='purple', marker='*', linestyle='None', 
                                markersize=10, label='30-day state change alert')
    legend_handles.append(triangle_handle)

    ax.legend(handles=legend_handles, title="30 Day State", loc='best')
    ax.set_title(f'{country_name} Activity Timeline with 30-Day State Segments and Alerts', fontsize=14, fontweight='bold')
    ax.set_xlabel('Date', fontsize=12)
    ax.set_ylabel('Number of Mentions', fontsize=12)
    ax.grid(True, alpha=0.3, linestyle='--')
    
    plt.tight_layout()
    
    return fig