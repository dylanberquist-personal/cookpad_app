-- Migration: Add Sync Functionality for Pantries and Shopping Lists
-- This migration adds tables and features for syncing pantries and shopping lists between users

-- ============================================
-- SYNCED PANTRIES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS synced_pantries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    recipient_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(sender_id, recipient_id),
    CHECK (sender_id != recipient_id)
);

-- Create indexes for synced pantries
CREATE INDEX IF NOT EXISTS idx_synced_pantries_sender_id ON synced_pantries(sender_id);
CREATE INDEX IF NOT EXISTS idx_synced_pantries_recipient_id ON synced_pantries(recipient_id);
CREATE INDEX IF NOT EXISTS idx_synced_pantries_status ON synced_pantries(status);

-- ============================================
-- SYNCED SHOPPING LISTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS synced_shopping_lists (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    shopping_list_id UUID NOT NULL REFERENCES shopping_lists(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    recipient_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(shopping_list_id, sender_id, recipient_id),
    CHECK (sender_id != recipient_id)
);

-- Create indexes for synced shopping lists
CREATE INDEX IF NOT EXISTS idx_synced_shopping_lists_list_id ON synced_shopping_lists(shopping_list_id);
CREATE INDEX IF NOT EXISTS idx_synced_shopping_lists_sender_id ON synced_shopping_lists(sender_id);
CREATE INDEX IF NOT EXISTS idx_synced_shopping_lists_recipient_id ON synced_shopping_lists(recipient_id);
CREATE INDEX IF NOT EXISTS idx_synced_shopping_lists_status ON synced_shopping_lists(status);

-- ============================================
-- ROW LEVEL SECURITY POLICIES
-- ============================================

-- Enable RLS on synced_pantries
ALTER TABLE synced_pantries ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view synced pantries they sent or received
CREATE POLICY synced_pantries_select_policy ON synced_pantries
    FOR SELECT
    USING (
        sender_id = auth.uid() OR 
        recipient_id = auth.uid()
    );

-- Policy: Users can insert synced pantry invites (send to others)
CREATE POLICY synced_pantries_insert_policy ON synced_pantries
    FOR INSERT
    WITH CHECK (sender_id = auth.uid());

-- Policy: Recipients can update synced pantry status
CREATE POLICY synced_pantries_update_policy ON synced_pantries
    FOR UPDATE
    USING (recipient_id = auth.uid())
    WITH CHECK (recipient_id = auth.uid());

-- Policy: Senders and recipients can delete synced pantries
CREATE POLICY synced_pantries_delete_policy ON synced_pantries
    FOR DELETE
    USING (sender_id = auth.uid() OR recipient_id = auth.uid());

-- Enable RLS on synced_shopping_lists
ALTER TABLE synced_shopping_lists ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view synced shopping lists they sent or received
CREATE POLICY synced_shopping_lists_select_policy ON synced_shopping_lists
    FOR SELECT
    USING (
        sender_id = auth.uid() OR 
        recipient_id = auth.uid()
    );

-- Policy: Users can insert synced shopping list invites (send to others)
CREATE POLICY synced_shopping_lists_insert_policy ON synced_shopping_lists
    FOR INSERT
    WITH CHECK (
        sender_id = auth.uid() AND
        -- Can only share shopping lists they own
        EXISTS (
            SELECT 1 FROM shopping_lists 
            WHERE id = shopping_list_id AND user_id = auth.uid()
        )
    );

-- Policy: Recipients can update synced shopping list status
CREATE POLICY synced_shopping_lists_update_policy ON synced_shopping_lists
    FOR UPDATE
    USING (recipient_id = auth.uid())
    WITH CHECK (recipient_id = auth.uid());

-- Policy: Senders and recipients can delete synced shopping lists
CREATE POLICY synced_shopping_lists_delete_policy ON synced_shopping_lists
    FOR DELETE
    USING (sender_id = auth.uid() OR recipient_id = auth.uid());

-- ============================================
-- UPDATE PANTRY_ITEMS RLS FOR SYNCED ACCESS
-- ============================================
-- Allow synced users to view and modify each other's pantry items

-- Drop existing policies to recreate them with sync support
DROP POLICY IF EXISTS pantry_items_select_policy ON pantry_items;
DROP POLICY IF EXISTS pantry_items_insert_policy ON pantry_items;
DROP POLICY IF EXISTS pantry_items_update_policy ON pantry_items;
DROP POLICY IF EXISTS pantry_items_delete_policy ON pantry_items;

-- Policy: Users can view their own pantry items and items from synced pantries
CREATE POLICY pantry_items_select_policy ON pantry_items
    FOR SELECT
    USING (
        user_id = auth.uid() OR
        -- Can see items from users who accepted sync with them
        EXISTS (
            SELECT 1 FROM synced_pantries
            WHERE status = 'accepted' 
            AND ((sender_id = auth.uid() AND recipient_id = user_id) 
                 OR (recipient_id = auth.uid() AND sender_id = user_id))
        )
    );

-- Policy: Users can insert pantry items for themselves or synced pantries
CREATE POLICY pantry_items_insert_policy ON pantry_items
    FOR INSERT
    WITH CHECK (
        user_id = auth.uid() OR
        -- Can add items to synced pantries
        EXISTS (
            SELECT 1 FROM synced_pantries
            WHERE status = 'accepted' 
            AND ((sender_id = auth.uid() AND recipient_id = user_id) 
                 OR (recipient_id = auth.uid() AND sender_id = user_id))
        )
    );

-- Policy: Users can update their own pantry items or items from synced pantries
CREATE POLICY pantry_items_update_policy ON pantry_items
    FOR UPDATE
    USING (
        user_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM synced_pantries
            WHERE status = 'accepted' 
            AND ((sender_id = auth.uid() AND recipient_id = user_id) 
                 OR (recipient_id = auth.uid() AND sender_id = user_id))
        )
    );

