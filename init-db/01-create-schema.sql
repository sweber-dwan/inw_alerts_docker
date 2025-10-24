-- Create GDELT events table
CREATE TABLE IF NOT EXISTS gdelt_events (
    id SERIAL PRIMARY KEY,
    csv_index INTEGER,
    globaleventid BIGINT,
    sqldate INTEGER,
    monthyear INTEGER,
    year INTEGER,
    fractiondate DOUBLE PRECISION,
    
    -- Actor 1 fields
    actor1code VARCHAR(50),
    actor1name VARCHAR(255),
    actor1countrycode VARCHAR(10),
    actor1knowngroupcode VARCHAR(50),
    actor1ethniccode VARCHAR(50),
    actor1religion1code VARCHAR(50),
    actor1religion2code VARCHAR(50),
    actor1type1code VARCHAR(50),
    actor1type2code VARCHAR(50),
    actor1type3code VARCHAR(50),
    
    -- Actor 2 fields
    actor2code VARCHAR(50),
    actor2name VARCHAR(255),
    actor2countrycode VARCHAR(10),
    actor2knowngroupcode VARCHAR(50),
    actor2ethniccode VARCHAR(50),
    actor2religion1code VARCHAR(50),
    actor2religion2code VARCHAR(50),
    actor2type1code VARCHAR(50),
    actor2type2code VARCHAR(50),
    actor2type3code VARCHAR(50),
    
    -- Event fields
    isrootevent INTEGER,
    eventcode VARCHAR(10),
    cameocodedescription TEXT,
    eventbasecode VARCHAR(10),
    eventrootcode VARCHAR(10),
    quadclass INTEGER,
    goldsteinscale DOUBLE PRECISION,
    nummentions INTEGER,
    numsources INTEGER,
    numarticles INTEGER,
    avgtone DOUBLE PRECISION,
    
    -- Actor 1 geo fields
    actor1geotype INTEGER,
    actor1geofullname VARCHAR(255),
    actor1geocountrycode VARCHAR(10),
    actor1geoadm1code VARCHAR(50),
    actor1geoadm2code VARCHAR(50),
    actor1geolat DOUBLE PRECISION,
    actor1geolong DOUBLE PRECISION,
    actor1geofeatureid VARCHAR(50),
    
    -- Actor 2 geo fields
    actor2geotype INTEGER,
    actor2geofullname VARCHAR(255),
    actor2geocountrycode VARCHAR(10),
    actor2geoadm1code VARCHAR(50),
    actor2geoadm2code VARCHAR(50),
    actor2geolat DOUBLE PRECISION,
    actor2geolong DOUBLE PRECISION,
    actor2geofeatureid VARCHAR(50),
    
    -- Action geo fields
    actiongeotype INTEGER,
    actiongeofullname VARCHAR(255),
    actiongeocountrycode VARCHAR(10),
    actiongeoadm1code VARCHAR(50),
    actiongeoadm2code VARCHAR(50),
    actiongeolat DOUBLE PRECISION,
    actiongeolong DOUBLE PRECISION,
    actiongeofeatureid VARCHAR(50),
    
    -- Source fields
    dateadded BIGINT,
    sourceurl TEXT,
    datetime_of_article TIMESTAMP,
    acled_category VARCHAR(100),
    
    -- Metadata
    source_file VARCHAR(50),
    imported_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for common query patterns
CREATE INDEX IF NOT EXISTS idx_globaleventid ON gdelt_events(globaleventid);
CREATE INDEX IF NOT EXISTS idx_sqldate ON gdelt_events(sqldate);
CREATE INDEX IF NOT EXISTS idx_year ON gdelt_events(year);
CREATE INDEX IF NOT EXISTS idx_actor1countrycode ON gdelt_events(actor1countrycode);
CREATE INDEX IF NOT EXISTS idx_actor2countrycode ON gdelt_events(actor2countrycode);
CREATE INDEX IF NOT EXISTS idx_eventcode ON gdelt_events(eventcode);
CREATE INDEX IF NOT EXISTS idx_actiongeocountrycode ON gdelt_events(actiongeocountrycode);
CREATE INDEX IF NOT EXISTS idx_acled_category ON gdelt_events(acled_category);
CREATE INDEX IF NOT EXISTS idx_datetime_of_article ON gdelt_events(datetime_of_article);

-- Create a view for basic event summary
CREATE OR REPLACE VIEW gdelt_events_summary AS
SELECT 
    year,
    monthyear,
    actor1countrycode,
    actor2countrycode,
    actiongeocountrycode,
    acled_category,
    COUNT(*) as event_count,
    AVG(goldsteinscale) as avg_goldstein_scale,
    AVG(avgtone) as avg_tone
FROM gdelt_events
GROUP BY year, monthyear, actor1countrycode, actor2countrycode, actiongeocountrycode, acled_category;

COMMENT ON TABLE gdelt_events IS 'GDELT (Global Database of Events, Language, and Tone) events data';
COMMENT ON VIEW gdelt_events_summary IS 'Summary view of GDELT events aggregated by key dimensions';

