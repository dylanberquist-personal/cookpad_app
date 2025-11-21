-- Migration: Add report action capabilities
-- This migration adds:
-- 1. Admin notes and action tracking fields to user_reports
-- 2. Functions to safely take actions on reported content
-- 3. Audit trail for admin actions

-- Add admin tracking fields to user_reports
ALTER TABLE user_reports 
ADD COLUMN IF NOT EXISTS admin_notes TEXT,
ADD COLUMN IF NOT EXISTS action_taken TEXT,
ADD COLUMN IF NOT EXISTS action_taken_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS action_taken_by UUID REFERENCES users(id);

-- Create index for action tracking
CREATE INDEX IF NOT EXISTS idx_user_reports_action_taken ON user_reports(action_taken);

-- Function to mark report as resolved with notes
CREATE OR REPLACE FUNCTION resolve_report(
    report_id_param UUID,
    admin_user_id UUID,
    notes TEXT DEFAULT NULL,
    action_taken_param TEXT DEFAULT NULL
)
RETURNS void AS $$
BEGIN
    UPDATE user_reports
    SET 
        status = 'resolved',
        admin_notes = notes,
        action_taken = action_taken_param,
        action_taken_at = NOW(),
        action_taken_by = admin_user_id
    WHERE id = report_id_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to delete a reported recipe and mark reports as resolved
CREATE OR REPLACE FUNCTION delete_reported_recipe(
    recipe_id_param UUID,
    admin_user_id UUID,
    notes TEXT DEFAULT NULL
)
RETURNS void AS $$
DECLARE
    report_ids UUID[];
BEGIN
    -- Get all pending reports for this recipe
    SELECT ARRAY_AGG(id) INTO report_ids
    FROM user_reports
    WHERE reported_recipe_id = recipe_id_param
      AND status = 'pending';
    
    -- Delete the recipe (cascades will handle related data)
    DELETE FROM recipes WHERE id = recipe_id_param;
    
    -- Mark all related reports as resolved
    UPDATE user_reports
    SET 
        status = 'resolved',
        admin_notes = COALESCE(notes, 'Recipe deleted by admin'),
        action_taken = 'recipe_deleted',
        action_taken_at = NOW(),
        action_taken_by = admin_user_id
    WHERE reported_recipe_id = recipe_id_param;
    
    -- Also mark reports that were resolved
    IF report_ids IS NOT NULL THEN
        UPDATE user_reports
        SET 
            status = 'resolved',
            admin_notes = COALESCE(notes, 'Recipe deleted by admin'),
            action_taken = 'recipe_deleted',
            action_taken_at = NOW(),
            action_taken_by = admin_user_id
        WHERE id = ANY(report_ids);
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to delete a reported comment and mark reports as resolved
CREATE OR REPLACE FUNCTION delete_reported_comment(
    comment_id_param UUID,
    admin_user_id UUID,
    notes TEXT DEFAULT NULL
)
RETURNS void AS $$
DECLARE
    report_ids UUID[];
BEGIN
    -- Get all pending reports for this comment
    SELECT ARRAY_AGG(id) INTO report_ids
    FROM user_reports
    WHERE reported_comment_id = comment_id_param
      AND status = 'pending';
    
    -- Delete the comment (cascades will handle related data)
    DELETE FROM comments WHERE id = comment_id_param;
    
    -- Mark all related reports as resolved
    UPDATE user_reports
    SET 
        status = 'resolved',
        admin_notes = COALESCE(notes, 'Comment deleted by admin'),
        action_taken = 'comment_deleted',
        action_taken_at = NOW(),
        action_taken_by = admin_user_id
    WHERE reported_comment_id = comment_id_param;
    
    -- Also mark reports that were resolved
    IF report_ids IS NOT NULL THEN
        UPDATE user_reports
        SET 
            status = 'resolved',
            admin_notes = COALESCE(notes, 'Comment deleted by admin'),
            action_taken = 'comment_deleted',
            action_taken_at = NOW(),
            action_taken_by = admin_user_id
        WHERE id = ANY(report_ids);
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to delete a recipe image and mark reports as resolved
CREATE OR REPLACE FUNCTION delete_reported_recipe_image(
    image_url_param TEXT,
    recipe_id_param UUID,
    admin_user_id UUID,
    notes TEXT DEFAULT NULL
)
RETURNS void AS $$
BEGIN
    -- Delete the image record
    DELETE FROM recipe_images 
    WHERE recipe_id = recipe_id_param 
      AND image_url = image_url_param;
    
    -- Mark all related reports as resolved (if any)
    UPDATE user_reports
    SET 
        status = 'resolved',
        admin_notes = COALESCE(notes, 'Image deleted by admin'),
        action_taken = 'image_deleted',
        action_taken_at = NOW(),
        action_taken_by = admin_user_id
    WHERE reported_recipe_id = recipe_id_param
      AND report_type = 'Image'
      AND status = 'pending';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to suspend/ban a user (soft delete by setting a flag)
