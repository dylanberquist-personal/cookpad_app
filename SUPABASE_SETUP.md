# Supabase Database Setup Guide

This guide will help you set up your Supabase database for the Cookpad Recipe Social App.

## Quick Setup

1. **Run the SQL Migrations**
   - Go to your Supabase Dashboard
   - Navigate to SQL Editor
   - Copy and paste the contents of `supabase/migrations/001_initial_schema.sql`
   - Run the SQL
   - Then copy and paste `supabase/migrations/002_row_level_security.sql`
   - Run the SQL

## Step-by-Step Instructions

### 1. Create Tables

1. Open your Supabase project dashboard
2. Click on "SQL Editor" in the left sidebar
3. Click "New Query"
4. Copy the entire contents of `supabase/migrations/001_initial_schema.sql`
5. Paste into the SQL editor
6. Click "Run" or press Ctrl+Enter (Cmd+Enter on Mac)
7. Wait for success message

### 2. Set Up Row Level Security

1. Still in SQL Editor, create a new query
2. Copy the entire contents of `supabase/migrations/002_row_level_security.sql`
3. Paste and run
4. Verify all policies are created

### 3. Verify Tables Created

1. Go to "Table Editor" in Supabase Dashboard
2. You should see all 15 tables:
   - users
   - recipes
   - recipe_images
   - follows
   - ratings
   - favorites
   - comments
   - collections
   - collection_recipes
   - pantry_items
   - shopping_lists
   - shopping_list_items
   - notifications
   - ai_chat_sessions
   - user_reports

### 4. Set Up Storage Buckets

1. Go to "Storage" in Supabase Dashboard
2. Create the following buckets:

   **profile-pictures** (Public)
   - Click "New bucket"
   - Name: `profile-pictures`
   - Public bucket: ✅ Enabled
   - File size limit: 5 MB
   - Allowed MIME types: `image/jpeg, image/png, image/webp`

   **recipe-images** (Public)
   - Click "New bucket"
   - Name: `recipe-images`
   - Public bucket: ✅ Enabled
   - File size limit: 10 MB
   - Allowed MIME types: `image/jpeg, image/png, image/webp`

   **recipe-photos-ocr** (Private)
   - Click "New bucket"
   - Name: `recipe-photos-ocr`
   - Public bucket: ❌ Disabled (Private)
   - File size limit: 10 MB
   - Allowed MIME types: `image/jpeg, image/png, image/webp`
   - Note: Set up auto-delete after 24 hours (via Edge Function or cron job)

### 5. Set Up Authentication Providers

#### Google Sign-In

1. Go to "Authentication" > "Providers" in Supabase Dashboard
2. Find "Google" and enable it
3. You'll need:
   - Google Client ID
   - Google Client Secret
   - Redirect URL (provided by Supabase)

   To get Google credentials:
   - Go to [Google Cloud Console](https://console.cloud.google.com)
   - Create a new project or select existing
   - Enable Google+ API
   - Go to "Credentials" > "Create Credentials" > "OAuth client ID"
   - Application type: Web application
   - Authorized redirect URIs: `https://YOUR_PROJECT.supabase.co/auth/v1/callback`


### 6. Verify RLS Policies

1. Go to "Authentication" > "Policies" in Supabase Dashboard
2. For each table, verify that policies are enabled
3. You should see policies created by the migration

### 7. Test the Setup

You can test by running a simple query in SQL Editor:

```sql
-- Test user creation
INSERT INTO users (email, username, display_name)
VALUES ('test@example.com', 'testuser', 'Test User')
RETURNING *;

-- Test recipe creation (requires a user first)
INSERT INTO recipes (user_id, title, description, ingredients, instructions, prep_time, cook_time, total_time, servings, difficulty_level, meal_type, source_type)
VALUES (
  (SELECT id FROM users WHERE username = 'testuser'),
  'Test Recipe',
  'A test recipe',
  '[{"name": "Flour", "quantity": "1", "unit": "cup"}]'::jsonb,
  '[{"step_number": 1, "instruction": "Mix ingredients"}]'::jsonb,
  10, 20, 30, 4, 'easy', 'dinner', 'manual'
)
RETURNING *;
```

## Database Schema Overview

### Core Tables
- **users**: User profiles with chef scores and preferences
- **recipes**: Main recipe data with ingredients and instructions
- **recipe_images**: Multiple images per recipe

### Social Tables
- **follows**: User following relationships
- **ratings**: Recipe ratings (1-5 stars)
- **favorites**: User favorite recipes
- **comments**: Recipe comments with threading support

### Organization Tables
- **collections**: User recipe collections
- **collection_recipes**: Many-to-many relationship

### Utility Tables
- **pantry_items**: User ingredient inventory
- **shopping_lists**: Shopping list management
- **shopping_list_items**: Items in shopping lists
- **notifications**: User notifications
- **ai_chat_sessions**: AI recipe generation chat history
- **user_reports**: Content moderation reports

## Key Features

### Automatic Updates
The schema includes triggers that automatically:
- Update `updated_at` timestamps
- Calculate recipe `average_rating` and `rating_count`
- Update recipe `favorite_count`
- Calculate user `chef_score` based on ratings and favorites

### Indexes
Performance-optimized indexes on:
- Username and email lookups
- Recipe search (full-text, tags, filters)
- Social features (follows, favorites, ratings)
- Notifications (unread, recent)

### Security
- Row Level Security (RLS) enabled on all tables
- Policies ensure users can only access/modify their own data
- Public recipes are readable by all authenticated users
- Private recipes only visible to creator

## Troubleshooting

### Migration Errors

If you get errors about existing objects:
- The migrations use `IF NOT EXISTS` clauses
- Safe to re-run if some tables already exist
- If conflicts occur, drop the conflicting table first (be careful!)

### RLS Policy Issues

If users can't access data:
- Verify RLS is enabled: `ALTER TABLE table_name ENABLE ROW LEVEL SECURITY;`
- Check policies exist: Query `pg_policies` table
- Ensure user is authenticated: `auth.uid()` must not be null

### Foreign Key Errors

If you get foreign key constraint errors:
- Ensure parent records exist (e.g., user exists before creating recipe)
- Check that referenced IDs are valid UUIDs
- Verify cascading deletes work as expected

## Next Steps

After setting up the database:

1. ✅ Tables created
2. ✅ RLS policies configured
3. ✅ Storage buckets created
4. ✅ OAuth providers configured
5. ✅ Test data inserted
6. Ready to run the Flutter app!

The app is now ready to connect to your Supabase backend.
