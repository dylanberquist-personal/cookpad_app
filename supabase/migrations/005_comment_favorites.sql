-- ============================================
-- COMMENT FAVORITES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS comment_favorites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    comment_id UUID NOT NULL REFERENCES comments(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, comment_id)
);

CREATE INDEX IF NOT EXISTS idx_comment_favorites_user_id ON comment_favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_comment_favorites_comment_id ON comment_favorites(comment_id);

-- Enable RLS on comment_favorites
ALTER TABLE comment_favorites ENABLE ROW LEVEL SECURITY;

-- ============================================
-- COMMENT FAVORITES RLS POLICIES
-- ============================================
-- Users can favorite any comment on recipes they can see
CREATE POLICY "Users can favorite comments" ON comment_favorites
    FOR INSERT
    WITH CHECK (
        auth.uid() = user_id AND
        EXISTS (
            SELECT 1 FROM comments c
            JOIN recipes r ON r.id = c.recipe_id
            WHERE c.id = comment_favorites.comment_id
            AND (r.is_public = true OR r.user_id = auth.uid())
        )
    );

-- Users can read their own comment favorites
CREATE POLICY "Users can read comment favorites" ON comment_favorites
    FOR SELECT
    USING (auth.uid() = user_id);

-- Users can delete their own comment favorites
CREATE POLICY "Users can delete own comment favorites" ON comment_favorites
    FOR DELETE
    USING (auth.uid() = user_id);

