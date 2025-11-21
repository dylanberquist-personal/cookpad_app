import 'package:flutter/material.dart';
import '../services/shopping_list_service.dart';
import '../models/shopping_list_model.dart';
import '../models/collection_model.dart';
import '../services/collection_service.dart';
import '../config/supabase_config.dart';
import '../widgets/notification_badge_icon.dart';
import 'shopping_list_detail_screen.dart';
import 'main_navigation.dart';

class ShoppingListsScreen extends StatefulWidget {
  const ShoppingListsScreen({super.key});

  @override
  State<ShoppingListsScreen> createState() => _ShoppingListsScreenState();
}

class _ShoppingListsScreenState extends State<ShoppingListsScreen> {
  final _shoppingListService = ShoppingListService();
  final _collectionService = CollectionService();
  
  List<ShoppingListModel> _ownShoppingLists = [];
  List<ShoppingListModel> _sharedShoppingLists = [];
  List<Map<String, dynamic>> _pendingInvites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    print('🔄 Loading shopping lists data...');
    setState(() => _isLoading = true);
    
    try {
      // Load own and shared shopping lists separately
      final ownLists = await _shoppingListService.getOwnShoppingLists();
      final sharedLists = await _shoppingListService.getSyncedShoppingLists();
      final invites = await _shoppingListService.getPendingSyncInvites();
      
      print('📋 Loaded ${ownLists.length} own shopping lists');
      print('📋 Loaded ${sharedLists.length} shared shopping lists');
      print('📬 Loaded ${invites.length} pending invites');
      
      setState(() {
        _ownShoppingLists = ownLists;
        _sharedShoppingLists = sharedLists;
        _pendingInvites = invites;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading data: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading shopping lists: $e')),
        );
      }
    }
  }

  Future<void> _acceptShoppingListInvite(Map<String, dynamic> invite) async {
    try {
      print('🔄 Accepting invite: ${invite['id']}');
      await _shoppingListService.acceptShoppingListSyncInvite(invite['id']);
      print('✅ Invite accepted, reloading data...');
      await _loadData();
      print('✅ Data reloaded');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Shopping list synced successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error accepting invite: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _declineShoppingListInvite(Map<String, dynamic> invite) async {
    try {
      await _shoppingListService.declineShoppingListSyncInvite(invite['id']);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invite declined')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _createNewList() async {
    final nameController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Shopping List'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            hintText: 'Enter list name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.pop(context, nameController.text.trim());
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        final newList = await _shoppingListService.createShoppingList(name: result);
        setState(() {
          _ownShoppingLists.insert(0, newList);
        });
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ShoppingListDetailScreen(
                shoppingListId: newList.id,
              ),
            ),
          ).then((_) => _loadData());
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error creating list: $e')),
          );
        }
      }
    }
  }

  Future<void> _generateFromCollection() async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) return;

      // Get user collections
      final collections = await _collectionService.getUserCollections(userId);
      
      if (collections.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You have no collections. Create a collection first.')),
          );
        }
        return;
      }

      // Show collection selection dialog
      final selectedCollection = await showDialog<CollectionModel>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Generate from Collection'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: collections.length,
              itemBuilder: (context, index) {
                final collection = collections[index];
                return ListTile(
                  title: Text(collection.name),
                  subtitle: Text('${collection.recipeCount} recipes'),
                  onTap: () => Navigator.pop(context, collection),
                );
              },
            ),
          ),
        ),
      );

      if (selectedCollection != null) {
        final nameController = TextEditingController(
          text: 'Shopping List - ${selectedCollection.name}',
        );

        final listName = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Shopping List Name'),
            content: TextField(
              controller: nameController,
              decoration: const InputDecoration(
                hintText: 'Enter list name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (nameController.text.trim().isNotEmpty) {
                    Navigator.pop(context, nameController.text.trim());
                  }
                },
                child: const Text('Generate'),
              ),
            ],
          ),
        );

        if (listName != null && mounted) {
          // Show loading dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(child: CircularProgressIndicator()),
          );

          try {
            final newList = await _shoppingListService.generateFromCollection(
              collectionId: selectedCollection.id,
              listName: listName,
              considerPantry: false,
            );

            if (mounted) {
              Navigator.pop(context); // Close loading dialog
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ShoppingListDetailScreen(
                    shoppingListId: newList.id,
                  ),
                ),
              ).then((_) => _loadData());
            }
          } catch (e) {
            if (mounted) {
              Navigator.pop(context); // Close loading dialog
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error generating list: $e')),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteList(ShoppingListModel list) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Shopping List'),
        content: Text('Are you sure you want to delete "${list.name}"?'),
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
      try {
        await _shoppingListService.deleteShoppingList(list.id);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Shopping list deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting list: $e')),
          );
        }
      }
    }
  }

  Future<void> _unsyncList(ShoppingListModel list) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Shared List'),
        content: Text('Remove "${list.name}" from your lists? The list will still exist for the owner.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _shoppingListService.unsyncShoppingList(list.id);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Shopping list removed')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error removing list: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Lists'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.add),
            tooltip: 'Add Shopping List',
            onSelected: (value) {
              if (value == 'new') {
                _createNewList();
              } else if (value == 'generate') {
                _generateFromCollection();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'new',
                child: Row(
                  children: [
                    Icon(Icons.add),
                    SizedBox(width: 8),
                    Text('New List'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'generate',
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome),
                    SizedBox(width: 8),
                    Text('Generate from Collection'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _ownShoppingLists.isEmpty && _sharedShoppingLists.isEmpty && _pendingInvites.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'No shopping lists yet',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create a new list or generate one from a collection',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: CustomScrollView(
                    slivers: [
                      // Pending Invites Section
                      if (_pendingInvites.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Text(
                              'Pending Sync Invites',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final invite = _pendingInvites[index];
                              final sender = invite['sender'] as Map<String, dynamic>;
                              final shoppingList = invite['shopping_list'] as Map<String, dynamic>?;
                              final listName = shoppingList?['name'] as String? ?? 'Shopping List';
                              
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: sender['profile_picture_url'] != null
                                        ? NetworkImage(sender['profile_picture_url'] as String)
                                        : null,
                                    child: sender['profile_picture_url'] == null
                                        ? const Icon(Icons.person)
                                        : null,
                                  ),
                                  title: Text(
                                    '${sender['username']} wants to sync',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text('List: $listName'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.check, color: Colors.green),
                                        onPressed: () => _acceptShoppingListInvite(invite),
                                        tooltip: 'Accept',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close, color: Colors.red),
                                        onPressed: () => _declineShoppingListInvite(invite),
                                        tooltip: 'Decline',
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            childCount: _pendingInvites.length,
                          ),
                        ),
                      ],
                      // My Shopping Lists Section
                      if (_ownShoppingLists.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(16, _pendingInvites.isNotEmpty ? 24 : 16, 16, 8),
                            child: Text(
                              'My Shopping Lists',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final list = _ownShoppingLists[index];
                              final checkedCount = list.items.where((i) => i.isChecked).length;
                              final totalCount = list.items.length;
                              
                              return ListTile(
                                leading: const Icon(Icons.shopping_cart),
                                title: Text(list.name),
                                subtitle: Text(
                                  totalCount > 0
                                      ? '$checkedCount of $totalCount items checked'
                                      : 'No items',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _deleteList(list),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ShoppingListDetailScreen(
                                        shoppingListId: list.id,
                                      ),
                                    ),
                                  ).then((_) => _loadData());
                                },
                              );
                            },
                            childCount: _ownShoppingLists.length,
                          ),
                        ),
                      ],
                      // Shared with Me Section
                      if (_sharedShoppingLists.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(16, (_pendingInvites.isNotEmpty || _ownShoppingLists.isNotEmpty) ? 24 : 16, 16, 8),
                            child: Text(
                              'Shared with Me',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final list = _sharedShoppingLists[index];
                              final checkedCount = list.items.where((i) => i.isChecked).length;
                              final totalCount = list.items.length;
                              
                              return ListTile(
                                leading: const Icon(Icons.shopping_cart_outlined),
                                title: Text(list.name),
                                subtitle: Text(
                                  totalCount > 0
                                      ? '$checkedCount of $totalCount items checked'
                                      : 'No items',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.close, color: Colors.red),
                                  onPressed: () => _unsyncList(list),
                                  tooltip: 'Remove from your lists',
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ShoppingListDetailScreen(
                                        shoppingListId: list.id,
                                      ),
                                    ),
                                  ).then((_) => _loadData());
                                },
                              );
                            },
                            childCount: _sharedShoppingLists.length,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
      bottomNavigationBar: SizedBox(
        height: 60,
        child: NavigationBar(
          selectedIndex: 4, // Profile tab
          onDestinationSelected: (index) {
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
    );
  }
}

