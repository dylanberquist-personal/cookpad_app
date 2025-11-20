-- Cookpad Recipe Social App - Badges and Improved Chef Score
-- This migration adds a badge system and improves the chef score calculation

-- ============================================
-- BADGES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS badges (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    icon TEXT NOT NULL, -- emoji or icon identifier
    tier TEXT CHECK (tier IN ('bronze', 'silver', 'gold', 'platinum')) DEFAULT 'bronze',
    requirement_type TEXT NOT NULL CHECK (requirement_type IN (
        'chef_score', 'recipe_count', 'follower_count', 'favorite_count', 
        'rating_avg', 'comment_count', 'cuisine_specialist', 'trending'
    )),
    requirement_value NUMERIC NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert predefined badges
INSERT INTO badges (id, name, description, icon, tier, requirement_type, requirement_value) VALUES
    -- Chef Score Tiers
    ('apprentice_chef', 'Apprentice Chef', 'Reached Chef Score of 25', '👨‍🍳', 'bronze', 'chef_score', 25),
    ('home_cook', 'Home Cook', 'Reached Chef Score of 50', '🏠', 'silver', 'chef_score', 50),
    ('skilled_chef', 'Skilled Chef', 'Reached Chef Score of 100', '⭐', 'gold', 'chef_score', 100),
    ('master_chef', 'Master Chef', 'Reached Chef Score of 200', '🎖️', 'platinum', 'chef_score', 200),
    ('celebrity_chef', 'Celebrity Chef', 'Reached Chef Score of 500', '👑', 'platinum', 'chef_score', 500),
    
    -- Recipe Count
    ('first_recipe', 'First Recipe', 'Published your first recipe', '📝', 'bronze', 'recipe_count', 1),
    ('recipe_creator', 'Recipe Creator', 'Published 10 recipes', '📚', 'silver', 'recipe_count', 10),
    ('prolific_chef', 'Prolific Chef', 'Published 50 recipes', '📖', 'gold', 'recipe_count', 50),
    ('recipe_master', 'Recipe Master', 'Published 100 recipes', '🏆', 'platinum', 'recipe_count', 100),
    
    -- Quality (Average Rating)
    ('quality_cook', 'Quality Cook', 'Maintain 4.0+ average rating with 10+ recipes', '⭐', 'silver', 'rating_avg', 4.0),
    ('quality_master', 'Quality Master', 'Maintain 4.5+ average rating with 20+ recipes', '🌟', 'gold', 'rating_avg', 4.5),
    ('perfectionist', 'Perfectionist', 'Maintain 4.8+ average rating with 30+ recipes', '💎', 'platinum', 'rating_avg', 4.8),
    
    -- Community Favorite
    ('popular', 'Popular', 'Received 50 total favorites', '💙', 'silver', 'favorite_count', 50),
    ('community_favorite', 'Community Favorite', 'Received 200 total favorites', '❤️', 'gold', 'favorite_count', 200),
    ('fan_favorite', 'Fan Favorite', 'Received 500 total favorites', '💖', 'platinum', 'favorite_count', 500),
    
    -- Followers
    ('influencer', 'Influencer', 'Gained 25 followers', '👥', 'silver', 'follower_count', 25),
    ('social_chef', 'Social Chef', 'Gained 100 followers', '🌐', 'gold', 'follower_count', 100),
    ('celebrity', 'Celebrity', 'Gained 500 followers', '✨', 'platinum', 'follower_count', 500),
    
    -- Engagement
    ('engaging', 'Engaging', 'Received 100 comments on your recipes', '💬', 'silver', 'comment_count', 100),
    ('conversationalist', 'Conversationalist', 'Received 500 comments on your recipes', '🗣️', 'gold', 'comment_count', 500),
    
    -- Trending (awarded manually by trigger for recent high activity)
    ('trending_chef', 'Trending Chef', 'High activity in the last 30 days', '🔥', 'gold', 'trending', 0)
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- UPDATE NOTIFICATIONS TABLE FOR BADGES
-- ============================================
-- Add columns for flexible notification data
ALTER TABLE notifications
ADD COLUMN IF NOT EXISTS message TEXT,
ADD COLUMN IF NOT EXISTS data JSONB DEFAULT '{}'::jsonb,
ADD COLUMN IF NOT EXISTS badge_id TEXT REFERENCES badges(id) ON DELETE CASCADE;

-- Add badge_earned to notification types
ALTER TABLE notifications
DROP CONSTRAINT IF EXISTS notifications_type_check;

ALTER TABLE notifications
ADD CONSTRAINT notifications_type_check 
CHECK (type IN ('new_follower', 'recipe_favorited', 'recipe_rated', 'comment', 'remix', 'recipe_image_added', 'badge_earned'));

-- Add index for badge notifications
CREATE INDEX IF NOT EXISTS idx_notifications_badge_id ON notifications(badge_id);

-- ============================================
-- USER_BADGES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS user_badges (
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    badge_id TEXT REFERENCES badges(id) ON DELETE CASCADE,
    awarded_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (user_id, badge_id)
);

CREATE INDEX IF NOT EXISTS idx_user_badges_user_id ON user_badges(user_id);
CREATE INDEX IF NOT EXISTS idx_user_badges_awarded_at ON user_badges(awarded_at DESC);

-- ============================================
-- IMPROVED CHEF SCORE CALCULATION
-- ============================================
CREATE OR REPLACE FUNCTION calculate_chef_score(p_user_id UUID)
RETURNS NUMERIC AS $$
DECLARE
    avg_rating NUMERIC;
    total_favorites INTEGER;
    recipe_count INTEGER;
    total_ratings INTEGER;
    follower_count INTEGER;
    comment_count INTEGER;
    score NUMERIC;
    activity_multiplier NUMERIC;
BEGIN
    -- Get recipe statistics
    SELECT 
        COALESCE(AVG(average_rating), 0.0),
        COUNT(*),
        COALESCE(SUM(rating_count), 0)
    INTO avg_rating, recipe_count, total_ratings
    FROM recipes
    WHERE user_id = p_user_id;

    -- Count total favorites
    SELECT COUNT(*) INTO total_favorites
    FROM favorites f
    JOIN recipes r ON f.recipe_id = r.id
    WHERE r.user_id = p_user_id;
    
    -- Get follower count
    SELECT COUNT(*) INTO follower_count
    FROM follows
    WHERE following_id = p_user_id;
    
    -- Get comment engagement (comments received on user's recipes)
    SELECT COUNT(*) INTO comment_count
    FROM comments c
    JOIN recipes r ON c.recipe_id = r.id
    WHERE r.user_id = p_user_id;
    
    -- Activity multiplier (recent activity bonus)
    SELECT CASE
        WHEN MAX(created_at) > NOW() - INTERVAL '30 days' THEN 1.2
        WHEN MAX(created_at) > NOW() - INTERVAL '90 days' THEN 1.0
        ELSE 0.8
    END INTO activity_multiplier
    FROM recipes
    WHERE user_id = p_user_id;
    
    -- Handle users with no recipes
    IF recipe_count = 0 THEN
        activity_multiplier := 1.0;
    END IF;
    
    -- Calculate balanced score
    -- Components: Quality + Productivity + Popularity + Influence + Engagement + Validation
    score := (
        (avg_rating * 15.0) +                      -- Quality (max 75 for 5.0 rating)
        (recipe_count * 2.0) +                     -- Productivity (2 points per recipe)
        (total_favorites * 0.5) +                  -- Popularity (0.5 per favorite)
        (follower_count * 1.0) +                   -- Influence (1 point per follower)
        (comment_count * 0.2) +                    -- Engagement (0.2 per comment)
        (LEAST(total_ratings, 100) * 0.3)          -- Community validation (capped at 100)
    ) * activity_multiplier;                       -- Bonus for recent activity
    
    RETURN GREATEST(score, 0.0);
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- BADGE CHECKING AND AWARDING FUNCTIONS
-- ============================================

-- Function to check and award badges for a user
CREATE OR REPLACE FUNCTION check_and_award_badges(p_user_id UUID)
RETURNS void AS $$
DECLARE
    v_chef_score NUMERIC;
    v_recipe_count INTEGER;
    v_total_favorites INTEGER;
    v_follower_count INTEGER;
    v_comment_count INTEGER;
    v_avg_rating NUMERIC;
    v_badge RECORD;
    v_already_has BOOLEAN;
BEGIN
    -- Get user's current statistics
    SELECT chef_score INTO v_chef_score FROM users WHERE id = p_user_id;
    
    SELECT COUNT(*) INTO v_recipe_count FROM recipes WHERE user_id = p_user_id;
    
    SELECT COUNT(*) INTO v_total_favorites
    FROM favorites f
    JOIN recipes r ON f.recipe_id = r.id
    WHERE r.user_id = p_user_id;
    
    SELECT COUNT(*) INTO v_follower_count
    FROM follows
    WHERE following_id = p_user_id;
    
    SELECT COUNT(*) INTO v_comment_count
    FROM comments c
    JOIN recipes r ON c.recipe_id = r.id
    WHERE r.user_id = p_user_id;
    
    SELECT COALESCE(AVG(average_rating), 0.0) INTO v_avg_rating
    FROM recipes
    WHERE user_id = p_user_id AND rating_count > 0;
    
    -- Check each badge type
    FOR v_badge IN SELECT * FROM badges LOOP
        -- Check if user already has this badge
        SELECT EXISTS(
            SELECT 1 FROM user_badges 
            WHERE user_id = p_user_id AND badge_id = v_badge.id
        ) INTO v_already_has;
        
        IF NOT v_already_has THEN
            -- Check if user qualifies for this badge
            IF v_badge.requirement_type = 'chef_score' AND v_chef_score >= v_badge.requirement_value THEN
                INSERT INTO user_badges (user_id, badge_id) VALUES (p_user_id, v_badge.id);
                
            ELSIF v_badge.requirement_type = 'recipe_count' AND v_recipe_count >= v_badge.requirement_value THEN
                INSERT INTO user_badges (user_id, badge_id) VALUES (p_user_id, v_badge.id);
                
            ELSIF v_badge.requirement_type = 'favorite_count' AND v_total_favorites >= v_badge.requirement_value THEN
                INSERT INTO user_badges (user_id, badge_id) VALUES (p_user_id, v_badge.id);
                
            ELSIF v_badge.requirement_type = 'follower_count' AND v_follower_count >= v_badge.requirement_value THEN
                INSERT INTO user_badges (user_id, badge_id) VALUES (p_user_id, v_badge.id);
                
            ELSIF v_badge.requirement_type = 'comment_count' AND v_comment_count >= v_badge.requirement_value THEN
                INSERT INTO user_badges (user_id, badge_id) VALUES (p_user_id, v_badge.id);
                
            ELSIF v_badge.requirement_type = 'rating_avg' THEN
                -- Special handling for rating average badges with minimum recipe requirements
                IF v_badge.id = 'quality_cook' AND v_avg_rating >= 4.0 AND v_recipe_count >= 10 THEN
                    INSERT INTO user_badges (user_id, badge_id) VALUES (p_user_id, v_badge.id);
                ELSIF v_badge.id = 'quality_master' AND v_avg_rating >= 4.5 AND v_recipe_count >= 20 THEN
                    INSERT INTO user_badges (user_id, badge_id) VALUES (p_user_id, v_badge.id);
                ELSIF v_badge.id = 'perfectionist' AND v_avg_rating >= 4.8 AND v_recipe_count >= 30 THEN
                    INSERT INTO user_badges (user_id, badge_id) VALUES (p_user_id, v_badge.id);
                END IF;
                
            ELSIF v_badge.requirement_type = 'trending' THEN
                -- Check for trending (3+ recipes in last 30 days with good engagement)
                DECLARE
                    recent_recipe_count INTEGER;
                    recent_engagement INTEGER;
                BEGIN
                    SELECT COUNT(*) INTO recent_recipe_count
                    FROM recipes
                    WHERE user_id = p_user_id 
                    AND created_at > NOW() - INTERVAL '30 days';
                    
                    SELECT COALESCE(SUM(favorite_count + rating_count), 0) INTO recent_engagement
                    FROM recipes
                    WHERE user_id = p_user_id 
                    AND created_at > NOW() - INTERVAL '30 days';
                    
                    IF recent_recipe_count >= 3 AND recent_engagement >= 20 THEN
                        INSERT INTO user_badges (user_id, badge_id) VALUES (p_user_id, v_badge.id);
                    END IF;
                END;
            END IF;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TRIGGER TO SEND NOTIFICATION WHEN BADGE IS AWARDED
-- ============================================
CREATE OR REPLACE FUNCTION notify_badge_awarded()
RETURNS TRIGGER AS $$
DECLARE
    v_badge_name TEXT;
    v_badge_icon TEXT;
BEGIN
    -- Get badge details
    SELECT name, icon INTO v_badge_name, v_badge_icon
    FROM badges
    WHERE id = NEW.badge_id;
    
    -- Create notification
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
            'badge_icon', v_badge_icon
        ),
        false,
        NOW()
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER badge_awarded_notification_trigger
    AFTER INSERT ON user_badges
    FOR EACH ROW EXECUTE FUNCTION notify_badge_awarded();

-- ============================================
-- UPDATE EXISTING UPDATE_CHEF_SCORE FUNCTION
-- ============================================
CREATE OR REPLACE FUNCTION update_chef_score()
RETURNS TRIGGER AS $$
DECLARE
    affected_user_id UUID;
BEGIN
    -- Determine which user was affected
    IF TG_TABLE_NAME = 'ratings' THEN
        SELECT r.user_id INTO affected_user_id
        FROM recipes r
        WHERE r.id = COALESCE(NEW.recipe_id, OLD.recipe_id);
    ELSIF TG_TABLE_NAME = 'favorites' THEN
        SELECT r.user_id INTO affected_user_id
        FROM recipes r
        WHERE r.id = COALESCE(NEW.recipe_id, OLD.recipe_id);
    ELSIF TG_TABLE_NAME = 'follows' THEN
        affected_user_id := COALESCE(NEW.following_id, OLD.following_id);
    ELSIF TG_TABLE_NAME = 'comments' THEN
        SELECT r.user_id INTO affected_user_id
        FROM recipes r
        WHERE r.id = COALESCE(NEW.recipe_id, OLD.recipe_id);
    ELSIF TG_TABLE_NAME = 'recipes' THEN
        affected_user_id := COALESCE(NEW.user_id, OLD.user_id);
    END IF;

    -- Update chef score and check for new badges
    IF affected_user_id IS NOT NULL THEN
        UPDATE users
        SET chef_score = calculate_chef_score(affected_user_id)
        WHERE id = affected_user_id;
        
        -- Check and award any new badges
        PERFORM check_and_award_badges(affected_user_id);
    END IF;

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Add triggers for new tables that affect chef score
CREATE TRIGGER update_chef_score_follows_trigger
    AFTER INSERT OR DELETE ON follows
    FOR EACH ROW EXECUTE FUNCTION update_chef_score();

CREATE TRIGGER update_chef_score_comments_trigger
    AFTER INSERT OR DELETE ON comments
    FOR EACH ROW EXECUTE FUNCTION update_chef_score();

CREATE TRIGGER update_chef_score_recipes_trigger
    AFTER INSERT OR DELETE ON recipes
    FOR EACH ROW EXECUTE FUNCTION update_chef_score();

-- ============================================
-- ROW LEVEL SECURITY FOR BADGES
-- ============================================
ALTER TABLE badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_badges ENABLE ROW LEVEL SECURITY;

-- Everyone can read badges
CREATE POLICY "Badges are viewable by everyone"
    ON badges FOR SELECT
    USING (true);

-- Everyone can view user badges
CREATE POLICY "User badges are viewable by everyone"
    ON user_badges FOR SELECT
    USING (true);

-- Only the system can insert user badges (via triggers)
-- Users cannot manually insert badges

-- ============================================
-- FUNCTION TO RECALCULATE ALL SCORES AND BADGES
-- ============================================
-- Utility function to recalculate scores and badges for all users
CREATE OR REPLACE FUNCTION recalculate_all_chef_scores_and_badges()
RETURNS void AS $$
DECLARE
    v_user RECORD;
BEGIN
    FOR v_user IN SELECT id FROM users LOOP
        UPDATE users
        SET chef_score = calculate_chef_score(v_user.id)
        WHERE id = v_user.id;
        
        PERFORM check_and_award_badges(v_user.id);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Run it once to update existing users
SELECT recalculate_all_chef_scores_and_badges();