-- Note: You may want to add an is_suspended or is_banned field to users table
-- For now, this function marks all their content and reports as resolved
CREATE OR REPLACE FUNCTION suspend_reported_user(
    user_id_param UUID,
    admin_user_id UUID,
    notes TEXT DEFAULT NULL
)
RETURNS void AS $$
BEGIN
    -- Mark all pending reports for this user as resolved
    UPDATE user_reports
    SET 
        status = 'resolved',
        admin_notes = COALESCE(notes, 'User suspended by admin'),
        action_taken = 'user_suspended',
        action_taken_at = NOW(),
        action_taken_by = admin_user_id
    WHERE reported_user_id = user_id_param
      AND status = 'pending';
    
    -- You can add additional actions here, such as:
    -- UPDATE users SET is_suspended = true WHERE id = user_id_param;
    -- Or delete their content, etc.
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to dismiss a report (mark as false positive)
CREATE OR REPLACE FUNCTION dismiss_report(
    report_id_param UUID,
    admin_user_id UUID,
    notes TEXT DEFAULT NULL
)
RETURNS void AS $$
BEGIN
    UPDATE user_reports
    SET 
        status = 'resolved',
        admin_notes = COALESCE(notes, 'Report dismissed - no violation found'),
        action_taken = 'dismissed',
        action_taken_at = NOW(),
        action_taken_by = admin_user_id
    WHERE id = report_id_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get all actions taken by an admin
CREATE OR REPLACE FUNCTION get_admin_actions(
    admin_user_id UUID,
    days_back INTEGER DEFAULT 30
)
RETURNS TABLE (
    report_id UUID,
    report_type TEXT,
    action_taken TEXT,
    admin_notes TEXT,
    action_taken_at TIMESTAMPTZ,
    content_type TEXT,
    content_id UUID
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ur.id as report_id,
        ur.report_type,
        ur.action_taken,
        ur.admin_notes,
        ur.action_taken_at,
        CASE 
            WHEN ur.reported_recipe_id IS NOT NULL THEN 'recipe'
            WHEN ur.reported_user_id IS NOT NULL THEN 'user'
            WHEN ur.reported_comment_id IS NOT NULL THEN 'comment'
        END as content_type,
        COALESCE(ur.reported_recipe_id, ur.reported_user_id, ur.reported_comment_id) as content_id
    FROM user_reports ur
    WHERE ur.action_taken_by = admin_user_id
      AND ur.action_taken_at >= NOW() - (days_back || ' days')::INTERVAL
    ORDER BY ur.action_taken_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Grant execute permissions (adjust based on your admin setup)
-- Note: SECURITY DEFINER functions run with the privileges of the function creator
-- Make sure only admins can execute these

COMMENT ON FUNCTION resolve_report IS 'Mark a report as resolved with admin notes';
COMMENT ON FUNCTION delete_reported_recipe IS 'Delete a reported recipe and resolve all related reports';
COMMENT ON FUNCTION delete_reported_comment IS 'Delete a reported comment and resolve all related reports';
COMMENT ON FUNCTION delete_reported_recipe_image IS 'Delete a reported recipe image and resolve related reports';
COMMENT ON FUNCTION suspend_reported_user IS 'Suspend a reported user and resolve all related reports';
COMMENT ON FUNCTION dismiss_report IS 'Dismiss a report as false positive';
COMMENT ON FUNCTION get_admin_actions IS 'Get all actions taken by an admin user';

