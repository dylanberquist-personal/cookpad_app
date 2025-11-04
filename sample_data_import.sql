-- Sample Data Import for Cookpad App
-- This script creates sample users and recipes
-- 
-- ⚠️ IMPORTANT: You must create users in Supabase Auth first, then run this script
-- The UUIDs in this script must match the auth.users.id values
-- 
-- What happens if you run this WITHOUT creating auth.users first?
-- ✅ Data will be inserted (if run with service role)
-- ❌ Users CANNOT log in or authenticate
-- ❌ Users cannot access their own data due to RLS policies
-- ❌ Recipes will be visible but users can't interact as owners
-- 
-- To use this script properly:
-- 1. First, create users in Supabase Auth using the Supabase Dashboard or Admin API
--    OR use the create_sample_users.py script which does both
-- 2. Get the UUID for each user from auth.users
-- 3. Replace the UUIDs in this script with the actual auth.users.id values
-- 4. Run this script in Supabase SQL Editor with admin privileges
--
-- Alternative: See sample_data_import_with_placeholders.sql for a version that
-- works with placeholder UUIDs (but users still won't be able to authenticate)

-- ============================================
-- SAMPLE USERS
-- ============================================
-- Note: Replace these UUIDs with actual auth.users.id values after creating users in Auth

-- User 1: Sarah Chen (sarah.chen@example.com)
INSERT INTO users (id, email, username, display_name, bio, skill_level, dietary_restrictions, cuisine_preferences, chef_score)
VALUES (
    '11111111-1111-1111-1111-111111111111'::uuid,  -- REPLACE with actual auth.users.id
    'sarah.chen@example.com',
    'sarahchen',
    'Sarah Chen',
    'Home cook passionate about Asian fusion cuisine. Love experimenting with traditional recipes!',
    'intermediate',
    '[]'::jsonb,
    '["Asian", "Fusion", "Chinese"]'::jsonb,
    0.0
);

-- User 2: Marcus Johnson (marcus.j@example.com)
INSERT INTO users (id, email, username, display_name, bio, skill_level, dietary_restrictions, cuisine_preferences, chef_score)
VALUES (
    '22222222-2222-2222-2222-222222222222'::uuid,  -- REPLACE with actual auth.users.id
    'marcus.j@example.com',
    'marcusj',
    'Marcus Johnson',
    'BBQ enthusiast and grilling master. Always ready for a cookout!',
    'advanced',
    '[]'::jsonb,
    '["American", "BBQ", "Southern"]'::jsonb,
    0.0
);

-- User 3: Emma Rodriguez (emma.rodriguez@example.com)
INSERT INTO users (id, email, username, display_name, bio, skill_level, dietary_restrictions, cuisine_preferences, chef_score)
VALUES (
    '33333333-3333-3333-3333-333333333333'::uuid,  -- REPLACE with actual auth.users.id
    'emma.rodriguez@example.com',
    'emmarod',
    'Emma Rodriguez',
    'Vegetarian chef specializing in healthy, plant-based meals. Food photographer on the side!',
    'intermediate',
    '["Vegetarian"]'::jsonb,
    '["Mediterranean", "Mexican", "Vegetarian"]'::jsonb,
    0.0
);

-- User 4: James Wilson (james.wilson@example.com)
INSERT INTO users (id, email, username, display_name, bio, skill_level, dietary_restrictions, cuisine_preferences, chef_score)
VALUES (
    '44444444-4444-4444-4444-444444444444'::uuid,  -- REPLACE with actual auth.users.id
    'james.wilson@example.com',
    'jamesw',
    'James Wilson',
    'Professional chef sharing restaurant-quality recipes for home cooks.',
    'advanced',
    '[]'::jsonb,
    '["French", "Italian", "Contemporary"]'::jsonb,
    0.0
);

-- User 5: Priya Patel (priya.patel@example.com)
INSERT INTO users (id, email, username, display_name, bio, skill_level, dietary_restrictions, cuisine_preferences, chef_score)
VALUES (
    '55555555-5555-5555-5555-555555555555'::uuid,  -- REPLACE with actual auth.users.id
    'priya.patel@example.com',
    'priyap',
    'Priya Patel',
    'Sharing authentic Indian family recipes passed down through generations.',
    'advanced',
    '[]'::jsonb,
    '["Indian", "Vegetarian", "Vegan"]'::jsonb,
    0.0
);

-- User 6: David Kim (david.kim@example.com)
INSERT INTO users (id, email, username, display_name, bio, skill_level, dietary_restrictions, cuisine_preferences, chef_score)
VALUES (
    '66666666-6666-6666-6666-666666666666'::uuid,  -- REPLACE with actual auth.users.id
    'david.kim@example.com',
    'davidkim',
    'David Kim',
    'Korean food lover and meal prep enthusiast. Quick and easy recipes for busy weekdays!',
    'intermediate',
    '[]'::jsonb,
    '["Korean", "Asian", "Meal Prep"]'::jsonb,
    0.0
);

-- User 7: Maria Garcia (maria.garcia@example.com)
INSERT INTO users (id, email, username, display_name, bio, skill_level, dietary_restrictions, cuisine_preferences, chef_score)
VALUES (
    '77777777-7777-7777-7777-777777777777'::uuid,  -- REPLACE with actual auth.users.id
    'maria.garcia@example.com',
    'mariag',
    'Maria Garcia',
    'Passionate about Spanish and Latin American cuisine. Love sharing traditional dishes!',
    'intermediate',
    '[]'::jsonb,
    '["Spanish", "Mexican", "Latin American"]'::jsonb,
    0.0
);

-- User 8: Alex Thompson (alex.thompson@example.com)
INSERT INTO users (id, email, username, display_name, bio, skill_level, dietary_restrictions, cuisine_preferences, chef_score)
VALUES (
    '88888888-8888-8888-8888-888888888888'::uuid,  -- REPLACE with actual auth.users.id
    'alex.thompson@example.com',
    'alext',
    'Alex Thompson',
    'Beginner cook learning to make delicious meals on a budget. Sharing my journey!',
    'beginner',
    '[]'::jsonb,
    '["American", "Comfort Food"]'::jsonb,
    0.0
);

-- User 9: Sophie Martin (sophie.martin@example.com)
INSERT INTO users (id, email, username, display_name, bio, skill_level, dietary_restrictions, cuisine_preferences, chef_score)
VALUES (
    '99999999-9999-9999-9999-999999999999'::uuid,  -- REPLACE with actual auth.users.id
    'sophie.martin@example.com',
    'sophiem',
    'Sophie Martin',
    'Baking enthusiast and dessert lover. Specializing in French pastries and cakes.',
    'advanced',
    '[]'::jsonb,
    '["French", "Baking", "Desserts"]'::jsonb,
    0.0
);

-- User 10: Ryan O''Connor (ryan.oconnor@example.com)
INSERT INTO users (id, email, username, display_name, bio, skill_level, dietary_restrictions, cuisine_preferences, chef_score)
VALUES (
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid,  -- REPLACE with actual auth.users.id
    'ryan.oconnor@example.com',
    'ryano',
    'Ryan O''Connor',
    'Fitness-focused meal prep recipes. High protein, nutritious, and delicious!',
    'intermediate',
    '[]'::jsonb,
    '["Healthy", "High Protein", "Meal Prep"]'::jsonb,
    0.0
);

-- ============================================
-- SAMPLE RECIPES
-- ============================================

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
);

