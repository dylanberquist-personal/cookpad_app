-- Migration: Add helper views and functions for report management
-- This migration adds:
-- 1. A view for easy report review with all context
-- 2. Helper functions for report statistics

-- Create a comprehensive report review view
CREATE OR REPLACE VIEW report_review_view AS
SELECT 
    ur.id,
    ur.report_type,
    ur.comment as report_comment,
    ur.reason,
    ur.status,
    ur.created_at,
    -- Reporter info
    reporter.id as reporter_id,
    reporter.username as reporter_username,
    reporter.display_name as reporter_display_name,
    reporter.email as reporter_email,
    -- Reported user info
    reported_user.id as reported_user_id,
    reported_user.username as reported_user_username,
    reported_user.display_name as reported_user_display_name,
    -- Recipe info (if applicable)
    r.id as recipe_id,
    r.title as recipe_title,
    r.user_id as recipe_owner_id,
    recipe_owner.username as recipe_owner_username,
    -- Comment info (if applicable)
    c.id as comment_id,
    c.content as comment_content,
    c.user_id as comment_owner_id,
    comment_owner.username as comment_owner_username,
    -- Count of pending reports on same content
    (SELECT COUNT(*) 
     FROM user_reports ur2 
     WHERE ur2.status = 'pending'
       AND (
         (ur2.reported_recipe_id = ur.reported_recipe_id AND ur.reported_recipe_id IS NOT NULL)
         OR (ur2.reported_user_id = ur.reported_user_id AND ur.reported_user_id IS NOT NULL)
         OR (ur2.reported_comment_id = ur.reported_comment_id AND ur.reported_comment_id IS NOT NULL)
       )
       AND ur2.id != ur.id
    ) as pending_reports_count,
    -- Total reports on same content (all statuses)
    (SELECT COUNT(*) 
     FROM user_reports ur3 
     WHERE (
         (ur3.reported_recipe_id = ur.reported_recipe_id AND ur.reported_recipe_id IS NOT NULL)
         OR (ur3.reported_user_id = ur.reported_user_id AND ur.reported_user_id IS NOT NULL)
         OR (ur3.reported_comment_id = ur.reported_comment_id AND ur.reported_comment_id IS NOT NULL)
       )
       AND ur3.id != ur.id
    ) as total_reports_count
FROM user_reports ur
LEFT JOIN users reporter ON ur.reporter_id = reporter.id
LEFT JOIN users reported_user ON ur.reported_user_id = reported_user.id
LEFT JOIN recipes r ON ur.reported_recipe_id = r.id
LEFT JOIN users recipe_owner ON r.user_id = recipe_owner.id
LEFT JOIN comments c ON ur.reported_comment_id = c.id
LEFT JOIN users comment_owner ON c.user_id = comment_owner.id
ORDER BY ur.created_at DESC;

