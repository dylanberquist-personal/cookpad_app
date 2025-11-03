# Google Sign-In Setup Guide - Step by Step

This guide will walk you through setting up Google Sign-In for your Cookpad app using Supabase authentication.

## Prerequisites

- A Google account
- Access to [Google Cloud Console](https://console.cloud.google.com)
- Your Supabase project URL (already have: `https://sfyidxcygzeeltkuwwyo.supabase.co`)

---

## Part 1: Google Cloud Console Setup

### Step 1: Create or Select a Project

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Click the project dropdown at the top (next to "Google Cloud")
3. Either:
   - **Select an existing project**, OR
   - **Click "New Project"** to create one:
     - Project name: `Cookpad App` (or any name you prefer)
     - Click "Create"
     - Wait for it to be created (may take a few seconds)

### Step 2: Configure OAuth Consent Screen

1. In your selected project, go to **APIs & Services** > **OAuth consent screen**
   (Or search for "OAuth consent screen" in the top search bar)

2. Choose **User Type**:
   - Select **"External"** (unless you have a Google Workspace account)
   - Click **"Create"**

3. Fill in the **App information**:
   - **App name**: `Cookpad` (or your app name)
   - **User support email**: Select your email from dropdown
   - **App logo**: (Optional - you can skip for now)
   - **App domain**: Leave blank for now
   - **Developer contact information**: Enter your email
   - Click **"Save and Continue"**

4. **Scopes** page:
   - You'll see default scopes (`.../auth/userinfo.email` and `.../auth/userinfo.profile`)
   - Click **"Save and Continue"** (no changes needed)

5. **Test users** (if you selected External):
   - Add test users if you want to test before publishing
   - Or click **"Save and Continue"** to skip

6. **Summary**:
   - Review everything
   - Click **"Back to Dashboard"**

### Step 3: Create OAuth 2.0 Credentials

1. Go to **APIs & Services** > **Credentials**
   (Or search for "Credentials" in the search bar)

2. Click **"+ CREATE CREDENTIALS"** at the top
3. Select **"OAuth client ID"**

4. If prompted, configure consent screen first:
   - Follow Step 2 above, then come back here

5. **Application type**: Select **"Web application"**

6. **Name**: Enter `Cookpad Web Client` (or any name)

7. **Authorized JavaScript origins**:
   - Click **"+ ADD URI"**
   - Add: `https://sfyidxcygzeeltkuwwyo.supabase.co`
   - Click **"+ ADD URI"** again (add another one if needed)

8. **Authorized redirect URIs**:
   - Click **"+ ADD URI"**
   - Add: `https://sfyidxcygzeeltkuwwyo.supabase.co/auth/v1/callback`
   - ⚠️ **This is the most important part - must match exactly!**

9. Click **"CREATE"**

10. **Copy your credentials**:
    - A popup will appear with:
      - **Your Client ID** (looks like: `123456789-abc...xyz.apps.googleusercontent.com`)
      - **Your Client Secret** (looks like: `GOCSPX-abc...xyz`)
    - ⚠️ **Copy both immediately** - you won't see the secret again!
    - Click **"OK"**

---

## Part 2: Supabase Configuration

### Step 4: Enable Google Provider in Supabase

1. Go to your [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project (`sfyidxcygzeeltkuwwyo`)
3. Navigate to **Authentication** > **Providers** (in the left sidebar)
4. Find **"Google"** in the list of providers
5. Toggle the **"Enable Google provider"** switch to ON

### Step 5: Add Google Credentials to Supabase

1. In the Google provider settings, you'll see two fields:
   - **Client ID (for OAuth)**
   - **Client Secret (for OAuth)**

2. Paste your credentials:
   - Paste your **Client ID** from Step 3 into the "Client ID" field
   - Paste your **Client Secret** from Step 3 into the "Client Secret" field

3. **Redirect URL**:
   - Supabase should automatically show: `https://sfyidxcygzeeltkuwwyo.supabase.co/auth/v1/callback`
   - Verify this matches what you added in Google Cloud Console (Step 3.8)

4. Click **"Save"** at the bottom

### Step 6: Verify Settings

1. Make sure **"Enable Google provider"** is toggled ON
2. Verify all fields are filled correctly
3. The status should show as active/configured

---

## Part 3: Flutter App Configuration

### Step 7: Update Auth Service (Already Done ✅)

The app already has Google Sign-In implemented in `lib/services/auth_service.dart`. No changes needed here.

### Step 8: Handle OAuth Redirects (Important!)

For mobile apps, OAuth redirects need special handling. Let's update the implementation:

**Note**: The current implementation will work on **Web**, but for **Android/iOS**, we need additional configuration. I'll provide both options below.

---

## Testing Google Sign-In

### Step 9: Test the Integration

1. **Run your Flutter app**:
   ```bash
   flutter run
   ```

2. **Test on Web first** (easiest):
   ```bash
   flutter run -d chrome
   ```
   - Click "Continue with Google" button
   - Should redirect to Google sign-in page
   - After signing in, should redirect back to your app

3. **If it doesn't work, check**:
   - Supabase Dashboard > Authentication > Providers > Google
   - Verify Client ID and Secret are saved
   - Check browser console for errors
   - Verify redirect URI matches exactly

---

## Common Issues & Troubleshooting

### Issue 1: "Redirect URI mismatch"
**Error**: `Error 400: redirect_uri_mismatch`

**Solution**:
- Go to Google Cloud Console > Credentials
- Make sure you added: `https://sfyidxcygzeeltkuwwyo.supabase.co/auth/v1/callback`
- Check for typos or extra spaces
- Wait a few minutes for changes to propagate

### Issue 2: "OAuth client not found"
**Error**: Client ID not found

**Solution**:
- Verify Client ID is copied correctly
- Check it's the "Web application" client ID (not Android/iOS)
- Make sure you're using the correct project in Google Cloud Console

### Issue 3: Nothing happens when clicking Google button
**Possible causes**:
- Google provider not enabled in Supabase
- Client ID/Secret not saved in Supabase
- Check Flutter console for errors
- Verify Supabase credentials in `.env` file

### Issue 4: "Access blocked: This app's request is invalid"
**Solution**:
- OAuth consent screen may need to be published
- Add test users in OAuth consent screen
- Or publish the app (requires verification if public)

---

## For Production (Later)

When ready to publish:

1. **Publish OAuth consent screen**:
   - Google Cloud Console > OAuth consent screen
   - Click "PUBLISH APP"
   - This makes it available to all users (not just test users)

2. **Add your production domain** (if different):
   - Update authorized JavaScript origins
   - Update authorized redirect URIs if needed

---

## Quick Checklist

Before testing, verify:

- [ ] Google Cloud Console project created
- [ ] OAuth consent screen configured
- [ ] OAuth 2.0 credentials created (Web application type)
- [ ] Redirect URI added: `https://sfyidxcygzeeltkuwwyo.supabase.co/auth/v1/callback`
- [ ] Client ID and Secret copied
- [ ] Google provider enabled in Supabase
- [ ] Client ID and Secret added to Supabase
- [ ] Redirect URI matches in both places
- [ ] `.env` file has correct Supabase credentials

---

## Need Help?

If you encounter issues:

1. Check the **Common Issues** section above
2. Verify all URLs match exactly (no trailing slashes, correct protocol)
3. Check Supabase Dashboard > Authentication > Logs for errors
4. Check browser console for JavaScript errors (on web)
5. Verify your Google Cloud Console project is active

---

**Once configured, Google Sign-In should work! 🎉**