-- Policy: Users can delete their own pantry items or items from synced pantries
CREATE POLICY pantry_items_delete_policy ON pantry_items
    FOR DELETE
    USING (
        user_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM synced_pantries
            WHERE status = 'accepted' 
            AND ((sender_id = auth.uid() AND recipient_id = user_id) 
                 OR (recipient_id = auth.uid() AND sender_id = user_id))
        )
    );

-- ============================================
-- UPDATE SHOPPING_LISTS RLS FOR SYNCED ACCESS
-- ============================================
-- Allow synced users to view each other's shopping lists

-- Drop existing policies to recreate them with sync support
DROP POLICY IF EXISTS shopping_lists_select_policy ON shopping_lists;

-- Policy: Users can view their own shopping lists and synced shopping lists
CREATE POLICY shopping_lists_select_policy ON shopping_lists
    FOR SELECT
    USING (
        user_id = auth.uid() OR
        -- Can see shopping lists that are synced with them
        EXISTS (
            SELECT 1 FROM synced_shopping_lists
            WHERE shopping_list_id = id
            AND status = 'accepted'
            AND (sender_id = auth.uid() OR recipient_id = auth.uid())
        )
    );

-- ============================================
-- UPDATE SHOPPING_LIST_ITEMS RLS FOR SYNCED ACCESS
-- ============================================
-- Allow synced users to view and modify shopping list items

-- Drop existing policies if they exist to recreate them with sync support
DROP POLICY IF EXISTS shopping_list_items_select_policy ON shopping_list_items;
DROP POLICY IF EXISTS shopping_list_items_insert_policy ON shopping_list_items;
DROP POLICY IF EXISTS shopping_list_items_update_policy ON shopping_list_items;
DROP POLICY IF EXISTS shopping_list_items_delete_policy ON shopping_list_items;

-- Policy: Users can view items from their own lists or synced lists
CREATE POLICY shopping_list_items_select_policy ON shopping_list_items
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM shopping_lists
            WHERE shopping_lists.id = shopping_list_id
            AND (
                shopping_lists.user_id = auth.uid() OR
                EXISTS (
                    SELECT 1 FROM synced_shopping_lists
                    WHERE synced_shopping_lists.shopping_list_id = shopping_lists.id
                    AND synced_shopping_lists.status = 'accepted'
                    AND (synced_shopping_lists.sender_id = auth.uid() OR synced_shopping_lists.recipient_id = auth.uid())
                )
            )
        )
    );

