-- Quick Reference SQL Queries for Report Management
-- Use these in Supabase SQL Editor for daily report management

-- ============================================
-- DAILY REVIEW QUERIES
-- ============================================

-- 1. Get all pending reports with full context (USE THIS MOST OFTEN)
SELECT * FROM report_review_view 
WHERE status = 'pending'
ORDER BY pending_reports_count DESC, created_at DESC;

-- 2. Get today's pending reports
SELECT * FROM report_review_view 
WHERE status = 'pending' 
  AND DATE(created_at) = CURRENT_DATE
ORDER BY created_at DESC;

-- 3. Get high-priority reports (multiple reports on same content)
SELECT * FROM get_high_priority_reports();

-- 4. Get reports by type
SELECT 
    report_type,
    COUNT(*) as total,
    COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending
FROM user_reports
GROUP BY report_type
ORDER BY total DESC;

-- ============================================
-- STATISTICS QUERIES
-- ============================================

-- Get overall statistics (last 30 days)
SELECT * FROM get_report_statistics(30);

-- Get statistics for last 7 days
SELECT * FROM get_report_statistics(7);

-- Daily report count for last 30 days
SELECT 
    DATE(created_at) as report_date,
    COUNT(*) as total_reports,
    COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending,
    COUNT(CASE WHEN status = 'reviewed' THEN 1 END) as reviewed,
    COUNT(CASE WHEN status = 'resolved' THEN 1 END) as resolved
FROM user_reports
WHERE created_at >= NOW() - INTERVAL '30 days'
GROUP BY DATE(created_at)
ORDER BY report_date DESC;

-- ============================================
-- CONTENT-SPECIFIC QUERIES
-- ============================================

-- Find users with multiple reports
SELECT 
    reported_user_id,
    username,
    display_name,
    COUNT(*) as report_count,
    MAX(created_at) as latest_report
FROM user_reports ur
JOIN users u ON ur.reported_user_id = u.id
WHERE ur.reported_user_id IS NOT NULL
  AND ur.status = 'pending'
GROUP BY reported_user_id, username, display_name
HAVING COUNT(*) >= 2
ORDER BY report_count DESC;

-- Find recipes with multiple reports
SELECT 
    reported_recipe_id,
    r.title,
    recipe_owner.username as owner_username,
    COUNT(*) as report_count,
    MAX(ur.created_at) as latest_report
FROM user_reports ur
JOIN recipes r ON ur.reported_recipe_id = r.id
JOIN users recipe_owner ON r.user_id = recipe_owner.id
WHERE ur.reported_recipe_id IS NOT NULL
  AND ur.status = 'pending'
GROUP BY reported_recipe_id, r.title, recipe_owner.username
HAVING COUNT(*) >= 2
ORDER BY report_count DESC;

-- ============================================
-- ACTION QUERIES - TAKE ACTIONS ON REPORTS
-- ============================================

-- IMPORTANT: Replace 'YOUR_ADMIN_USER_ID' with your actual admin user ID
-- You can get your user ID with: SELECT id FROM users WHERE email = 'your-email@example.com';

-- Delete a reported recipe (deletes recipe and resolves all related reports)
SELECT delete_reported_recipe(
    'RECIPE_ID_HERE'::UUID,
    'YOUR_ADMIN_USER_ID'::UUID,
    'Violation: Inappropriate content'  -- Optional admin notes
);

-- Delete a reported comment (deletes comment and resolves all related reports)
SELECT delete_reported_comment(
    'COMMENT_ID_HERE'::UUID,
    'YOUR_ADMIN_USER_ID'::UUID,
    'Violation: Harassment'  -- Optional admin notes
);

-- Delete a reported recipe image (deletes image and resolves related reports)
SELECT delete_reported_recipe_image(
    'IMAGE_URL_HERE',  -- Full image URL
    'RECIPE_ID_HERE'::UUID,
    'YOUR_ADMIN_USER_ID'::UUID,
    'Violation: Inappropriate image'  -- Optional admin notes
);

