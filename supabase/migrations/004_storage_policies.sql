-- Storage Bucket Policies
-- These policies control who can upload/download files from storage buckets

-- ============================================
-- RECIPE IMAGES STORAGE POLICIES
-- ============================================
-- Allow authenticated users to upload images
CREATE POLICY "Authenticated users can upload recipe images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'recipe-images'
);

-- Allow authenticated users to update their own images
CREATE POLICY "Authenticated users can update recipe images"
ON storage.objects FOR UPDATE
TO authenticated
USING (
    bucket_id = 'recipe-images'
)
WITH CHECK (
    bucket_id = 'recipe-images'
);

-- Allow authenticated users to delete images
CREATE POLICY "Authenticated users can delete recipe images"
ON storage.objects FOR DELETE
TO authenticated
USING (
    bucket_id = 'recipe-images'
);

-- Allow anyone to read recipe images (public bucket)
CREATE POLICY "Anyone can read recipe images"
ON storage.objects FOR SELECT
TO public
USING (
    bucket_id = 'recipe-images'
);

-- ============================================
-- PROFILE PICTURES STORAGE POLICIES
-- ============================================
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

-- Allow anyone to read profile pictures (public bucket)
CREATE POLICY "Anyone can read profile pictures"
ON storage.objects FOR SELECT
TO public
USING (
    bucket_id = 'profile-pictures'
);

