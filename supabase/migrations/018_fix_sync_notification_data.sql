-- Migration: Fix Sync Notification Data
-- This migration updates the notification trigger functions to properly store sync IDs in notification data

-- Update function to create notification when pantry sync is requested
CREATE OR REPLACE FUNCTION notify_pantry_sync()
RETURNS TRIGGER AS $$
BEGIN
    -- Create notification for recipient with synced_pantry_id in data
    INSERT INTO notifications (user_id, type, actor_id, data)
    VALUES (
        NEW.recipient_id,
        'pantry_sync_invite',
        NEW.sender_id,
        jsonb_build_object('synced_pantry_id', NEW.id)
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update function to create notification when shopping list sync is requested
CREATE OR REPLACE FUNCTION notify_shopping_list_sync()
RETURNS TRIGGER AS $$
DECLARE
    list_name TEXT;
BEGIN
    -- Get shopping list name
    SELECT name INTO list_name
    FROM shopping_lists
    WHERE id = NEW.shopping_list_id;
    
    -- Create notification for recipient with shopping list details in data
    INSERT INTO notifications (user_id, type, actor_id, data)
    VALUES (
        NEW.recipient_id,
        'shopping_list_sync_invite',
        NEW.sender_id,
        jsonb_build_object(
            'shopping_list_id', NEW.shopping_list_id, 
            'synced_shopping_list_id', NEW.id,
            'shopping_list_name', list_name
        )
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

