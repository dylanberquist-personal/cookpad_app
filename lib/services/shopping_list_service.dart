import '../config/supabase_config.dart';
import '../models/shopping_list_model.dart';
import 'collection_service.dart';
import 'pantry_service.dart';

class ShoppingListService {
  final _supabase = SupabaseConfig.client;
  final _collectionService = CollectionService();
  final _pantryService = PantryService();

  /// Get all shopping lists for the current user (including synced lists)
  Future<List<ShoppingListModel>> getShoppingLists() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Get own shopping lists
    final ownResponse = await _supabase
        .from('shopping_lists')
        .select('*, items:shopping_list_items(*)')
        .eq('user_id', userId)
        .order('updated_at', ascending: false);

    final ownLists = (ownResponse as List).map((json) => _shoppingListFromJson(json)).toList();
    print('📋 Found ${ownLists.length} own shopping lists');

    // Get synced shopping list IDs where user is sender
    final syncedAsSender = await _supabase
        .from('synced_shopping_lists')
        .select('shopping_list_id')
        .eq('sender_id', userId)
        .eq('status', 'accepted');

    // Get synced shopping list IDs where user is recipient
    final syncedAsRecipient = await _supabase
        .from('synced_shopping_lists')
        .select('shopping_list_id')
        .eq('recipient_id', userId)
        .eq('status', 'accepted');

    print('📋 Synced as sender: ${(syncedAsSender as List).length}');
    print('📋 Synced as recipient: ${(syncedAsRecipient as List).length}');

    final syncedListIds = <String>{};
    for (final row in syncedAsSender as List) {
      final id = row['shopping_list_id'] as String;
      if (!ownLists.any((list) => list.id == id)) {
        syncedListIds.add(id);
      }
    }
    for (final row in syncedAsRecipient as List) {
      final id = row['shopping_list_id'] as String;
      if (!ownLists.any((list) => list.id == id)) {
        syncedListIds.add(id);
      }
    }

    print('📋 Total unique synced list IDs: ${syncedListIds.length}');
    if (syncedListIds.isNotEmpty) {
      print('📋 Synced list IDs: ${syncedListIds.toList()}');
    }

    // Get synced shopping lists
    final syncedLists = <ShoppingListModel>[];
    if (syncedListIds.isNotEmpty) {
      try {
        print('📋 Attempting to fetch shopping lists with IDs: ${syncedListIds.toList()}');
        final syncedResponse = await _supabase
            .from('shopping_lists')
            .select('*, items:shopping_list_items(*)')
            .inFilter('id', syncedListIds.toList())
            .order('updated_at', ascending: false);

        print('📋 Raw response: ${syncedResponse}');
        syncedLists.addAll(
          (syncedResponse as List).map((json) => _shoppingListFromJson(json)).toList(),
        );
        print('📋 Fetched ${syncedLists.length} synced shopping lists');
      } catch (e) {
        print('❌ Error fetching synced lists: $e');
      }
    }

