-- Sample Data Import for Cookpad App (WITH PLACEHOLDER UUIDs)
-- =============================================================
-- 
-- IMPORTANT WARNING:
-- If you run this script with placeholder UUIDs WITHOUT creating auth.users entries first:
-- 
-- ✅ The data will be inserted successfully (if run with service role)
-- ❌ Users WILL NOT be able to authenticate/login
-- ❌ Users won't be able to access their own data due to RLS policies
-- ❌ Recipes will be visible but users can't interact with them as owners
--
-- This script is useful for:
-- - Testing the database structure
-- - Populating sample data for development
-- - Previewing recipes without authentication
--
-- To make these users functional:
-- 1. After running this script, create users in Supabase Auth (Dashboard > Authentication > Users)
-- 2. Update the UUIDs in this script to match auth.users.id values
-- 3. Re-run the script (or manually update each user's id)
-- 
-- OR use the create_sample_users.py script which handles both auth and profile creation
--
-- =============================================================

-- Temporarily disable RLS to allow inserts (optional, service role already bypasses RLS)
-- ALTER TABLE users DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE recipes DISABLE ROW LEVEL SECURITY;

-- ============================================
-- SAMPLE USERS (with placeholder UUIDs)
-- ============================================
-- These UUIDs are placeholders - users won't be able to authenticate until
-- you create corresponding entries in auth.users with matching IDs

-- User 1: Sarah Chen (sarah.chen@example.com)
INSERT INTO users (id, email, username, display_name, bio, skill_level, dietary_restrictions, cuisine_preferences, chef_score)
VALUES (
    '11111111-1111-1111-1111-111111111111'::uuid,
    'sarah.chen@example.com',
    'sarahchen',
    'Sarah Chen',
    'Home cook passionate about Asian fusion cuisine. Love experimenting with traditional recipes!',
    'intermediate',
    '[]'::jsonb,
    '["Asian", "Fusion", "Chinese"]'::jsonb,
    0.0
)
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    username = EXCLUDED.username,
    display_name = EXCLUDED.display_name,
    bio = EXCLUDED.bio,
    skill_level = EXCLUDED.skill_level,
    dietary_restrictions = EXCLUDED.dietary_restrictions,
    cuisine_preferences = EXCLUDED.cuisine_preferences;

-- User 2: Marcus Johnson (marcus.j@example.com)
INSERT INTO users (id, email, username, display_name, bio, skill_level, dietary_restrictions, cuisine_preferences, chef_score)
VALUES (
    '22222222-2222-2222-2222-222222222222'::uuid,
    'marcus.j@example.com',
    'marcusj',
    'Marcus Johnson',
    'BBQ enthusiast and grilling master. Always ready for a cookout!',
    'advanced',
    '[]'::jsonb,
    '["American", "BBQ", "Southern"]'::jsonb,
    0.0
)
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    username = EXCLUDED.username,
    display_name = EXCLUDED.display_name,
    bio = EXCLUDED.bio,
    skill_level = EXCLUDED.skill_level,
    dietary_restrictions = EXCLUDED.dietary_restrictions,
    cuisine_preferences = EXCLUDED.cuisine_preferences;

-- User 3: Emma Rodriguez (emma.rodriguez@example.com)
INSERT INTO users (id, email, username, display_name, bio, skill_level, dietary_restrictions, cuisine_preferences, chef_score)
VALUES (
    '33333333-3333-3333-3333-333333333333'::uuid,
    'emma.rodriguez@example.com',
    'emmarod',
    'Emma Rodriguez',
    'Vegetarian chef specializing in healthy, plant-based meals. Food photographer on the side!',
    'intermediate',
    '["Vegetarian"]'::jsonb,
    '["Mediterranean", "Mexican", "Vegetarian"]'::jsonb,
    0.0
)
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    username = EXCLUDED.username,
    display_name = EXCLUDED.display_name,
    bio = EXCLUDED.bio,
    skill_level = EXCLUDED.skill_level,
    dietary_restrictions = EXCLUDED.dietary_restrictions,
    cuisine_preferences = EXCLUDED.cuisine_preferences;

-- User 4: James Wilson (james.wilson@example.com)
INSERT INTO users (id, email, username, display_name, bio, skill_level, dietary_restrictions, cuisine_preferences, chef_score)
VALUES (
    '44444444-4444-4444-4444-444444444444'::uuid,
    'james.wilson@example.com',
    'jamesw',
    'James Wilson',
    'Professional chef sharing restaurant-quality recipes for home cooks.',
    'advanced',
    '[]'::jsonb,
    '["French", "Italian", "Contemporary"]'::jsonb,
    0.0
)
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    username = EXCLUDED.username,
    display_name = EXCLUDED.display_name,
    bio = EXCLUDED.bio,
    skill_level = EXCLUDED.skill_level,
    dietary_restrictions = EXCLUDED.dietary_restrictions,
    cuisine_preferences = EXCLUDED.cuisine_preferences;

-- User 5: Priya Patel (priya.patel@example.com)
INSERT INTO users (id, email, username, display_name, bio, skill_level, dietary_restrictions, cuisine_preferences, chef_score)
VALUES (
    '55555555-5555-5555-5555-555555555555'::uuid,
    'priya.patel@example.com',
    'priyap',
    'Priya Patel',
    'Sharing authentic Indian family recipes passed down through generations.',
    'advanced',
    '[]'::jsonb,
    '["Indian", "Vegetarian", "Vegan"]'::jsonb,
    0.0
)
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    username = EXCLUDED.username,
    display_name = EXCLUDED.display_name,
    bio = EXCLUDED.bio,
    skill_level = EXCLUDED.skill_level,
    dietary_restrictions = EXCLUDED.dietary_restrictions,
    cuisine_preferences = EXCLUDED.cuisine_preferences;

-- User 6: David Kim (david.kim@example.com)
INSERT INTO users (id, email, username, display_name, bio, skill_level, dietary_restrictions, cuisine_preferences, chef_score)
VALUES (
    '66666666-6666-6666-6666-666666666666'::uuid,
    'david.kim@example.com',
    'davidkim',
    'David Kim',
    'Korean food lover and meal prep enthusiast. Quick and easy recipes for busy weekdays!',
    'intermediate',
    '[]'::jsonb,
    '["Korean", "Asian", "Meal Prep"]'::jsonb,
    0.0
)
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    username = EXCLUDED.username,
    display_name = EXCLUDED.display_name,
    bio = EXCLUDED.bio,
    skill_level = EXCLUDED.skill_level,
    dietary_restrictions = EXCLUDED.dietary_restrictions,
    cuisine_preferences = EXCLUDED.cuisine_preferences;

-- User 7: Maria Garcia (maria.garcia@example.com)
INSERT INTO users (id, email, username, display_name, bio, skill_level, dietary_restrictions, cuisine_preferences, chef_score)
VALUES (
    '77777777-7777-7777-7777-777777777777'::uuid,
    'maria.garcia@example.com',
    'mariag',
    'Maria Garcia',
    'Passionate about Spanish and Latin American cuisine. Love sharing traditional dishes!',
    'intermediate',
    '[]'::jsonb,
    '["Spanish", "Mexican", "Latin American"]'::jsonb,
    0.0
)
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    username = EXCLUDED.username,
    display_name = EXCLUDED.display_name,
    bio = EXCLUDED.bio,
    skill_level = EXCLUDED.skill_level,
    dietary_restrictions = EXCLUDED.dietary_restrictions,
    cuisine_preferences = EXCLUDED.cuisine_preferences;

-- User 8: Alex Thompson (alex.thompson@example.com)
INSERT INTO users (id, email, username, display_name, bio, skill_level, dietary_restrictions, cuisine_preferences, chef_score)
VALUES (
    '88888888-8888-8888-8888-888888888888'::uuid,
    'alex.thompson@example.com',
    'alext',
    'Alex Thompson',
    'Beginner cook learning to make delicious meals on a budget. Sharing my journey!',
    'beginner',
    '[]'::jsonb,
    '["American", "Comfort Food"]'::jsonb,
    0.0
)
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    username = EXCLUDED.username,
    display_name = EXCLUDED.display_name,
    bio = EXCLUDED.bio,
    skill_level = EXCLUDED.skill_level,
    dietary_restrictions = EXCLUDED.dietary_restrictions,
    cuisine_preferences = EXCLUDED.cuisine_preferences;

-- User 9: Sophie Martin (sophie.martin@example.com)
INSERT INTO users (id, email, username, display_name, bio, skill_level, dietary_restrictions, cuisine_preferences, chef_score)
VALUES (
    '99999999-9999-9999-9999-999999999999'::uuid,
    'sophie.martin@example.com',
    'sophiem',
    'Sophie Martin',
    'Baking enthusiast and dessert lover. Specializing in French pastries and cakes.',
    'advanced',
    '[]'::jsonb,
    '["French", "Baking", "Desserts"]'::jsonb,
    0.0
)
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    username = EXCLUDED.username,
    display_name = EXCLUDED.display_name,
    bio = EXCLUDED.bio,
    skill_level = EXCLUDED.skill_level,
    dietary_restrictions = EXCLUDED.dietary_restrictions,
    cuisine_preferences = EXCLUDED.cuisine_preferences;

-- User 10: Ryan O'Connor (ryan.oconnor@example.com)
INSERT INTO users (id, email, username, display_name, bio, skill_level, dietary_restrictions, cuisine_preferences, chef_score)
VALUES (
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid,
    'ryan.oconnor@example.com',
    'ryano',
    'Ryan O''Connor',
    'Fitness-focused meal prep recipes. High protein, nutritious, and delicious!',
    'intermediate',
    '[]'::jsonb,
    '["Healthy", "High Protein", "Meal Prep"]'::jsonb,
    0.0
)
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    username = EXCLUDED.username,
    display_name = EXCLUDED.display_name,
    bio = EXCLUDED.bio,
    skill_level = EXCLUDED.skill_level,
    dietary_restrictions = EXCLUDED.dietary_restrictions,
    cuisine_preferences = EXCLUDED.cuisine_preferences;

-- ============================================
-- SAMPLE RECIPES (using placeholder UUIDs)
-- ============================================
-- Note: These recipes will be visible but users can't interact with them
-- until auth.users entries are created with matching IDs

-- Sarah Chen's Recipes (3 recipes)
INSERT INTO recipes (user_id, title, description, ingredients, instructions, prep_time, cook_time, total_time, servings, difficulty_level, cuisine_type, meal_type, tags, source_type, is_public)
VALUES (
    '11111111-1111-1111-1111-111111111111'::uuid,
    'Mapo Tofu',
    'A spicy Sichuan dish featuring silky tofu in a flavorful chili and bean sauce. Perfect comfort food!',
    '[
        {"name": "Firm tofu", "quantity": "1", "unit": "block", "category": "proteins"},
        {"name": "Ground pork", "quantity": "200", "unit": "g", "category": "proteins"},
        {"name": "Doubanjiang", "quantity": "2", "unit": "tbsp", "category": "spices"},
        {"name": "Garlic", "quantity": "3", "unit": "cloves", "category": "produce"},
        {"name": "Ginger", "quantity": "1", "unit": "tbsp", "category": "produce"},
        {"name": "Green onions", "quantity": "2", "unit": "stalks", "category": "produce"},
        {"name": "Sichuan peppercorns", "quantity": "1", "unit": "tsp", "category": "spices"},
        {"name": "Soy sauce", "quantity": "1", "unit": "tbsp", "category": "condiments"},
        {"name": "Chicken stock", "quantity": "200", "unit": "ml", "category": "liquids"},
        {"name": "Cornstarch", "quantity": "1", "unit": "tbsp", "category": "thickeners"}
    ]'::jsonb,
    '[
        {"step_number": 1, "instruction": "Cut tofu into 1-inch cubes and set aside"},
        {"step_number": 2, "instruction": "Heat oil in a wok and add ground pork, cook until browned"},
        {"step_number": 3, "instruction": "Add doubanjiang, garlic, and ginger, stir-fry for 1 minute"},
        {"step_number": 4, "instruction": "Add chicken stock and bring to a boil"},
        {"step_number": 5, "instruction": "Gently add tofu cubes and simmer for 5 minutes"},
        {"step_number": 6, "instruction": "Mix cornstarch with water and add to thicken sauce"},
        {"step_number": 7, "instruction": "Garnish with green onions and Sichuan peppercorns"}
    ]'::jsonb,
    15, 15, 30, 4, 'medium', 'Chinese', 'dinner', ARRAY['spicy', 'tofu', 'sichuan', 'comfort food'], 'manual', true
),
(
    '11111111-1111-1111-1111-111111111111'::uuid,
    'Chicken Teriyaki Bowl',
    'Classic Japanese-inspired teriyaki chicken served over steamed rice with vegetables.',
    '[
        {"name": "Chicken thighs", "quantity": "500", "unit": "g", "category": "proteins"},
        {"name": "Soy sauce", "quantity": "60", "unit": "ml", "category": "condiments"},
        {"name": "Mirin", "quantity": "60", "unit": "ml", "category": "condiments"},
        {"name": "Sugar", "quantity": "2", "unit": "tbsp", "category": "sweeteners"},
        {"name": "Ginger", "quantity": "1", "unit": "tbsp", "category": "produce"},
        {"name": "Garlic", "quantity": "2", "unit": "cloves", "category": "produce"},
        {"name": "Rice", "quantity": "2", "unit": "cups", "category": "grains"},
        {"name": "Broccoli", "quantity": "200", "unit": "g", "category": "produce"},
        {"name": "Carrots", "quantity": "2", "unit": "medium", "category": "produce"}
    ]'::jsonb,
    '[
        {"step_number": 1, "instruction": "Mix soy sauce, mirin, sugar, ginger, and garlic to make teriyaki sauce"},
        {"step_number": 2, "instruction": "Cook chicken thighs in a pan until golden, then add sauce"},
        {"step_number": 3, "instruction": "Simmer until sauce thickens and glazes the chicken"},
        {"step_number": 4, "instruction": "Cook rice according to package instructions"},
        {"step_number": 5, "instruction": "Steam broccoli and carrots until tender"},
        {"step_number": 6, "instruction": "Serve chicken over rice with vegetables on the side"}
    ]'::jsonb,
    10, 25, 35, 4, 'easy', 'Japanese', 'dinner', ARRAY['teriyaki', 'chicken', 'rice bowl', 'asian'], 'manual', true
),
(
    '11111111-1111-1111-1111-111111111111'::uuid,
    'Pork Belly Bao Buns',
    'Soft steamed bao buns filled with tender braised pork belly, pickled vegetables, and hoisin sauce.',
    '[
        {"name": "Pork belly", "quantity": "500", "unit": "g", "category": "proteins"},
        {"name": "Bao bun dough", "quantity": "300", "unit": "g", "category": "grains"},
        {"name": "Hoisin sauce", "quantity": "4", "unit": "tbsp", "category": "condiments"},
        {"name": "Cucumber", "quantity": "1", "unit": "medium", "category": "produce"},
        {"name": "Carrots", "quantity": "2", "unit": "medium", "category": "produce"},
        {"name": "Rice vinegar", "quantity": "2", "unit": "tbsp", "category": "condiments"},
        {"name": "Soy sauce", "quantity": "3", "unit": "tbsp", "category": "condiments"},
        {"name": "Star anise", "quantity": "2", "unit": "pieces", "category": "spices"},
        {"name": "Cinnamon stick", "quantity": "1", "unit": "piece", "category": "spices"}
    ]'::jsonb,
    '[
        {"step_number": 1, "instruction": "Braise pork belly with soy sauce, star anise, and cinnamon for 2 hours until tender"},
        {"step_number": 2, "instruction": "Prepare bao bun dough and steam buns until puffy"},
        {"step_number": 3, "instruction": "Pickle cucumber and carrots in rice vinegar"},
        {"step_number": 4, "instruction": "Slice braised pork belly"},
        {"step_number": 5, "instruction": "Fill buns with pork, pickled vegetables, and hoisin sauce"}
    ]'::jsonb,
    30, 120, 150, 6, 'hard', 'Chinese', 'dinner', ARRAY['bao buns', 'pork belly', 'steamed', 'asian fusion'], 'manual', true
);

