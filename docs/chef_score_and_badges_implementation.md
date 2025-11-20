# Chef Score & Badge System Implementation

## Overview
This document describes the implementation of the improved chef score calculation and the new badge system for the Cookpad Recipe Social App.

## 🎯 What Was Implemented

### 1. Improved Chef Score Calculation

#### Old Formula (Simple)
```
Chef Score = (Average Rating × 20) + (Total Favorites × 0.1)
```

#### New Formula (Balanced Multi-Factor)
```
Chef Score = (
    (Average Rating × 15.0) +           // Quality (max 75 for 5.0 rating)
    (Recipe Count × 2.0) +              // Productivity (2 points per recipe)
    (Total Favorites × 0.5) +           // Popularity (0.5 per favorite)
    (Follower Count × 1.0) +            // Influence (1 point per follower)
    (Comment Count × 0.2) +             // Engagement (0.2 per comment)
    (Total Ratings × 0.3)               // Community validation (capped at 100)
) × Activity Multiplier                 // 1.2 for active, 1.0 normal, 0.8 inactive
```

#### Activity Multiplier
- **1.2x** - User posted a recipe in the last 30 days (active)
- **1.0x** - User posted a recipe in the last 90 days (normal)
- **0.8x** - User hasn't posted in 90+ days (inactive)

#### Benefits of New Formula
✅ Rewards both quality AND quantity  
✅ Encourages community engagement (comments, followers)  
✅ Prevents gaming with single high-rated recipe  
✅ Rewards active contributors with bonus multiplier  
✅ More balanced and comprehensive scoring  

### 2. Badge System

#### Database Structure

**Badges Table**
- Stores all available badges
- Fields: id, name, description, icon (emoji), tier, requirement_type, requirement_value

**User_Badges Table**
- Tracks which users have earned which badges
- Fields: user_id, badge_id, awarded_at
- Junction table between users and badges

#### Badge Tiers
- 🥉 **Bronze** - Entry level achievements
- 🥈 **Silver** - Intermediate achievements
- 🥇 **Gold** - Advanced achievements  
- 💎 **Platinum** - Elite achievements

#### Available Badges

**Chef Score Tiers**
- 👨‍🍳 Apprentice Chef (25 score)
- 🏠 Home Cook (50 score)
- ⭐ Skilled Chef (100 score)
- 🎖️ Master Chef (200 score)
- 👑 Celebrity Chef (500 score)

**Recipe Count**
- 📝 First Recipe (1 recipe)
- 📚 Recipe Creator (10 recipes)
- 📖 Prolific Chef (50 recipes)
- 🏆 Recipe Master (100 recipes)

**Quality (Average Rating)**
- ⭐ Quality Cook (4.0+ avg with 10+ recipes)
- 🌟 Quality Master (4.5+ avg with 20+ recipes)
- 💎 Perfectionist (4.8+ avg with 30+ recipes)

**Community Favorite (Favorites Received)**
- 💙 Popular (50 favorites)
- ❤️ Community Favorite (200 favorites)
- 💖 Fan Favorite (500 favorites)

**Followers**
- 👥 Influencer (25 followers)
- 🌐 Social Chef (100 followers)
- ✨ Celebrity (500 followers)

**Engagement (Comments Received)**
- 💬 Engaging (100 comments)
- 🗣️ Conversationalist (500 comments)

**Special**
- 🔥 Trending Chef (3+ recipes in 30 days with 20+ engagement)

### 3. Automatic Badge Awarding

#### Trigger System
Badges are automatically checked and awarded when:
- User posts a recipe
- User receives a rating
- User receives a favorite
- User gains a follower
- User's recipe receives a comment

#### Notification System
When a badge is earned:
1. Badge is added to `user_badges` table
2. Trigger automatically creates a notification
3. User sees: "New Badge Earned! [emoji]"
4. Message: "Congratulations! You earned the '[Badge Name]' badge!"

