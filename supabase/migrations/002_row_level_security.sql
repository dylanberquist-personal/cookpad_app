-- Row Level Security (RLS) Policies
-- Enables security at the database level

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE recipe_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE collections ENABLE ROW LEVEL SECURITY;
ALTER TABLE collection_recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE pantry_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE shopping_lists ENABLE ROW LEVEL SECURITY;
ALTER TABLE shopping_list_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_chat_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_reports ENABLE ROW LEVEL SECURITY;

-- ============================================
-- USERS POLICIES
-- ============================================
-- Users can read all public user profiles
CREATE POLICY "Users can read public profiles" ON users
    FOR SELECT
    USING (true);

-- Users can insert their own profile (for signup)
CREATE POLICY "Users can insert own profile" ON users
    FOR INSERT
    WITH CHECK (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- ============================================
-- RECIPES POLICIES
-- ============================================
-- Anyone can read public recipes
CREATE POLICY "Anyone can read public recipes" ON recipes
    FOR SELECT
    USING (is_public = true OR auth.uid() = user_id);

-- Users can create their own recipes
CREATE POLICY "Users can create own recipes" ON recipes
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own recipes
CREATE POLICY "Users can update own recipes" ON recipes
    FOR UPDATE
    USING (auth.uid() = user_id);

-- Users can delete their own recipes
CREATE POLICY "Users can delete own recipes" ON recipes
    FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================
-- RECIPE IMAGES POLICIES
-- ============================================
-- Create a function to check if a recipe exists (bypasses RLS)
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

-- Anyone can read recipe images for public recipes
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
-- Using SECURITY DEFINER function to bypass RLS on recipes table
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

-- ============================================
-- FOLLOWS POLICIES
-- ============================================
-- Anyone can read follows (public)
CREATE POLICY "Anyone can read follows" ON follows
    FOR SELECT
    USING (true);

-- Users can follow/unfollow
CREATE POLICY "Users can manage own follows" ON follows
    FOR ALL
    USING (auth.uid() = follower_id)
    WITH CHECK (auth.uid() = follower_id);

-- ============================================
-- RATINGS POLICIES
-- ============================================
-- Anyone can read ratings for public recipes
CREATE POLICY "Anyone can read ratings" ON ratings
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM recipes r
            WHERE r.id = ratings.recipe_id
            AND (r.is_public = true OR r.user_id = auth.uid())
        )
    );

-- Users can rate any public recipe (or own private recipes)
CREATE POLICY "Users can create ratings" ON ratings
    FOR INSERT
    WITH CHECK (
        auth.uid() = user_id AND
        EXISTS (
            SELECT 1 FROM recipes r
            WHERE r.id = ratings.recipe_id
            AND (r.is_public = true OR r.user_id = auth.uid())
        )
    );

-- Users can update their own ratings
CREATE POLICY "Users can update own ratings" ON ratings
    FOR UPDATE
    USING (auth.uid() = user_id);

-- Users can delete their own ratings
CREATE POLICY "Users can delete own ratings" ON ratings
    FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================
-- FAVORITES POLICIES
-- ============================================
-- Users can read their own favorites
CREATE POLICY "Users can read own favorites" ON favorites
    FOR SELECT
    USING (auth.uid() = user_id);

-- Users can favorite any public recipe
CREATE POLICY "Users can create favorites" ON favorites
    FOR INSERT
    WITH CHECK (
        auth.uid() = user_id AND
        EXISTS (
            SELECT 1 FROM recipes r
            WHERE r.id = favorites.recipe_id
            AND (r.is_public = true OR r.user_id = auth.uid())
        )
    );

-- Users can delete their own favorites
CREATE POLICY "Users can delete own favorites" ON favorites
    FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================
-- COMMENTS POLICIES
-- ============================================
-- Anyone can read comments on public recipes
CREATE POLICY "Anyone can read comments" ON comments
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM recipes r
            WHERE r.id = comments.recipe_id
            AND (r.is_public = true OR r.user_id = auth.uid())
        )
    );

