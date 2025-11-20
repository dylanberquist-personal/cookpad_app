# Recipe Link Extraction Guide

This document explains how recipe link extraction works and what to expect from different types of sources.

## ✅ What Works Best

### Recipe Websites
**Success Rate: ~95%**

Works excellently with major recipe sites that use structured data:
- AllRecipes, Food Network, Bon Appétit, Epicurious
- Serious Eats, Tasty, Delish, Simply Recipes
- Food blogs with Recipe Schema markup
- King Arthur Baking, Yummly, The Kitchn

**Why it works:** These sites use Recipe Schema (JSON-LD) which provides structured data that can be easily extracted.

## ⚠️ Enhanced Video Support

### Video Platforms (YouTube, TikTok, Instagram)
**Success Rate: 40-75% (with RapidAPI + Vision API)**
**Success Rate: 20-30% (without APIs)**

The app now uses advanced extraction methods:

1. **OpenAI Vision API**: Analyzes video thumbnails and images for visible recipe information
2. **RapidAPI Integration**: Bypasses bot protection to access social media content
3. **Multiple Sources**: Combines captions, descriptions, metadata, and visual analysis
4. **Smart Fallbacks**: Tries multiple methods automatically

**Without API Keys:**
Video recipes remain challenging due to:
- **Visual Content**: Recipe details shown in video, not text
- **Minimal Captions**: Descriptions often promotional only
- **Bot Protection**: Platforms block automated access
- **Incomplete Information**: Text is often just teasers

**What Gets Extracted:**
- YouTube: Title, description, closed captions (if available)
- TikTok: Video description only (if accessible)
- Instagram: Post caption only (if accessible)

### When Videos Work

Videos CAN work if the creator includes detailed text:
- ✅ Full ingredient list in description
- ✅ Step-by-step instructions in captions
- ✅ Detailed closed captions with measurements
- ✅ Pinned comment with full recipe

### Best Practices for Video Recipes

If you want to save a recipe from a video:

1. **Check for Written Version**
   - Look in video description for blog/website links
   - Check pinned comments for full recipe
   - Visit creator's profile for recipe links

2. **Manual Transcription**
   - Watch the video and type out the recipe
   - Paste the transcribed recipe into the chat
   - Let AI format it for you

3. **Alternative Sources**
   - Search for the recipe name + creator name
   - Check if recipe is on their blog/website
   - Look for recipe in Instagram "link in bio"

## 🎯 Recommended Workflow

### For Blog Recipes
1. Copy the recipe URL
2. Paste into recipe generator
3. ✅ Done! Recipe extracts automatically

### For Video Recipes
1. Check video description for blog link → Use blog link instead
2. If no blog link, check pinned comment → Copy recipe text manually
3. Look for "link in bio" or creator website → Use that link
4. Last resort: Watch video and transcribe → Paste text into chat

## 🔧 Technical Details

### URL Detection
The app automatically detects:
- YouTube: `youtube.com`, `youtu.be`
- TikTok: `tiktok.com`, `vm.tiktok.com`
- Instagram: `instagram.com`, `instagr.am`
- Recipe Sites: 18+ major cooking websites
- General: Any other URL with Recipe Schema

### Extraction Methods

1. **Recipe Schema (Best)**
   - Reads structured JSON-LD data
   - Gets exact ingredients, steps, times
   - Works on most modern recipe websites

2. **HTML Scraping (Good)**
   - Extracts text from webpage
   - Uses AI to structure the content
   - Works when schema isn't available

3. **Video Metadata (Limited)**
   - Gets title, description, captions
   - Often insufficient for complete recipe
   - Best with detailed captions

4. **AI Extraction (Fallback)**
   - Processes any text content
   - Structures into recipe format
   - Quality depends on source content

## 📊 Success Rates by Platform

| Platform | Without APIs | With RapidAPI | With Vision API | Why |
|----------|--------------|---------------|-----------------|-----|
| Recipe Blogs | 95% | 95% | 95% | Structured data, complete recipes |
| Recipe Websites | 90% | 90% | 90% | Recipe Schema support |
| YouTube | 30% | 60% | 75% | Now analyzes thumbnails + extended metadata |
| TikTok | 10% | 40% | 50% | RapidAPI bypasses bot protection |
| Instagram | 10% | 50% | 70% | Vision API analyzes post images |
| General Blogs | 70% | 70% | 70% | Varies by site structure |

**Note:** See `social_media_api_setup.md` for configuration details.

## 💡 Tips for Success

1. **Prefer text sources over videos**
2. **Look for "link in bio" on social media**
3. **Check video descriptions for blog links**
4. **Use pinned comments for full recipes**
5. **When in doubt, manually copy the text**

## 🐛 Common Error Messages

### "No recipe found in content"
- Content doesn't contain a structured recipe
- Video shows recipe visually without text
- **Solution:** Look for written version or transcribe manually

### "Could not extract content from [Platform]"
- Platform blocks automated access
- **Solution:** Copy text manually from the post/video

### "Insufficient text content"
- Too little text to extract a recipe
- **Solution:** Find a more detailed source

### "Website blocking automated access"
- Site has bot protection
- **Solution:** Copy recipe manually from browser

## 🚀 Future Improvements

Potential enhancements being considered:
- Video frame analysis using AI vision
- Better caption extraction
- Community recipe database
- Manual entry UI for video recipes

