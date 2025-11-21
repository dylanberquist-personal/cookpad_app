-- Migration: Add reporting and blocking functionality
-- This migration adds:
-- 1. Report type and comment fields to user_reports table
-- 2. User blocks table to track blocked users
-- 3. RLS policies for blocks table

-- Add report_type and comment fields to user_reports
ALTER TABLE user_reports 
ADD COLUMN IF NOT EXISTS report_type TEXT CHECK (report_type IN ('Image', 'Title/Description/Ingredients/Instructions', 'Creator profile', 'Comment')),
ADD COLUMN IF NOT EXISTS comment TEXT CHECK (char_length(comment) <= 255);

-- Create user_blocks table
CREATE TABLE IF NOT EXISTS user_blocks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    blocker_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    blocked_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(blocker_id, blocked_id),
    CHECK (blocker_id != blocked_id)
);

-- Create indexes for user_blocks
CREATE INDEX IF NOT EXISTS idx_user_blocks_blocker_id ON user_blocks(blocker_id);
CREATE INDEX IF NOT EXISTS idx_user_blocks_blocked_id ON user_blocks(blocked_id);

-- Enable RLS on user_blocks
ALTER TABLE user_blocks ENABLE ROW LEVEL SECURITY;

-- RLS Policies for user_blocks
-- Users can view their own blocks (both as blocker and blocked)
CREATE POLICY "Users can view own blocks" ON user_blocks
    FOR SELECT
    USING (
        auth.uid() = blocker_id OR 
        auth.uid() = blocked_id
    );

-- Users can create blocks (only as blocker)
CREATE POLICY "Users can create blocks" ON user_blocks
    FOR INSERT
    WITH CHECK (auth.uid() = blocker_id);

-- Users can delete their own blocks (only as blocker)
CREATE POLICY "Users can delete own blocks" ON user_blocks
    FOR DELETE
    USING (auth.uid() = blocker_id);

-- Update user_reports to allow report_type instead of just reason
-- Make reason nullable if report_type is provided
ALTER TABLE user_reports 
ALTER COLUMN reason DROP NOT NULL;

-- Add constraint: either reason or report_type must be provided
ALTER TABLE user_reports 
ADD CONSTRAINT check_reason_or_type 
CHECK (
    (reason IS NOT NULL AND reason != '') OR 
    (report_type IS NOT NULL)
);

