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

## 📱 Installing on Android Phone (Without USB Connection)

To test your app on an Android phone without connecting it directly to your computer, follow these steps:

### Step 1: Build the Release APK

Open a terminal in your project directory and run:
```bash
flutter build apk --release
```

This will create an APK file at:
```
build/app/outputs/flutter-apk/app-release.apk
```

### Step 2: Transfer the APK to Your Phone

You have several options to transfer the APK:

**Option A: Cloud Storage (Recommended)**
1. Upload `app-release.apk` to Google Drive, Dropbox, or OneDrive
2. Open the cloud storage app on your phone
3. Download the APK file to your phone

**Option B: Email**
1. Email the APK file to yourself
2. Open the email on your phone
3. Download the attachment

**Option C: Local Network Sharing**
1. Use a file sharing service like ShareIt, Send Anywhere, or AirDroid
2. Or set up a local web server on your computer and access it from your phone's browser

**Option D: USB Drive**
1. Copy the APK to a USB drive
2. Use a USB OTG adapter to connect the drive to your phone

### Step 3: Enable Unknown Sources on Your Phone

Before installing, you need to allow installation from unknown sources:

1. Go to **Settings** > **Security** (or **Settings** > **Apps** > **Special access**)
2. Enable **"Install unknown apps"** or **"Unknown sources"**
3. If prompted, select the app you'll use to install the APK (e.g., Files app, Chrome)

**Note:** On newer Android versions, you may need to enable this permission for the specific app you're using to install the APK.

### Step 4: Install the APK

1. Open the file manager app on your phone
2. Navigate to where you downloaded the APK (usually in the Downloads folder)
3. Tap on `app-release.apk`
4. Tap **"Install"** when prompted
5. Wait for the installation to complete
6. Tap **"Open"** to launch the app

### Alternative: Build App Bundle (AAB) for Google Play

If you plan to distribute via Google Play Store (even for internal testing), build an AAB instead:
```bash
flutter build appbundle --release
```

This creates `build/app/outputs/bundle/release/app-release.aab` which you can upload to Google Play Console for internal testing track distribution.

### Troubleshooting

- **"App not installed" error**: Make sure you uninstalled any previous debug versions first
- **"Installation blocked"**: Check that "Unknown sources" is enabled
- **APK not found**: Check the build output path or search for `.apk` files in your project directory

## 📝 Notes

- The app uses Supabase for backend (database, auth, storage)
- OpenAI GPT-4 Turbo for AI recipe generation
- All models match the PRD schema specifications

### Email Confirmation Branding

- Custom Supabase confirmation email HTML lives in `supabase/email_templates/confirm_signup.html`
- Static confirmation landing page lives in `web/email-confirmed.html`
- Follow `docs/email_confirmation_setup.md` for deployment and configuration steps
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