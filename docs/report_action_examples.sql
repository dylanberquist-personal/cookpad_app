-- Practical Examples: Taking Actions on Reports
-- Copy and modify these queries with actual IDs from your reports

-- ============================================
-- STEP 1: Find a report to act on
-- ============================================

-- Get a pending report with full context
SELECT * FROM report_review_view 
WHERE status = 'pending'
ORDER BY pending_reports_count DESC, created_at DESC
LIMIT 1;

-- Example result will show:
-- - report_id, report_type, recipe_id, comment_id, etc.
-- - Copy the IDs you need for the actions below

-- ============================================
-- STEP 2: Review the content
-- ============================================

-- If it's a recipe report, view the recipe:
-- SELECT * FROM recipes WHERE id = 'RECIPE_ID_FROM_REPORT';

-- If it's a comment report, view the comment:
-- SELECT * FROM comments WHERE id = 'COMMENT_ID_FROM_REPORT';

-- If it's a user report, view the user:
-- SELECT * FROM users WHERE id = 'USER_ID_FROM_REPORT';

-- ============================================
-- STEP 3: Take action
-- ============================================

-- EXAMPLE 1: Delete a recipe that violates guidelines
-- Replace with actual IDs from your report
SELECT delete_reported_recipe(
    'abc123-recipe-id-here'::UUID,  -- From report_review_view.recipe_id
    'your-admin-user-id'::UUID,     -- Your admin user ID
    'Violation: Spam content'       -- Reason for deletion
);

-- EXAMPLE 2: Delete an inappropriate comment
SELECT delete_reported_comment(
    'xyz789-comment-id-here'::UUID, -- From report_review_view.comment_id
    'your-admin-user-id'::UUID,
    'Violation: Harassment'
);

-- EXAMPLE 3: Delete an inappropriate image
-- First, get the image URL from the recipe:
-- SELECT image_url FROM recipe_images WHERE recipe_id = 'RECIPE_ID';
-- Then delete it:
SELECT delete_reported_recipe_image(
    'https://your-supabase-url.com/storage/v1/object/public/recipe-images/...',  -- Full image URL
    'abc123-recipe-id-here'::UUID,
    'your-admin-user-id'::UUID,
    'Violation: Inappropriate image'
);

-- EXAMPLE 4: Suspend a user with multiple violations
SELECT suspend_reported_user(
    'user123-id-here'::UUID,        -- From report_review_view.reported_user_id
    'your-admin-user-id'::UUID,
    'Multiple violations: Spam, harassment, inappropriate content'
);

-- EXAMPLE 5: Dismiss a false positive report
SELECT dismiss_report(
    'report456-id-here'::UUID,      -- From report_review_view.id
    'your-admin-user-id'::UUID,
    'No violation found - content is appropriate'
);

-- EXAMPLE 6: Resolve without deletion (e.g., user already fixed it)
SELECT resolve_report(
    'report456-id-here'::UUID,
    'your-admin-user-id'::UUID,
    'User has already corrected the issue',
    'user_corrected'
);

-- ============================================
-- STEP 4: Verify the action
-- ============================================

-- Check that the report is now resolved
SELECT 
    id,
    status,
    action_taken,
    admin_notes,
    action_taken_at,
    action_taken_by
FROM user_reports
WHERE id = 'report456-id-here'::UUID;

-- Should show:
-- status = 'resolved'
-- action_taken = 'recipe_deleted' (or 'comment_deleted', etc.)
-- admin_notes = your notes
-- action_taken_at = current timestamp

-- ============================================
-- BULK ACTIONS
-- ============================================

-- Delete all recipes from a specific user (use with extreme caution)
-- First, get their recipe IDs:
-- SELECT id FROM recipes WHERE user_id = 'USER_ID_HERE';

-- Then delete each one (or create a loop):
-- SELECT delete_reported_recipe('RECIPE_ID_1'::UUID, 'ADMIN_ID'::UUID, 'Bulk deletion: Spam account');
-- SELECT delete_reported_recipe('RECIPE_ID_2'::UUID, 'ADMIN_ID'::UUID, 'Bulk deletion: Spam account');

-- ============================================
-- GET YOUR ADMIN USER ID
-- ============================================

-- Find your user ID to use in action functions:
SELECT id, username, email FROM users WHERE email = 'your-admin-email@example.com';

-- Or if you're logged into Supabase Dashboard, you can use:
-- SELECT auth.uid();  -- This returns your current user ID

-- ============================================
-- VIEW ACTION HISTORY
-- ============================================

-- See all actions you've taken
SELECT * FROM get_admin_actions('your-admin-user-id'::UUID, 30);

-- See all resolved reports with actions
SELECT 
    id,
    report_type,
    action_taken,
    admin_notes,
    action_taken_at,
    action_taken_by,
    CASE 
        WHEN reported_recipe_id IS NOT NULL THEN 'recipe'
        WHEN reported_user_id IS NOT NULL THEN 'user'
        WHEN reported_comment_id IS NOT NULL THEN 'comment'
    END as content_type
FROM user_reports
WHERE status = 'resolved'
  AND action_taken IS NOT NULL
ORDER BY action_taken_at DESC
LIMIT 50;

