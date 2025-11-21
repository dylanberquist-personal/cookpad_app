# Report Management Guide

This guide provides recommendations for systematically and manually handling user reports in the Cookpad app.

## 🚀 Quick Start: Taking Actions on Reports

**The fastest way to take action:**

1. **Find a report:**
```sql
SELECT * FROM report_review_view WHERE status = 'pending' LIMIT 1;
```

2. **Delete the reported content (example - recipe):**
```sql
SELECT delete_reported_recipe(
    'RECIPE_ID_FROM_REPORT'::UUID,
    'YOUR_ADMIN_USER_ID'::UUID,
    'Violation: Spam content'
);
```

**That's it!** The function automatically:
- ✅ Deletes the content (recipe/comment/image)
- ✅ Resolves all related reports
- ✅ Tracks who took the action and when
- ✅ Saves your admin notes

**Available Actions:**
- `delete_reported_recipe()` - Delete recipe
- `delete_reported_comment()` - Delete comment  
- `delete_reported_recipe_image()` - Delete image
- `suspend_reported_user()` - Suspend user
- `dismiss_report()` - Mark as false positive

See [Action Examples](report_action_examples.sql) for detailed examples.

## Report Structure

Reports are stored in the `user_reports` table with the following structure:
- `id`: Unique report identifier
- `reporter_id`: User who made the report
- `reported_user_id`: User being reported (if applicable)
- `reported_recipe_id`: Recipe being reported (if applicable)
- `reported_comment_id`: Comment being reported (if applicable)
- `report_type`: Type of report (Image, Title/Description/Ingredients/Instructions, Creator profile, Comment)
- `comment`: Optional additional details (max 255 characters)
- `reason`: Legacy field (can be null if report_type is provided)
- `status`: pending, reviewed, or resolved
- `created_at`: When the report was created

## Recommended Approach

### 1. Manual Review Process (Recommended for Start)

**Daily Review Workflow:**
1. Check pending reports daily
2. Review each report with context
3. Take appropriate action
4. Update report status

**Priority Levels:**
- **High Priority**: Reports with multiple reports on same content/user, reports with detailed comments
- **Medium Priority**: Single reports with context
- **Low Priority**: Vague reports without details

### 2. Automated/Semi-Automated Approach

**Automated Actions:**
- Auto-flag users/content with 3+ reports in 24 hours
- Auto-flag users/content with 5+ reports in 7 days
- Send email notifications to admins for high-priority reports

**Semi-Automated:**
- Bulk review similar reports
- Quick actions for common violations

## SQL Queries for Report Management

### View All Pending Reports with Context

```sql
SELECT 
    ur.id,
    ur.report_type,
    ur.comment,
    ur.status,
    ur.created_at,
    -- Reporter info
    reporter.username as reporter_username,
    reporter.display_name as reporter_display_name,
    -- Reported user info
    reported_user.username as reported_user_username,
    reported_user.display_name as reported_user_display_name,
    -- Recipe info (if applicable)
    r.title as recipe_title,
    r.id as recipe_id,
    -- Comment info (if applicable)
    c.content as comment_content,
    c.id as comment_id,
    -- Count of reports on same content
    (SELECT COUNT(*) 
     FROM user_reports ur2 
     WHERE ur2.reported_recipe_id = ur.reported_recipe_id 
       OR ur2.reported_user_id = ur.reported_user_id
       OR ur2.reported_comment_id = ur.reported_comment_id
    ) as total_reports_on_content
FROM user_reports ur
LEFT JOIN users reporter ON ur.reporter_id = reporter.id
LEFT JOIN users reported_user ON ur.reported_user_id = reported_user.id
LEFT JOIN recipes r ON ur.reported_recipe_id = r.id
LEFT JOIN comments c ON ur.reported_comment_id = c.id
WHERE ur.status = 'pending'
ORDER BY ur.created_at DESC;
```

### Get Reports by Type

```sql
SELECT 
    report_type,
    COUNT(*) as count,
    COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_count
FROM user_reports
GROUP BY report_type
ORDER BY count DESC;
```

### Find Users/Content with Multiple Reports

