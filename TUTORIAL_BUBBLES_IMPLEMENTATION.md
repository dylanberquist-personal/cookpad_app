# Tutorial Bubbles Implementation

This document describes the implementation of tutorial bubbles throughout the app.

## Overview

Three tutorial bubbles have been added to guide users through key features:

1. **Profile Screen Tutorial** - Encourages users to complete their profile
2. **Home Screen Tutorial** - Prompts users to try the recipe generator after login
3. **Generate Recipe Screen Tutorial** - Explains the pantry items toggle button

## Implementation Details

### 1. Profile Screen Tutorial

**Location:** `lib/screens/profile_screen.dart`

**Trigger Conditions:**
- Shows next to "My Profile" option in the profile screen
- Only appears if user has incomplete profile:
  - No bio/description
  - Skill level is still 'beginner'
  - No profile picture uploaded

**Behavior:**
- Bubble appears to the right of the "My Profile" list item
- Shows "Complete your profile!" message
- Dismissed by clicking the X button
- Never shows again once dismissed (tracked in preferences)
- Automatically rechecks when returning from profile edit screen

**Key Components:**
- `_ProfileHintBubble` widget with left-pointing arrow
- `_LeftTrianglePainter` for the arrow
- Uses GlobalKey `_myProfileKey` for positioning
- Tracked via `PreferencesService.hasSeenProfileHint()`

### 2. Home Screen Tutorial

**Location:** `lib/screens/main_navigation.dart`

**Trigger Conditions:**
- Shows above the FAB (Floating Action Button) on the feed screen
- Only appears when user is redirected from login page
- Shown on the home/feed screen (index 0)

**Behavior:**
- Bubble appears above the FAB with "Generate a recipe!" message
- Dismissed by clicking the X button
- Automatically disappears when navigating away from home screen
- Never shows again once dismissed (tracked in preferences)

**Key Components:**
- `_GenerateRecipeHintBubble` widget with down-pointing arrow
- `_DownTrianglePainter` for the arrow
- Uses GlobalKey `_fabKey` for positioning
- Tracked via `PreferencesService.hasSeenGenerateRecipeHint()`
- Login screen passes `isFromLogin: true` flag to MainNavigation

### 3. Generate Recipe Screen - Pantry Toggle Tutorial

**Location:** `lib/screens/generate_recipe_screen.dart`

**Trigger Conditions:**
- Shows below the pantry toggle button in the app bar
- Only appears if pantry feature is enabled
- Shows on first visit to generate recipe screen after enabling pantry
- Similar behavior to the existing dietary restrictions tutorial

**Behavior:**
- Bubble appears below the pantry toggle button
- Shows "Toggle your pantry items" message
- Dismissed by clicking the X button
- Never shows again once dismissed (tracked in preferences)

**Key Components:**
- `_PantryHintBubble` widget with up-pointing arrow
- Uses existing `_TrianglePainter` for the arrow
- Uses GlobalKey `_pantryButtonKey` for positioning
- Tracked via `PreferencesService.hasSeenPantryHint()`

## Shared Architecture

All three tutorial bubbles follow a similar pattern:

1. **GlobalKey** - Used to get the position and size of the target UI element
2. **OverlayEntry** - Creates an overlay that appears on top of other content
3. **PreferencesService** - Tracks whether the hint has been shown
4. **Session Tracking** - `_hasShownXxxHintThisSession` prevents showing multiple times in one session
5. **Lifecycle Management** - Overlays are properly removed when:
   - Screen is no longer visible
   - App goes to background
   - User navigates away
   - Widget is disposed

## PreferencesService Updates

New methods added to `lib/services/preferences_service.dart`:

- `hasSeenPantryHint()` / `setPantryHintSeen()` / `resetPantryHint()`
- `hasSeenProfileHint()` / `setProfileHintSeen()` / `resetProfileHint()`
- `hasSeenGenerateRecipeHint()` / `setGenerateRecipeHintSeen()` / `resetGenerateRecipeHint()`
- `isFromLogin()` / `setFromLogin(bool value)` (for tracking login navigation)

## Visual Design

All bubbles follow consistent design:

- **Color:** Orange background (`Colors.orange`)
- **Size:** 180-200px width
- **Shadow:** Soft shadow for depth
- **Close Button:** Small X button in top-right corner
- **Icon:** Info icon (`Icons.info_outline`)
- **Arrow:** Pointing to the relevant UI element
- **Text:** Clear, actionable message

## Testing

To test the bubbles:

1. **Profile Tutorial:**
   - Create a new account or use one with incomplete profile
   - Navigate to Profile screen
   - Bubble should appear next to "My Profile"

2. **Home Screen Tutorial:**
   - Log out and log back in
   - After login, you should be on the feed screen
   - Bubble should appear above the FAB

3. **Pantry Tutorial:**
   - Enable pantry feature in Settings
   - Navigate to Generate Recipe screen
   - Bubble should appear below the pantry toggle button

## Reset Hints (for Testing)

To reset hints and see them again, you can:

1. Call the reset methods in PreferencesService:
   - `resetProfileHint()`
   - `resetGenerateRecipeHint()`
   - `resetPantryHint()`

2. Or clear app data (Android) / delete and reinstall (iOS)