### 4. Frontend Integration

#### Profile Detail Screen
- Shows up to 6 top badges in a dedicated badges section
- Badges displayed with icon, name, and tier-colored border
- Tooltip shows full badge description on hover
- Badges section appears between stats and bio

#### Creator Profile Card
- Shows up to 3 top badges as emoji icons
- Appears below chef score
- Tooltip shows badge name on hover
- Compact display suitable for card format

#### Badge Service
Provides methods for:
- `getUserBadges(userId)` - Get all badges earned by user
- `getAllBadges()` - Get all available badges
- `getBadgesWithStatus(userId)` - Get earned vs locked badges
- `getTopBadges(userId, limit)` - Get most prestigious badges
- `getBadgeStats(userId)` - Get badge count by tier

## 📁 Files Created/Modified

### New Files
1. `supabase/migrations/010_badges_and_improved_chef_score.sql` - Database migration
2. `lib/models/badge_model.dart` - Badge data model
3. `lib/services/badge_service.dart` - Badge service for fetching badges

### Modified Files
1. `lib/models/user_model.dart` - Added optional badges field
2. `lib/screens/my_profile_detail_screen.dart` - Added badge display section
3. `lib/widgets/creator_profile_card.dart` - Added compact badge display

## 🚀 How to Deploy

### 1. Run Database Migration
```bash
# The migration will automatically run when you push to Supabase
# Or run manually in Supabase SQL editor:
```
Execute the contents of `supabase/migrations/010_badges_and_improved_chef_score.sql`

### 2. Recalculate Scores for Existing Users
The migration automatically runs this at the end, but you can also run it manually:
```sql
SELECT recalculate_all_chef_scores_and_badges();
```

### 3. Test the Features
1. Create/update recipes to trigger chef score updates
2. Check that badges are automatically awarded
3. Verify notifications are sent for new badges
4. Check badge display on profile screens and creator cards

## 💡 Future Enhancements

### Possible Badge Additions
- 🍕 Cuisine Specialist (50+ recipes in one cuisine type)
- 🎨 Creative Chef (High remix count)
- 💬 Mentor (Many helpful comments given)
- ⚡ Speed Chef (Quick recipe creation)
- 🌍 International Chef (Recipes from multiple cuisines)

### Possible Features
- Badge showcase on profile (choose which to display)
- Badge progress tracking (e.g., "50/100 followers to Social Chef")
- Rare/seasonal badges
- Badge-specific rewards or unlocks
- Leaderboard filtered by badges

## 📊 Score Examples

### Example 1: Quality-Focused Chef
- 5 recipes, 4.8 avg rating, 20 favorites, 15 followers, 30 comments, 25 ratings
- Score: (4.8×15) + (5×2) + (20×0.5) + (15×1) + (30×0.2) + (25×0.3) × 1.2
- Score: 72 + 10 + 10 + 15 + 6 + 7.5 × 1.2 = **145.2**

### Example 2: Prolific Chef
- 50 recipes, 4.0 avg rating, 150 favorites, 40 followers, 200 comments, 100 ratings
- Score: (4.0×15) + (50×2) + (150×0.5) + (40×1) + (200×0.2) + (100×0.3) × 1.2
- Score: 60 + 100 + 75 + 40 + 40 + 30 × 1.2 = **414.0**

### Example 3: Community Star
- 20 recipes, 4.5 avg rating, 300 favorites, 150 followers, 500 comments, 80 ratings
- Score: (4.5×15) + (20×2) + (300×0.5) + (150×1) + (500×0.2) + (80×0.3) × 1.2
- Score: 67.5 + 40 + 150 + 150 + 100 + 24 × 1.2 = **637.8**

## 🎉 Conclusion

The new chef score system provides a more comprehensive and fair way to recognize chefs' contributions, while the badge system adds gamification and visual recognition for achievements. Together, they encourage quality content, community engagement, and active participation in the platform.