INSERT INTO recipes (user_id, title, description, ingredients, instructions, prep_time, cook_time, total_time, servings, difficulty_level, cuisine_type, meal_type, tags, source_type, is_public)
VALUES (
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
);

INSERT INTO recipes (user_id, title, description, ingredients, instructions, prep_time, cook_time, total_time, servings, difficulty_level, cuisine_type, meal_type, tags, source_type, is_public)
VALUES (
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
);

INSERT INTO recipes (user_id, title, description, ingredients, instructions, prep_time, cook_time, total_time, servings, difficulty_level, cuisine_type, meal_type, tags, source_type, is_public)
VALUES (
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

-- Emma Rodriguez's Recipes (3 recipes)
INSERT INTO recipes (user_id, title, description, ingredients, instructions, prep_time, cook_time, total_time, servings, difficulty_level, cuisine_type, meal_type, tags, source_type, is_public)
VALUES (
    '33333333-3333-3333-3333-333333333333'::uuid,
    'Mediterranean Quinoa Bowl',
    'A healthy and colorful bowl with quinoa, roasted vegetables, chickpeas, and tahini dressing.',
    '[
        {"name": "Quinoa", "quantity": "1", "unit": "cup", "category": "grains"},
        {"name": "Chickpeas", "quantity": "400", "unit": "g", "category": "proteins"},
        {"name": "Bell peppers", "quantity": "2", "unit": "medium", "category": "produce"},
        {"name": "Zucchini", "quantity": "2", "unit": "medium", "category": "produce"},
        {"name": "Cherry tomatoes", "quantity": "200", "unit": "g", "category": "produce"},
        {"name": "Red onion", "quantity": "1", "unit": "medium", "category": "produce"},
        {"name": "Tahini", "quantity": "3", "unit": "tbsp", "category": "condiments"},
        {"name": "Lemon juice", "quantity": "2", "unit": "tbsp", "category": "condiments"},
        {"name": "Olive oil", "quantity": "3", "unit": "tbsp", "category": "oils"},
        {"name": "Feta cheese", "quantity": "100", "unit": "g", "category": "dairy"}
    ]'::jsonb,
    '[
        {"step_number": 1, "instruction": "Cook quinoa according to package instructions"},
        {"step_number": 2, "instruction": "Drain and rinse chickpeas, then roast with olive oil for 20 minutes"},
        {"step_number": 3, "instruction": "Chop vegetables and roast in oven at 400°F for 25 minutes"},
        {"step_number": 4, "instruction": "Mix tahini, lemon juice, and water to make dressing"},
        {"step_number": 5, "instruction": "Assemble bowl with quinoa, roasted vegetables, chickpeas, and feta"},
        {"step_number": 6, "instruction": "Drizzle with tahini dressing and serve"}
    ]'::jsonb,
    20, 30, 50, 4, 'easy', 'Mediterranean', 'lunch', ARRAY['vegetarian', 'healthy', 'quinoa', 'mediterranean'], 'manual', true
);

INSERT INTO recipes (user_id, title, description, ingredients, instructions, prep_time, cook_time, total_time, servings, difficulty_level, cuisine_type, meal_type, tags, source_type, is_public)
VALUES (
    '33333333-3333-3333-3333-333333333333'::uuid,
    'Black Bean Tacos',
    'Delicious vegetarian tacos with seasoned black beans, fresh salsa, and avocado.',
    '[
        {"name": "Black beans", "quantity": "400", "unit": "g", "category": "proteins"},
        {"name": "Corn tortillas", "quantity": "8", "unit": "pieces", "category": "grains"},
        {"name": "Avocado", "quantity": "2", "unit": "medium", "category": "produce"},
        {"name": "Tomatoes", "quantity": "2", "unit": "medium", "category": "produce"},
        {"name": "Red onion", "quantity": "1/2", "unit": "medium", "category": "produce"},
        {"name": "Cilantro", "quantity": "1/4", "unit": "cup", "category": "produce"},
        {"name": "Lime", "quantity": "2", "unit": "pieces", "category": "produce"},
        {"name": "Cumin", "quantity": "1", "unit": "tsp", "category": "spices"},
        {"name": "Chili powder", "quantity": "1", "unit": "tsp", "category": "spices"},
        {"name": "Garlic", "quantity": "2", "unit": "cloves", "category": "produce"}
    ]'::jsonb,
    '[
        {"step_number": 1, "instruction": "Drain and rinse black beans"},
        {"step_number": 2, "instruction": "Heat beans in a pan with cumin, chili powder, and minced garlic"},
        {"step_number": 3, "instruction": "Dice tomatoes, red onion, and cilantro for salsa"},
        {"step_number": 4, "instruction": "Mix salsa ingredients with lime juice and salt"},
        {"step_number": 5, "instruction": "Slice avocado"},
        {"step_number": 6, "instruction": "Warm tortillas and fill with beans, salsa, and avocado"}
    ]'::jsonb,
    15, 10, 25, 4, 'easy', 'Mexican', 'dinner', ARRAY['vegetarian', 'tacos', 'black beans', 'mexican'], 'manual', true
);

