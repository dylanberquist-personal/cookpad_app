# Quick RapidAPI Setup Guide

This guide will walk you through setting up the Video Transcript Scraper API in under 5 minutes.

## 🎯 What You'll Get

With this ONE API, you'll be able to extract recipes from:
- ✅ YouTube videos
- ✅ TikTok videos
- ✅ Instagram Reels
- ✅ Facebook videos
- ✅ X (Twitter) videos
- ✅ Vimeo, Dailymotion, Loom, and more!

## 📝 Step-by-Step Setup

### Step 1: Create RapidAPI Account (2 minutes)

1. Go to https://rapidapi.com/
2. Click "Sign Up" in the top right
3. Sign up with Google, GitHub, or email
4. Verify your email (if using email signup)

### Step 2: Subscribe to Video Transcript Scraper (2 minutes)

1. Go to: https://rapidapi.com/gaudard.olivier/api/video-transcript-scraper
2. Click the **"Subscribe to Test"** button
3. Choose a plan:
   - **FREE**: 100 requests/month (great for testing!)
   - **Basic**: $9.99/month - 1000 requests (~30/day)
   - **Pro**: $29.99/month - 10000 requests (~300/day)
4. Click "Subscribe"

💡 **Tip**: Start with the free tier to test it out!

### Step 3: Get Your API Key (1 minute)

1. After subscribing, look at the code example on the API page
2. You'll see a header like: `'X-RapidAPI-Key': 'your-key-here'`
3. Copy your API key (it looks like: `abc123def456...`)

**OR**

1. Click your profile icon (top right)
2. Go to "My Apps"
3. Click on "default-application"
4. Copy the API key shown

### Step 4: Add to Your App (1 minute)

1. Open your `.env` file in the app root directory
2. Add this line:
   ```
   RAPIDAPI_KEY=your_actual_api_key_here
   ```
3. Save the file
4. **Restart the app** (important!)

### Step 5: Test It! (1 minute)

1. Open the app
2. Tap the "+" button → "Link"
3. Paste a YouTube recipe video URL
4. Hit send and watch it extract the recipe!

## ✅ Verification

You'll know it's working if you see in the logs:
```
Fetching video data via RapidAPI Video Transcript Scraper...
API response status: 200
Successfully fetched video data from API
```

## 📊 Usage Monitoring

Keep track of your API usage:

1. Go to https://rapidapi.com/developer/billing/subscriptions
2. Click on "Video Transcript Scraper"
3. View your current usage and limits

The free tier gives you 100 requests per month - that's about 3 recipe videos per day!

## 💰 Cost Examples

### Free Tier (100 requests/month)
- Perfect for: Personal use, testing
- ~3 recipe videos per day
- **Cost**: $0

### Basic Plan (1000 requests/month)
- Perfect for: Regular cooking enthusiasts
- ~30 recipe videos per day
- **Cost**: $9.99/month

### Pro Plan (10000 requests/month)
- Perfect for: Content creators, recipe curators
- ~300 recipe videos per day
- **Cost**: $29.99/month

## 🎓 Pro Tips

1. **Test with free tier first** - Make sure it works for your use case
2. **Recipe websites don't use API** - They work without RapidAPI, so save your quota for videos
3. **Monitor usage** - Check your dashboard regularly to avoid overages
4. **Upgrade when needed** - Start free, upgrade if you need more

## 🐛 Troubleshooting

### "API key not configured"
**Solution**: Make sure your `.env` file has `RAPIDAPI_KEY=...` and restart the app

### "Failed to extract recipe"
**Possible causes**:
- Video has no transcript/captions available
- API quota exceeded (check dashboard)
- Video is private or restricted

**Solution**: Check RapidAPI dashboard for error details

### "Status: 429 Too Many Requests"
**Solution**: You've hit your monthly limit. Either:
- Wait until next month (free tier)
- Upgrade to a paid plan
- Use recipe websites instead (they don't count toward quota)

### "Status: 401 Unauthorized"
**Solution**: 
- Verify your API key is correct
- Make sure you're subscribed to the API
- Check that your subscription is active

## 🔄 Migration from Old Setup

If you were using separate YouTube/TikTok/Instagram APIs:

1. **Unsubscribe** from old APIs (save money!)
2. **Subscribe** to Video Transcript Scraper
3. **Update** `.env` with new `RAPIDAPI_KEY`
4. **Delete** old API keys if any
5. **Restart** the app

The code will automatically use the new unified API!

## 📞 Support

Need help?
- **RapidAPI Support**: Click "Contact Provider" on the API page
- **App Issues**: Check the main documentation or create an issue

## 🎉 You're All Set!

That's it! Your app can now extract recipes from videos across all major platforms with a single API subscription.

Happy cooking! 👨‍🍳👩‍🍳