-- Users can comment on public recipes
CREATE POLICY "Users can create comments" ON comments
    FOR INSERT
    WITH CHECK (
        auth.uid() = user_id AND
        EXISTS (
            SELECT 1 FROM recipes r
            WHERE r.id = comments.recipe_id
            AND (r.is_public = true OR r.user_id = auth.uid())
        )
    );

-- Users can update their own comments
CREATE POLICY "Users can update own comments" ON comments
    FOR UPDATE
    USING (auth.uid() = user_id);

-- Users can delete their own comments
CREATE POLICY "Users can delete own comments" ON comments
    FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================
-- COLLECTIONS POLICIES
-- ============================================
-- Users can read their own collections and public collections
CREATE POLICY "Users can read collections" ON collections
    FOR SELECT
    USING (is_public = true OR auth.uid() = user_id);

-- Users can create their own collections
CREATE POLICY "Users can create own collections" ON collections
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own collections
CREATE POLICY "Users can update own collections" ON collections
    FOR UPDATE
    USING (auth.uid() = user_id);

-- Users can delete their own collections
CREATE POLICY "Users can delete own collections" ON collections
    FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================
-- COLLECTION RECIPES POLICIES
-- ============================================
-- Users can read recipes in their own collections or public collections
CREATE POLICY "Users can read collection recipes" ON collection_recipes
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM collections c
            WHERE c.id = collection_recipes.collection_id
            AND (c.is_public = true OR c.user_id = auth.uid())
        )
    );

-- Users can add recipes to their own collections
CREATE POLICY "Users can add to own collections" ON collection_recipes
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM collections c
            WHERE c.id = collection_recipes.collection_id
            AND c.user_id = auth.uid()
        )
    );

-- Users can remove recipes from their own collections
CREATE POLICY "Users can remove from own collections" ON collection_recipes
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM collections c
            WHERE c.id = collection_recipes.collection_id
            AND c.user_id = auth.uid()
        )
    );

-- ============================================
-- PANTRY ITEMS POLICIES
-- ============================================
-- Users can only access their own pantry
CREATE POLICY "Users can manage own pantry" ON pantry_items
    FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- ============================================
-- SHOPPING LISTS POLICIES
-- ============================================
-- Users can only access their own shopping lists
CREATE POLICY "Users can manage own shopping lists" ON shopping_lists
    FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- ============================================
-- SHOPPING LIST ITEMS POLICIES
-- ============================================
-- Users can manage items in their own shopping lists
CREATE POLICY "Users can manage own shopping list items" ON shopping_list_items
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM shopping_lists sl
            WHERE sl.id = shopping_list_items.shopping_list_id
            AND sl.user_id = auth.uid()
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM shopping_lists sl
            WHERE sl.id = shopping_list_items.shopping_list_id
            AND sl.user_id = auth.uid()
        )
    );

-- ============================================
-- NOTIFICATIONS POLICIES
-- ============================================
-- Users can only read their own notifications
CREATE POLICY "Users can read own notifications" ON notifications
    FOR SELECT
    USING (auth.uid() = user_id);

-- System can create notifications (via service role)
CREATE POLICY "System can create notifications" ON notifications
    FOR INSERT
    WITH CHECK (true);

-- Users can update their own notifications (mark as read)
CREATE POLICY "Users can update own notifications" ON notifications
    FOR UPDATE
    USING (auth.uid() = user_id);

-- ============================================
-- AI CHAT SESSIONS POLICIES
-- ============================================
-- Users can only access their own chat sessions
CREATE POLICY "Users can manage own chat sessions" ON ai_chat_sessions
    FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- ============================================
-- USER REPORTS POLICIES
-- ============================================
-- Users can create reports
CREATE POLICY "Users can create reports" ON user_reports
    FOR INSERT
    WITH CHECK (auth.uid() = reporter_id);

-- Users can read their own reports
CREATE POLICY "Users can read own reports" ON user_reports
    FOR SELECT
    USING (auth.uid() = reporter_id);

-- Admins can read all reports (implement admin check in application logic)
