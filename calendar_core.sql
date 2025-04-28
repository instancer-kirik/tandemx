-- Core calendar types and variants
CREATE TYPE calendar_variant AS ENUM (
    'gregorian_julian', -- Julian calendar
    'gregorian_revised', -- Gregorian calendar
    'gregorian_astronomical', -- Proleptic Gregorian
    'mayan_classic',  -- Classic period correlation
    'mayan_goodman_martinez_thompson', -- GMT correlation
    'mayan_spinden', -- Spinden correlation
    'chinese_astronomical', -- Astronomical rules
    'chinese_traditional', -- Traditional rules
    'islamic_astronomical', -- Based on astronomical calculation
    'islamic_civil', -- Tabular Islamic calendar
    'islamic_observed', -- Based on observation
    'hebrew_astronomical',
    'hebrew_traditional'
);

-- Calendar precision requirements
CREATE TYPE calendar_precision AS ENUM (
    'day',
    'lunar_phase',
    'solar_term',
    'astronomical'
);

-- Enhanced epoch handling
CREATE TABLE calendar_epoch_correlations (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    calendar_system calendar_system NOT NULL,
    calendar_variant calendar_variant NOT NULL,
    epoch_name text NOT NULL,
    jdn numeric(20,8) NOT NULL, -- Julian Day Number with high precision
    gregorian_date timestamp with time zone NOT NULL,
    precision_requirement calendar_precision NOT NULL,
    uncertainty_days numeric(10,2), -- For historical correlations
    reference_source text, -- Academic/historical reference
    notes text,
    UNIQUE(calendar_system, calendar_variant, epoch_name)
);

-- Calendar system properties
CREATE TABLE calendar_system_properties (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    calendar_system calendar_system NOT NULL,
    calendar_variant calendar_variant NOT NULL,
    is_lunisolar boolean NOT NULL DEFAULT false,
    is_solar boolean NOT NULL DEFAULT false,
    is_lunar boolean NOT NULL DEFAULT false,
    mean_year_length numeric(10,6), -- In days
    mean_month_length numeric(10,6), -- In days
    intercalation_cycle_years integer, -- e.g. 19 for Metonic cycle
    minimum_supported_jdn numeric(20,8), -- Earliest reliable date
    maximum_supported_jdn numeric(20,8), -- Latest reliable date
    UNIQUE(calendar_system, calendar_variant)
);

-- Function to validate calendar date components
CREATE OR REPLACE FUNCTION validate_calendar_components(
    calendar_sys calendar_system,
    variant calendar_variant,
    components jsonb
) RETURNS boolean AS $$
BEGIN
    -- Validation logic varies by calendar system
    CASE calendar_sys
        WHEN 'gregorian' THEN
            -- Basic Gregorian validation
            RETURN (
                components ? 'year' AND
                components ? 'month' AND
                components ? 'day' AND
                (components->>'month')::integer BETWEEN 1 AND 12 AND
                (components->>'day')::integer BETWEEN 1 AND 31
            );
        WHEN 'mayan_long_count' THEN
            -- Validate Long Count components
            RETURN (
                components ? 'baktun' AND
                components ? 'katun' AND
                components ? 'tun' AND
                components ? 'uinal' AND
                components ? 'kin'
            );
        WHEN 'mayan_tzolkin' THEN
            -- Validate Tzolkin components
            RETURN (
                components ? 'number' AND
                components ? 'name' AND
                (components->>'number')::integer BETWEEN 1 AND 13
            );
        WHEN 'chinese' THEN
            -- Validate Chinese calendar components
            RETURN (
                components ? 'cycle' AND
                components ? 'year' AND
                components ? 'month' AND
                components ? 'day' AND
                components ? 'is_leap_month'
            );
        ELSE
            RETURN false;
    END CASE;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate JDN from calendar components
CREATE OR REPLACE FUNCTION calendar_to_jdn(
    calendar_sys calendar_system,
    variant calendar_variant,
    components jsonb
) RETURNS numeric AS $$
DECLARE
    jdn numeric;
    year integer;
    month integer;
    day integer;