-- Policy: Users can insert items into their own lists or synced lists
CREATE POLICY shopping_list_items_insert_policy ON shopping_list_items
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM shopping_lists
            WHERE shopping_lists.id = shopping_list_id
            AND (
                shopping_lists.user_id = auth.uid() OR
                EXISTS (
                    SELECT 1 FROM synced_shopping_lists
                    WHERE synced_shopping_lists.shopping_list_id = shopping_lists.id
                    AND synced_shopping_lists.status = 'accepted'
                    AND (synced_shopping_lists.sender_id = auth.uid() OR synced_shopping_lists.recipient_id = auth.uid())
                )
            )
        )
    );

-- Policy: Users can update items in their own lists or synced lists
CREATE POLICY shopping_list_items_update_policy ON shopping_list_items
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM shopping_lists
            WHERE shopping_lists.id = shopping_list_id
            AND (
                shopping_lists.user_id = auth.uid() OR
                EXISTS (
                    SELECT 1 FROM synced_shopping_lists
                    WHERE synced_shopping_lists.shopping_list_id = shopping_lists.id
                    AND synced_shopping_lists.status = 'accepted'
                    AND (synced_shopping_lists.sender_id = auth.uid() OR synced_shopping_lists.recipient_id = auth.uid())
                )
            )
        )
    );

-- Policy: Users can delete items from their own lists or synced lists
CREATE POLICY shopping_list_items_delete_policy ON shopping_list_items
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM shopping_lists
            WHERE shopping_lists.id = shopping_list_id
            AND (
                shopping_lists.user_id = auth.uid() OR
                EXISTS (
                    SELECT 1 FROM synced_shopping_lists
                    WHERE synced_shopping_lists.shopping_list_id = shopping_lists.id
                    AND synced_shopping_lists.status = 'accepted'
                    AND (synced_shopping_lists.sender_id = auth.uid() OR synced_shopping_lists.recipient_id = auth.uid())
                )
            )
        )
    );

-- ============================================
-- UPDATE NOTIFICATION TYPES
-- ============================================
-- Add pantry_sync_invite and shopping_list_sync_invite to notification types
ALTER TABLE notifications
DROP CONSTRAINT IF EXISTS notifications_type_check;

ALTER TABLE notifications
ADD CONSTRAINT notifications_type_check 
CHECK (type IN (
    'new_follower', 
    'recipe_favorited', 
    'recipe_rated', 
    'comment', 
    'remix', 
    'recipe_image_added', 
    'badge_earned',
    'collection_shared',
    'recipe_shared',
    'pantry_sync_invite',
    'shopping_list_sync_invite'
));

-- ============================================
-- FUNCTIONS AND TRIGGERS
-- ============================================

-- Function to create notification when pantry sync is requested
CREATE OR REPLACE FUNCTION notify_pantry_sync()
RETURNS TRIGGER AS $$
BEGIN
    -- Create notification for recipient
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

-- Trigger for pantry sync notifications
CREATE TRIGGER trigger_notify_pantry_sync
    AFTER INSERT ON synced_pantries
    FOR EACH ROW
    EXECUTE FUNCTION notify_pantry_sync();

-- Function to create notification when shopping list sync is requested
CREATE OR REPLACE FUNCTION notify_shopping_list_sync()
RETURNS TRIGGER AS $$
DECLARE
    list_name TEXT;
BEGIN
    -- Get shopping list name
    SELECT name INTO list_name
    FROM shopping_lists
    WHERE id = NEW.shopping_list_id;
    
    -- Create notification for recipient
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

-- Trigger for shopping list sync notifications
CREATE TRIGGER trigger_notify_shopping_list_sync
    AFTER INSERT ON synced_shopping_lists
    FOR EACH ROW
    EXECUTE FUNCTION notify_shopping_list_sync();

-- Function to update updated_at timestamp on synced pantries
CREATE OR REPLACE FUNCTION update_synced_pantry_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update timestamp on synced pantry updates
CREATE TRIGGER trigger_update_synced_pantry_timestamp
    BEFORE UPDATE ON synced_pantries
    FOR EACH ROW
    EXECUTE FUNCTION update_synced_pantry_timestamp();

-- Function to update updated_at timestamp on synced shopping lists
CREATE OR REPLACE FUNCTION update_synced_shopping_list_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update timestamp on synced shopping list updates
CREATE TRIGGER trigger_update_synced_shopping_list_timestamp
    BEFORE UPDATE ON synced_shopping_lists
    FOR EACH ROW
    EXECUTE FUNCTION update_synced_shopping_list_timestamp();


