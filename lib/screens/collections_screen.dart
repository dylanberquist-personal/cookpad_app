import 'package:flutter/material.dart';
import '../services/collection_service.dart';
import '../models/collection_model.dart';
import '../config/supabase_config.dart';
import '../widgets/notification_badge_icon.dart';
import '../widgets/user_search_dialog.dart';
import 'collection_detail_screen.dart';
import 'edit_collection_screen.dart';
import 'main_navigation.dart';

class CollectionsScreen extends StatefulWidget {
  final String? userId; // If null, shows current user's collections

  const CollectionsScreen({
    super.key,
    this.userId,
  });

  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> {
  final _collectionService = CollectionService();
  List<CollectionModel> _collections = [];
  List<Map<String, dynamic>> _pendingSharedCollections = [];
  List<CollectionModel> _acceptedSharedCollections = [];
  bool _isLoading = true;
  bool _isOwner = true;

  @override
  void initState() {
    super.initState();
    _checkOwnership();
    _loadCollections();
    if (widget.userId == null) {
      _loadPendingSharedCollections();
    }
  }

  void _checkOwnership() {
    final currentUserId = SupabaseConfig.client.auth.currentUser?.id;
    final targetUserId = widget.userId ?? currentUserId;
    _isOwner = currentUserId != null && currentUserId == targetUserId;
  }

  Future<void> _loadCollections() async {
    setState(() => _isLoading = true);
    try {
      final currentUserId = SupabaseConfig.client.auth.currentUser?.id;
      final targetUserId = widget.userId ?? currentUserId;

      if (targetUserId == null) {
        throw Exception('User not authenticated');
      }

      if (_isOwner) {
        // Show all collections (public and private) for owner
        final ownCollections = await _collectionService.getUserCollections(targetUserId);
        print('📁 Loaded ${ownCollections.length} own collections');
        
        // Get accepted shared collections separately
        try {
          final sharedCollections = await _collectionService.getSharedCollections();
          print('📁 Loaded ${sharedCollections.length} accepted shared collections');
          
          setState(() {
            _collections = ownCollections;
            _acceptedSharedCollections = sharedCollections;
            _isLoading = false;
          });
        } catch (e) {
          print('⚠️ Error loading shared collections: $e');
          // If shared collections fail, just show own collections
          setState(() {
            _collections = ownCollections;
            _acceptedSharedCollections = [];
            _isLoading = false;
          });
        }
      } else {
        // Show only public collections for other users
        final collections = await _collectionService.getPublicCollections(targetUserId);
        setState(() {
          _collections = collections;
          _acceptedSharedCollections = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading collections: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading collections: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _loadPendingSharedCollections() async {
    try {
      print('📬 Fetching pending shared collections...');
      final pendingCollections = await _collectionService.getPendingSharedCollections();
      print('📬 Loaded ${pendingCollections.length} pending shared collections');
      
      // Debug: print details of each pending collection
      for (var i = 0; i < pendingCollections.length; i++) {
        final sc = pendingCollections[i];
        final collection = sc['collection'] as Map<String, dynamic>?;
        final sender = sc['sender'] as Map<String, dynamic>?;
        print('   [$i] Collection: ${collection?['name'] ?? 'null'}, Sender: ${sender?['username'] ?? 'null'}, Status: ${sc['status']}');
      }
      
      setState(() {
        _pendingSharedCollections = pendingCollections;
      });
    } catch (e) {
      // Silently fail - pending collections are optional
      print('❌ Error loading pending shared collections: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  Future<void> _acceptSharedCollection(Map<String, dynamic> sharedCollection) async {
    try {
      await _collectionService.acceptSharedCollection(sharedCollection['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Collection accepted!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadPendingSharedCollections();
        _loadCollections();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting collection: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _declineSharedCollection(Map<String, dynamic> sharedCollection) async {
    try {
      await _collectionService.declineSharedCollection(sharedCollection['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Collection declined')),
        );
        _loadPendingSharedCollections();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error declining collection: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeSharedCollection(CollectionModel collection) async {
    if (collection.sharedCollectionId == null) return;
    
    try {
      await _collectionService.removeSharedCollection(collection.sharedCollectionId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Collection removed from your list')),
        );
        _loadCollections();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing collection: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showDeleteDialog(CollectionModel collection) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Collection'),
        content: Text('Are you sure you want to delete "${collection.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteCollection(collection);
    }
  }

  Future<void> _deleteCollection(CollectionModel collection) async {
    try {
      await _collectionService.deleteCollection(collection.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Collection deleted')),
        );
        _loadCollections();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting collection: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _shareCollection(CollectionModel collection) async {
    // Check if collection is private and show confirmation
    if (!collection.isPublic) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Share Private Collection?'),
          content: const Text(
            'This collection is private. The person you share it with will be able to view it even though it\'s not public. Are you sure you want to share?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Share Anyway'),
            ),
          ],
        ),
      );
      
      if (confirm != true) return; // User cancelled
    }
    
    String? selectedUsername;
    bool? wasReshare;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => UserSearchDialog(
        title: 'Share Collection',
        onUserSelected: (user) async {
          selectedUsername = user.username;
          try {
            // Check if already shared before sharing
            final userId = SupabaseConfig.client.auth.currentUser?.id;
            if (userId != null) {
              final existing = await SupabaseConfig.client
                  .from('shared_collections')
                  .select()
                  .eq('collection_id', collection.id)
                  .eq('sender_id', userId)
                  .eq('recipient_id', user.id)
                  .maybeSingle();
              
              wasReshare = existing != null;
            }
            
            await _collectionService.shareCollection(collection.id, user.id);
            return true;
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error sharing collection: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return false;
          }
        },
      ),
    );
    
    // Show success message if sharing was successful
    if (result == true && mounted) {
      final message = wasReshare == true 
          ? 'Collection re-shared with $selectedUsername!'
          : 'Collection shared successfully!';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collections'),
        actions: _isOwner
            ? [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditCollectionScreen(),
                      ),
                    );
                    _loadCollections();
                  },
                  tooltip: 'Create Collection',
                ),
              ]
            : null,
      ),
      bottomNavigationBar: SizedBox(
        height: 60,
        child: NavigationBar(
          selectedIndex: 4, // Profile tab
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await _loadCollections();
                if (_isOwner) {
                  await _loadPendingSharedCollections();
                }
              },
              child: CustomScrollView(
                slivers: [
                  // My Collections section header (show if there are collections)
                  if (_isOwner && _collections.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          'My Collections',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ),
                  
                  // Main collections grid
                  if (_collections.isEmpty && (!_isOwner || _pendingSharedCollections.isEmpty))
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.folder_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _isOwner ? 'No collections yet' : 'No public collections',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isOwner
                                  ? 'Tap the + button to create your first collection'
                                  : 'This user has no public collections',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[500],
                                  ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.85,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final collection = _collections[index];
                            return _CollectionCard(
                              collection: collection,
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CollectionDetailScreen(
                                      collection: collection,
                                      isOwner: _isOwner,
                                    ),
                                  ),
                                );
                                _loadCollections();
                              },
                              onLongPress: _isOwner
                                  ? () => _showDeleteDialog(collection)
                                  : null,
                              onEdit: _isOwner
                                  ? () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => EditCollectionScreen(
                                            collection: collection,
                                          ),
                                        ),
                                      );
                                      _loadCollections();
                                    }
                                  : null,
                              onDelete: _isOwner
                                  ? () => _deleteCollection(collection)
                                  : null,
                              onShare: _isOwner
                                  ? () => _shareCollection(collection)
                                  : null,
                            );
                          },
                          childCount: _collections.length,
                        ),
                      ),
                    ),
                  
