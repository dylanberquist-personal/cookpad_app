#!/usr/bin/env python3
"""
Script to create sample users in Supabase Auth via Admin API.
This script creates users and then generates an updated SQL file with the correct UUIDs.

Requirements:
    pip install supabase

Usage:
    python create_sample_users.py

Environment Variables:
    SUPABASE_URL: Your Supabase project URL
    SUPABASE_SERVICE_KEY: Your Supabase service role key (keep secret!)
"""

import os
import json
import sys
from supabase import create_client, Client

# Sample users data
SAMPLE_USERS = [
    {
        "email": "sarah.chen@example.com",
        "password": "TestPassword123!",
        "username": "sarahchen",
        "display_name": "Sarah Chen",
        "bio": "Home cook passionate about Asian fusion cuisine. Love experimenting with traditional recipes!",
        "skill_level": "intermediate",
        "dietary_restrictions": [],
        "cuisine_preferences": ["Asian", "Fusion", "Chinese"]
    },
    {
        "email": "marcus.j@example.com",
        "password": "TestPassword123!",
        "username": "marcusj",
        "display_name": "Marcus Johnson",
        "bio": "BBQ enthusiast and grilling master. Always ready for a cookout!",
        "skill_level": "advanced",
        "dietary_restrictions": [],
        "cuisine_preferences": ["American", "BBQ", "Southern"]
    },
    {
        "email": "emma.rodriguez@example.com",
        "password": "TestPassword123!",
        "username": "emmarod",
        "display_name": "Emma Rodriguez",
        "bio": "Vegetarian chef specializing in healthy, plant-based meals. Food photographer on the side!",
        "skill_level": "intermediate",
        "dietary_restrictions": ["Vegetarian"],
        "cuisine_preferences": ["Mediterranean", "Mexican", "Vegetarian"]
    },
    {
        "email": "james.wilson@example.com",
        "password": "TestPassword123!",
        "username": "jamesw",
        "display_name": "James Wilson",
        "bio": "Professional chef sharing restaurant-quality recipes for home cooks.",
        "skill_level": "advanced",
        "dietary_restrictions": [],
        "cuisine_preferences": ["French", "Italian", "Contemporary"]
    },
    {
        "email": "priya.patel@example.com",
        "password": "TestPassword123!",
        "username": "priyap",
        "display_name": "Priya Patel",
        "bio": "Sharing authentic Indian family recipes passed down through generations.",
        "skill_level": "advanced",
        "dietary_restrictions": [],
        "cuisine_preferences": ["Indian", "Vegetarian", "Vegan"]
    },
    {
        "email": "david.kim@example.com",
        "password": "TestPassword123!",
        "username": "davidkim",
        "display_name": "David Kim",
        "bio": "Korean food lover and meal prep enthusiast. Quick and easy recipes for busy weekdays!",
        "skill_level": "intermediate",
        "dietary_restrictions": [],
        "cuisine_preferences": ["Korean", "Asian", "Meal Prep"]
    },
    {
        "email": "maria.garcia@example.com",
        "password": "TestPassword123!",
        "username": "mariag",
        "display_name": "Maria Garcia",
        "bio": "Passionate about Spanish and Latin American cuisine. Love sharing traditional dishes!",
        "skill_level": "intermediate",
        "dietary_restrictions": [],
        "cuisine_preferences": ["Spanish", "Mexican", "Latin American"]
    },
    {
        "email": "alex.thompson@example.com",
        "password": "TestPassword123!",
        "username": "alext",
        "display_name": "Alex Thompson",
        "bio": "Beginner cook learning to make delicious meals on a budget. Sharing my journey!",
        "skill_level": "beginner",
        "dietary_restrictions": [],
        "cuisine_preferences": ["American", "Comfort Food"]
    },
    {
        "email": "sophie.martin@example.com",
        "password": "TestPassword123!",
        "username": "sophiem",
        "display_name": "Sophie Martin",
        "bio": "Baking enthusiast and dessert lover. Specializing in French pastries and cakes.",
        "skill_level": "advanced",
        "dietary_restrictions": [],
        "cuisine_preferences": ["French", "Baking", "Desserts"]
    },
    {
        "email": "ryan.oconnor@example.com",
        "password": "TestPassword123!",
        "username": "ryano",
        "display_name": "Ryan O'Connor",
        "bio": "Fitness-focused meal prep recipes. High protein, nutritious, and delicious!",
        "skill_level": "intermediate",
        "dietary_restrictions": [],
        "cuisine_preferences": ["Healthy", "High Protein", "Meal Prep"]
    }
]


def create_users():
    """Create users in Supabase Auth and return their UUIDs."""
    supabase_url = os.getenv("SUPABASE_URL")
    supabase_service_key = os.getenv("SUPABASE_SERVICE_KEY")
    
    if not supabase_url or not supabase_service_key:
        print("ERROR: SUPABASE_URL and SUPABASE_SERVICE_KEY environment variables must be set")
        print("\nTo set them:")
        print("  export SUPABASE_URL='https://your-project.supabase.co'")
        print("  export SUPABASE_SERVICE_KEY='your-service-role-key'")
        print("\nOr create a .env file with:")
        print("  SUPABASE_URL=https://your-project.supabase.co")
        print("  SUPABASE_SERVICE_KEY=your-service-role-key")
        sys.exit(1)
    
    supabase: Client = create_client(supabase_url, supabase_service_key)
    
    user_ids = {}
    
    print("Creating users in Supabase Auth...")
    print("=" * 50)
    
    for user_data in SAMPLE_USERS:
        email = user_data["email"]
        password = user_data["password"]
        
        try:
            # Create user in Auth
            response = supabase.auth.admin.create_user({
                "email": email,
                "password": password,
                "email_confirm": True
            })
            
            user_id = response.user.id
            user_ids[email] = user_id
            
            print(f"✓ Created: {email} -> {user_id}")
            
            # Create profile in public.users table
            profile_data = {
                "id": user_id,
                "email": email,
                "username": user_data["username"],
                "display_name": user_data["display_name"],
                "bio": user_data["bio"],
                "skill_level": user_data["skill_level"],
                "dietary_restrictions": json.dumps(user_data["dietary_restrictions"]),
                "cuisine_preferences": json.dumps(user_data["cuisine_preferences"]),
                "chef_score": 0.0
            }
            
            supabase.table("users").insert(profile_data).execute()
            print(f"  ✓ Created profile for {user_data['username']}")
            
        except Exception as e:
            print(f"✗ Error creating {email}: {str(e)}")
            continue
    
    print("\n" + "=" * 50)
    print(f"Successfully created {len(user_ids)} users")
    print("\nUser IDs:")
    for email, user_id in user_ids.items():
        print(f"  {email}: {user_id}")
    
    return user_ids


if __name__ == "__main__":
    print("Sample User Creation Script for Cookpad App")
    print("=" * 50)
    print()
    
    # Check if supabase is installed
    try:
        import supabase
    except ImportError:
        print("ERROR: supabase package not installed")
        print("Install it with: pip install supabase")
        sys.exit(1)
    
    user_ids = create_users()
    
    print("\n" + "=" * 50)
    print("Next Steps:")
    print("1. Run the sample_data_import.sql file in Supabase SQL Editor")
    print("2. Replace the placeholder UUIDs with the actual user IDs shown above")
    print("3. Or use the user_ids dictionary to update the SQL file programmatically")
    print("\nAll users have the password: TestPassword123!")

