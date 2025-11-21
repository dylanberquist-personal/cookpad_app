import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:palette_generator/palette_generator.dart';
import 'dart:io';
import '../services/auth_service.dart';
import '../services/follow_service.dart';
import '../services/recipe_service_supabase.dart';
import '../services/collection_service.dart';
import '../services/preferences_service.dart';
import '../services/badge_service.dart';
import '../models/user_model.dart';
import '../models/recipe_model.dart';
import '../models/collection_model.dart';
import '../models/badge_model.dart';
import '../config/supabase_config.dart';
import '../widgets/creator_profile_card.dart';
import '../widgets/notification_badge_icon.dart';
import '../services/block_service.dart';
import 'main_navigation.dart';
import 'recipe_detail_screen_new.dart';
import 'collection_detail_screen.dart';

class MyProfileDetailScreen extends StatefulWidget {
  final String userId;

  const MyProfileDetailScreen({
    super.key,
    required this.userId,
  });

  @override
  State<MyProfileDetailScreen> createState() => _MyProfileDetailScreenState();
}

class _MyProfileDetailScreenState extends State<MyProfileDetailScreen> {
  final _authService = AuthService();
  final _followService = FollowService();
  final _recipeService = RecipeServiceSupabase();
  final _collectionService = CollectionService();
  final _preferencesService = PreferencesService();
  final _badgeService = BadgeService();
  final _blockService = BlockService();
  final _supabase = SupabaseConfig.client;
  final _scrollController = ScrollController();
  final GlobalKey _recipesKey = GlobalKey();
  final GlobalKey _collectionsKey = GlobalKey();
  
  UserModel? _userProfile;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isUploadingImage = false;
  bool _isFollowing = false;
  bool _isTogglingFollow = false;
  bool _isBlockedBy = false;
  Color? _bannerColor;
  int _currentNavIndex = 4; // Profile is index 4
  List<RecipeModel> _publicRecipes = [];
  List<CollectionModel> _publicCollections = [];

  // Editable fields
  final _bioController = TextEditingController();
  final _displayNameController = TextEditingController();
  String _selectedSkillLevel = 'beginner';
  List<String> _selectedDietaryRestrictions = [];
  
  // Stats
  int _totalRecipes = 0;
  int _followerCount = 0;
  int _followingCount = 0;
  double _averageRecipeRating = 0.0;
  
  // Badges
  List<BadgeModel> _badges = [];