INSERT INTO recipes (user_id, title, description, ingredients, instructions, prep_time, cook_time, total_time, servings, difficulty_level, cuisine_type, meal_type, tags, source_type, is_public)
VALUES (
    '33333333-3333-3333-3333-333333333333'::uuid,
    'Veggie Pad Thai',
    'A vegetarian version of the classic Thai noodle dish with tofu and vegetables.',
    '[
        {"name": "Rice noodles", "quantity": "200", "unit": "g", "category": "grains"},
        {"name": "Firm tofu", "quantity": "300", "unit": "g", "category": "proteins"},
        {"name": "Bean sprouts", "quantity": "200", "unit": "g", "category": "produce"},
        {"name": "Carrots", "quantity": "2", "unit": "medium", "category": "produce"},
        {"name": "Green onions", "quantity": "3", "unit": "stalks", "category": "produce"},
        {"name": "Tamarind paste", "quantity": "2", "unit": "tbsp", "category": "condiments"},
        {"name": "Fish sauce substitute", "quantity": "2", "unit": "tbsp", "category": "condiments"},
        {"name": "Brown sugar", "quantity": "2", "unit": "tbsp", "category": "sweeteners"},
        {"name": "Lime", "quantity": "2", "unit": "pieces", "category": "produce"},
        {"name": "Peanuts", "quantity": "50", "unit": "g", "category": "nuts"}
    ]'::jsonb,
    '[
        {"step_number": 1, "instruction": "Soak rice noodles in warm water for 30 minutes"},
        {"step_number": 2, "instruction": "Cut tofu into cubes and pan-fry until golden"},
        {"step_number": 3, "instruction": "Mix tamarind, fish sauce substitute, and brown sugar for sauce"},
        {"step_number": 4, "instruction": "Julienne carrots and chop green onions"},
        {"step_number": 5, "instruction": "Stir-fry noodles with sauce and vegetables"},
        {"step_number": 6, "instruction": "Add tofu and bean sprouts, toss to combine"},
        {"step_number": 7, "instruction": "Garnish with peanuts, lime wedges, and green onions"}
    ]'::jsonb,
    20, 15, 35, 4, 'medium', 'Thai', 'dinner', ARRAY['vegetarian', 'pad thai', 'thai', 'noodles'], 'manual', true
);

-- James Wilson's Recipes (2 recipes)
INSERT INTO recipes (user_id, title, description, ingredients, instructions, prep_time, cook_time, total_time, servings, difficulty_level, cuisine_type, meal_type, tags, source_type, is_public)
VALUES (
    '44444444-4444-4444-4444-444444444444'::uuid,
    'Coq au Vin',
    'Classic French braised chicken cooked in red wine with mushrooms, onions, and bacon.',
    '[
        {"name": "Chicken thighs", "quantity": "1", "unit": "kg", "category": "proteins"},
        {"name": "Red wine", "quantity": "750", "unit": "ml", "category": "liquids"},
        {"name": "Bacon", "quantity": "200", "unit": "g", "category": "proteins"},
        {"name": "Pearl onions", "quantity": "300", "unit": "g", "category": "produce"},
        {"name": "Mushrooms", "quantity": "300", "unit": "g", "category": "produce"},
        {"name": "Carrots", "quantity": "3", "unit": "medium", "category": "produce"},
        {"name": "Garlic", "quantity": "4", "unit": "cloves", "category": "produce"},
        {"name": "Thyme", "quantity": "2", "unit": "tbsp", "category": "produce"},
        {"name": "Bay leaves", "quantity": "2", "unit": "pieces", "category": "spices"},
        {"name": "Chicken stock", "quantity": "500", "unit": "ml", "category": "liquids"},
        {"name": "Butter", "quantity": "3", "unit": "tbsp", "category": "dairy"}
    ]'::jsonb,
    '[
        {"step_number": 1, "instruction": "Marinate chicken in red wine with herbs overnight"},
        {"step_number": 2, "instruction": "Render bacon in a Dutch oven, then remove"},
        {"step_number": 3, "instruction": "Brown chicken pieces in bacon fat"},
        {"step_number": 4, "instruction": "Add vegetables and cook until softened"},
        {"step_number": 5, "instruction": "Add wine, stock, and herbs, bring to simmer"},
        {"step_number": 6, "instruction": "Cover and braise in 325°F oven for 1.5 hours"},
        {"step_number": 7, "instruction": "Remove chicken and reduce sauce"},
        {"step_number": 8, "instruction": "Finish sauce with butter and serve over chicken"}
    ]'::jsonb,
    30, 90, 120, 6, 'hard', 'French', 'dinner', ARRAY['french', 'braised', 'wine', 'classic'], 'manual', true
);

