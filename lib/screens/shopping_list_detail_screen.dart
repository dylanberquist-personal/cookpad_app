import 'package:flutter/material.dart';
import '../services/shopping_list_service.dart';
import '../models/shopping_list_model.dart';
import '../models/collection_model.dart';
import '../services/preferences_service.dart';
import '../services/pantry_service.dart';
import '../services/collection_service.dart';
import '../config/supabase_config.dart';
import '../widgets/notification_badge_icon.dart';
import 'main_navigation.dart';

class ShoppingListDetailScreen extends StatefulWidget {
  final String shoppingListId;

  const ShoppingListDetailScreen({
    super.key,
    required this.shoppingListId,
  });

  @override
  State<ShoppingListDetailScreen> createState() => _ShoppingListDetailScreenState();
}

class _ShoppingListDetailScreenState extends State<ShoppingListDetailScreen> {
  final _shoppingListService = ShoppingListService();
  final _preferencesService = PreferencesService();
  final _pantryService = PantryService();
  final _collectionService = CollectionService();
  
  ShoppingListModel? _shoppingList;
  bool _isLoading = true;
  bool _pantryEnabled = false;
  bool _hidePantryItems = false;
  List<String> _pantryItemNames = [];
  final _itemNameController = TextEditingController();
  String? _editingItemId;
  final Map<String, TextEditingController> _editControllers = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    for (final controller in _editControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load pantry status
      final isEnabled = await _preferencesService.isPantryEnabled();
      setState(() {
        _pantryEnabled = isEnabled;
      });

      // Load pantry items if enabled
      if (_pantryEnabled) {
        try {
          _pantryItemNames = await _pantryService.getPantryIngredientNames();
          _pantryItemNames = _pantryItemNames.map((n) => n.toLowerCase().trim()).toList();
        } catch (e) {
          // Silently fail
        }
      }

      // Load shopping list
      final list = await _shoppingListService.getShoppingListById(widget.shoppingListId);
      setState(() {
        _shoppingList = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading shopping list: $e')),
        );
      }
    }
  }

  Future<void> _addItem() async {
    final itemName = _itemNameController.text.trim();
    if (itemName.isEmpty || _shoppingList == null) return;

    try {
      final newItem = await _shoppingListService.addItem(
        shoppingListId: _shoppingList!.id,
        itemName: itemName,
      );
      
      // Update locally without full refresh - add new item at the top
      setState(() {
        _shoppingList = ShoppingListModel(
          id: _shoppingList!.id,
          userId: _shoppingList!.userId,
          name: _shoppingList!.name,
          createdAt: _shoppingList!.createdAt,
          updatedAt: DateTime.now(),
          items: [newItem, ..._shoppingList!.items],
        );
      });
      
      _itemNameController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding item: $e')),
        );
      }
    }
  }

  Future<void> _toggleItemChecked(ShoppingListItemModel item) async {
    try {
      final updatedItem = await _shoppingListService.toggleItemChecked(item.id);
      
      // Update locally without full refresh
      setState(() {
        _shoppingList = ShoppingListModel(
          id: _shoppingList!.id,
          userId: _shoppingList!.userId,
          name: _shoppingList!.name,
          createdAt: _shoppingList!.createdAt,
          updatedAt: DateTime.now(),
          items: _shoppingList!.items.map((i) => 
            i.id == item.id ? updatedItem : i
          ).toList(),
        );
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating item: $e')),
        );
      }
    }
  }

  Future<void> _deleteItem(ShoppingListItemModel item) async {
    try {
      await _shoppingListService.deleteItem(item.id);
      
      // Update locally without full refresh
      setState(() {
        _shoppingList = ShoppingListModel(
          id: _shoppingList!.id,
          userId: _shoppingList!.userId,
          name: _shoppingList!.name,
          createdAt: _shoppingList!.createdAt,
          updatedAt: DateTime.now(),
          items: _shoppingList!.items.where((i) => i.id != item.id).toList(),
        );
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting item: $e')),
        );
      }
    }
  }

  void _startEditingItem(ShoppingListItemModel item) {
    setState(() {
      _editingItemId = item.id;
      // Create a controller with the current item name if it doesn't exist
      if (!_editControllers.containsKey(item.id)) {
        _editControllers[item.id] = TextEditingController(text: item.itemName);
      }
    });
  }

  Future<void> _saveEditingItem(ShoppingListItemModel item) async {
    final controller = _editControllers[item.id];
    if (controller == null) return;

    final newName = controller.text.trim();
    if (newName.isEmpty) {
      // If empty, don't save and just cancel editing
      setState(() {
        _editingItemId = null;
      });
      return;
    }

    if (newName == item.itemName) {
      // No change, just cancel editing
      setState(() {
        _editingItemId = null;
      });
      return;
    }

    try {
      final updatedItem = await _shoppingListService.updateItem(
        id: item.id,
        itemName: newName,
      );

      // Update locally without full refresh
      setState(() {
        _shoppingList = ShoppingListModel(
          id: _shoppingList!.id,
          userId: _shoppingList!.userId,
          name: _shoppingList!.name,
          createdAt: _shoppingList!.createdAt,
          updatedAt: DateTime.now(),
          items: _shoppingList!.items.map((i) => 
            i.id == item.id ? updatedItem : i
          ).toList(),
        );
        _editingItemId = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating item: $e')),
        );
      }
      setState(() {
        _editingItemId = null;
      });
    }
  }

  void _cancelEditingItem() {
    setState(() {
      _editingItemId = null;
    });
  }

  Future<void> _moveCheckedItemsToPantry() async {
    final checkedItems = _shoppingList!.items.where((item) => item.isChecked).toList();
    
    if (checkedItems.isEmpty) return;

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Add items to pantry
      final itemNames = checkedItems.map((item) => item.itemName).toList();
      await _pantryService.addPantryItems(itemNames);

      // Delete items from shopping list
      for (final item in checkedItems) {
        await _shoppingListService.deleteItem(item.id);
      }

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        // Update locally without full refresh
        setState(() {
          _shoppingList = ShoppingListModel(
            id: _shoppingList!.id,
            userId: _shoppingList!.userId,
            name: _shoppingList!.name,
            createdAt: _shoppingList!.createdAt,
            updatedAt: DateTime.now(),
            items: _shoppingList!.items.where((i) => !i.isChecked).toList(),
          );
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Moved ${checkedItems.length} item${checkedItems.length == 1 ? '' : 's'} to pantry'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error moving items to pantry: $e')),
        );
      }
    }
  }

  Future<void> _importFromText() async {
    final textController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import from Text'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            hintText: 'Paste items, one per line',
            border: OutlineInputBorder(),
          ),
          maxLines: 10,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (textController.text.trim().isNotEmpty) {
                Navigator.pop(context, textController.text.trim());
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (result != null && _shoppingList != null) {
      final lines = result.split('\n').where((line) => line.trim().isNotEmpty).toList();
      if (lines.isEmpty) return;

      try {
        final items = await _shoppingListService.addItems(
          shoppingListId: _shoppingList!.id,
          itemNames: lines,
        );

        // Update locally without full refresh - add new items at the top
        setState(() {
          _shoppingList = ShoppingListModel(
            id: _shoppingList!.id,
            userId: _shoppingList!.userId,
            name: _shoppingList!.name,
            createdAt: _shoppingList!.createdAt,
            updatedAt: DateTime.now(),
            items: [...items, ..._shoppingList!.items],
          );
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error importing items: $e')),
          );
        }
      }
    }
  }

  Future<void> _importFromCollection() async {
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
          title: const Text('Import from Collection'),
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

      if (selectedCollection != null && _shoppingList != null) {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );

        try {
          // Get collection recipes
          final recipes = await _collectionService.getCollectionRecipes(selectedCollection.id);
          
          // Collect all unique ingredients
          final Map<String, String> ingredientMap = {};
          for (final recipe in recipes) {
            for (final ingredient in recipe.ingredients) {
              final name = ingredient.name.toLowerCase().trim();
              if (!ingredientMap.containsKey(name)) {
                // Format item name with quantity if available
                String formattedName = ingredient.name;
                if (ingredient.quantity.isNotEmpty) {
                  formattedName = '${ingredient.quantity} ${ingredient.unit ?? ''} ${ingredient.name}'.trim();
                }
                ingredientMap[name] = formattedName;
              }
            }
          }

          // Add items to shopping list
          final itemNames = ingredientMap.values.toList();
          if (itemNames.isNotEmpty) {
            final items = await _shoppingListService.addItems(
              shoppingListId: _shoppingList!.id,
              itemNames: itemNames,
            );

            if (mounted) {
              Navigator.pop(context); // Close loading dialog
              
              // Update locally without full refresh - add new items at the top
              setState(() {
                _shoppingList = ShoppingListModel(
                  id: _shoppingList!.id,
                  userId: _shoppingList!.userId,
                  name: _shoppingList!.name,
                  createdAt: _shoppingList!.createdAt,
                  updatedAt: DateTime.now(),
                  items: [...items, ..._shoppingList!.items],
                );
              });
            }
          } else {
            if (mounted) {
              Navigator.pop(context); // Close loading dialog
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Collection has no recipes with ingredients')),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            Navigator.pop(context); // Close loading dialog
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error importing from collection: $e')),
            );
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

  Future<void> _editListName() async {
    if (_shoppingList == null) return;

    final nameController = TextEditingController(text: _shoppingList!.name);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit List Name'),
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
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result != _shoppingList!.name) {
      try {
        await _shoppingListService.updateShoppingList(
          id: _shoppingList!.id,
          name: result,
        );
        await _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating list: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_shoppingList?.name ?? 'Shopping List'),
        actions: [
          // Import button
          PopupMenuButton(
            icon: const Icon(Icons.upload_file),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'text',
                child: Row(
                  children: [
                    Icon(Icons.text_fields),
                    SizedBox(width: 8),
                    Text('Import from Text'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'collection',
                child: Row(
                  children: [
                    Icon(Icons.folder),
                    SizedBox(width: 8),
                    Text('Import from Collection'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'text') {
                _importFromText();
              } else if (value == 'collection') {
                _importFromCollection();
              }
            },
          ),
          // Pantry toggle (only show if pantry feature is enabled)
          if (_pantryEnabled)
            Tooltip(
              message: _hidePantryItems
                  ? 'Show pantry items'
                  : 'Hide pantry items',
              child: IconButton(
                icon: Icon(
                  _hidePantryItems ? Icons.kitchen : Icons.kitchen_outlined,
                  color: _hidePantryItems ? Colors.orange : Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _hidePantryItems = !_hidePantryItems;
                  });
                },
              ),
            ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editListName,
            tooltip: 'Edit List Name',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _shoppingList == null
              ? const Center(child: Text('Shopping list not found'))
              : Column(
                  children: [
                    // Add item input
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _itemNameController,
                              decoration: const InputDecoration(
                                hintText: 'Add item...',
                                border: OutlineInputBorder(),
                              ),
                              onSubmitted: (_) => _addItem(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.add_circle),
                            onPressed: _addItem,
                            tooltip: 'Add Item',
                          ),
                        ],
                      ),
                    ),
                    // Items list
                    Expanded(
                      child: () {
                        // Filter items based on pantry toggle
                        List<ShoppingListItemModel> displayItems = _shoppingList!.items;
                        if (_pantryEnabled && _hidePantryItems && _pantryItemNames.isNotEmpty) {
                          displayItems = _shoppingList!.items.where((item) {
                            final lowerName = item.itemName.toLowerCase().trim();
                            return !_pantryItemNames.any((pantryName) =>
                                pantryName == lowerName ||
                                pantryName.contains(lowerName) ||
                                lowerName.contains(pantryName));
                          }).toList();
                        }

                        if (displayItems.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shopping_cart_outlined,
                                    size: 64, color: Colors.grey),
                                const SizedBox(height: 16),
                                Text(
                                  _shoppingList!.items.isEmpty
                                      ? 'No items yet'
                                      : (_hidePantryItems
                                          ? 'All items are in your pantry'
                                          : 'No items'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _shoppingList!.items.isEmpty
                                      ? 'Add items to your shopping list'
                                      : 'Toggle pantry filter to see all items',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: Colors.grey),
                                ),
                              ],
                            ),
                          );
                        }

                        return RefreshIndicator(
                          onRefresh: _loadData,
                          child: ListView.builder(
                            itemCount: displayItems.length,
                            itemBuilder: (context, index) {
                              final item = displayItems[index];
                              final isEditing = _editingItemId == item.id;
                              
                              return Dismissible(
                                key: Key(item.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 16),
                                  color: Colors.red,
                                  child: const Icon(Icons.delete, color: Colors.white),
                                ),
                                onDismissed: (direction) => _deleteItem(item),
                                child: GestureDetector(
                                  onLongPress: () => _startEditingItem(item),
                                  child: isEditing
                                      ? ListTile(
                                          leading: Checkbox(
                                            value: item.isChecked,
                                            onChanged: (_) => _toggleItemChecked(item),
                                          ),
                                          title: TextField(
                                            controller: _editControllers[item.id],
                                            autofocus: true,
                                            decoration: InputDecoration(
                                              hintText: 'Item name',
                                              border: OutlineInputBorder(),
                                              contentPadding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                              suffixIcon: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.check, color: Colors.green),
                                                    onPressed: () => _saveEditingItem(item),
                                                    tooltip: 'Save',
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.close, color: Colors.red),
                                                    onPressed: _cancelEditingItem,
                                                    tooltip: 'Cancel',
                                                  ),
                                                ],
                                              ),
                                            ),
                                            onSubmitted: (_) => _saveEditingItem(item),
                                          ),
                                          subtitle: item.quantity != null
                                              ? Padding(
                                                  padding: const EdgeInsets.only(top: 8.0),
                                                  child: Text(item.quantity!),
                                                )
                                              : null,
                                        )
                                      : CheckboxListTile(
                                          value: item.isChecked,
                                          onChanged: (_) => _toggleItemChecked(item),
                                          title: Text(
                                            item.itemName,
                                            style: TextStyle(
                                              decoration: item.isChecked
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                              color: item.isChecked
                                                  ? Colors.grey
                                                  : null,
                                            ),
                                          ),
                                          subtitle: item.quantity != null
                                              ? Text(item.quantity!)
                                              : null,
                                        ),
                                ),
                              );
                            },
                          ),
                        );
                      }(),
                    ),
                  ],
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
      floatingActionButton: (_shoppingList != null && 
          _shoppingList!.items.any((item) => item.isChecked) &&
          _pantryEnabled)
          ? FloatingActionButton.extended(
              onPressed: _moveCheckedItemsToPantry,
              icon: const Icon(Icons.kitchen),
              label: const Text('Move to Pantry'),
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }
}

