-- Fix RLS policies for users table to allow signup
-- Users need to be able to insert their own record during signup

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can read public profiles" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;

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


