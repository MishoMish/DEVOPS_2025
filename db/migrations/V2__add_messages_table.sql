-- V2__add_messages_table.sql
-- Flyway migration: Create messages table for guestbook feature

CREATE TABLE IF NOT EXISTS messages (
    id SERIAL PRIMARY KEY,
    author VARCHAR(100) NOT NULL DEFAULT 'Anonymous',
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create index for faster queries
CREATE INDEX idx_messages_created_at ON messages(created_at DESC);

-- Add some sample messages
INSERT INTO messages (author, content) VALUES 
    ('DevOps Bot', 'Welcome to the DevOps Demo!'),
    ('System', 'Database migrations working correctly.');

COMMENT ON TABLE messages IS 'Guestbook messages from visitors';