INSERT INTO recipes (user_id, title, description, ingredients, instructions, prep_time, cook_time, total_time, servings, difficulty_level, cuisine_type, meal_type, tags, source_type, is_public)
VALUES (
    '44444444-4444-4444-4444-444444444444'::uuid,
    'Beef Bourguignon',
    'Traditional French stew with beef braised in red wine, perfect for a special occasion.',
    '[
        {"name": "Beef chuck", "quantity": "1.5", "unit": "kg", "category": "proteins"},
        {"name": "Red wine", "quantity": "750", "unit": "ml", "category": "liquids"},
        {"name": "Bacon", "quantity": "150", "unit": "g", "category": "proteins"},
        {"name": "Pearl onions", "quantity": "200", "unit": "g", "category": "produce"},
        {"name": "Mushrooms", "quantity": "300", "unit": "g", "category": "produce"},
        {"name": "Carrots", "quantity": "4", "unit": "medium", "category": "produce"},
        {"name": "Garlic", "quantity": "4", "unit": "cloves", "category": "produce"},
        {"name": "Tomato paste", "quantity": "2", "unit": "tbsp", "category": "condiments"},
        {"name": "Beef stock", "quantity": "500", "unit": "ml", "category": "liquids"},
        {"name": "Thyme", "quantity": "1", "unit": "tbsp", "category": "produce"},
        {"name": "Bay leaves", "quantity": "2", "unit": "pieces", "category": "spices"}
    ]'::jsonb,
    '[
        {"step_number": 1, "instruction": "Cut beef into 2-inch cubes and marinate in wine overnight"},
        {"step_number": 2, "instruction": "Pat beef dry and season, then brown in batches"},
        {"step_number": 3, "instruction": "Cook bacon until crisp, remove and set aside"},
        {"step_number": 4, "instruction": "Sauté vegetables in bacon fat"},
        {"step_number": 5, "instruction": "Add tomato paste and cook for 1 minute"},
        {"step_number": 6, "instruction": "Add wine, stock, herbs, and beef, bring to boil"},
        {"step_number": 7, "instruction": "Cover and braise in 325°F oven for 3 hours"},
        {"step_number": 8, "instruction": "Sauté mushrooms and onions separately, add to stew"},
        {"step_number": 9, "instruction": "Season and serve with crusty bread"}
    ]'::jsonb,
    45, 180, 225, 8, 'hard', 'French', 'dinner', ARRAY['french', 'stew', 'beef', 'wine'], 'manual', true
);

-- Priya Patel's Recipes (3 recipes)
INSERT INTO recipes (user_id, title, description, ingredients, instructions, prep_time, cook_time, total_time, servings, difficulty_level, cuisine_type, meal_type, tags, source_type, is_public)
VALUES (
    '55555555-5555-5555-5555-555555555555'::uuid,
    'Butter Chicken',
    'Creamy, rich Indian curry with tender chicken in a tomato-based sauce. A family favorite!',
    '[
        {"name": "Chicken thighs", "quantity": "800", "unit": "g", "category": "proteins"},
        {"name": "Yogurt", "quantity": "200", "unit": "ml", "category": "dairy"},
        {"name": "Garam masala", "quantity": "2", "unit": "tsp", "category": "spices"},
        {"name": "Turmeric", "quantity": "1", "unit": "tsp", "category": "spices"},
        {"name": "Cumin", "quantity": "1", "unit": "tsp", "category": "spices"},
        {"name": "Tomatoes", "quantity": "400", "unit": "g", "category": "produce"},
        {"name": "Onions", "quantity": "2", "unit": "medium", "category": "produce"},
        {"name": "Ginger", "quantity": "2", "unit": "tbsp", "category": "produce"},
        {"name": "Garlic", "quantity": "4", "unit": "cloves", "category": "produce"},
        {"name": "Heavy cream", "quantity": "200", "unit": "ml", "category": "dairy"},
        {"name": "Butter", "quantity": "4", "unit": "tbsp", "category": "dairy"}
    ]'::jsonb,
    '[
        {"step_number": 1, "instruction": "Marinate chicken in yogurt and spices for at least 2 hours"},
        {"step_number": 2, "instruction": "Grill or pan-fry chicken until cooked through"},
        {"step_number": 3, "instruction": "Blend tomatoes, onions, ginger, and garlic into a paste"},
        {"step_number": 4, "instruction": "Cook the paste in butter until oil separates"},
        {"step_number": 5, "instruction": "Add spices and cook for 2 minutes"},
        {"step_number": 6, "instruction": "Add cream and simmer sauce"},
        {"step_number": 7, "instruction": "Add chicken pieces and simmer for 10 minutes"},
        {"step_number": 8, "instruction": "Garnish with cilantro and serve with naan or rice"}
    ]'::jsonb,
    30, 40, 70, 6, 'medium', 'Indian', 'dinner', ARRAY['indian', 'curry', 'chicken', 'butter chicken'], 'manual', true
);

