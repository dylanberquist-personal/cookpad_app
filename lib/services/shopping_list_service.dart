import '../config/supabase_config.dart';
import '../models/shopping_list_model.dart';
import 'collection_service.dart';
import 'pantry_service.dart';

class ShoppingListService {
  final _supabase = SupabaseConfig.client;
  final _collectionService = CollectionService();
  final _pantryService = PantryService();

  /// Get all shopping lists for the current user
  Future<List<ShoppingListModel>> getShoppingLists() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('shopping_lists')
        .select('*, items:shopping_list_items(*)')
        .eq('user_id', userId)
        .order('updated_at', ascending: false);

    return (response as List).map((json) => _shoppingListFromJson(json)).toList();
  }

  /// Get a shopping list by ID with its items
  Future<ShoppingListModel?> getShoppingListById(String shoppingListId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('shopping_lists')
        .select('*, items:shopping_list_items(*)')
        .eq('id', shoppingListId)
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;

    return _shoppingListFromJson(response);
  }

  /// Create a new shopping list
  Future<ShoppingListModel> createShoppingList({required String name}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final now = DateTime.now();
    final response = await _supabase
        .from('shopping_lists')
        .insert({
          'user_id': userId,
          'name': name,
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        })
        .select('*, items:shopping_list_items(*)')
        .single();

    return _shoppingListFromJson(response);
  }

  /// Update a shopping list
  Future<ShoppingListModel> updateShoppingList({
    required String id,
    String? name,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final updateData = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (name != null) updateData['name'] = name;

    final response = await _supabase
        .from('shopping_lists')
        .update(updateData)
        .eq('id', id)
        .eq('user_id', userId)
        .select('*, items:shopping_list_items(*)')
        .single();

    return _shoppingListFromJson(response);
  }

  /// Delete a shopping list
  Future<void> deleteShoppingList(String id) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase
        .from('shopping_lists')
        .delete()
        .eq('id', id)
        .eq('user_id', userId);
  }

  /// Add an item to a shopping list
  Future<ShoppingListItemModel> addItem({
    required String shoppingListId,
    required String itemName,
    String? quantity,
    String? category,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Verify ownership of shopping list
    final list = await getShoppingListById(shoppingListId);
    if (list == null) throw Exception('Shopping list not found');

    final response = await _supabase
        .from('shopping_list_items')
        .insert({
          'shopping_list_id': shoppingListId,
          'item_name': itemName,
          'quantity': quantity,
          'category': category,
          'is_checked': false,
          'created_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    // Update shopping list updated_at
    await _supabase
        .from('shopping_lists')
        .update({'updated_at': DateTime.now().toIso8601String()})
        .eq('id', shoppingListId);

    return ShoppingListItemModel.fromJson(response);
  }

  /// Add multiple items to a shopping list
  Future<List<ShoppingListItemModel>> addItems({
    required String shoppingListId,
    required List<String> itemNames,
    String? category,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Verify ownership of shopping list
    final list = await getShoppingListById(shoppingListId);
    if (list == null) throw Exception('Shopping list not found');

    final now = DateTime.now();
    final items = itemNames.map((name) => {
      'shopping_list_id': shoppingListId,
      'item_name': name.trim(),
      'quantity': null,
      'category': category,
      'is_checked': false,
      'created_at': now.toIso8601String(),
    }).toList();

    final response = await _supabase
        .from('shopping_list_items')
        .insert(items)
        .select();

    // Update shopping list updated_at
    await _supabase
        .from('shopping_lists')
        .update({'updated_at': DateTime.now().toIso8601String()})
        .eq('id', shoppingListId);

    return (response as List)
        .map((json) => ShoppingListItemModel.fromJson(json))
        .toList();
  }

  /// Update a shopping list item
  Future<ShoppingListItemModel> updateItem({
    required String id,
    String? itemName,
    String? quantity,
    String? category,
    bool? isChecked,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final updateData = <String, dynamic>{};

    if (itemName != null) updateData['item_name'] = itemName;
    if (quantity != null) updateData['quantity'] = quantity;
    if (category != null) updateData['category'] = category;
    if (isChecked != null) updateData['is_checked'] = isChecked;

    final response = await _supabase
        .from('shopping_list_items')
        .update(updateData)
        .eq('id', id)
        .select()
        .single();

    // Verify ownership through shopping list
    final item = ShoppingListItemModel.fromJson(response);
    final list = await getShoppingListById(item.shoppingListId);
    if (list == null || list.userId != userId) {
      throw Exception('Unauthorized');
    }

    // Update shopping list updated_at
    await _supabase
        .from('shopping_lists')
        .update({'updated_at': DateTime.now().toIso8601String()})
        .eq('id', item.shoppingListId);

    return item;
  }

  /// Delete a shopping list item
  Future<void> deleteItem(String id) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Get item to find shopping list ID
    final itemResponse = await _supabase
        .from('shopping_list_items')
        .select('shopping_list_id')
        .eq('id', id)
        .maybeSingle();

    if (itemResponse == null) throw Exception('Item not found');

    final shoppingListId = itemResponse['shopping_list_id'] as String;

    // Verify ownership
    final list = await getShoppingListById(shoppingListId);
    if (list == null || list.userId != userId) {
      throw Exception('Unauthorized');
    }

    await _supabase.from('shopping_list_items').delete().eq('id', id);

    // Update shopping list updated_at
    await _supabase
        .from('shopping_lists')
        .update({'updated_at': DateTime.now().toIso8601String()})
        .eq('id', shoppingListId);
  }

  /// Toggle item checked status
  Future<ShoppingListItemModel> toggleItemChecked(String id) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Get current item
    final itemResponse = await _supabase
        .from('shopping_list_items')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (itemResponse == null) throw Exception('Item not found');

    final currentItem = ShoppingListItemModel.fromJson(itemResponse);

    // Verify ownership
    final list = await getShoppingListById(currentItem.shoppingListId);
    if (list == null || list.userId != userId) {
      throw Exception('Unauthorized');
    }

    // Toggle checked status
    final response = await _supabase
        .from('shopping_list_items')
        .update({'is_checked': !currentItem.isChecked})
        .eq('id', id)
        .select()
        .single();

    // Update shopping list updated_at
    await _supabase
        .from('shopping_lists')
        .update({'updated_at': DateTime.now().toIso8601String()})
        .eq('id', currentItem.shoppingListId);

    return ShoppingListItemModel.fromJson(response);
  }

  /// Generate shopping list from collection recipes
  /// If considerPantry is true, excludes items already in pantry
  Future<ShoppingListModel> generateFromCollection({
    required String collectionId,
    required String listName,
    bool considerPantry = false,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Get collection recipes
    final recipes = await _collectionService.getCollectionRecipes(collectionId);

    if (recipes.isEmpty) {
      throw Exception('Collection has no recipes');
    }

    // Collect all unique ingredients
    final Map<String, IngredientInfo> ingredientMap = {};
    for (final recipe in recipes) {
      for (final ingredient in recipe.ingredients) {
        final name = ingredient.name.toLowerCase().trim();
        if (ingredientMap.containsKey(name)) {
          // Merge quantities if needed
          final existing = ingredientMap[name]!;
          ingredientMap[name] = IngredientInfo(
            name: ingredient.name,
            quantity: _mergeQuantities(existing.quantity, ingredient.quantity),
            unit: ingredient.unit ?? existing.unit,
            category: ingredient.category ?? existing.category,
          );
        } else {
          ingredientMap[name] = IngredientInfo(
            name: ingredient.name,
            quantity: ingredient.quantity,
            unit: ingredient.unit,
            category: ingredient.category,
          );
        }
      }
    }

    // Filter out pantry items if considerPantry is true
    List<String> pantryItemNames = [];
    if (considerPantry) {
      pantryItemNames = await _pantryService.getPantryIngredientNames();
      pantryItemNames = pantryItemNames.map((n) => n.toLowerCase().trim()).toList();
    }

    // Create shopping list
    final shoppingList = await createShoppingList(name: listName);

    // Add items to shopping list
    final itemsToAdd = <String>[];
    for (final entry in ingredientMap.entries) {
      final itemName = entry.value.name;
      final lowerName = itemName.toLowerCase().trim();

      // Skip if in pantry and considerPantry is true
      if (considerPantry) {
        bool inPantry = pantryItemNames.any((pantryName) =>
            pantryName == lowerName ||
            pantryName.contains(lowerName) ||
            lowerName.contains(pantryName));
        if (inPantry) continue;
      }

      // Format item name with quantity if available
      String formattedName = itemName;
      if (entry.value.quantity.isNotEmpty) {
        formattedName = '${entry.value.quantity} ${entry.value.unit ?? ''} ${itemName}'.trim();
      }

      itemsToAdd.add(formattedName);
    }

    if (itemsToAdd.isNotEmpty) {
      await addItems(
        shoppingListId: shoppingList.id,
        itemNames: itemsToAdd,
      );
    }

    // Reload shopping list with items
    return await getShoppingListById(shoppingList.id) ?? shoppingList;
  }

  ShoppingListModel _shoppingListFromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>?)
            ?.map((i) => ShoppingListItemModel.fromJson(i as Map<String, dynamic>))
            .toList() ??
        [];

    return ShoppingListModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      items: items,
    );
  }

  String _mergeQuantities(String q1, String q2) {
    // Simple merge - just return the first one for now
    // Could be enhanced to parse and add quantities
    return q1.isNotEmpty ? q1 : q2;
  }
}

// Helper class for ingredient aggregation
class IngredientInfo {
  final String name;
  final String quantity;
  final String? unit;
  final String? category;

  IngredientInfo({
    required this.name,
    required this.quantity,
    this.unit,
    this.category,
  });
}