-- Continue with other users' recipes...
-- (I'll include just a few more examples to keep the file manageable)

-- Marcus Johnson's Recipes (2 recipes)
INSERT INTO recipes (user_id, title, description, ingredients, instructions, prep_time, cook_time, total_time, servings, difficulty_level, cuisine_type, meal_type, tags, source_type, is_public)
VALUES (
    '22222222-2222-2222-2222-222222222222'::uuid,
    'Classic Smoked Brisket',
    'Texas-style brisket smoked low and slow for 12 hours. Tender, juicy, and packed with flavor.',
    '[
        {"name": "Beef brisket", "quantity": "5", "unit": "kg", "category": "proteins"},
        {"name": "Kosher salt", "quantity": "1/4", "unit": "cup", "category": "spices"},
        {"name": "Black pepper", "quantity": "1/4", "unit": "cup", "category": "spices"},
        {"name": "Garlic powder", "quantity": "2", "unit": "tbsp", "category": "spices"},
        {"name": "Onion powder", "quantity": "2", "unit": "tbsp", "category": "spices"},
        {"name": "Paprika", "quantity": "2", "unit": "tbsp", "category": "spices"},
        {"name": "Wood chips", "quantity": "500", "unit": "g", "category": "other"},
        {"name": "BBQ sauce", "quantity": "1", "unit": "cup", "category": "condiments"}
    ]'::jsonb,
    '[
        {"step_number": 1, "instruction": "Trim brisket fat cap to 1/4 inch thickness"},
        {"step_number": 2, "instruction": "Mix all dry spices to create rub"},
        {"step_number": 3, "instruction": "Apply rub liberally to all sides of brisket"},
        {"step_number": 4, "instruction": "Let brisket rest in refrigerator overnight"},
        {"step_number": 5, "instruction": "Preheat smoker to 225°F (107°C)"},
        {"step_number": 6, "instruction": "Smoke brisket for 12 hours, maintaining temperature"},
        {"step_number": 7, "instruction": "Wrap in butcher paper when internal temp reaches 165°F"},
        {"step_number": 8, "instruction": "Continue cooking until internal temp reaches 203°F"},
        {"step_number": 9, "instruction": "Rest for 2 hours before slicing against the grain"}
    ]'::jsonb,
    60, 720, 780, 12, 'hard', 'American', 'dinner', ARRAY['bbq', 'brisket', 'smoked', 'texas'], 'manual', true
),
(
    '22222222-2222-2222-2222-222222222222'::uuid,
    'BBQ Pulled Pork Sliders',
    'Slow-cooked pulled pork with homemade BBQ sauce, perfect for parties and game day!',
    '[
        {"name": "Pork shoulder", "quantity": "2", "unit": "kg", "category": "proteins"},
        {"name": "Brown sugar", "quantity": "2", "unit": "tbsp", "category": "sweeteners"},
        {"name": "Paprika", "quantity": "2", "unit": "tbsp", "category": "spices"},
        {"name": "Cumin", "quantity": "1", "unit": "tsp", "category": "spices"},
        {"name": "Garlic powder", "quantity": "1", "unit": "tbsp", "category": "spices"},
        {"name": "Apple cider vinegar", "quantity": "1/4", "unit": "cup", "category": "condiments"},
        {"name": "Ketchup", "quantity": "1", "unit": "cup", "category": "condiments"},
        {"name": "Worcestershire sauce", "quantity": "2", "unit": "tbsp", "category": "condiments"},
        {"name": "Slider buns", "quantity": "12", "unit": "pieces", "category": "grains"},
        {"name": "Coleslaw", "quantity": "300", "unit": "g", "category": "produce"}
    ]'::jsonb,
    '[
        {"step_number": 1, "instruction": "Mix dry spices and rub all over pork shoulder"},
        {"step_number": 2, "instruction": "Cook pork shoulder in slow cooker on low for 8 hours"},
        {"step_number": 3, "instruction": "Mix ketchup, vinegar, and Worcestershire for BBQ sauce"},
        {"step_number": 4, "instruction": "Shred pork with forks when tender"},
        {"step_number": 5, "instruction": "Mix shredded pork with BBQ sauce"},
        {"step_number": 6, "instruction": "Serve on slider buns with coleslaw"}
    ]'::jsonb,
    20, 480, 500, 12, 'medium', 'American', 'dinner', ARRAY['bbq', 'pulled pork', 'sliders', 'party food'], 'manual', true
);

-- Note: For brevity, I've included 5 recipes total. 
-- You can copy the remaining recipes from sample_data_import.sql if needed,
-- or run the full script from that file after creating auth.users entries.

-- Re-enable RLS if you disabled it (optional)
-- ALTER TABLE users ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE recipes ENABLE ROW LEVEL SECURITY;

-- ============================================
-- NEXT STEPS TO MAKE USERS FUNCTIONAL:
-- ============================================
-- 
-- Option 1: Create auth users via Supabase Dashboard
--   1. Go to Authentication > Users > Add User
--   2. For each email, create a user with password "TestPassword123!"
--   3. Note the UUID for each user
--   4. Update the UUIDs in this script and re-run
--
-- Option 2: Use create_sample_users.py script
--   1. Install: pip install supabase
--   2. Set environment variables: SUPABASE_URL, SUPABASE_SERVICE_KEY
--   3. Run: python create_sample_users.py
--   4. This creates both auth.users and public.users entries automatically
--
-- Option 3: Use Supabase Admin API directly
--   See sample_user_credentials.txt for curl examples