INSERT INTO recipes (user_id, title, description, ingredients, instructions, prep_time, cook_time, total_time, servings, difficulty_level, cuisine_type, meal_type, tags, source_type, is_public)
VALUES (
    '55555555-5555-5555-5555-555555555555'::uuid,
    'Chana Masala',
    'Flavorful chickpea curry with aromatic spices. A delicious vegetarian dish!',
    '[
        {"name": "Chickpeas", "quantity": "400", "unit": "g", "category": "proteins"},
        {"name": "Tomatoes", "quantity": "400", "unit": "g", "category": "produce"},
        {"name": "Onions", "quantity": "2", "unit": "medium", "category": "produce"},
        {"name": "Ginger", "quantity": "1", "unit": "tbsp", "category": "produce"},
        {"name": "Garlic", "quantity": "3", "unit": "cloves", "category": "produce"},
        {"name": "Cumin seeds", "quantity": "1", "unit": "tsp", "category": "spices"},
        {"name": "Coriander powder", "quantity": "2", "unit": "tsp", "category": "spices"},
        {"name": "Turmeric", "quantity": "1", "unit": "tsp", "category": "spices"},
        {"name": "Garam masala", "quantity": "1", "unit": "tsp", "category": "spices"},
        {"name": "Cilantro", "quantity": "1/4", "unit": "cup", "category": "produce"},
        {"name": "Lemon juice", "quantity": "2", "unit": "tbsp", "category": "condiments"}
    ]'::jsonb,
    '[
        {"step_number": 1, "instruction": "Heat oil and toast cumin seeds until fragrant"},
        {"step_number": 2, "instruction": "Add diced onions and cook until golden"},
        {"step_number": 3, "instruction": "Add ginger and garlic, cook for 1 minute"},
        {"step_number": 4, "instruction": "Add spices and cook until aromatic"},
        {"step_number": 5, "instruction": "Add tomatoes and cook until soft"},
        {"step_number": 6, "instruction": "Add chickpeas and water, simmer for 20 minutes"},
        {"step_number": 7, "instruction": "Mash some chickpeas to thicken sauce"},
        {"step_number": 8, "instruction": "Garnish with cilantro and lemon juice"}
    ]'::jsonb,
    15, 25, 40, 4, 'easy', 'Indian', 'dinner', ARRAY['vegetarian', 'indian', 'chickpeas', 'curry'], 'manual', true
);

INSERT INTO recipes (user_id, title, description, ingredients, instructions, prep_time, cook_time, total_time, servings, difficulty_level, cuisine_type, meal_type, tags, source_type, is_public)
VALUES (
    '55555555-5555-5555-5555-555555555555'::uuid,
    'Biryani',
    'Aromatic basmati rice layered with spiced meat and herbs. A celebratory dish!',
    '[
        {"name": "Basmati rice", "quantity": "500", "unit": "g", "category": "grains"},
        {"name": "Chicken thighs", "quantity": "1", "unit": "kg", "category": "proteins"},
        {"name": "Yogurt", "quantity": "200", "unit": "ml", "category": "dairy"},
        {"name": "Onions", "quantity": "3", "unit": "large", "category": "produce"},
        {"name": "Ginger-garlic paste", "quantity": "3", "unit": "tbsp", "category": "condiments"},
        {"name": "Biryani masala", "quantity": "2", "unit": "tbsp", "category": "spices"},
        {"name": "Saffron", "quantity": "1/4", "unit": "tsp", "category": "spices"},
        {"name": "Milk", "quantity": "2", "unit": "tbsp", "category": "dairy"},
        {"name": "Mint leaves", "quantity": "1/2", "unit": "cup", "category": "produce"},
        {"name": "Cilantro", "quantity": "1/2", "unit": "cup", "category": "produce"},
        {"name": "Ghee", "quantity": "4", "unit": "tbsp", "category": "dairy"}
    ]'::jsonb,
    '[
        {"step_number": 1, "instruction": "Marinate chicken in yogurt and spices for 2 hours"},
        {"step_number": 2, "instruction": "Soak rice for 30 minutes, then parboil until 70% cooked"},
        {"step_number": 3, "instruction": "Cook marinated chicken until tender and liquid evaporates"},
        {"step_number": 4, "instruction": "Fry sliced onions until golden brown"},
        {"step_number": 5, "instruction": "Layer rice and chicken in a heavy pot"},
        {"step_number": 6, "instruction": "Add fried onions, herbs, and saffron-soaked milk"},
        {"step_number": 7, "instruction": "Seal pot with foil and lid, cook on low heat for 30 minutes"},
        {"step_number": 8, "instruction": "Let rest for 10 minutes before serving"}
    ]'::jsonb,
    45, 60, 105, 8, 'hard', 'Indian', 'dinner', ARRAY['indian', 'biryani', 'rice', 'special occasion'], 'manual', true
);

-- David Kim's Recipes (2 recipes)
INSERT INTO recipes (user_id, title, description, ingredients, instructions, prep_time, cook_time, total_time, servings, difficulty_level, cuisine_type, meal_type, tags, source_type, is_public)
VALUES (
    '66666666-6666-6666-6666-666666666666'::uuid,
    'Bulgogi',
    'Sweet and savory Korean marinated beef, perfect for meal prep or BBQ.',
    '[
        {"name": "Beef sirloin", "quantity": "500", "unit": "g", "category": "proteins"},
        {"name": "Soy sauce", "quantity": "60", "unit": "ml", "category": "condiments"},
        {"name": "Brown sugar", "quantity": "2", "unit": "tbsp", "category": "sweeteners"},
        {"name": "Pear", "quantity": "1/2", "unit": "medium", "category": "produce"},
        {"name": "Garlic", "quantity": "3", "unit": "cloves", "category": "produce"},
        {"name": "Ginger", "quantity": "1", "unit": "tbsp", "category": "produce"},
        {"name": "Sesame oil", "quantity": "1", "unit": "tbsp", "category": "oils"},
        {"name": "Green onions", "quantity": "2", "unit": "stalks", "category": "produce"},
        {"name": "Sesame seeds", "quantity": "1", "unit": "tbsp", "category": "other"}
    ]'::jsonb,
    '[
        {"step_number": 1, "instruction": "Thinly slice beef against the grain"},
        {"step_number": 2, "instruction": "Grate pear and mix with soy sauce, sugar, garlic, and ginger"},
        {"step_number": 3, "instruction": "Marinate beef in sauce for at least 2 hours"},
        {"step_number": 4, "instruction": "Heat pan or grill to high heat"},
        {"step_number": 5, "instruction": "Cook beef quickly until caramelized"},
        {"step_number": 6, "instruction": "Garnish with green onions and sesame seeds"}
    ]'::jsonb,
    20, 10, 30, 4, 'easy', 'Korean', 'dinner', ARRAY['korean', 'bulgogi', 'beef', 'meal prep'], 'manual', true
);

