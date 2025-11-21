-- Migration: Add image_url field to user_reports for specific image reporting
-- This allows users to specify which image they're reporting

ALTER TABLE user_reports 
ADD COLUMN IF NOT EXISTS reported_image_url TEXT;

-- Add index for image URL lookups
CREATE INDEX IF NOT EXISTS idx_user_reports_image_url ON user_reports(reported_image_url) 
WHERE reported_image_url IS NOT NULL;

COMMENT ON COLUMN user_reports.reported_image_url IS 'Specific image URL being reported (when report_type is Image)';