```sql
-- Users with multiple reports
SELECT 
    reported_user_id,
    u.username,
    u.display_name,
    COUNT(*) as report_count,
    MAX(ur.created_at) as latest_report
FROM user_reports ur
JOIN users u ON ur.reported_user_id = u.id
WHERE ur.reported_user_id IS NOT NULL
  AND ur.status = 'pending'
GROUP BY reported_user_id, u.username, u.display_name
HAVING COUNT(*) >= 2
ORDER BY report_count DESC;

-- Recipes with multiple reports
SELECT 
    reported_recipe_id,
    r.title,
    r.user_id as recipe_owner_id,
    u.username as recipe_owner_username,
    COUNT(*) as report_count,
    MAX(ur.created_at) as latest_report
FROM user_reports ur
JOIN recipes r ON ur.reported_recipe_id = r.id
JOIN users u ON r.user_id = u.id
WHERE ur.reported_recipe_id IS NOT NULL
  AND ur.status = 'pending'
GROUP BY reported_recipe_id, r.title, r.user_id, u.username
HAVING COUNT(*) >= 2
ORDER BY report_count DESC;
```

### Update Report Status

```sql
-- Mark report as reviewed
UPDATE user_reports
SET status = 'reviewed'
WHERE id = 'REPORT_ID_HERE';

-- Mark report as resolved
UPDATE user_reports
SET status = 'resolved'
WHERE id = 'REPORT_ID_HERE';

-- Bulk mark similar reports as reviewed
UPDATE user_reports
SET status = 'reviewed'
WHERE reported_recipe_id = 'RECIPE_ID_HERE'
  AND status = 'pending';
```

### Get Report Statistics

```sql
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
```

## Recommended Actions by Report Type

### Image Reports
- **Action**: Review the reported image
- **If Violation**: Remove image, notify recipe owner
- **If False**: Mark as resolved

### Title/Description/Ingredients/Instructions Reports
- **Action**: Review the recipe content
- **If Violation**: Request edit or remove content
- **If False**: Mark as resolved

### Creator Profile Reports
- **Action**: Review user's profile and recent activity
- **If Violation**: Warn user, suspend, or ban account
- **If False**: Mark as resolved

### Comment Reports
- **Action**: Review the specific comment
- **If Violation**: Delete comment, warn user
- **If False**: Mark as resolved

## Workflow Recommendations

### Daily Review Process

1. **Morning Check** (5-10 minutes)
   - Run "Pending Reports" query
   - Identify high-priority items (multiple reports, detailed comments)
   - Flag items needing immediate attention

2. **Review Session** (15-30 minutes)
   - Review flagged items first
   - Check context (view recipe/comment/profile)
   - Take appropriate action
   - Update report status

3. **Weekly Review** (30 minutes)
   - Review report statistics
   - Identify patterns (repeat offenders, common issues)
   - Adjust automated rules if needed

### Escalation Rules

- **1-2 Reports**: Standard review
- **3-5 Reports**: Priority review within 24 hours
- **5+ Reports**: Immediate review, consider temporary suspension
- **Pattern of Reports**: Investigate user behavior, consider warnings/bans

## Creating a Supabase View for Easy Access

You can create a view in Supabase for easier report management:

```sql
CREATE OR REPLACE VIEW report_review_view AS
SELECT 
    ur.id,
    ur.report_type,
    ur.comment,
    ur.status,
    ur.created_at,
    reporter.username as reporter_username,
    reporter.display_name as reporter_display_name,
    reported_user.username as reported_user_username,
    reported_user.display_name as reported_user_display_name,
    r.title as recipe_title,
    r.id as recipe_id,
    c.content as comment_content,
    c.id as comment_id,
    (SELECT COUNT(*) 
     FROM user_reports ur2 
     WHERE (ur2.reported_recipe_id = ur.reported_recipe_id 
            OR ur2.reported_user_id = ur.reported_user_id
            OR ur2.reported_comment_id = ur.reported_comment_id)
       AND ur2.status = 'pending'
    ) as pending_reports_count
FROM user_reports ur
LEFT JOIN users reporter ON ur.reporter_id = reporter.id
LEFT JOIN users reported_user ON ur.reported_user_id = reported_user.id
LEFT JOIN recipes r ON ur.reported_recipe_id = r.id
LEFT JOIN comments c ON ur.reported_comment_id = c.id
ORDER BY ur.created_at DESC;
```

Then query with:
```sql
SELECT * FROM report_review_view WHERE status = 'pending';
```

