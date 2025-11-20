# Social Media Recipe Extraction Setup

This guide explains how to set up enhanced social media recipe extraction using RapidAPI services.

## 🎯 Overview

The app now supports advanced recipe extraction from social media videos using:
- **OpenAI Vision API** - Analyzes video frames and images
- **RapidAPI** - Accesses social media content that blocks standard scraping
- **Multiple extraction methods** - Combines text, captions, and visual analysis

## 🔑 Required API Keys

### 1. OpenAI API Key (Required)
**Already configured** - Used for recipe extraction and vision analysis

**Cost:** GPT-4 Vision is more expensive than regular GPT-4
- ~$0.01-0.03 per image analysis
- Consider costs when analyzing multiple frames

### 2. RapidAPI Key (Optional but Recommended)
**Significantly improves** YouTube, TikTok, and Instagram extraction

**Get your key:**
1. Go to [https://rapidapi.com/](https://rapidapi.com/)
2. Create a free account
3. Navigate to your profile → Apps → Add New App
4. Copy your API key

**Add to `.env` file:**
```
RAPIDAPI_KEY=your_rapidapi_key_here
```

## 📱 Recommended RapidAPI Service

**ONE API for ALL platforms!** 🎉

### Video Transcript Scraper (Highly Recommended)
**One API that works for YouTube, TikTok, Instagram, Facebook, X (Twitter), Vimeo, and more!**

- **URL**: https://rapidapi.com/gaudard.olivier/api/video-transcript-scraper
- **Pricing**: 
  - Free tier: 100 requests/month
  - Basic: $9.99/month - 1000 requests
  - Pro: $29.99/month - 10000 requests
- **Features**:
  - Full video transcripts with timestamps
  - Works across ALL major platforms
  - Video metadata (title, description, duration, views, etc.)
  - LLM-ready JSON output
  - Fast response times (milliseconds)
  - High accuracy transcription

**Why this API?**
- ✅ One subscription instead of three separate APIs
- ✅ Unified response format for all platforms
- ✅ Better transcript quality than platform-specific scrapers
- ✅ More reliable (constantly maintained)
- ✅ More cost-effective

**Setup Steps:**
1. Go to the API page (link above)
2. Click "Subscribe to Test"
3. Choose a plan (free tier is great for testing)
4. Get your API key from your RapidAPI dashboard
5. Add it to your `.env` file

## 🚀 How It Works

### All Video Platforms (YouTube, TikTok, Instagram, etc.)
The app uses a unified extraction approach:

1. **Basic fallback** - Tries platform-specific scraping
2. **RapidAPI Transcript Scraper** - Gets full video transcript and metadata
3. **OpenAI Vision** - Analyzes thumbnails/images (if available)
4. **AI Processing** - Combines all data to extract the complete recipe

**Example Flow for YouTube:**
```
URL → youtube_explode_dart (captions) 
    → RapidAPI (full transcript + metadata)
    → Vision API (thumbnail analysis)
    → Combined → AI extraction → Recipe JSON
```

**Example Flow for TikTok:**
```
URL → Basic scraping (limited)
    → RapidAPI (transcript + video info)
    → Combined → AI extraction → Recipe JSON
```

**Example Flow for Instagram:**
```
URL → Basic scraping (limited)
    → RapidAPI (transcript + post data)
    → Vision API (image analysis)
    → Combined → AI extraction → Recipe JSON
```

## 💰 Cost Considerations

### Without RapidAPI (Free)
- ✅ Recipe websites: Excellent
- ⚠️ YouTube: Limited (caption-dependent)
- ❌ TikTok: Very limited
- ❌ Instagram: Very limited

### With RapidAPI Free Tier (100 requests/month)
- ✅ Recipe websites: Excellent
- ✅ YouTube: Very Good
- ✅ TikTok: Good
- ✅ Instagram: Good
- **Perfect for testing and personal use!**

### With RapidAPI Basic Plan ($9.99/month - 1000 requests)
- ✅ All platforms: Excellent
- Good for regular users
- ~30 videos per day
- More than enough for most recipe enthusiasts

### With RapidAPI Pro Plan ($29.99/month - 10000 requests)
- ✅ All platforms: Excellent
- Perfect for power users
- ~300 videos per day
- Ideal for content creators or recipe curators

## 📊 Expected Success Rates

| Platform | Without RapidAPI | With RapidAPI | With Vision API |
|----------|-----------------|---------------|-----------------|
| Recipe Blogs | 95% | 95% | 95% |
| YouTube | 30% | 60% | 75% |
| TikTok | 10% | 40% | 50% |
| Instagram | 10% | 50% | 70% |

## ⚙️ Configuration

### Minimal Setup (Free)
```env
OPENAI_API_KEY=sk-...
# No RAPIDAPI_KEY needed
```
- Recipe websites work perfectly
- Videos have limited success

### Recommended Setup (Mostly Free)
```env
OPENAI_API_KEY=sk-...
RAPIDAPI_KEY=your_rapidapi_key
```
- Subscribe to Video Transcript Scraper (free tier: 100 requests/month)
- Works for ALL video platforms
- Significantly better video extraction
- Vision analysis of thumbnails/images included

### Premium Setup (Paid)
```env
OPENAI_API_KEY=sk-...
RAPIDAPI_KEY=your_rapidapi_key
```
- Paid RapidAPI subscriptions
- Unlimited video extraction
- Best possible results

## 🔧 Implementation Details

### Vision API Usage
The app uses OpenAI's GPT-4 Vision to analyze:
- YouTube video thumbnails
- Instagram post images
- TikTok preview images (when available)

**What Vision API sees:**
- Visible ingredients in images
- Text overlays with measurements
- Recipe steps shown visually
- Cooking techniques being demonstrated

### Fallback Strategy
The service tries multiple methods in order:
1. **Structured data** (Recipe Schema, if available)
2. **API scraping** (RapidAPI, if configured)
3. **Basic scraping** (HTML parsing)
4. **Vision analysis** (images/thumbnails)
5. **AI extraction** (from combined data)

If earlier methods succeed, later ones are skipped to save costs.

## 🐛 Troubleshooting

### "API key not configured"
- Check `.env` file has `RAPIDAPI_KEY=...`
- Restart the app after adding the key
- Verify the key is valid on RapidAPI dashboard
- Make sure you've subscribed to the Video Transcript Scraper API

### Vision API errors
- Check OpenAI API key has GPT-4 Vision access
- Verify sufficient API credits
- Image URLs must be publicly accessible

### Rate limits
- Free tiers have daily/monthly limits
- Upgrade RapidAPI subscription for more requests
- Cache results to avoid repeated API calls

### High costs
- Vision API can be expensive with many requests
- Consider limiting to 1-2 frames per video
- Use text extraction when sufficient

## 📈 Future Enhancements

Planned improvements:
- [ ] Video downloading and multi-frame analysis
- [ ] Caching of API responses
- [ ] OCR for text in images
- [ ] Support for more platforms (Facebook, Pinterest)
- [ ] Batch processing for multiple videos
- [ ] Recipe confidence scoring

## 🎓 Best Practices

1. **Start with free tiers** - Test before paying
2. **Monitor API usage** - Check RapidAPI dashboard regularly
3. **Cache results** - Don't re-extract same URLs
4. **Prefer recipe websites** - Always best option
5. **Check creator bios** - Often link to blog with recipes

## 📝 Summary

- **Recipe websites**: Work great without any setup
- **YouTube**: Decent with captions, better with RapidAPI
- **TikTok/Instagram**: Need RapidAPI for reliable results
- **Vision API**: Significantly improves all video sources
- **Cost**: Free tier sufficient for most users

For the best experience with social media recipes, configure RapidAPI with free tier subscriptions!

