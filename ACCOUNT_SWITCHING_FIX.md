# Account Switching Fix

## Issue: Infinite Loading When Switching Accounts ✅

**Problem**: 
- After signing out and trying to sign in with a different account, the app showed an infinite loading spinner
- Users couldn't seamlessly switch between accounts

**Root Causes**:
1. **Login Screen Loading State**: The loading spinner was kept active indefinitely, waiting for AuthWrapper to navigate away, but without a timeout
2. **AuthWrapper Not Detecting User Changes**: The AuthWrapper wasn't properly tracking when users switched accounts
3. **Const Constructor Issue**: Using `const MainNavigation()` prevented the widget from rebuilding when switching to a different user

## Fixes Applied

### 1. Login Screen Timeout Fix
**File**: `lib/screens/auth/login_screen.dart`

Added a 300ms timeout to prevent infinite loading:

```dart
// Success! Keep loading state for a reasonable time while AuthWrapper navigates
// but set a timeout to prevent infinite loading
await Future.delayed(const Duration(milliseconds: 300));

// Check if we're still on this screen (AuthWrapper should have navigated us away)
if (mounted) {
  // If we're still here after 300ms, something might be wrong with navigation
  // but the user IS logged in, so just turn off loading
  setState(() => _isLoading = false);
}
```

**Result**: Loading spinner will automatically turn off after 300ms, even if navigation is delayed.

---

### 2. AuthWrapper User Tracking
**File**: `lib/screens/auth/auth_wrapper.dart`

Added tracking of the last user ID to detect account switches:

```dart
String? _lastUserId;  // Track the current user

// In initState:
_lastUserId = Supabase.instance.client.auth.currentUser?.id;

// In build method:
// Detect user change (switching accounts)
if (currentUserId != null && currentUserId != _lastUserId && _lastUserId != null) {
  print('User switched from $_lastUserId to $currentUserId');
  _lastUserId = currentUserId;
  // Force rebuild to ensure navigation happens
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) setState(() {});
  });
}
```

**Result**: AuthWrapper now properly detects when users switch accounts and forces a rebuild.

---

### 3. MainNavigation Key Fix
**File**: `lib/screens/auth/auth_wrapper.dart`

Changed from const constructor to keyed constructor:

```dart
// Before:
if (session != null && user != null) {
  return const MainNavigation();
}

// After:
if (session != null && user != null) {
  return MainNavigation(key: ValueKey(currentUserId));
}
```

**Result**: MainNavigation rebuilds completely when switching to a different user, ensuring clean state.

---

## Testing Steps

### Test Account Switching:
1. ✅ Sign in with Account A
2. ✅ Navigate around the app
3. ✅ Sign out
4. ✅ Sign in with Account B
   - Should show loading briefly then navigate to main screen
   - NO infinite loading spinner
5. ✅ Verify you're seeing Account B's data (not Account A's)
6. ✅ Sign out again
7. ✅ Sign back in with Account A
   - Should work seamlessly

### Test Same Account Re-login:
1. ✅ Sign in with an account
2. ✅ Sign out
3. ✅ Sign in with the SAME account
   - Should work without issues

### Test Auto Sign-In:
1. ✅ Sign in with an account
2. ✅ Close the app (don't sign out)
3. ✅ Reopen the app
   - Should auto-sign in to the same account

---

## Debug Logging

The AuthWrapper now includes helpful debug logging:

```
Auth state - Session: true, User: true, UserId: abc123...
Auth event: SIGNED_IN
User switched from xyz789 to abc123
User signed out (was abc123)
```

This helps troubleshoot any auth state issues in the future.

---

## Summary of Changes

### Modified Files:
1. **lib/screens/auth/login_screen.dart**
   - Added 300ms timeout to prevent infinite loading
   - Improved loading state management

2. **lib/screens/auth/auth_wrapper.dart**
   - Added user ID tracking to detect account switches
   - Changed MainNavigation to use unique key based on userId
   - Added debug logging for auth events
   - Force rebuild when user switches accounts

### Key Improvements:
- ✅ No more infinite loading when switching accounts
- ✅ Clean state when switching between users
- ✅ Better debugging capabilities
- ✅ Maintains auto-sign-in functionality
- ✅ Works seamlessly with sign-out flow

---

## Technical Details

### Why the Timeout?
The 300ms timeout ensures that even if the StreamBuilder in AuthWrapper doesn't emit immediately, the loading state won't persist forever. This is a safety net for edge cases.

### Why Track User ID?
By tracking the last user ID, we can detect when:
- A new user signs in (different from the last one)
- The same user signs back in (same as last one)
- A user signs out (current user becomes null)

This allows us to handle each case appropriately and force UI updates when needed.

### Why Use ValueKey?
Using `ValueKey(currentUserId)` on MainNavigation ensures that when the user ID changes, Flutter treats it as a completely new widget and rebuilds everything from scratch. This prevents stale state from the previous user from persisting.

---

## No Breaking Changes

All changes are backward compatible and don't affect:
- Existing sign-in/sign-out flows
- Auto-sign-in on app restart
- Any other authentication features

The changes only improve the reliability of account switching.

