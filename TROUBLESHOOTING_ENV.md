# Troubleshooting .env File Issues

## 🚨 Problem: "RapidAPI key not configured"

If you see this message in your logs:
```
⚠️ RapidAPI key not configured, skipping API extraction
```

The `.env` file is not being loaded correctly.

## ✅ Solution Steps

### Step 1: Verify .env File Exists

1. Look in your project root directory (same folder as `pubspec.yaml`)
2. You should see a file named `.env` (note the dot at the start!)
3. On Windows, this might show as just `env` in Explorer

**If you don't see it:**
- Create a new file named `.env` (with the dot)
- Copy contents from `env_template.txt`

### Step 2: Check .env File Contents

Open `.env` and verify it looks like this:

```env
# Supabase Configuration
SUPABASE_URL=your_actual_supabase_url_here
SUPABASE_ANON_KEY=your_actual_supabase_anon_key_here

# OpenAI Configuration  
OPENAI_API_KEY=sk-proj-xxxxxxxxxxxxx

# RapidAPI Configuration
RAPIDAPI_KEY=your_actual_rapidapi_key_here
```

**Common Mistakes:**
- ❌ Extra spaces: `RAPIDAPI_KEY = abc123` (should be `RAPIDAPI_KEY=abc123`)
- ❌ Quotes: `RAPIDAPI_KEY="abc123"` (should be `RAPIDAPI_KEY=abc123`)
- ❌ Comments on same line: `RAPIDAPI_KEY=abc123 # my key` (remove the comment)
- ❌ Missing the key: `RAPIDAPI_KEY=` (must have a value)

### Step 3: Get Your RapidAPI Key

1. Go to https://rapidapi.com/
2. Log in
3. Click your profile (top right) → "My Apps"
4. Click "default-application" (or your app name)
5. Copy the "Application Key"
6. Paste it in your `.env` file:
   ```env
   RAPIDAPI_KEY=paste_here_no_quotes_or_spaces
   ```

### Step 4: Verify Subscription

1. Go to https://rapidapi.com/gaudard.olivier/api/video-transcript-scraper
2. Make sure you see "Unsubscribe" button (not "Subscribe")
3. If you see "Subscribe", click it and choose a plan (free tier is fine)

### Step 5: Restart the App COMPLETELY

**This is crucial!** .env changes only load when the app starts.

**On Windows:**
1. Stop the app (click stop button in IDE)
2. Close the app on your phone/emulator completely
3. Run `flutter clean` in terminal
4. Run `flutter pub get`
5. Start the app again

**Quick Command:**
```bash
flutter clean && flutter pub get && flutter run
```

### Step 6: Verify It Loaded

When the app starts, check the console/logs. You should see:
```
✅ RapidAPI key loaded: abc123defg...xyz9
```

**If you see:**
```
⚠️ WARNING: RAPIDAPI_KEY not found in .env file
```

The key is still not loading. Try:
- Make sure filename is exactly `.env` (with dot)
- Check file is in project root (same folder as `pubspec.yaml`)
- No typos: `RAPIDAPI_KEY` not `RAPID_API_KEY` or `RAPIDAPIKEY`
- Restart IDE completely
- Clear Flutter cache: `flutter clean`

## 🔍 Diagnostic Checklist

Run through this checklist:

- [ ] `.env` file exists in project root
- [ ] File is named `.env` exactly (with the dot)
- [ ] `RAPIDAPI_KEY=your_key` line exists
- [ ] No extra spaces or quotes around the key
- [ ] Key is from RapidAPI dashboard
- [ ] Subscribed to Video Transcript Scraper API
- [ ] App was completely restarted after adding key
- [ ] Console shows "✅ RapidAPI key loaded"

## 🧪 Test Your Setup

1. **Stop and restart the app**
2. **Paste a YouTube URL in the recipe generator**
3. **Check console logs** - you should see:

```
✅ RapidAPI key loaded: abc123...xyz9
🎬 Fetching video data via RapidAPI Video Transcript Scraper...
📡 API response status: 200
✅ Successfully fetched video data from API
   Video title: [video title]
   Transcript segments: XX
   Transcript length: XXXX characters
```

**If you see 401 or 403:**
- Your API key is invalid
- Check you copied the full key
- Verify subscription is active

**If you see 404:**
- Wrong endpoint (shouldn't happen with latest code)
- API might be down (rare)

**If you still see "⚠️ RapidAPI key not configured":**
- .env file not being loaded
- Follow steps 1-5 above again carefully

## 📝 Example Working .env File

```env
SUPABASE_URL=https://abcdefghijk.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

OPENAI_API_KEY=sk-proj-1234567890abcdefghijklmnopqrstuvwxyz...

RAPIDAPI_KEY=1234567890abcdefghijklmnopqrstuvwxyz1234567890
```

No quotes, no spaces around `=`, no comments on the same line.

## 💡 Pro Tip

After adding the RapidAPI key, you should see a HUGE improvement:

**Before (without key):**
```
Has transcript: false
Total content length: 1050 characters
No recipe found in content
```

**After (with key):**
```
✅ Successfully fetched video data from API
   Transcript segments: 95
   Transcript length: 3245 characters
   [Full recipe extracted successfully!]
```

## 🆘 Still Having Issues?

If you've tried everything above and it still doesn't work:

1. **Share your .env file format** (with keys redacted):
   ```
   RAPIDAPI_KEY=abc...xyz  (first 3 and last 3 characters)
   ```

2. **Share the console logs** when starting the app

3. **Verify Flutter version**: Run `flutter doctor -v`

4. **Try creating a fresh .env**:
   ```bash
   # Delete old .env
   rm .env
   
   # Create new one
   echo "RAPIDAPI_KEY=your_key_here" > .env
   echo "OPENAI_API_KEY=your_key_here" >> .env
   
   # Restart
   flutter clean && flutter run
   ```

Good luck! Once the key loads, video recipe extraction will work much better! 🚀