INSERT INTO recipes (user_id, title, description, ingredients, instructions, prep_time, cook_time, total_time, servings, difficulty_level, cuisine_type, meal_type, tags, source_type, is_public)
VALUES (
    '66666666-6666-6666-6666-666666666666'::uuid,
    'Kimchi Fried Rice',
    'Quick and easy fried rice with kimchi, perfect for using leftover rice.',
    '[
        {"name": "Cooked rice", "quantity": "3", "unit": "cups", "category": "grains"},
        {"name": "Kimchi", "quantity": "200", "unit": "g", "category": "produce"},
        {"name": "Bacon", "quantity": "100", "unit": "g", "category": "proteins"},
        {"name": "Eggs", "quantity": "2", "unit": "pieces", "category": "proteins"},
        {"name": "Green onions", "quantity": "2", "unit": "stalks", "category": "produce"},
        {"name": "Sesame oil", "quantity": "1", "unit": "tbsp", "category": "oils"},
        {"name": "Gochujang", "quantity": "1", "unit": "tbsp", "category": "condiments"},
        {"name": "Soy sauce", "quantity": "1", "unit": "tbsp", "category": "condiments"}
    ]'::jsonb,
    '[
        {"step_number": 1, "instruction": "Chop kimchi into bite-sized pieces"},
        {"step_number": 2, "instruction": "Cook bacon until crisp, then remove"},
        {"step_number": 3, "instruction": "Fry eggs sunny-side up, set aside"},
        {"step_number": 4, "instruction": "Sauté kimchi in bacon fat until slightly caramelized"},
        {"step_number": 5, "instruction": "Add rice and break up any clumps"},
        {"step_number": 6, "instruction": "Add gochujang and soy sauce, stir to combine"},
        {"step_number": 7, "instruction": "Top with fried eggs, bacon, and green onions"}
    ]'::jsonb,
    10, 15, 25, 2, 'easy', 'Korean', 'dinner', ARRAY['korean', 'fried rice', 'kimchi', 'quick meal'], 'manual', true
);

-- Maria Garcia's Recipes (2 recipes)
INSERT INTO recipes (user_id, title, description, ingredients, instructions, prep_time, cook_time, total_time, servings, difficulty_level, cuisine_type, meal_type, tags, source_type, is_public)
VALUES (
    '77777777-7777-7777-7777-777777777777'::uuid,
    'Paella',
    'Traditional Spanish rice dish with saffron, seafood, and vegetables.',
    '[
        {"name": "Bomba rice", "quantity": "400", "unit": "g", "category": "grains"},
        {"name": "Chicken thighs", "quantity": "400", "unit": "g", "category": "proteins"},
        {"name": "Shrimp", "quantity": "300", "unit": "g", "category": "proteins"},
        {"name": "Mussels", "quantity": "300", "unit": "g", "category": "proteins"},
        {"name": "Chorizo", "quantity": "200", "unit": "g", "category": "proteins"},
        {"name": "Bell peppers", "quantity": "2", "unit": "medium", "category": "produce"},
        {"name": "Tomatoes", "quantity": "2", "unit": "medium", "category": "produce"},
        {"name": "Onion", "quantity": "1", "unit": "medium", "category": "produce"},
        {"name": "Garlic", "quantity": "4", "unit": "cloves", "category": "produce"},
        {"name": "Saffron", "quantity": "1", "unit": "tsp", "category": "spices"},
        {"name": "Chicken stock", "quantity": "1", "unit": "liter", "category": "liquids"},
        {"name": "Peas", "quantity": "100", "unit": "g", "category": "produce"}
    ]'::jsonb,
    '[
        {"step_number": 1, "instruction": "Heat oil in a large paella pan"},
        {"step_number": 2, "instruction": "Brown chicken pieces and chorizo, then remove"},
        {"step_number": 3, "instruction": "Sauté vegetables until soft"},
        {"step_number": 4, "instruction": "Add rice and toast for 2 minutes"},
        {"step_number": 5, "instruction": "Add saffron-infused stock and bring to boil"},
        {"step_number": 6, "instruction": "Arrange chicken and chorizo on top"},
        {"step_number": 7, "instruction": "Simmer without stirring for 15 minutes"},
        {"step_number": 8, "instruction": "Add seafood and peas, cook for 5 more minutes"},
        {"step_number": 9, "instruction": "Let rest for 5 minutes before serving"}
    ]'::jsonb,
    30, 35, 65, 6, 'hard', 'Spanish', 'dinner', ARRAY['spanish', 'paella', 'seafood', 'rice'], 'manual', true
);

