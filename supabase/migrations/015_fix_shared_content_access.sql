-- Migration: Fix RLS Policies for Shared Content Access
-- Allows recipients to view shared private recipes and collections

-- ============================================
-- UPDATE RECIPES RLS POLICY
-- ============================================
-- Drop the existing policy
DROP POLICY IF EXISTS "Anyone can read public recipes" ON recipes;

-- Create new policy that includes shared recipes
CREATE POLICY "Users can read accessible recipes" ON recipes
    FOR SELECT
    USING (
        -- Public recipes are accessible to everyone
        is_public = true 
        -- Owner can always see their own recipes
        OR auth.uid() = user_id
        -- Recipients can see recipes shared with them
        OR EXISTS (
            SELECT 1 FROM shared_recipes
            WHERE shared_recipes.recipe_id = recipes.id
            AND shared_recipes.recipient_id = auth.uid()
        )
    );

-- ============================================
-- UPDATE COLLECTIONS RLS POLICY  
-- ============================================
-- Drop the existing policy
DROP POLICY IF EXISTS "Users can read own and public collections" ON collections;

-- Create new policy that includes shared collections
CREATE POLICY "Users can read accessible collections" ON collections
    FOR SELECT
    USING (
        -- Public collections are accessible to everyone
        is_public = true
        -- Owner can always see their own collections
        OR auth.uid() = user_id
        -- Recipients can see collections shared with them (any status)
        OR EXISTS (
            SELECT 1 FROM shared_collections
            WHERE shared_collections.collection_id = collections.id
            AND shared_collections.recipient_id = auth.uid()
        )
    );

-- ============================================
-- UPDATE COLLECTION_RECIPES RLS POLICY
-- ============================================
-- Drop the existing policy
DROP POLICY IF EXISTS "Users can read collection recipes" ON collection_recipes;

-- Create new policy that includes recipes from shared collections
CREATE POLICY "Users can read accessible collection recipes" ON collection_recipes
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM collections c
            WHERE c.id = collection_recipes.collection_id
            AND (
                -- Public collections
                c.is_public = true 
                -- Owner's collections
                OR c.user_id = auth.uid()
                -- Shared collections
                OR EXISTS (
                    SELECT 1 FROM shared_collections sc
                    WHERE sc.collection_id = c.id
                    AND sc.recipient_id = auth.uid()
                )
            )
        )
    );

-- ============================================
-- UPDATE RECIPE_IMAGES RLS POLICY
-- ============================================
-- Drop the existing policy
DROP POLICY IF EXISTS "Anyone can read recipe images" ON recipe_images;

-- Create new policy that includes images from shared recipes
CREATE POLICY "Users can read accessible recipe images" ON recipe_images
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM recipes r
            WHERE r.id = recipe_images.recipe_id
            AND (
                -- Public recipes
                r.is_public = true 
                -- Owner's recipes
                OR r.user_id = auth.uid()
                -- Shared recipes
                OR EXISTS (
                    SELECT 1 FROM shared_recipes sr
                    WHERE sr.recipe_id = r.id
                    AND sr.recipient_id = auth.uid()
                )
            )
        )
    );

