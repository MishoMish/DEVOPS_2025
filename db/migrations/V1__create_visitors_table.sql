-- V1__create_visitors_table.sql
-- Flyway migration: Create visitors table to track page visits

CREATE TABLE IF NOT EXISTS visitors (
    id SERIAL PRIMARY KEY,
    ip_address VARCHAR(45),
    user_agent TEXT,
    path VARCHAR(255),
    visited_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create index for faster queries on visited_at
CREATE INDEX idx_visitors_visited_at ON visitors(visited_at);

-- Create a summary table for quick stats
CREATE TABLE IF NOT EXISTS visitor_stats (
    id SERIAL PRIMARY KEY,
    stat_name VARCHAR(50) UNIQUE NOT NULL,
    stat_value BIGINT DEFAULT 0,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Initialize total visits counter
INSERT INTO visitor_stats (stat_name, stat_value) 
VALUES ('total_visits', 0)
ON CONFLICT (stat_name) DO NOTHING;

-- Add comment for documentation
COMMENT ON TABLE visitors IS 'Tracks individual page visits for analytics';
COMMENT ON TABLE visitor_stats IS 'Stores aggregated visitor statistics';
