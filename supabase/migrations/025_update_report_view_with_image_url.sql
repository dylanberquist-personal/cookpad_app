-- Migration: Update report_review_view to include reported_image_url
-- This migration updates the view to include the image URL field added in migration 024

-- Drop and recreate the view with the new column
DROP VIEW IF EXISTS report_review_view;

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
    -- Image URL (if reporting specific image)
    ur.reported_image_url,
    -- Count of pending reports on same content
    (SELECT COUNT(*) 
     FROM user_reports ur2 
     WHERE ur2.status = 'pending'
       AND (
         (ur2.reported_recipe_id = ur.reported_recipe_id AND ur.reported_recipe_id IS NOT NULL)
         OR (ur2.reported_user_id = ur.reported_user_id AND ur.reported_user_id IS NOT NULL)
         OR (ur2.reported_comment_id = ur.reported_comment_id AND ur.reported_comment_id IS NOT NULL)
         OR (ur2.reported_image_url = ur.reported_image_url AND ur.reported_image_url IS NOT NULL)
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
         OR (ur3.reported_image_url = ur.reported_image_url AND ur.reported_image_url IS NOT NULL)
       )
       AND ur3.id != ur.id
    ) as total_reports_count
FROM user_reports ur
-- Join reporter
LEFT JOIN users reporter ON ur.reporter_id = reporter.id
-- Join reported user
LEFT JOIN users reported_user ON ur.reported_user_id = reported_user.id
-- Join recipe (if applicable)
LEFT JOIN recipes r ON ur.reported_recipe_id = r.id
LEFT JOIN users recipe_owner ON r.user_id = recipe_owner.id
-- Join comment (if applicable)
LEFT JOIN comments c ON ur.reported_comment_id = c.id
LEFT JOIN users comment_owner ON c.user_id = comment_owner.id
ORDER BY ur.created_at DESC;