                  // Combined Shared with You section (pending at top, then accepted collections)
                  if (_isOwner && (_pendingSharedCollections.isNotEmpty || _acceptedSharedCollections.isNotEmpty)) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                        child: Text(
                          'Shared with You',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ),
                    // Pending collections (list tiles with accept/decline buttons)
                    if (_pendingSharedCollections.isNotEmpty)
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final sharedCollection = _pendingSharedCollections[index];
                            final collection = sharedCollection['collection'] as Map<String, dynamic>?;
                            final sender = sharedCollection['sender'] as Map<String, dynamic>?;
                            
                            if (collection == null) return const SizedBox();
                            
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: ListTile(
                                leading: const Icon(Icons.folder_shared, size: 32),
                                title: Text(
                                  collection['name'] as String? ?? 'Collection',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  'From ${sender != null ? sender['username'] as String? ?? 'someone' : 'someone'}',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.check, color: Colors.green),
                                      onPressed: () => _acceptSharedCollection(sharedCollection),
                                      tooltip: 'Accept',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, color: Colors.red),
                                      onPressed: () => _declineSharedCollection(sharedCollection),
                                      tooltip: 'Decline',
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          childCount: _pendingSharedCollections.length,
                        ),
                      ),
                    // Accepted collections (grid of collection cards)
                    if (_acceptedSharedCollections.isNotEmpty)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.85,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final collection = _acceptedSharedCollections[index];
                              return _CollectionCard(
                                collection: collection,
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CollectionDetailScreen(
                                        collection: collection,
                                        isOwner: false, // Shared collections are not editable
                                      ),
                                    ),
                                  );
                                  _loadCollections();
                                },
                                onDelete: () => _removeSharedCollection(collection), // Remove instead of delete
                                isShared: true, // Mark as shared to customize the menu
                              );
                            },
                            childCount: _acceptedSharedCollections.length,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _CollectionCard extends StatelessWidget {
  final CollectionModel collection;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onShare;
  final bool isShared; // Whether this is a shared collection (affects menu options)

  const _CollectionCard({
    required this.collection,
    required this.onTap,
    this.onLongPress,
    this.onEdit,
    this.onDelete,
    this.onShare,
    this.isShared = false,
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
        onLongPress: onLongPress,
        child: Stack(
          children: [
            Column(
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
                          _parseColor(collection.color).withOpacity(0.9),
                          _parseColor(collection.color).withOpacity(0.6),
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
                          fontSize: 16,
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
                          if (collection.isPublic)
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
            // Action buttons
            if (onEdit != null || onDelete != null || onShare != null)
              Positioned(
                top: 8,
                right: 8,
                child: PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: Colors.white.withOpacity(0.9),
                    size: 20,
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit?.call();
                    } else if (value == 'delete') {
                      onDelete?.call();
                    } else if (value == 'share') {
                      onShare?.call();
                    }
                  },
                  itemBuilder: (context) => [
                    if (onEdit != null)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                    if (onShare != null && !isShared)
                      const PopupMenuItem(
                        value: 'share',
                        child: Row(
                          children: [
                            Icon(Icons.share, size: 20),
                            SizedBox(width: 8),
                            Text('Share'),
                          ],
                        ),
                      ),
                    if (onDelete != null)
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              isShared ? Icons.remove_circle_outline : Icons.delete,
                              size: 20,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isShared ? 'Remove' : 'Delete',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Helper method to parse hex color string to Color
  Color _parseColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hexColor', radix: 16));
  }
}