  // Available options
  final List<String> _skillLevels = ['beginner', 'intermediate', 'advanced'];
  final List<String> _dietaryOptions = [
    'Vegetarian',
    'Vegan',
    'Gluten-Free',
    'Dairy-Free',
    'Nut-Free',
    'Keto',
    'Paleo',
    'Low-Carb',
    'Halal',
    'Kosher',
    'Pescatarian',
    'Carnivore',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _bioController.dispose();
    _displayNameController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      // Load user profile
      final profile = await _authService.getCurrentUserProfile();
      if (profile == null || profile.id != widget.userId) {
        // Load other user's profile
        final response = await _supabase
            .from('users')
            .select()
            .eq('id', widget.userId)
            .single();
        _userProfile = UserModel.fromJson(response);
      } else {
        _userProfile = profile;
      }

      // Load stats
      await _loadStats();
      
      // Load badges
      await _loadBadges();

      // Load follow status and block status
      if (!_isOwner) {
        await _checkFollowStatus();
        await _checkBlockStatus();
      }

      // Load public recipes
      await _loadPublicRecipes();

      // Load public collections
      await _loadPublicCollections();

      // Load banner color from profile picture
      await _loadBannerColor();

      // Initialize editable fields
      _bioController.text = _userProfile?.bio ?? '';
      _displayNameController.text = _userProfile?.displayName ?? '';
      _selectedSkillLevel = _userProfile?.skillLevel ?? 'beginner';
      _selectedDietaryRestrictions = List.from(_userProfile?.dietaryRestrictions ?? []);

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _loadStats() async {
    try {
      // Total recipes
      final recipesResponse = await _supabase
          .from('recipes')
          .select('id')
          .eq('user_id', widget.userId);
      _totalRecipes = (recipesResponse as List).length;

      // Follower count
      final followersResponse = await _supabase
          .from('follows')
          .select('id')
          .eq('following_id', widget.userId);
      _followerCount = (followersResponse as List).length;

      // Following count
      final followingResponse = await _supabase
          .from('follows')
          .select('id')
          .eq('follower_id', widget.userId);
      _followingCount = (followingResponse as List).length;

      // Average recipe rating
      final recipes = await _supabase
          .from('recipes')
          .select('average_rating')
          .eq('user_id', widget.userId)
          .gt('rating_count', 0);
      
      if ((recipes as List).isNotEmpty) {
        final ratings = recipes
            .map((r) => (r['average_rating'] as num?)?.toDouble() ?? 0.0)
            .toList();
        _averageRecipeRating = ratings.reduce((a, b) => a + b) / ratings.length;
      }
    } catch (e) {
      print('Error loading stats: $e');
    }
  }

  Future<void> _loadBadges() async {
    try {
      final badges = await _badgeService.getTopBadges(widget.userId, limit: 6);
      setState(() {
        _badges = badges;
      });
    } catch (e) {
      print('Error loading badges: $e');
    }
  }

  Future<void> _loadBannerColor() async {
    if (_userProfile?.profilePictureUrl == null) {
      _bannerColor = Theme.of(context).primaryColor;
      return;
    }

    try {
      final imageProvider = NetworkImage(_userProfile!.profilePictureUrl!);
      final paletteGenerator = await PaletteGenerator.fromImageProvider(imageProvider);
      final dominantColor = paletteGenerator.dominantColor?.color;
      
      if (dominantColor != null) {
        setState(() {
          _bannerColor = dominantColor;
        });
      } else {
        _bannerColor = Theme.of(context).primaryColor;
      }
    } catch (e) {
      print('Error loading banner color: $e');
      _bannerColor = Theme.of(context).primaryColor;
    }
  }

  Future<void> _checkFollowStatus() async {
    try {
      final isFollowing = await _followService.isFollowing(widget.userId);
      setState(() {
        _isFollowing = isFollowing;
      });
    } catch (e) {
      print('Error checking follow status: $e');
    }
  }

  Future<void> _checkBlockStatus() async {
    try {
      final isBlockedBy = await _blockService.isBlockedBy(widget.userId);
      setState(() {
        _isBlockedBy = isBlockedBy;
      });
    } catch (e) {
      print('Error checking block status: $e');
    }
  }

  Future<void> _toggleFollow() async {
    if (_isTogglingFollow) return;

    setState(() => _isTogglingFollow = true);
    try {
      if (_isFollowing) {
        await _followService.unfollowUser(widget.userId);
      } else {
        await _followService.followUser(widget.userId);
      }
      await _checkFollowStatus();
      await _loadStats(); // Reload stats to update follower count
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      setState(() => _isTogglingFollow = false);
    }
  }

  Future<void> _loadPublicRecipes() async {
    try {
      final recipes = await _recipeService.getRecipes(
        userId: widget.userId,
        isPublic: true,
        limit: 50,
      );
      setState(() {
        _publicRecipes = recipes;
      });
    } catch (e) {
      print('Error loading public recipes: $e');
    }
  }

  Future<void> _loadPublicCollections() async {
    try {
      final collections = await _collectionService.getPublicCollections(widget.userId);
      setState(() {
        _publicCollections = collections;
      });
    } catch (e) {
      print('Error loading public collections: $e');
    }
  }

  void _scrollToRecipes() {
    final context = _recipesKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _showFollowersPopup() async {
    try {
      final followers = await _followService.getFollowers(widget.userId);
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => _FollowersFollowingDialog(
          title: 'Followers',
          users: followers,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading followers: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _showFollowingPopup() async {
    try {
      final following = await _followService.getFollowing(widget.userId);
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => _FollowersFollowingDialog(
          title: 'Following',
          users: following,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading following: ${e.toString()}')),
        );
      }
    }
  }

  bool get _isOwner {
    final currentUserId = _supabase.auth.currentUser?.id;
    return currentUserId != null && currentUserId == widget.userId;
  }

  Future<void> _saveProfile() async {
    if (!_isOwner) return;

    setState(() => _isSaving = true);
    try {
      // Check if dietary restrictions have changed
      final oldRestrictions = _userProfile?.dietaryRestrictions ?? [];
      final restrictionsChanged = !_listsEqual(oldRestrictions, _selectedDietaryRestrictions);

      await _authService.updateUserProfile(
        displayName: _displayNameController.text.isEmpty 
            ? null 
            : _displayNameController.text,
        bio: _bioController.text.trim(), // Always pass the text, even if empty
        skillLevel: _selectedSkillLevel,
        dietaryRestrictions: _selectedDietaryRestrictions,
      );

      // If dietary restrictions changed and user has restrictions, reset hint
      if (restrictionsChanged && _selectedDietaryRestrictions.isNotEmpty) {
        await _preferencesService.resetDietaryHint();
      }

      await _loadProfileData();
      setState(() {
        _isEditing = false;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: ${e.toString()}')),
        );
      }
    }
  }

  bool _listsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    final aSet = Set<String>.from(a);
    final bSet = Set<String>.from(b);
    return aSet.difference(bSet).isEmpty && bSet.difference(aSet).isEmpty;
  }

  Future<void> _pickImage() async {
    if (!_isOwner || _isUploadingImage) return;

    try {
      // Show source selection dialog
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null && mounted) {
        await _uploadProfilePicture(pickedFile);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadProfilePicture(XFile imageFile) async {
    if (!_isOwner) return;

    setState(() => _isUploadingImage = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final file = File(imageFile.path);
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = '$userId/$fileName';

      // Delete old profile picture if exists
      if (_userProfile?.profilePictureUrl != null) {
        try {
          final oldUrl = _userProfile!.profilePictureUrl!;
          final uri = Uri.parse(oldUrl);
          final pathSegments = uri.pathSegments;
          final bucketIndex = pathSegments.indexWhere((s) => s == 'profile-pictures');
          if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
            final oldFilePath = pathSegments.sublist(bucketIndex + 1).join('/');
            await _supabase.storage.from('profile-pictures').remove([oldFilePath]);
          }
        } catch (e) {
          print('Warning: Failed to delete old profile picture: $e');
        }
      }

      // Upload new profile picture
      await _supabase.storage.from('profile-pictures').upload(
        filePath,
        file,
      );

      // Get public URL
      final imageUrl = _supabase.storage.from('profile-pictures').getPublicUrl(filePath);

      // Update user profile
      await _authService.updateUserProfile(
        profilePictureUrl: imageUrl,
      );

      // Reload profile data and banner color
      await _loadProfileData();
      await _loadBannerColor();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload profile picture: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_userProfile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('User not found')),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        title: Text(
          _userProfile!.displayName ?? _userProfile!.username,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        actions: _isOwner
            ? [
                if (_isEditing)
                  IconButton(
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check, color: Colors.green),
                    onPressed: _isSaving ? null : _saveProfile,
                    tooltip: 'Save',
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => setState(() => _isEditing = true),
                    tooltip: 'Edit Profile',
                  ),
              ]
            : null,
      ),
      bottomNavigationBar: SizedBox(
        height: 60,
        child: NavigationBar(
          selectedIndex: _currentNavIndex,
          onDestinationSelected: (index) {
            // Dismiss keyboard before navigation
            FocusScope.of(context).unfocus();
            
            // Always navigate to profile screen when clicking profile icon
            if (index == 4) {
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => MainNavigation(initialIndex: 4),
                  ),
                  (route) => false,
                );
              }
              return;
            }
            
            // For other icons, only navigate if not already on that screen
            if (index == _currentNavIndex) return;
            
            if (mounted) {
              // Navigate back to main navigation with the selected index
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => MainNavigation(initialIndex: index),
                ),
                (route) => false,
              );
            }
          },
          height: 60,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, size: 20),
              selectedIcon: Icon(Icons.home, size: 20),
              label: '',
            ),
            NavigationDestination(
              icon: Icon(Icons.search_outlined, size: 20),
              selectedIcon: Icon(Icons.search, size: 20),
              label: '',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined, size: 20),
              selectedIcon: Icon(Icons.auto_awesome, size: 20),
              label: '',
            ),
            NavigationDestination(
              icon: NotificationBadgeIcon(isSelected: false),
              selectedIcon: NotificationBadgeIcon(isSelected: true),
              label: '',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline, size: 20),
              selectedIcon: Icon(Icons.person, size: 20),
              label: '',
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            // Header Section with Gradient from Profile Picture Color
            Container(
              height: 220,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _bannerColor ?? Theme.of(context).primaryColor,
                    (_bannerColor ?? Theme.of(context).primaryColor).withOpacity(0.7),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Profile Picture - Centered
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 65,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: _userProfile!.profilePictureUrl != null
                                  ? NetworkImage(_userProfile!.profilePictureUrl!)
                                  : null,
                              child: _userProfile!.profilePictureUrl == null
                                  ? Text(
                                      (_userProfile!.displayName ?? _userProfile!.username)
                                          .substring(0, 1)
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 50,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          if (_isOwner)
                            Positioned(
                              bottom: -5,
                              right: -5,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  icon: _isUploadingImage
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                          ),
                                        )
                                      : const Icon(Icons.camera_alt, size: 22),
                                  color: (_bannerColor ?? Theme.of(context).primaryColor),
                                  onPressed: _isUploadingImage ? null : _pickImage,
                                  tooltip: 'Change Photo',
                                  padding: const EdgeInsets.all(8),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 70),

            // User Info Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Text(
                    _userProfile!.displayName ?? _userProfile!.username,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@${_userProfile!.username}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 24),

                  // Show blocked message if user has blocked current user
                  if (_isBlockedBy && !_isOwner) ...[
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(
                              Icons.block,
                              size: 48,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'This user has blocked you',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'You cannot view their profile, recipes, or interact with their content.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  // Follow Button (only show if not owner and not blocked)
                  if (!_isOwner && !_isBlockedBy) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isTogglingFollow ? null : _toggleFollow,
                        icon: _isTogglingFollow
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(_isFollowing ? Icons.person_remove : Icons.person_add),
                        label: Text(_isFollowing ? 'Unfollow' : 'Follow'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Stats Card (only show if not blocked)
                  if (!_isBlockedBy || _isOwner) ...[
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatColumn(
                            'Recipes',
                            _totalRecipes.toString(),
                            Icons.restaurant_menu,
                            onTap: _scrollToRecipes,
                          ),
                          _buildStatColumn(
                            'Followers',
                            _followerCount.toString(),
                            Icons.people,
                            onTap: _showFollowersPopup,
                          ),
                          _buildStatColumn(
                            'Following',
                            _followingCount.toString(),
                            Icons.person_add,
                            onTap: _showFollowingPopup,
                          ),
                          _buildStatColumn(
                            'Chef Score',
                            _userProfile!.chefScore.toStringAsFixed(1),
                            Icons.star,
                            isHighlight: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Badges Section
                  if (_badges.isNotEmpty)
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.emoji_events, size: 20, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Badges',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : Colors.black87,
                                          ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${_badges.length}',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: _badges.map((badge) => _buildBadgeWidget(badge, isDark)).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  if (_badges.isNotEmpty)
                    const SizedBox(height: 16),

                  // Bio Card
                  if (_isEditing || (_userProfile!.bio != null && _userProfile!.bio!.isNotEmpty))
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.person, size: 20, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                                const SizedBox(width: 8),
                                Text(
                                  'About',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _isEditing
                                ? TextField(
                                    controller: _bioController,
                                    maxLines: 4,
                                    decoration: InputDecoration(
                                      hintText: 'Tell us about yourself...',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      filled: true,
                                      fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                                    ),
                                  )
                                : Text(
                                    _userProfile!.bio ?? '',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          color: isDark ? Colors.grey[200] : Colors.black87,
                                        ),
                                  ),
                          ],
                        ),
                      ),
                    ),

                  if (_isEditing || (_userProfile!.bio != null && _userProfile!.bio!.isNotEmpty))
                    const SizedBox(height: 16),

                  // Skill Level Card with Meter
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.school, size: 20, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                              const SizedBox(width: 8),
                              Text(
                                'Skill Level',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _isEditing
                              ? _buildSkillLevelMeter(_selectedSkillLevel, isEditing: true)
                              : _buildSkillLevelMeter(_userProfile!.skillLevel),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Dietary Restrictions Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.restaurant_menu, size: 20, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                              const SizedBox(width: 8),
                              Text(
                                'Dietary Restrictions',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _isEditing
                              ? Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    ..._dietaryOptions.map((option) {
                                      final isSelected = _selectedDietaryRestrictions.contains(option);
                                      return FilterChip(
                                        label: Text(
                                          option,
                                          style: TextStyle(
                                            color: isSelected
                                                ? (isDark ? Colors.white : Theme.of(context).primaryColor)
                                                : (isDark ? Colors.grey[300] : Colors.black87),
                                          ),
                                        ),
                                        selected: isSelected,
                                        selectedColor: Theme.of(context).primaryColor.withOpacity(isDark ? 0.4 : 0.2),
                                        checkmarkColor: isDark ? Colors.white : Theme.of(context).primaryColor,
                                        backgroundColor: isDark ? Colors.grey[800] : null,
                                        onSelected: (selected) {
                                          setState(() {
                                            if (selected) {
                                              _selectedDietaryRestrictions.add(option);
                                            } else {
                                              _selectedDietaryRestrictions.remove(option);
                                            }
                                          });
                                        },
                                      );
                                    }).toList(),
                                    // Custom dietary restrictions
                                    ..._selectedDietaryRestrictions
                                        .where((r) => !_dietaryOptions.contains(r))
                                        .map((restriction) {
                                      return FilterChip(
                                        label: Text(
                                          restriction,
                                          style: TextStyle(
                                            color: isDark ? Colors.white : Theme.of(context).primaryColor,
                                          ),
                                        ),
                                        selected: true,
                                        selectedColor: Theme.of(context).primaryColor.withOpacity(isDark ? 0.4 : 0.2),
                                        checkmarkColor: isDark ? Colors.white : Theme.of(context).primaryColor,
                                        backgroundColor: isDark ? Colors.grey[800] : null,
                                        onSelected: (selected) {
                                          setState(() {
                                            _selectedDietaryRestrictions.remove(restriction);
                                          });
                                        },
                                      );
                                    }).toList(),
                                    // Add custom option button
                                    ActionChip(
                                      label: const Text('+'),
                                      backgroundColor: isDark ? Colors.grey[800] : null,
                                      onPressed: _showAddCustomDietaryDialog,
                                    ),
                                  ],
                                )
                              : _userProfile!.dietaryRestrictions.isEmpty
                                  ? Text(
                                      'No dietary restrictions',
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                                            fontStyle: FontStyle.italic,
                                          ),
                                    )
                                  : Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: _userProfile!.dietaryRestrictions.map((restriction) {
                                        return Chip(
                                          label: Text(restriction),
                                          backgroundColor: isDark 
                                              ? Theme.of(context).primaryColor.withOpacity(0.3)
                                              : Theme.of(context).primaryColor.withOpacity(0.1),
                                          labelStyle: TextStyle(
                                            color: isDark ? Colors.white : Theme.of(context).primaryColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        );
                                      }).toList(),
                                    ),
                        ],
                      ),
                    ),
                  ),

                  // Average Recipe Rating Card
                  if (_averageRecipeRating > 0) ...[
                    const SizedBox(height: 16),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 28),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Average Recipe Rating',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _averageRecipeRating.toStringAsFixed(2),
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber[700],
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  ],
                  const SizedBox(height: 24),
                  
                  // Block User Button (only show if not owner and not blocked)
                  if (!_isOwner && !_isBlockedBy) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _showBlockDialog,
                        icon: const Icon(Icons.block, color: Colors.red),
                        label: const Text(
                          'Block User',
                          style: TextStyle(color: Colors.red),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  ],
                ],
              ),
            ),

            // Public Recipes Section (only show if not blocked)
            if (!_isBlockedBy || _isOwner) ...[
            if (_publicRecipes.isNotEmpty) ...[
              Container(
                key: _recipesKey,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.restaurant_menu,
                          size: 24,
                          color: isDark ? Colors.white : Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Public Recipes',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: _publicRecipes.length,
                      itemBuilder: (context, index) {
                        final recipe = _publicRecipes[index];
                        return _RecipeCard(
                          recipe: recipe,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RecipeDetailScreenNew(recipe: recipe),
                              ),
                            ).then((_) => _loadPublicRecipes());
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              ],
            ],

            // Public Collections Section (only show if not blocked)
            if (!_isBlockedBy || _isOwner) ...[
            if (_publicCollections.isNotEmpty) ...[
              Container(
                key: _collectionsKey,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.folder,
                          size: 24,
                          color: isDark ? Colors.white : Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Public Collections',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: _publicCollections.length,
                      itemBuilder: (context, index) {
                        final collection = _publicCollections[index];
                        return _CollectionCard(
                          collection: collection,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CollectionDetailScreen(
                                  collection: collection,
                                  isOwner: false,
                                ),
                              ),
                            ).then((_) => _loadPublicCollections());
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon, {bool isHighlight = false, VoidCallback? onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final column = Column(
      children: [
        Icon(
          icon,
          color: isHighlight 
              ? Colors.amber 
              : (isDark ? Colors.white : Theme.of(context).primaryColor),
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isHighlight ? Colors.amber[700] : null,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontSize: 12,
              ),
        ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: column,
        ),
      );
    }

    return column;
  }

  Widget _buildBadgeWidget(BadgeModel badge, bool isDark) {
    Color tierColor;
    switch (badge.tier) {
      case 'platinum':
        tierColor = const Color(0xFFE5E4E2);
        break;
      case 'gold':
        tierColor = const Color(0xFFFFD700);
        break;
      case 'silver':
        tierColor = const Color(0xFFC0C0C0);
        break;
      case 'bronze':
        tierColor = const Color(0xFFCD7F32);
        break;
      default:
        tierColor = Colors.grey;
    }

    return Tooltip(
      message: badge.description,
      child: Container(
        width: 80,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: tierColor.withOpacity(0.5),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              badge.icon,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 4),
            Text(
              badge.name,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey[300] : Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillLevelMeter(String skillLevel, {bool isEditing = false}) {
    final levelIndex = _skillLevels.indexOf(skillLevel);
    final progress = (levelIndex + 1) / _skillLevels.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Color getLevelColor(int index) {
      switch (index) {
        case 0:
          return Colors.green;
        case 1:
          return Colors.orange;
        case 2:
          return Colors.red;
        default:
          return Colors.grey;
      }
    }

    String getLevelLabel(int index) {
      switch (index) {
        case 0:
          return 'Beginner';
        case 1:
          return 'Intermediate';
        case 2:
          return 'Advanced';
        default:
          return '';
      }
    }

    return Column(
      children: [
        // Meter visual
        Stack(
          children: [
            // Background track
            Container(
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    Colors.green,
                    Colors.orange,
                    Colors.red,
                  ],
                ),
              ),
            ),
            // Progress indicator
            LayoutBuilder(
              builder: (context, constraints) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 40,
                  width: constraints.maxWidth * progress,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white.withOpacity(0.3),
                  ),
                );
              },
            ),
            // Level markers
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(3, (index) {
                final isActive = index <= levelIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
                    border: Border.all(
                      color: getLevelColor(index),
                      width: 2,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: getLevelColor(index).withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                );
              }),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Level labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(3, (index) {
            final isSelected = index == levelIndex;
            return Expanded(
              child: Column(
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? getLevelColor(index) : (isDark ? Colors.grey[500] : Colors.grey[600]),
                          fontSize: isSelected ? 14 : 12,
                        ),
                    child: Text(
                      getLevelLabel(index),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(height: 4),
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Icon(
                            Icons.check_circle,
                            color: getLevelColor(index),
                            size: 20,
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            );
          }),
        ),
        if (isEditing) ...[
          const SizedBox(height: 24),
          // Animated slider for editing
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: getLevelColor(levelIndex).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 8),
                  child: Text(
                    'Adjust your skill level',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 8,
                    activeTrackColor: getLevelColor(levelIndex).withOpacity(0.8),
                    inactiveTrackColor: isDark 
                        ? Colors.grey[700] 
                        : Colors.grey[300],
                    thumbColor: getLevelColor(levelIndex),
                    overlayColor: getLevelColor(levelIndex).withOpacity(0.2),
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 12,
                      elevation: 4,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 24,
                    ),
                    activeTickMarkColor: Colors.transparent,
                    inactiveTickMarkColor: Colors.transparent,
                    valueIndicatorColor: getLevelColor(levelIndex),
                    valueIndicatorTextStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: Slider(
                    value: levelIndex.toDouble(),
                    min: 0,
                    max: 2,
                    divisions: 2,
                    label: getLevelLabel(levelIndex),
                    onChanged: (value) {
                      setState(() {
                        _selectedSkillLevel = _skillLevels[value.toInt()];
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _showBlockDialog() async {
    if (_isOwner) return;

    final isBlocked = await _blockService.isBlocked(widget.userId);

    if (isBlocked) {
      // Show unblock dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unblock User'),
          content: Text(
            'Are you sure you want to unblock ${_userProfile?.displayName ?? _userProfile?.username ?? 'this user'}? You will be able to see their content again.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Unblock'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        try {
          await _blockService.unblockUser(widget.userId);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('User unblocked successfully'),
                backgroundColor: Colors.green,
              ),
            );
            // Navigate back since we can now see their content
            Navigator.pop(context);
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to unblock user: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } else {
      // Show block dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Block User'),
          content: Text(
            'Are you sure you want to block ${_userProfile?.displayName ?? _userProfile?.username ?? 'this user'}? You will no longer see their profile or recipes, and they will not be able to interact with your content.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Block'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        try {
          await _blockService.blockUser(widget.userId);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('User blocked successfully'),
                backgroundColor: Colors.green,
              ),
            );
            // Navigate back since we can't see their content anymore
            Navigator.pop(context);
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to block user: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    }
  }

  Future<void> _showAddCustomDietaryDialog() async {
    final TextEditingController controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[850] : null,
        title: Text(
          'Add Custom',
          style: TextStyle(color: isDark ? Colors.white : null),
        ),
        content: TextField(
          controller: controller,
          maxLength: 25,
          autofocus: true,
          style: TextStyle(color: isDark ? Colors.white : null),
          decoration: InputDecoration(
            hintText: 'Enter dietary restriction',
            hintStyle: TextStyle(color: isDark ? Colors.grey[400] : null),
            border: const OutlineInputBorder(),
            counterText: '',
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: isDark ? Colors.grey[600]! : Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).primaryColor),
            ),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) {
                Navigator.pop(context, value);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        if (!_selectedDietaryRestrictions.contains(result)) {
          _selectedDietaryRestrictions.add(result);
        }
      });
    }
  }
}

class _RecipeCard extends StatelessWidget {
  final RecipeModel recipe;
  final VoidCallback onTap;

  const _RecipeCard({
    required this.recipe,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  image: recipe.imageUrls?.isNotEmpty == true
                      ? DecorationImage(
                          image: NetworkImage(recipe.imageUrls!.first),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: recipe.imageUrls?.isEmpty != false
                    ? const Center(
                        child: Icon(Icons.restaurant_menu, size: 48, color: Colors.grey),
                      )
                    : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text('${recipe.totalTime} min', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      const SizedBox(width: 12),
                      Icon(Icons.star, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text('${recipe.averageRating.toStringAsFixed(1)}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.speed,
                        size: 14,
                        color: recipe.difficultyLevel.name == 'easy'
                            ? Colors.green
                            : recipe.difficultyLevel.name == 'medium'
                                ? Colors.orange
                                : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        recipe.difficultyLevel.name == 'medium' ? 'INTERMEDIATE' : recipe.difficultyLevel.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          color: recipe.difficultyLevel.name == 'easy'
                              ? Colors.green
                              : recipe.difficultyLevel.name == 'medium'
                                  ? Colors.orange
                                  : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CollectionCard extends StatelessWidget {
  final CollectionModel collection;
  final VoidCallback onTap;

  const _CollectionCard({
    required this.collection,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon/Image placeholder
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).primaryColor.withOpacity(0.7),
                      Theme.of(context).primaryColor.withOpacity(0.4),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.folder,
                    size: 48,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
            ),
            // Info section
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    collection.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.restaurant_menu,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${collection.recipeCount} recipe${collection.recipeCount != 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.public,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FollowersFollowingDialog extends StatelessWidget {
  final String title;
  final List<UserModel> users;

  const _FollowersFollowingDialog({
    required this.title,
    required this.users,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: users.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'No $title',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
                          child: CreatorProfileCard(creator: user),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