    // Combine and sort by updated_at
    final allLists = [...ownLists, ...syncedLists];
    allLists.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    print('📋 Total lists: ${allLists.length}');
    return allLists;
  }

  /// Get only owned shopping lists
  Future<List<ShoppingListModel>> getOwnShoppingLists() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('shopping_lists')
        .select('*, items:shopping_list_items(*)')
        .eq('user_id', userId)
        .order('updated_at', ascending: false);

    return (response as List).map((json) => _shoppingListFromJson(json)).toList();
  }

  /// Get only synced (shared with me) shopping lists
  Future<List<ShoppingListModel>> getSyncedShoppingLists() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Get synced shopping list IDs where user is recipient
    final syncedAsRecipient = await _supabase
        .from('synced_shopping_lists')
        .select('shopping_list_id')
        .eq('recipient_id', userId)
        .eq('status', 'accepted');

    final syncedListIds = (syncedAsRecipient as List)
        .map((row) => row['shopping_list_id'] as String)
        .toList();

    if (syncedListIds.isEmpty) return [];

    final syncedResponse = await _supabase
        .from('shopping_lists')
        .select('*, items:shopping_list_items(*)')
        .inFilter('id', syncedListIds)
        .order('updated_at', ascending: false);

    return (syncedResponse as List).map((json) => _shoppingListFromJson(json)).toList();
  }

  /// Unsync from a shopping list (remove from your view without deleting)
  Future<void> unsyncShoppingList(String shoppingListId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Delete the sync record where user is recipient
    await _supabase
        .from('synced_shopping_lists')
        .delete()
        .eq('shopping_list_id', shoppingListId)
        .eq('recipient_id', userId);
  }

  /// Get a shopping list by ID with its items (includes synced lists)
  Future<ShoppingListModel?> getShoppingListById(String shoppingListId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('shopping_lists')
        .select('*, items:shopping_list_items(*)')
        .eq('id', shoppingListId)
        .maybeSingle();

    if (response == null) return null;

    final list = _shoppingListFromJson(response);
    
    // Verify user has access (owner or synced)
    if (list.userId != userId) {
      final syncCheck = await _supabase
          .from('synced_shopping_lists')
          .select()
          .eq('shopping_list_id', shoppingListId)
          .eq('status', 'accepted')
          .or('sender_id.eq.$userId,recipient_id.eq.$userId')
          .maybeSingle();
      
      if (syncCheck == null) {
        throw Exception('Unauthorized access to shopping list');
      }
    }

    return list;
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

    // Verify access through shopping list (owner or synced)
    final item = ShoppingListItemModel.fromJson(response);
    final list = await getShoppingListById(item.shoppingListId);
    if (list == null) {
      throw Exception('Shopping list not found');
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

    // Verify access (owner or synced)
    final list = await getShoppingListById(shoppingListId);
    if (list == null) {
      throw Exception('Shopping list not found');
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

    // Verify access (owner or synced)
    final list = await getShoppingListById(currentItem.shoppingListId);
    if (list == null) {
      throw Exception('Shopping list not found');
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

  /// ========================================
  /// SHOPPING LIST SYNC METHODS
  /// ========================================

  /// Send a shopping list sync invitation to another user
  Future<void> inviteUserToSyncShoppingList(String shoppingListId, String recipientUserId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    if (userId == recipientUserId) {
      throw Exception('Cannot sync shopping list with yourself');
    }

    // Verify ownership of shopping list
    final list = await getShoppingListById(shoppingListId);
    if (list == null || list.userId != userId) {
      throw Exception('Shopping list not found or unauthorized');
    }

    // Check if invitation already exists
    final existing = await _supabase
        .from('synced_shopping_lists')
        .select()
        .eq('shopping_list_id', shoppingListId)
        .eq('recipient_id', recipientUserId)
        .maybeSingle();

    if (existing != null) {
      final status = existing['status'] as String;
      if (status == 'accepted') {
        throw Exception('Already synced with this user');
      } else if (status == 'pending') {
        throw Exception('Invite already pending with this user');
      }
      // If declined, delete the old one and create new
      await _supabase
          .from('synced_shopping_lists')
          .delete()
          .eq('id', existing['id']);
    }

    await _supabase.from('synced_shopping_lists').insert({
      'shopping_list_id': shoppingListId,
      'sender_id': userId,
      'recipient_id': recipientUserId,
      'status': 'pending',
    });
  }

  /// Accept a shopping list sync invitation
  Future<void> acceptShoppingListSyncInvite(String syncedShoppingListId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    print('🔄 Accepting sync invite $syncedShoppingListId for user $userId');
    
    // First, check the current state
    final checkBefore = await _supabase
        .from('synced_shopping_lists')
        .select()
        .eq('id', syncedShoppingListId);
    print('📋 Before update: ${checkBefore}');

    await _supabase
        .from('synced_shopping_lists')
        .update({'status': 'accepted'})
        .eq('id', syncedShoppingListId)
        .eq('recipient_id', userId);
    
    // Check after update
    final checkAfter = await _supabase
        .from('synced_shopping_lists')
        .select()
        .eq('id', syncedShoppingListId);
    print('📋 After update: ${checkAfter}');
  }

  /// Decline a shopping list sync invitation
  Future<void> declineShoppingListSyncInvite(String syncedShoppingListId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase
        .from('synced_shopping_lists')
        .delete()
        .eq('id', syncedShoppingListId)
        .eq('recipient_id', userId);
  }

  /// Remove a synced shopping list connection
  Future<void> removeSyncedShoppingList(String syncedShoppingListId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase
        .from('synced_shopping_lists')
        .delete()
        .eq('id', syncedShoppingListId)
        .or('sender_id.eq.$userId,recipient_id.eq.$userId');
  }

  /// Get pending shopping list sync invitations
  Future<List<Map<String, dynamic>>> getPendingSyncInvites() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('synced_shopping_lists')
        .select('''
          *, 
          sender:users!sender_id(*), 
          shopping_list:shopping_lists(id, name)
        ''')
        .eq('recipient_id', userId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return (response as List).map((e) => e as Map<String, dynamic>).toList();
  }

  /// Get list of users synced with a specific shopping list
  Future<List<Map<String, dynamic>>> getSyncedUsers(String shoppingListId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Verify ownership or sync access
    final list = await getShoppingListById(shoppingListId);
    if (list == null) throw Exception('Shopping list not found');

    final response = await _supabase
        .from('synced_shopping_lists')
        .select('id, status, recipient:users!recipient_id(id, username, display_name, profile_picture_url)')
        .eq('shopping_list_id', shoppingListId)
        .eq('sender_id', userId);

    return (response as List).cast<Map<String, dynamic>>();
  }

  /// Check if shopping list is synced with current user
  Future<bool> isShoppingListSynced(String shoppingListId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    final response = await _supabase
        .from('synced_shopping_lists')
        .select()
        .eq('shopping_list_id', shoppingListId)
        .eq('status', 'accepted')
        .or('sender_id.eq.$userId,recipient_id.eq.$userId')
        .maybeSingle();

    return response != null;
  }

  /// Get shopping list sync info (who it's synced with)
  Future<Map<String, dynamic>?> getShoppingListSyncInfo(String shoppingListId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _supabase
        .from('synced_shopping_lists')
        .select('''
          id,
          status,
          sender_id,
          recipient_id,
          sender:users!sender_id(id, username, display_name, profile_picture_url),
          recipient:users!recipient_id(id, username, display_name, profile_picture_url)
        ''')
        .eq('shopping_list_id', shoppingListId)
        .eq('status', 'accepted')
        .or('sender_id.eq.$userId,recipient_id.eq.$userId')
        .maybeSingle();

    return response;
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

