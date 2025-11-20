-- Add delete policy for users table
-- Users should be able to delete their own profile

-- Add delete policy for users
DROP POLICY IF EXISTS "Users can delete own profile" ON users;
CREATE POLICY "Users can delete own profile" ON users
    FOR DELETE
    USING (auth.uid() = id);