INSERT INTO recipes (user_id, title, description, ingredients, instructions, prep_time, cook_time, total_time, servings, difficulty_level, cuisine_type, meal_type, tags, source_type, is_public)
VALUES (
    '77777777-7777-7777-7777-777777777777'::uuid,
    'Churros con Chocolate',
    'Crispy Spanish donuts served with thick hot chocolate for dipping.',
    '[
        {"name": "Water", "quantity": "250", "unit": "ml", "category": "liquids"},
        {"name": "Butter", "quantity": "50", "unit": "g", "category": "dairy"},
        {"name": "Salt", "quantity": "1/4", "unit": "tsp", "category": "spices"},
        {"name": "Flour", "quantity": "150", "unit": "g", "category": "grains"},
        {"name": "Eggs", "quantity": "2", "unit": "pieces", "category": "proteins"},
        {"name": "Sugar", "quantity": "100", "unit": "g", "category": "sweeteners"},
        {"name": "Cinnamon", "quantity": "1", "unit": "tsp", "category": "spices"},
        {"name": "Dark chocolate", "quantity": "200", "unit": "g", "category": "other"},
        {"name": "Milk", "quantity": "250", "unit": "ml", "category": "dairy"},
        {"name": "Cornstarch", "quantity": "1", "unit": "tbsp", "category": "thickeners"}
    ]'::jsonb,
    '[
        {"step_number": 1, "instruction": "Bring water, butter, and salt to a boil"},
        {"step_number": 2, "instruction": "Add flour and stir vigorously until dough forms"},
        {"step_number": 3, "instruction": "Remove from heat and beat in eggs one at a time"},
        {"step_number": 4, "instruction": "Pipe dough into hot oil and fry until golden"},
        {"step_number": 5, "instruction": "Mix sugar and cinnamon, roll churros in mixture"},
        {"step_number": 6, "instruction": "Melt chocolate with milk and thicken with cornstarch"},
        {"step_number": 7, "instruction": "Serve churros with hot chocolate for dipping"}
    ]'::jsonb,
    20, 15, 35, 6, 'medium', 'Spanish', 'dessert', ARRAY['spanish', 'churros', 'dessert', 'chocolate'], 'manual', true
);

-- Alex Thompson's Recipes (1 recipe)
INSERT INTO recipes (user_id, title, description, ingredients, instructions, prep_time, cook_time, total_time, servings, difficulty_level, cuisine_type, meal_type, tags, source_type, is_public)
VALUES (
    '88888888-8888-8888-8888-888888888888'::uuid,
    'Easy Mac and Cheese',
    'Simple, creamy mac and cheese that''s perfect for a quick weeknight dinner.',
    '[
        {"name": "Elbow macaroni", "quantity": "400", "unit": "g", "category": "grains"},
        {"name": "Butter", "quantity": "4", "unit": "tbsp", "category": "dairy"},
        {"name": "Flour", "quantity": "4", "unit": "tbsp", "category": "grains"},
        {"name": "Milk", "quantity": "500", "unit": "ml", "category": "dairy"},
        {"name": "Cheddar cheese", "quantity": "300", "unit": "g", "category": "dairy"},
        {"name": "Salt", "quantity": "1", "unit": "tsp", "category": "spices"},
        {"name": "Black pepper", "quantity": "1/2", "unit": "tsp", "category": "spices"},
        {"name": "Paprika", "quantity": "1/4", "unit": "tsp", "category": "spices"}
    ]'::jsonb,
    '[
        {"step_number": 1, "instruction": "Cook macaroni according to package directions"},
        {"step_number": 2, "instruction": "Melt butter in a saucepan"},
        {"step_number": 3, "instruction": "Whisk in flour and cook for 1 minute"},
        {"step_number": 4, "instruction": "Gradually whisk in milk until smooth"},
        {"step_number": 5, "instruction": "Cook until sauce thickens, about 5 minutes"},
        {"step_number": 6, "instruction": "Remove from heat and stir in cheese until melted"},
        {"step_number": 7, "instruction": "Season with salt, pepper, and paprika"},
        {"step_number": 8, "instruction": "Mix sauce with cooked pasta and serve"}
    ]'::jsonb,
    10, 20, 30, 4, 'easy', 'American', 'dinner', ARRAY['comfort food', 'mac and cheese', 'easy', 'budget-friendly'], 'manual', true
);

-- Sophie Martin's Recipes (2 recipes)
INSERT INTO recipes (user_id, title, description, ingredients, instructions, prep_time, cook_time, total_time, servings, difficulty_level, cuisine_type, meal_type, tags, source_type, is_public)
VALUES (
    '99999999-9999-9999-9999-999999999999'::uuid,
    'Chocolate Soufflé',
    'Light and airy chocolate soufflé with a molten center. Impressive but achievable!',
    '[
        {"name": "Dark chocolate", "quantity": "200", "unit": "g", "category": "other"},
        {"name": "Butter", "quantity": "30", "unit": "g", "category": "dairy"},
        {"name": "Flour", "quantity": "2", "unit": "tbsp", "category": "grains"},
        {"name": "Milk", "quantity": "150", "unit": "ml", "category": "dairy"},
        {"name": "Egg yolks", "quantity": "4", "unit": "pieces", "category": "proteins"},
        {"name": "Egg whites", "quantity": "6", "unit": "pieces", "category": "proteins"},
        {"name": "Sugar", "quantity": "100", "unit": "g", "category": "sweeteners"},
        {"name": "Vanilla extract", "quantity": "1", "unit": "tsp", "category": "other"},
        {"name": "Powdered sugar", "quantity": "2", "unit": "tbsp", "category": "sweeteners"}
    ]'::jsonb,
    '[
        {"step_number": 1, "instruction": "Melt chocolate and butter in a double boiler"},
        {"step_number": 2, "instruction": "Make a roux with flour and milk, cook until thick"},
        {"step_number": 3, "instruction": "Whisk in chocolate mixture and egg yolks"},
        {"step_number": 4, "instruction": "Beat egg whites until soft peaks"},
        {"step_number": 5, "instruction": "Gradually add sugar to egg whites, beat to stiff peaks"},
        {"step_number": 6, "instruction": "Fold egg whites into chocolate mixture"},
        {"step_number": 7, "instruction": "Pour into buttered ramekins"},
        {"step_number": 8, "instruction": "Bake at 375°F for 12-15 minutes until risen"},
        {"step_number": 9, "instruction": "Dust with powdered sugar and serve immediately"}
    ]'::jsonb,
    25, 15, 40, 6, 'hard', 'French', 'dessert', ARRAY['french', 'soufflé', 'chocolate', 'dessert'], 'manual', true
);