-- Create a function to get report statistics
CREATE OR REPLACE FUNCTION get_report_statistics(days_back INTEGER DEFAULT 30)
RETURNS TABLE (
    total_reports BIGINT,
    pending_reports BIGINT,
    reviewed_reports BIGINT,
    resolved_reports BIGINT,
    reports_by_type JSONB,
    top_reported_users JSONB,
    top_reported_recipes JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (SELECT COUNT(*) FROM user_reports WHERE created_at >= NOW() - (days_back || ' days')::INTERVAL)::BIGINT as total_reports,
        (SELECT COUNT(*) FROM user_reports WHERE status = 'pending' AND created_at >= NOW() - (days_back || ' days')::INTERVAL)::BIGINT as pending_reports,
        (SELECT COUNT(*) FROM user_reports WHERE status = 'reviewed' AND created_at >= NOW() - (days_back || ' days')::INTERVAL)::BIGINT as reviewed_reports,
        (SELECT COUNT(*) FROM user_reports WHERE status = 'resolved' AND created_at >= NOW() - (days_back || ' days')::INTERVAL)::BIGINT as resolved_reports,
        (SELECT jsonb_object_agg(report_type, count) 
         FROM (SELECT report_type, COUNT(*) as count 
               FROM user_reports 
               WHERE created_at >= NOW() - (days_back || ' days')::INTERVAL
               GROUP BY report_type) sub) as reports_by_type,
        (SELECT jsonb_agg(jsonb_build_object(
            'user_id', reported_user_id,
            'username', username,
            'report_count', report_count
         ))
         FROM (SELECT ur.reported_user_id, u.username, COUNT(*) as report_count
               FROM user_reports ur
               JOIN users u ON ur.reported_user_id = u.id
               WHERE ur.reported_user_id IS NOT NULL
                 AND ur.created_at >= NOW() - (days_back || ' days')::INTERVAL
               GROUP BY ur.reported_user_id, u.username
               ORDER BY report_count DESC
               LIMIT 10) sub) as top_reported_users,
        (SELECT jsonb_agg(jsonb_build_object(
            'recipe_id', reported_recipe_id,
            'recipe_title', title,
            'report_count', report_count
         ))
         FROM (SELECT ur.reported_recipe_id, r.title, COUNT(*) as report_count
               FROM user_reports ur
               JOIN recipes r ON ur.reported_recipe_id = r.id
               WHERE ur.reported_recipe_id IS NOT NULL
                 AND ur.created_at >= NOW() - (days_back || ' days')::INTERVAL
               GROUP BY ur.reported_recipe_id, r.title
               ORDER BY report_count DESC
               LIMIT 10) sub) as top_reported_recipes;
END;
$$ LANGUAGE plpgsql;

-- Create a function to get high-priority reports (multiple reports on same content)
CREATE OR REPLACE FUNCTION get_high_priority_reports()
RETURNS TABLE (
    report_id UUID,
    report_type TEXT,
    report_comment TEXT,
    created_at TIMESTAMPTZ,
    pending_reports_count BIGINT,
    content_type TEXT,
    content_id UUID,
    content_title TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ur.id as report_id,
        ur.report_type,
        ur.comment as report_comment,
        ur.created_at,
        (SELECT COUNT(*) 
         FROM user_reports ur2 
         WHERE ur2.status = 'pending'
           AND (
             (ur2.reported_recipe_id = ur.reported_recipe_id AND ur.reported_recipe_id IS NOT NULL)
             OR (ur2.reported_user_id = ur.reported_user_id AND ur.reported_user_id IS NOT NULL)
             OR (ur2.reported_comment_id = ur.reported_comment_id AND ur.reported_comment_id IS NOT NULL)
           )
        )::BIGINT as pending_reports_count,
        CASE 
            WHEN ur.reported_recipe_id IS NOT NULL THEN 'recipe'
            WHEN ur.reported_user_id IS NOT NULL THEN 'user'
            WHEN ur.reported_comment_id IS NOT NULL THEN 'comment'
        END as content_type,
        COALESCE(ur.reported_recipe_id, ur.reported_user_id, ur.reported_comment_id) as content_id,
        COALESCE(r.title, u.username, LEFT(c.content, 50)) as content_title
    FROM user_reports ur
    LEFT JOIN recipes r ON ur.reported_recipe_id = r.id
    LEFT JOIN users u ON ur.reported_user_id = u.id
    LEFT JOIN comments c ON ur.reported_comment_id = c.id
    WHERE ur.status = 'pending'
      AND (
        (SELECT COUNT(*) 
         FROM user_reports ur2 
         WHERE ur2.status = 'pending'
           AND (
             (ur2.reported_recipe_id = ur.reported_recipe_id AND ur.reported_recipe_id IS NOT NULL)
             OR (ur2.reported_user_id = ur.reported_user_id AND ur.reported_user_id IS NOT NULL)
             OR (ur2.reported_comment_id = ur.reported_comment_id AND ur.reported_comment_id IS NOT NULL)
           )
        ) >= 2
      )
    ORDER BY pending_reports_count DESC, ur.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Grant access to the view (adjust based on your admin setup)
-- Note: You may want to create an admin role and grant access only to that role
-- For now, this allows authenticated users to view (you can restrict this later)

COMMENT ON VIEW report_review_view IS 'Comprehensive view of all reports with context for admin review';
COMMENT ON FUNCTION get_report_statistics IS 'Get report statistics for the last N days';
COMMENT ON FUNCTION get_high_priority_reports IS 'Get reports that have multiple pending reports on the same content';