BEGIN
    -- Ensure valid components
    IF NOT validate_calendar_components(calendar_sys, variant, components) THEN
        RAISE EXCEPTION 'Invalid calendar components for %: %', calendar_sys, components;
    END IF;

    CASE calendar_sys
        WHEN 'gregorian' THEN
            -- Gregorian to JDN algorithm
            year := (components->>'year')::integer;
            month := (components->>'month')::integer;
            day := (components->>'day')::integer;
            
            -- Adjust month and year for JDN calculation
            IF month <= 2 THEN
                year := year - 1;
                month := month + 12;
            END IF;
            
            -- Calculate JDN using the standard formula
            jdn := FLOOR(365.25 * (year + 4716)) +
                   FLOOR(30.6001 * (month + 1)) +
                   day - 1524.5;
            
            -- Apply Gregorian correction if after 1582-10-15
            IF variant = 'gregorian_revised' AND jdn >= 2299161 THEN
                jdn := jdn + 2 - FLOOR(year/100.0) + FLOOR(year/400.0);
            END IF;
            
            RETURN jdn;
            
        WHEN 'mayan_long_count' THEN
            -- Convert Mayan Long Count to JDN
            -- Using the GMT correlation constant (584283)
            RETURN (
                (components->>'baktun')::integer * 144000 +
                (components->>'katun')::integer * 7200 +
                (components->>'tun')::integer * 360 +
                (components->>'uinal')::integer * 20 +
                (components->>'kin')::integer
            ) + 584283;
            
        -- Add more calendar systems here
        
        ELSE
            RAISE EXCEPTION 'Unsupported calendar system: %', calendar_sys;
    END CASE;
END;
$$ LANGUAGE plpgsql;

-- Function to convert JDN to calendar components
CREATE OR REPLACE FUNCTION jdn_to_calendar(
    jdn numeric,
    target_calendar calendar_system,
    target_variant calendar_variant
) RETURNS jsonb AS $$
DECLARE
    result jsonb;
    year integer;
    month integer;
    day integer;
    a integer;
    b integer;
    c integer;
    d integer;
    e integer;
    m integer;
BEGIN
    CASE target_calendar
        WHEN 'gregorian' THEN
            -- Convert JDN to Gregorian date
            IF target_variant = 'gregorian_revised' AND jdn >= 2299161 THEN
                -- Gregorian calendar algorithm
                a := jdn + 1 + FLOOR((jdn - 1867216.25)/36524.25)::integer - FLOOR(FLOOR((jdn - 1867216.25)/36524.25)/4)::integer;
                b := a + 1524;
            ELSE
                -- Julian calendar algorithm
                b := jdn + 1524;
            END IF;
            
            c := FLOOR((b - 122.1)/365.25)::integer;
            d := FLOOR(365.25 * c)::integer;
            e := FLOOR((b - d)/30.6001)::integer;
            
            day := b - d - FLOOR(30.6001 * e)::integer;
            
            IF e < 14 THEN
                month := e - 1;
            ELSE
                month := e - 13;
            END IF;
            
            IF month > 2 THEN
                year := c - 4716;
            ELSE
                year := c - 4715;
            END IF;
            
            result := jsonb_build_object(
                'year', year,
                'month', month,
                'day', day
            );
            
        WHEN 'mayan_long_count' THEN
            -- Convert JDN to Mayan Long Count
            -- Subtract GMT correlation constant
            d := (jdn - 584283)::integer;
            
            result := jsonb_build_object(
                'baktun', FLOOR(d/144000),
                'katun', FLOOR((d % 144000)/7200),
                'tun', FLOOR((d % 7200)/360),
                'uinal', FLOOR((d % 360)/20),
                'kin', d % 20
            );
            
        -- Add more calendar systems here
        
        ELSE
            RAISE EXCEPTION 'Unsupported calendar system: %', target_calendar;
    END CASE;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Function to convert between calendar systems
CREATE OR REPLACE FUNCTION convert_calendar_date(
    source_calendar calendar_system,
    source_variant calendar_variant,
    source_components jsonb,
    target_calendar calendar_system,
    target_variant calendar_variant
) RETURNS jsonb AS $$
DECLARE
    jdn numeric;
BEGIN
    -- Convert source to JDN
    jdn := calendar_to_jdn(source_calendar, source_variant, source_components);
    
    -- Convert JDN to target calendar
    RETURN jdn_to_calendar(jdn, target_calendar, target_variant);
END;
$$ LANGUAGE plpgsql;

-- Function to determine if a date is intercalary
CREATE OR REPLACE FUNCTION is_intercalary_date(
    calendar_sys calendar_system,
    variant calendar_variant,
    components jsonb
) RETURNS boolean AS $$
DECLARE
    year integer;
    month integer;
    day integer;
BEGIN
    CASE calendar_sys
        WHEN 'gregorian' THEN
            year := (components->>'year')::integer;
            month := (components->>'month')::integer;
            day := (components->>'day')::integer;
            
            -- Check for leap day
            RETURN month = 2 AND day = 29;
            
        WHEN 'chinese' THEN
            -- Check for leap month
            RETURN (components->>'is_leap_month')::boolean;
            
        WHEN 'mayan_haab' THEN
            -- Check for Wayeb
            day := (components->>'day')::integer;
            RETURN day > 360; -- Wayeb days
            
        ELSE
            RETURN false;
    END CASE;
END;
$$ LANGUAGE plpgsql; 