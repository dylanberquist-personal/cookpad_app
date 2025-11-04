import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:palette_generator/palette_generator.dart';
import 'dart:io';
import '../services/auth_service.dart';
import '../services/follow_service.dart';
import '../services/recipe_service_supabase.dart';
import '../services/collection_service.dart';
import '../models/user_model.dart';
import '../models/recipe_model.dart';
import '../models/collection_model.dart';
import '../config/supabase_config.dart';
import '../widgets/creator_profile_card.dart';
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

      // Load follow status
      if (!_isOwner) {
        await _checkFollowStatus();
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
      await _authService.updateUserProfile(
        displayName: _displayNameController.text.isEmpty 
            ? null 
            : _displayNameController.text,
        bio: _bioController.text.isEmpty ? null : _bioController.text,
        skillLevel: _selectedSkillLevel,
        dietaryRestrictions: _selectedDietaryRestrictions,
      );

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

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Text(
          _userProfile!.displayName ?? _userProfile!.username,
          style: const TextStyle(fontWeight: FontWeight.bold),
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentNavIndex,
        onDestinationSelected: (index) {
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
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: '',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: '',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: '',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '',
          ),
        ],
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
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 24),

                  // Follow Button (only show if not owner)
                  if (!_isOwner) ...[
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

                  // Stats Card
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
                                Icon(Icons.person, size: 20, color: Colors.grey[600]),
                                const SizedBox(width: 8),
                                Text(
                                  'About',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
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
                                      fillColor: Colors.grey[50],
                                    ),
                                  )
                                : Text(
                                    _userProfile!.bio ?? '',
                                    style: Theme.of(context).textTheme.bodyLarge,
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
                              Icon(Icons.school, size: 20, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Text(
                                'Skill Level',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
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
                              Icon(Icons.restaurant_menu, size: 20, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Text(
                                'Dietary Restrictions',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _isEditing
                              ? Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _dietaryOptions.map((option) {
                                    final isSelected = _selectedDietaryRestrictions.contains(option);
                                    return FilterChip(
                                      label: Text(option),
                                      selected: isSelected,
                                      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                                      checkmarkColor: Theme.of(context).primaryColor,
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
                                )
                              : _userProfile!.dietaryRestrictions.isEmpty
                                  ? Text(
                                      'No dietary restrictions',
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                            color: Colors.grey[600],
                                            fontStyle: FontStyle.italic,
                                          ),
                                    )
                                  : Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: _userProfile!.dietaryRestrictions.map((restriction) {
                                        return Chip(
                                          label: Text(restriction),
                                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                                          labelStyle: TextStyle(
                                            color: Theme.of(context).primaryColor,
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
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // Public Recipes Section
            if (_publicRecipes.isNotEmpty) ...[
              Container(
                key: _recipesKey,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.restaurant_menu, size: 24, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'Public Recipes',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
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

            // Public Collections Section
            if (_publicCollections.isNotEmpty) ...[
              Container(
                key: _collectionsKey,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.folder, size: 24, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'Public Collections',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
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
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon, {bool isHighlight = false, VoidCallback? onTap}) {
    final column = Column(
      children: [
        Icon(
          icon,
          color: isHighlight ? Colors.amber : Theme.of(context).primaryColor,
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

  Widget _buildSkillLevelMeter(String skillLevel, {bool isEditing = false}) {
    final levelIndex = _skillLevels.indexOf(skillLevel);
    final progress = (levelIndex + 1) / _skillLevels.length;
    
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
                return Container(
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
                  Text(
                    getLevelLabel(index),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? getLevelColor(index) : Colors.grey[600],
                          fontSize: isSelected ? 14 : 12,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  if (isSelected) ...[
                    const SizedBox(height: 4),
                    Icon(
                      Icons.check_circle,
                      color: getLevelColor(index),
                      size: 20,
                    ),
                  ],
                ],
              ),
            );
          }),
        ),
        if (isEditing) ...[
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: skillLevel,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              labelText: 'Change Skill Level',
            ),
            items: _skillLevels.map((level) {
              return DropdownMenuItem(
                value: level,
                child: Text(level[0].toUpperCase() + level.substring(1)),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedSkillLevel = value);
              }
            },
          ),
        ],
      ],
    );
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

