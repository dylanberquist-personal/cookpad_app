-- Create a trigger to automatically create user profile when auth user is created
-- This ensures the user profile is created even if the client-side insert fails

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  v_username TEXT;
BEGIN
  -- Extract username from metadata or use email prefix
  v_username := COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1));
  
  -- Ensure username is unique - if it already exists, append a number
  WHILE EXISTS (SELECT 1 FROM public.users WHERE username = v_username) LOOP
    v_username := v_username || floor(random() * 1000)::text;
  END LOOP;
  
  -- Insert user profile (this runs with SECURITY DEFINER, bypassing RLS)
  INSERT INTO public.users (id, email, username, skill_level, dietary_restrictions, chef_score)
  VALUES (
    NEW.id,
    NEW.email,
    v_username,
    'beginner',
    '[]'::jsonb,
    0.0
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    username = COALESCE(EXCLUDED.username, users.username),
    updated_at = NOW();
    
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger that fires when a new auth user is created
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Also ensure the insert policy allows the insert during signup
-- The policy should already exist, but we'll make sure it's correct
DROP POLICY IF EXISTS "Users can insert own profile" ON users;
CREATE POLICY "Users can insert own profile" ON users
    FOR INSERT
    WITH CHECK (auth.uid() = id);

