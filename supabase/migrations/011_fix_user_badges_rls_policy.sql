-- Fix RLS policy for user_badges table to allow system inserts via triggers
-- The triggers run in the context of the authenticated user, so we need to allow
-- INSERT operations for authenticated users on their own badges

-- Drop existing policies if any
DROP POLICY IF EXISTS "User badges are viewable by everyone" ON user_badges;

-- Recreate the SELECT policy
CREATE POLICY "User badges are viewable by everyone"
    ON user_badges FOR SELECT
    USING (true);

-- Add INSERT policy that allows authenticated users to insert their own badges
-- This is needed for the trigger functions to work properly
CREATE POLICY "Users can receive badges via system triggers"
    ON user_badges FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

-- Add a comment explaining the policy
COMMENT ON POLICY "Users can receive badges via system triggers" ON user_badges IS 
'Allows badge insertion for authenticated users via trigger functions. The trigger runs in the user context and inserts badges for the current user.';

