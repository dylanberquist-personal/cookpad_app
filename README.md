# Cookpad Recipe Social App

A Flutter-based recipe sharing and social platform with AI-powered recipe generation, built according to the Product Requirements Document (PRD).

## 🚀 Features Implemented

### ✅ Core Infrastructure
- **Supabase Integration**: Backend setup with PostgreSQL database
- **Authentication System**: Email/password and OAuth (Google) support
- **User Onboarding**: Collect dietary restrictions, skill level, and cuisine preferences
- **Data Models**: Complete models matching PRD schema (Recipe, User, Pantry, Collections, Shopping Lists, etc.)

### ✅ Recipe Management
- **Recipe CRUD**: Create, read, update, delete recipes
- **Recipe Detail View**: Full recipe display with ingredients, instructions, ratings
- **Recipe Search**: Global search functionality
- **Recipe Feed**: Personalized feed with recipe grid/list view

### ✅ Social Features
- **Ratings**: 1-5 star rating system
- **Favorites**: Save recipes to favorites
- **Following System**: Infrastructure ready (models and services created)

### ✅ AI Recipe Generation
- **Chatbot Interface**: Conversational AI recipe generation
- **OpenAI Integration**: GPT-4 Turbo API integration
- **Chat History**: Save chat sessions for recipe creation
- **Iterative Refinement**: Users can refine recipes through conversation

### ✅ Navigation & UI
- **Bottom Navigation**: Home, Search, Generate, Pantry, Profile
- **Material Design 3**: Modern UI with orange theme
- **Responsive Layout**: Grid and list views

## 📋 Setup Instructions

### 1. Supabase Setup
1. Create a Supabase project at [supabase.com](https://supabase.com)
2. Copy your Supabase URL and anon key
3. Update `lib/main.dart` with your credentials:
   ```dart
   await Supabase.initialize(
     url: 'YOUR_SUPABASE_URL',
     anonKey: 'YOUR_SUPABASE_ANON_KEY',
   );
   ```

### 2. Database Schema
Create the following tables in your Supabase database (see PRD section 10.2 for full schema):

**Key Tables:**
- `users` - User profiles with chef scores, dietary restrictions
- `recipes` - Recipe data with ingredients, instructions, nutrition
- `recipe_images` - Multiple images per recipe
- `follows` - User following relationships
- `ratings` - Recipe ratings (1-5 stars)
- `favorites` - User favorite recipes
- `comments` - Recipe comments with threading
- `collections` - User recipe collections
- `collection_recipes` - Recipes in collections
- `pantry_items` - User pantry inventory
- `shopping_lists` - Shopping list management
- `shopping_list_items` - Items in shopping lists
- `ai_chat_sessions` - AI recipe generation chat history
- `notifications` - User notifications

### 3. OpenAI API Key
1. Get your OpenAI API key from [platform.openai.com](https://platform.openai.com)
2. Update `lib/services/ai_recipe_service.dart`:
   ```dart
   static const String _openAiApiKey = 'YOUR_OPENAI_API_KEY';
   ```

### 4. Install Dependencies
```bash
flutter pub get
```

### 5. Run the App
```bash
flutter run
```

## 🔧 Configuration Needed

### Environment Variables (Recommended)
Create a `.env` file in the project root:
```
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
OPENAI_API_KEY=your_openai_api_key
```

Then use `flutter_dotenv` to load them in your code.

### OAuth Setup
1. **Google Sign-In**: Configure in Supabase Dashboard > Authentication > Providers

### Storage Buckets
Create the following storage buckets in Supabase:
- `profile-pictures` (public)
- `recipe-images` (public)
- `recipe-photos-ocr` (private, auto-delete after 24h)

## 📱 Remaining Features (To Be Implemented)

### Priority P0 (Must Have)
- [ ] Comments and threaded discussions
- [ ] Recipe remixing
- [ ] Photo OCR for recipe extraction
- [ ] URL import for recipes
- [ ] Nutrition calculation integration
- [ ] Enhanced personalized feed algorithm
- [ ] Follow/unfollow functionality UI
- [ ] User profile screens

### Priority P1 (Should Have)
- [ ] Pantry management UI
- [ ] Shopping list management UI
- [ ] Collections management UI
- [ ] Notifications system
- [ ] Chef score display and leaderboard
- [ ] Offline recipe access
- [ ] Recipe image upload

### Future Enhancements
- [ ] Video recipe tutorials
- [ ] Meal planning calendar
- [ ] Grocery delivery integration
- [ ] Recipe scaling calculator
- [ ] Voice-guided cooking mode

## 🏗️ Project Structure

```
lib/
├── config/
│   └── supabase_config.dart          # Supabase configuration
├── models/
│   ├── user_model.dart               # User profile model
│   ├── recipe_model.dart             # Recipe model with ingredients/instructions
│   ├── nutrition_model.dart          # Nutritional information
│   ├── collection_model.dart         # Recipe collections
│   ├── pantry_item_model.dart        # Pantry items
│   ├── shopping_list_model.dart      # Shopping lists
│   └── ai_chat_model.dart            # AI chat sessions
├── services/
│   ├── auth_service.dart             # Authentication service
│   ├── recipe_service_supabase.dart  # Recipe CRUD operations
│   └── ai_recipe_service.dart       # AI recipe generation
├── screens/
│   ├── auth/
│   │   ├── auth_wrapper.dart         # Auth state wrapper
│   │   ├── login_screen.dart         # Login UI
│   │   ├── signup_screen.dart        # Signup UI
│   │   └── onboarding_screen.dart   # User onboarding
│   ├── feed_screen.dart              # Recipe feed
│   ├── search_screen_new.dart        # Recipe search
│   ├── generate_recipe_screen.dart  # AI chatbot interface
│   ├── pantry_screen.dart            # Pantry management (placeholder)
│   ├── profile_screen.dart           # User profile
│   ├── recipe_detail_screen_new.dart # Recipe detail view
│   └── main_navigation.dart          # Bottom navigation
└── main.dart                         # App entry point
```

## 🧪 Testing

The app includes test infrastructure. Run tests with:
```bash
flutter test
```

## 📝 Notes

- The app uses Supabase for backend (database, auth, storage)
- OpenAI GPT-4 Turbo for AI recipe generation
- All models match the PRD schema specifications
- The codebase follows Flutter best practices and Material Design 3

## 🔒 Security

- API keys should be stored securely (use environment variables or secure storage)
- Implement Row Level Security (RLS) policies in Supabase
- Follow OAuth best practices for social login
- Sanitize user inputs before database queries

## 🤝 Contributing

This is a production application. Follow the PRD specifications and maintain code quality standards.

## 📄 License

[Specify your license here]

---

**Note**: This app requires a Supabase backend to function. Make sure to set up your Supabase project and configure all necessary tables, storage buckets, and authentication providers before running the app.