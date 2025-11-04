import 'package:flutter/material.dart';
import '../services/shopping_list_service.dart';
import '../models/shopping_list_model.dart';
import '../models/collection_model.dart';
import '../services/collection_service.dart';
import '../config/supabase_config.dart';
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
  
  List<ShoppingListModel> _shoppingLists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load shopping lists
      final lists = await _shoppingListService.getShoppingLists();
      setState(() {
        _shoppingLists = lists;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading shopping lists: $e')),
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
          _shoppingLists.insert(0, newList);
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
        setState(() {
          _shoppingLists.removeWhere((l) => l.id == list.id);
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting list: $e')),
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
          : _shoppingLists.isEmpty
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
                  child: ListView.builder(
                    itemCount: _shoppingLists.length,
                    itemBuilder: (context, index) {
                      final list = _shoppingLists[index];
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
                  ),
                ),
      bottomNavigationBar: NavigationBar(
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
    );
  }
}