INSERT INTO recipes (user_id, title, description, ingredients, instructions, prep_time, cook_time, total_time, servings, difficulty_level, cuisine_type, meal_type, tags, source_type, is_public)
VALUES (
    '99999999-9999-9999-9999-999999999999'::uuid,
    'Lemon Tart',
    'Classic French lemon tart with a buttery shortcrust pastry and tangy lemon filling.',
    '[
        {"name": "Flour", "quantity": "200", "unit": "g", "category": "grains"},
        {"name": "Butter", "quantity": "100", "unit": "g", "category": "dairy"},
        {"name": "Sugar", "quantity": "50", "unit": "g", "category": "sweeteners"},
        {"name": "Egg yolk", "quantity": "1", "unit": "piece", "category": "proteins"},
        {"name": "Lemon juice", "quantity": "150", "unit": "ml", "category": "produce"},
        {"name": "Lemon zest", "quantity": "2", "unit": "tbsp", "category": "produce"},
        {"name": "Eggs", "quantity": "4", "unit": "pieces", "category": "proteins"},
        {"name": "Sugar", "quantity": "200", "unit": "g", "category": "sweeteners"},
        {"name": "Butter", "quantity": "100", "unit": "g", "category": "dairy"}
    ]'::jsonb,
    '[
        {"step_number": 1, "instruction": "Mix flour, butter, and sugar for pastry"},
        {"step_number": 2, "instruction": "Add egg yolk and form into a ball"},
        {"step_number": 3, "instruction": "Roll out and line a tart pan, blind bake for 15 minutes"},
        {"step_number": 4, "instruction": "Whisk lemon juice, zest, eggs, and sugar together"},
        {"step_number": 5, "instruction": "Cook mixture over low heat until thickened"},
        {"step_number": 6, "instruction": "Remove from heat and whisk in butter"},
        {"step_number": 7, "instruction": "Pour filling into baked tart shell"},
        {"step_number": 8, "instruction": "Bake at 325°F for 20 minutes until set"},
        {"step_number": 9, "instruction": "Cool completely before serving"}
    ]'::jsonb,
    30, 40, 70, 8, 'medium', 'French', 'dessert', ARRAY['french', 'tart', 'lemon', 'dessert'], 'manual', true
);

-- Ryan O'Connor's Recipes (2 recipes)
INSERT INTO recipes (user_id, title, description, ingredients, instructions, prep_time, cook_time, total_time, servings, difficulty_level, cuisine_type, meal_type, tags, source_type, is_public)
VALUES (
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid,
    'High Protein Chicken Bowl',
    'Meal prep friendly bowl with grilled chicken, quinoa, and vegetables. Perfect for fitness goals!',
    '[
        {"name": "Chicken breast", "quantity": "600", "unit": "g", "category": "proteins"},
        {"name": "Quinoa", "quantity": "200", "unit": "g", "category": "grains"},
        {"name": "Broccoli", "quantity": "300", "unit": "g", "category": "produce"},
        {"name": "Sweet potato", "quantity": "400", "unit": "g", "category": "produce"},
        {"name": "Olive oil", "quantity": "2", "unit": "tbsp", "category": "oils"},
        {"name": "Garlic", "quantity": "3", "unit": "cloves", "category": "produce"},
        {"name": "Lemon juice", "quantity": "2", "unit": "tbsp", "category": "condiments"},
        {"name": "Paprika", "quantity": "1", "unit": "tsp", "category": "spices"},
        {"name": "Cumin", "quantity": "1", "unit": "tsp", "category": "spices"}
    ]'::jsonb,
    '[
        {"step_number": 1, "instruction": "Marinate chicken in olive oil, garlic, lemon, and spices"},
        {"step_number": 2, "instruction": "Cook quinoa according to package instructions"},
        {"step_number": 3, "instruction": "Grill or pan-fry chicken until cooked through"},
        {"step_number": 4, "instruction": "Roast sweet potato cubes at 400°F for 25 minutes"},
        {"step_number": 5, "instruction": "Steam broccoli until tender-crisp"},
        {"step_number": 6, "instruction": "Assemble bowls with quinoa, chicken, and vegetables"}
    ]'::jsonb,
    20, 30, 50, 4, 'easy', 'American', 'dinner', ARRAY['healthy', 'high protein', 'meal prep', 'fitness'], 'manual', true
);

INSERT INTO recipes (user_id, title, description, ingredients, instructions, prep_time, cook_time, total_time, servings, difficulty_level, cuisine_type, meal_type, tags, source_type, is_public)
VALUES (
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid,
    'Protein Smoothie Bowl',
    'Nutritious breakfast smoothie bowl topped with fresh fruits and granola.',
    '[
        {"name": "Greek yogurt", "quantity": "200", "unit": "g", "category": "dairy"},
        {"name": "Protein powder", "quantity": "30", "unit": "g", "category": "other"},
        {"name": "Banana", "quantity": "1", "unit": "medium", "category": "produce"},
        {"name": "Berries", "quantity": "100", "unit": "g", "category": "produce"},
        {"name": "Almond milk", "quantity": "100", "unit": "ml", "category": "liquids"},
        {"name": "Granola", "quantity": "50", "unit": "g", "category": "grains"},
        {"name": "Chia seeds", "quantity": "1", "unit": "tbsp", "category": "other"},
        {"name": "Honey", "quantity": "1", "unit": "tbsp", "category": "sweeteners"}
    ]'::jsonb,
    '[
        {"step_number": 1, "instruction": "Blend yogurt, protein powder, banana, berries, and almond milk"},
        {"step_number": 2, "instruction": "Pour into a bowl"},
        {"step_number": 3, "instruction": "Top with granola, chia seeds, and fresh berries"},
        {"step_number": 4, "instruction": "Drizzle with honey and serve"}
    ]'::jsonb,
    10, 0, 10, 1, 'easy', 'American', 'breakfast', ARRAY['healthy', 'smoothie', 'protein', 'breakfast'], 'manual', true
);

