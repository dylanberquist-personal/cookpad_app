-- Fix Profile Pictures Storage Policies
-- This migration fixes the storage policies for profile pictures to use a more reliable path check
-- Run this if you're getting "unauthorized" errors when uploading profile pictures

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can upload own profile pictures" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own profile pictures" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own profile pictures" ON storage.objects;

-- Recreate policies with correct path checking
-- Allow authenticated users to upload their own profile pictures
CREATE POLICY "Users can upload own profile pictures"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'profile-pictures' AND
    split_part(name, '/', 1) = auth.uid()::text
);

-- Allow users to update their own profile pictures
CREATE POLICY "Users can update own profile pictures"
ON storage.objects FOR UPDATE
TO authenticated
USING (
    bucket_id = 'profile-pictures' AND
    split_part(name, '/', 1) = auth.uid()::text
)
WITH CHECK (
    bucket_id = 'profile-pictures' AND
    split_part(name, '/', 1) = auth.uid()::text
);

-- Allow users to delete their own profile pictures
CREATE POLICY "Users can delete own profile pictures"
ON storage.objects FOR DELETE
TO authenticated
USING (
    bucket_id = 'profile-pictures' AND
    split_part(name, '/', 1) = auth.uid()::text
);

