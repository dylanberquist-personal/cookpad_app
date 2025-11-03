-- Fix recipe_images RLS policies using SECURITY DEFINER function
-- This approach bypasses RLS when checking recipe existence

-- Create a function to check if a recipe exists
-- SECURITY DEFINER allows this function to bypass RLS on recipes table
CREATE OR REPLACE FUNCTION recipe_exists(recipe_id_param UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 
        FROM recipes 
        WHERE recipes.id = recipe_id_param
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Anyone can read recipe images" ON recipe_images;
DROP POLICY IF EXISTS "Users can insert own recipe images" ON recipe_images;
DROP POLICY IF EXISTS "Anyone can insert recipe images" ON recipe_images;
DROP POLICY IF EXISTS "Users can delete own recipe images" ON recipe_images;
DROP POLICY IF EXISTS "Users can update own recipe images" ON recipe_images;

-- ============================================
-- RECIPE IMAGES POLICIES
-- ============================================
-- Anyone can read recipe images for public recipes or their own recipes
CREATE POLICY "Anyone can read recipe images" ON recipe_images
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM recipes r
            WHERE r.id = recipe_images.recipe_id
            AND (r.is_public = true OR r.user_id = auth.uid())
        )
    );

-- Anyone can insert images to any recipe (if authenticated)
-- Using the SECURITY DEFINER function to bypass RLS checks
CREATE POLICY "Anyone can insert recipe images" ON recipe_images
    FOR INSERT
    WITH CHECK (
        auth.uid() IS NOT NULL AND
        recipe_exists(recipe_images.recipe_id)
    );

-- Users can update images for their own recipes
CREATE POLICY "Users can update own recipe images" ON recipe_images
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM recipes r
            WHERE r.id = recipe_images.recipe_id
            AND r.user_id = auth.uid()
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM recipes r
            WHERE r.id = recipe_images.recipe_id
            AND r.user_id = auth.uid()
        )
    );

-- Users can delete images for their own recipes
CREATE POLICY "Users can delete own recipe images" ON recipe_images
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM recipes r
            WHERE r.id = recipe_images.recipe_id
            AND r.user_id = auth.uid()
        )
    );

