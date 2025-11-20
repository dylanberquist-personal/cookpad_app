-- Enhance badge notifications to include badge description for more detail

-- Update the badge notification trigger function to include description
CREATE OR REPLACE FUNCTION notify_badge_awarded()
RETURNS TRIGGER AS $$
DECLARE
    v_badge_name TEXT;
    v_badge_icon TEXT;
    v_badge_description TEXT;
BEGIN
    -- Get badge details including description
    SELECT name, icon, description INTO v_badge_name, v_badge_icon, v_badge_description
    FROM badges
    WHERE id = NEW.badge_id;
    
    -- Create notification with complete badge information
    INSERT INTO notifications (
        user_id,
        type,
        badge_id,
        message,
        data,
        is_read,
        created_at
    ) VALUES (
        NEW.user_id,
        'badge_earned',
        NEW.badge_id,
        v_badge_icon || ' Congratulations! You earned the "' || v_badge_name || '" badge!',
        jsonb_build_object(
            'badge_id', NEW.badge_id,
            'badge_name', v_badge_name,
            'badge_icon', v_badge_icon,
            'badge_description', v_badge_description
        ),
        false,
        NOW()
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add a comment explaining the enhanced notification
COMMENT ON FUNCTION notify_badge_awarded() IS 
'Creates a notification when a user earns a badge. Includes the badge emoji, name, and description for rich display in the app.';

