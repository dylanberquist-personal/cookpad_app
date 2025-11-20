-- Migration: Add Sharing Functionality for Recipes and Collections
-- This migration adds tables and features for sharing recipes and collections between users

-- ============================================
-- SHARED COLLECTIONS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS shared_collections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    collection_id UUID NOT NULL REFERENCES collections(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    recipient_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(collection_id, sender_id, recipient_id),
    CHECK (sender_id != recipient_id)
);

-- Create indexes for shared collections
CREATE INDEX IF NOT EXISTS idx_shared_collections_collection_id ON shared_collections(collection_id);
CREATE INDEX IF NOT EXISTS idx_shared_collections_sender_id ON shared_collections(sender_id);
CREATE INDEX IF NOT EXISTS idx_shared_collections_recipient_id ON shared_collections(recipient_id);
CREATE INDEX IF NOT EXISTS idx_shared_collections_status ON shared_collections(status);

-- ============================================
-- SHARED RECIPES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS shared_recipes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    recipe_id UUID NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    recipient_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(recipe_id, sender_id, recipient_id),
    CHECK (sender_id != recipient_id)
);

-- Create indexes for shared recipes
CREATE INDEX IF NOT EXISTS idx_shared_recipes_recipe_id ON shared_recipes(recipe_id);
CREATE INDEX IF NOT EXISTS idx_shared_recipes_sender_id ON shared_recipes(sender_id);
CREATE INDEX IF NOT EXISTS idx_shared_recipes_recipient_id ON shared_recipes(recipient_id);

-- ============================================
-- ROW LEVEL SECURITY POLICIES
-- ============================================

-- Enable RLS on shared_collections
ALTER TABLE shared_collections ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view shared collections they sent or received
CREATE POLICY shared_collections_select_policy ON shared_collections
    FOR SELECT
    USING (
        sender_id = auth.uid() OR 
        recipient_id = auth.uid()
    );

-- Policy: Users can insert shared collections (send to others)
CREATE POLICY shared_collections_insert_policy ON shared_collections
    FOR INSERT
    WITH CHECK (
        sender_id = auth.uid() AND
        -- Can only share collections they own
        EXISTS (
            SELECT 1 FROM collections 
            WHERE id = collection_id AND user_id = auth.uid()
        )
    );

-- Policy: Recipients can update shared collection status
CREATE POLICY shared_collections_update_policy ON shared_collections
    FOR UPDATE
    USING (recipient_id = auth.uid())
    WITH CHECK (recipient_id = auth.uid());

-- Policy: Senders and recipients can delete shared collections
CREATE POLICY shared_collections_delete_policy ON shared_collections
    FOR DELETE
    USING (sender_id = auth.uid() OR recipient_id = auth.uid());

-- Enable RLS on shared_recipes
ALTER TABLE shared_recipes ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view shared recipes they sent or received
CREATE POLICY shared_recipes_select_policy ON shared_recipes
    FOR SELECT
    USING (
        sender_id = auth.uid() OR 
        recipient_id = auth.uid()
    );

-- Policy: Users can insert shared recipes (send to others)
CREATE POLICY shared_recipes_insert_policy ON shared_recipes
    FOR INSERT
    WITH CHECK (sender_id = auth.uid());

-- Policy: Users can delete shared recipes they sent or received
CREATE POLICY shared_recipes_delete_policy ON shared_recipes
    FOR DELETE
    USING (sender_id = auth.uid() OR recipient_id = auth.uid());

-- ============================================
-- UPDATE NOTIFICATION TYPES
-- ============================================
-- Add collection_shared and recipe_shared to notification types
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
    'recipe_shared'
));

-- ============================================
-- FUNCTIONS AND TRIGGERS
-- ============================================

-- Function to create notification when collection is shared
CREATE OR REPLACE FUNCTION notify_collection_shared()
RETURNS TRIGGER AS $$
BEGIN
    -- Create notification for recipient
    INSERT INTO notifications (user_id, type, actor_id, data)
    VALUES (
        NEW.recipient_id,
        'collection_shared',
        NEW.sender_id,
        jsonb_build_object('collection_id', NEW.collection_id, 'shared_collection_id', NEW.id)
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for collection sharing notifications
CREATE TRIGGER trigger_notify_collection_shared
    AFTER INSERT ON shared_collections
    FOR EACH ROW
    EXECUTE FUNCTION notify_collection_shared();

-- Function to create notification when recipe is shared
CREATE OR REPLACE FUNCTION notify_recipe_shared()
RETURNS TRIGGER AS $$
BEGIN
    -- Create notification for recipient
    INSERT INTO notifications (user_id, type, actor_id, recipe_id)
    VALUES (
        NEW.recipient_id,
        'recipe_shared',
        NEW.sender_id,
        NEW.recipe_id
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for recipe sharing notifications
CREATE TRIGGER trigger_notify_recipe_shared
    AFTER INSERT ON shared_recipes
    FOR EACH ROW
    EXECUTE FUNCTION notify_recipe_shared();

-- Function to update updated_at timestamp on shared collections
CREATE OR REPLACE FUNCTION update_shared_collection_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update timestamp on shared collection updates
CREATE TRIGGER trigger_update_shared_collection_timestamp
    BEFORE UPDATE ON shared_collections
    FOR EACH ROW
    EXECUTE FUNCTION update_shared_collection_timestamp();