-- Suspend a reported user (resolves all reports for this user)
SELECT suspend_reported_user(
    'USER_ID_HERE'::UUID,
    'YOUR_ADMIN_USER_ID'::UUID,
    'Multiple violations reported'  -- Optional admin notes
);

-- Dismiss a report (mark as false positive)
SELECT dismiss_report(
    'REPORT_ID_HERE'::UUID,
    'YOUR_ADMIN_USER_ID'::UUID,
    'No violation found - false positive'  -- Optional admin notes
);

-- Resolve a report with custom notes (no deletion)
SELECT resolve_report(
    'REPORT_ID_HERE'::UUID,
    'YOUR_ADMIN_USER_ID'::UUID,
    'Content reviewed, warning issued to user',  -- Optional admin notes
    'warning_issued'  -- Optional action type
);

-- ============================================
-- SIMPLE STATUS UPDATES (Alternative to functions)
-- ============================================

-- Mark a specific report as reviewed (without taking action)
UPDATE user_reports
SET status = 'reviewed'
WHERE id = 'REPORT_ID_HERE';

-- Mark a specific report as resolved (without taking action)
UPDATE user_reports
SET status = 'resolved',
    admin_notes = 'Manually resolved',
    action_taken = 'manual_resolution',
    action_taken_at = NOW(),
    action_taken_by = 'YOUR_ADMIN_USER_ID'::UUID
WHERE id = 'REPORT_ID_HERE';

-- Mark all reports for a specific recipe as reviewed
UPDATE user_reports
SET status = 'reviewed'
WHERE reported_recipe_id = 'RECIPE_ID_HERE'
  AND status = 'pending';

-- Mark all reports for a specific user as reviewed
UPDATE user_reports
SET status = 'reviewed'
WHERE reported_user_id = 'USER_ID_HERE'
  AND status = 'pending';

-- Mark old pending reports as reviewed (older than 7 days, use with caution)
UPDATE user_reports
SET status = 'reviewed'
WHERE status = 'pending'
  AND created_at < NOW() - INTERVAL '7 days';

-- ============================================
-- DETAILED INVESTIGATION QUERIES
-- ============================================

-- Get all reports for a specific user
SELECT * FROM report_review_view
WHERE reported_user_id = 'USER_ID_HERE'
ORDER BY created_at DESC;

-- Get all reports for a specific recipe
SELECT * FROM report_review_view
WHERE recipe_id = 'RECIPE_ID_HERE'
ORDER BY created_at DESC;

-- Get all reports made by a specific user (to check for abuse)
SELECT * FROM report_review_view
WHERE reporter_id = 'USER_ID_HERE'
ORDER BY created_at DESC;

-- Get reports with detailed comments (usually more actionable)
SELECT * FROM report_review_view
WHERE status = 'pending'
  AND comment IS NOT NULL
  AND LENGTH(comment) > 20
ORDER BY created_at DESC;

-- ============================================
-- PATTERN DETECTION QUERIES
-- ============================================

-- Find users who report frequently (potential abuse)
SELECT 
    reporter_id,
    reporter.username,
    COUNT(*) as reports_made,
    COUNT(CASE WHEN status = 'resolved' THEN 1 END) as resolved_reports,
    MAX(created_at) as latest_report
FROM user_reports ur
JOIN users reporter ON ur.reporter_id = reporter.id
WHERE ur.created_at >= NOW() - INTERVAL '30 days'
GROUP BY reporter_id, reporter.username
HAVING COUNT(*) >= 5
ORDER BY reports_made DESC;

-- Find content that gets reported frequently
SELECT 
    CASE 
        WHEN reported_recipe_id IS NOT NULL THEN 'recipe'
        WHEN reported_user_id IS NOT NULL THEN 'user'
        WHEN reported_comment_id IS NOT NULL THEN 'comment'
    END as content_type,
    COALESCE(reported_recipe_id::text, reported_user_id::text, reported_comment_id::text) as content_id,
    COUNT(*) as total_reports,
    COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_reports
FROM user_reports
WHERE created_at >= NOW() - INTERVAL '30 days'
GROUP BY content_type, content_id
HAVING COUNT(*) >= 3
ORDER BY total_reports DESC;

