-- Create partitioning for prices table
CREATE TABLE prices_partitioned (
    price_id SERIAL,
    company_id INTEGER NOT NULL,
    price_date DATE NOT NULL,
    value NUMERIC(15,2) NOT NULL,
    PRIMARY KEY (price_id, price_date)
) PARTITION BY RANGE (price_date);

-- Create partitions by month (example for 2025)
CREATE TABLE prices_y2025m01 PARTITION OF prices_partitioned
    FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');
CREATE TABLE prices_y2025m02 PARTITION OF prices_partitioned
    FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');
CREATE TABLE prices_y2025m03 PARTITION OF prices_partitioned
    FOR VALUES FROM ('2025-03-01') TO ('2025-04-01');
-- Add more partitions as needed

-- Create partition maintenance function
CREATE OR REPLACE FUNCTION create_next_month_partition()
RETURNS void AS $$
DECLARE
    next_month_start DATE;
    next_month_end DATE;
    partition_name TEXT;
BEGIN
    -- Calculate the date for the next month
    next_month_start := date_trunc('month', current_date + interval '1 month')::date;
    next_month_end := date_trunc('month', next_month_start + interval '1 month')::date;
    
    -- Create partition name in format prices_yYYYYmMM
    partition_name := 'prices_y' || to_char(next_month_start, 'YYYY') || 'm' || to_char(next_month_start, 'MM');
    
    -- Create the partition if it doesn't exist
    EXECUTE format('
        CREATE TABLE IF NOT EXISTS %I PARTITION OF prices_partitioned
        FOR VALUES FROM (%L) TO (%L)',
        partition_name, next_month_start, next_month_end);
        
    RAISE NOTICE 'Created partition % for range % to %', partition_name, next_month_start, next_month_end;
END;
$$ LANGUAGE plpgsql;

-- Strategic indexes for common queries
CREATE INDEX idx_prices_company_date ON prices_partitioned(company_id, price_date);
CREATE INDEX idx_positions_portfolio ON positions(portfolio_id);
CREATE INDEX idx_positions_company ON positions(company_id);
CREATE INDEX idx_companies_name ON companies(company_name);

-- Create materialized view for common analytical queries
CREATE MATERIALIZED VIEW company_price_trends AS
SELECT 
    c.company_id,
    c.company_name,
    p.price_date,
    p.value,
    avg(p.value) OVER (PARTITION BY c.company_id ORDER BY p.price_date 
                       ROWS BETWEEN 7 PRECEDING AND CURRENT ROW) as moving_avg_7d
FROM 
    companies c
JOIN 
    prices_partitioned p ON c.company_id = p.company_id
WHERE 
    p.price_date >= current_date - interval '90 days';

CREATE INDEX idx_price_trends_company ON company_price_trends(company_id, price_date);

-- Schedule refresh of materialized view
CREATE OR REPLACE FUNCTION refresh_price_trends()
RETURNS void AS $$
BEGIN
    REFRESH MATERIALIZED VIEW company_price_trends;
END;
$$ LANGUAGE plpgsql;