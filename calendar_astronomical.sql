-- Astronomical calculations for calendar systems

-- Calculate Julian Centuries since J2000.0
CREATE OR REPLACE FUNCTION julian_centuries(jd numeric)
RETURNS numeric AS $$
BEGIN
    RETURN (jd - 2451545.0) / 36525.0;
END;
$$ LANGUAGE plpgsql;

-- Calculate mean lunar phase
CREATE OR REPLACE FUNCTION mean_lunar_phase(jd numeric)
RETURNS numeric AS $$
DECLARE
    t numeric;
    phase numeric;
BEGIN
    t := julian_centuries(jd);
    
    -- Meeus formula for mean lunar phase
    phase := 297.8501921 + 
             445267.1114034 * t -
             0.0018819 * t * t +
             t * t * t / 545868.0 -
             t * t * t * t / 113065000.0;
             
    -- Normalize to [0, 360)
    RETURN phase - FLOOR(phase / 360.0) * 360.0;
END;
$$ LANGUAGE plpgsql;

-- Calculate solar terms (24 divisions of solar year)
CREATE OR REPLACE FUNCTION solar_term(jd numeric)
RETURNS integer AS $$
DECLARE
    t numeric;
    l0 numeric; -- Mean solar longitude
BEGIN
    t := julian_centuries(jd);
    
    -- Calculate mean solar longitude (Meeus formula)
    l0 := 280.46646 + 
          36000.76983 * t +
          0.0003032 * t * t;
          
    -- Normalize to [0, 360)
    l0 := l0 - FLOOR(l0 / 360.0) * 360.0;
    
    -- Convert to solar term number (0-23)
    RETURN FLOOR(l0 / 15.0)::integer;
END;
$$ LANGUAGE plpgsql;

-- Calculate lunar month number
CREATE OR REPLACE FUNCTION lunar_month_number(jd numeric)
RETURNS integer AS $$
DECLARE
    new_moon_epoch numeric := 2451550.1; -- A known new moon
    synodic_month numeric := 29.530588861; -- Mean length of synodic month
BEGIN
    RETURN FLOOR((jd - new_moon_epoch) / synodic_month)::integer;
END;
$$ LANGUAGE plpgsql;

-- Determine if a lunar month is leap month (Chinese calendar)
CREATE OR REPLACE FUNCTION is_chinese_leap_month(
    year integer,
    month integer,
    timezone text DEFAULT 'UTC'
) RETURNS boolean AS $$
DECLARE
    solar_term_before numeric;
    solar_term_after numeric;
    month_start_jdn numeric;
    next_month_start_jdn numeric;
BEGIN
    -- Calculate JDN for start of lunar month
    month_start_jdn := chinese_new_year_jdn(year) + (month - 1) * 29.530588861;
    next_month_start_jdn := month_start_jdn + 29.530588861;
    
    -- Get solar terms before and after
    solar_term_before := solar_term(month_start_jdn);
    solar_term_after := solar_term(next_month_start_jdn);
    
    -- If no major solar term (zhongqi) occurs in this month, it's a leap month
    RETURN FLOOR(solar_term_before / 2.0) = FLOOR(solar_term_after / 2.0);
END;
$$ LANGUAGE plpgsql;

-- Calculate Chinese New Year JDN for a given Gregorian year
CREATE OR REPLACE FUNCTION chinese_new_year_jdn(
    gregorian_year integer
) RETURNS numeric AS $$
DECLARE
    estimate_jdn numeric;
    winter_solstice_jdn numeric;
    new_moon_jdn numeric;
BEGIN
    -- Estimate Chinese New Year as second new moon after winter solstice
    winter_solstice_jdn := winter_solstice(gregorian_year - 1);
    new_moon_jdn := next_new_moon(winter_solstice_jdn);
    new_moon_jdn := next_new_moon(new_moon_jdn);
    
    RETURN new_moon_jdn;
END;
$$ LANGUAGE plpgsql;

-- Calculate winter solstice JDN
CREATE OR REPLACE FUNCTION winter_solstice(
    gregorian_year integer
) RETURNS numeric AS $$
DECLARE
    t numeric;
    jd numeric;
BEGIN
    -- Approximate formula for winter solstice
    t := (gregorian_year - 2000) / 1000.0;
    jd := 2451900.05952 + 
          365242.74049 * t -
          0.06223 * t * t -
          0.00823 * t * t * t +
          0.00032 * t * t * t * t;
    
    RETURN jd;
END;
$$ LANGUAGE plpgsql;

-- Find next new moon after given JDN
CREATE OR REPLACE FUNCTION next_new_moon(
    jd numeric
) RETURNS numeric AS $$
DECLARE
    synodic_month numeric := 29.530588861;
    phase numeric;
    next_jd numeric;
BEGIN
    -- Get rough estimate
    phase := mean_lunar_phase(jd);
    next_jd := jd + (360.0 - phase) * synodic_month / 360.0;
    
    -- Could be refined with more accurate lunar phase calculation
    RETURN next_jd;
END;
$$ LANGUAGE plpgsql;

-- Calculate Hebrew calendar year type
CREATE OR REPLACE FUNCTION hebrew_year_type(
    hebrew_year integer
) RETURNS text AS $$
DECLARE
    rosh_hashana_jdn numeric;
    next_year_jdn numeric;
    year_length integer;
BEGIN
    -- Calculate JDN of Rosh Hashana for this year and next
    rosh_hashana_jdn := hebrew_new_year_jdn(hebrew_year);
    next_year_jdn := hebrew_new_year_jdn(hebrew_year + 1);
    
    year_length := next_year_jdn - rosh_hashana_jdn;
    
    RETURN CASE year_length
        WHEN 353 THEN 'deficient'
        WHEN 354 THEN 'regular'
        WHEN 355 THEN 'complete'
        WHEN 383 THEN 'deficient-leap'
        WHEN 384 THEN 'regular-leap'
        WHEN 385 THEN 'complete-leap'
        ELSE 'unknown'
    END;
END;
$$ LANGUAGE plpgsql;

-- Calculate Hebrew New Year (Rosh Hashana) JDN
CREATE OR REPLACE FUNCTION hebrew_new_year_jdn(
    hebrew_year integer
) RETURNS numeric AS $$
DECLARE
    months_elapsed integer;
    parts integer;
    hours integer;
    parts_elapsed integer;
    day_of_week integer;
    jdn numeric;
BEGIN
    -- Simplified calculation - for complete implementation, 
    -- see Calendrical Calculations by Dershowitz & Reingold
    months_elapsed := FLOOR((235 * hebrew_year - 234) / 19.0);
    parts := 12084 + 13753 * months_elapsed;
    hours := 5 + 12 * months_elapsed + 793 * (parts / 1080);
    parts_elapsed := parts % 1080 + hours * 1080;
    jdn := 1 + 29 * months_elapsed + hours / 24;
    
    -- Add postponement rules here
    
    RETURN jdn + 347997;
END;
$$ LANGUAGE plpgsql; 