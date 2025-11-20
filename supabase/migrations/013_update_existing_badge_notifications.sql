-- Update existing badge notifications to include complete badge information
-- This will fix any badge notifications that were created before the enhanced trigger

-- Update all existing badge_earned notifications to include badge data
UPDATE notifications n
SET 
    message = b.icon || ' Congratulations! You earned the "' || b.name || '" badge!',
    data = jsonb_build_object(
        'badge_id', b.id,
        'badge_name', b.name,
        'badge_icon', b.icon,
        'badge_description', b.description
    )
FROM badges b
WHERE n.type = 'badge_earned' 
  AND n.badge_id = b.id
  AND (n.message IS NULL OR n.data IS NULL OR n.data = '{}'::jsonb);

-- Add a comment
COMMENT ON TABLE notifications IS 'User notifications with support for various types including badge achievements';