## Future Enhancements

### Admin Dashboard (Recommended)
Consider building a simple admin interface that:
- Lists all pending reports
- Shows report context (recipe/comment/profile preview)
- Allows quick actions (resolve, escalate, take action)
- Tracks review history

### Automated Features
- Email notifications for high-priority reports
- Auto-flagging based on report patterns
- Integration with moderation tools
- Report analytics dashboard

### Integration Options
- Supabase Dashboard: Use SQL Editor to run queries
- Admin Panel: Build a Flutter admin screen (separate from main app)
- Web Dashboard: Create a simple web interface using Supabase
- Third-party Tools: Use tools like Retool, AdminJS, or similar

## Best Practices

1. **Respond Quickly**: Review reports within 24-48 hours
2. **Be Consistent**: Apply same standards to all reports
3. **Document Actions**: Consider adding a notes/action_taken field
4. **Communicate**: Notify users when action is taken (optional)
5. **Learn Patterns**: Track common issues to improve prevention
6. **Respect Privacy**: Only access necessary information for review

## Taking Actions on Reports

### Quick Action Functions

The database includes helper functions to easily take actions on reports. These functions automatically:
- Delete the reported content
- Mark all related reports as resolved
- Track who took the action and when
- Add admin notes

#### Delete a Reported Recipe
```sql
-- This will delete the recipe and resolve all related reports
SELECT delete_reported_recipe(
    'RECIPE_ID_HERE'::UUID,
    'YOUR_ADMIN_USER_ID'::UUID,
    'Violation: Inappropriate content'  -- Optional notes
);
```

#### Delete a Reported Comment
```sql
SELECT delete_reported_comment(
    'COMMENT_ID_HERE'::UUID,
    'YOUR_ADMIN_USER_ID'::UUID,
    'Violation: Harassment'  -- Optional notes
);
```

#### Delete a Reported Recipe Image
```sql
SELECT delete_reported_recipe_image(
    'IMAGE_URL_HERE',
    'RECIPE_ID_HERE'::UUID,
    'YOUR_ADMIN_USER_ID'::UUID,
    'Violation: Inappropriate image'  -- Optional notes
);
```

#### Suspend a Reported User
```sql
SELECT suspend_reported_user(
    'USER_ID_HERE'::UUID,
    'YOUR_ADMIN_USER_ID'::UUID,
    'Multiple violations reported'  -- Optional notes
);
```

#### Dismiss a Report (False Positive)
```sql
SELECT dismiss_report(
    'REPORT_ID_HERE'::UUID,
    'YOUR_ADMIN_USER_ID'::UUID,
    'No violation found'  -- Optional notes
);
```

#### Resolve a Report with Notes
```sql
SELECT resolve_report(
    'REPORT_ID_HERE'::UUID,
    'YOUR_ADMIN_USER_ID'::UUID,
    'Content reviewed, no action needed',  -- Optional notes
    'no_action'  -- Optional action type
);
```

### Workflow Example

1. **Review the report:**
```sql
SELECT * FROM report_review_view WHERE id = 'REPORT_ID_HERE';
```

2. **Take action:**
```sql
-- If recipe needs deletion:
SELECT delete_reported_recipe('RECIPE_ID'::UUID, 'ADMIN_ID'::UUID, 'Reason: Spam');

-- If false positive:
SELECT dismiss_report('REPORT_ID'::UUID, 'ADMIN_ID'::UUID, 'No violation found');
```

3. **Verify action:**
```sql
SELECT * FROM user_reports WHERE id = 'REPORT_ID_HERE';
-- Should show status = 'resolved' and action_taken details
```

## Quick Reference Commands

```sql
-- Get today's pending reports
SELECT * FROM user_reports 
WHERE status = 'pending' 
  AND DATE(created_at) = CURRENT_DATE
ORDER BY created_at DESC;

-- Get reports needing attention (multiple reports)
SELECT * FROM report_review_view 
WHERE status = 'pending' 
  AND pending_reports_count >= 2
ORDER BY pending_reports_count DESC, created_at DESC;

-- Mark all old reports as reviewed (older than 7 days)
UPDATE user_reports
SET status = 'reviewed'
WHERE status = 'pending'
  AND created_at < NOW() - INTERVAL '7 days';
```

