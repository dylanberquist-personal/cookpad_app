import 'package:flutter/material.dart';
import '../services/collection_service.dart';
import '../models/collection_model.dart';
import '../config/supabase_config.dart';
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
  bool _isLoading = true;
  bool _isOwner = true;

  @override
  void initState() {
    super.initState();
    _checkOwnership();
    _loadCollections();
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

      List<CollectionModel> collections;
      if (_isOwner) {
        // Show all collections (public and private) for owner
        collections = await _collectionService.getUserCollections(targetUserId);
      } else {
        // Show only public collections for other users
        collections = await _collectionService.getPublicCollections(targetUserId);
      }

      setState(() {
        _collections = collections;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading collections: ${e.toString()}')),
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: 4, // Profile tab
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _collections.isEmpty
              ? Center(
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
                )
              : RefreshIndicator(
                  onRefresh: _loadCollections,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: _collections.length,
                    itemBuilder: (context, index) {
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
                      );
                    },
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

  const _CollectionCard({
    required this.collection,
    required this.onTap,
    this.onLongPress,
    this.onEdit,
    this.onDelete,
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
            if (onEdit != null || onDelete != null)
              Positioned(
                top: 8,
                right: 8,
                child: PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: Colors.white.withOpacity(0.9),
                    size: 20,
                  ),
                  color: Colors.white,
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit?.call();
                    } else if (value == 'delete') {
                      onDelete?.call();
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
                    if (onDelete != null)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
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
}

