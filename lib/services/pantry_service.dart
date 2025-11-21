import '../config/supabase_config.dart';
import '../models/pantry_item_model.dart';

class PantryService {
  final _supabase = SupabaseConfig.client;

  /// Get all pantry items for the current user (including synced pantries)
  Future<List<PantryItemModel>> getPantryItems() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Get own pantry items
    final ownResponse = await _supabase
        .from('pantry_items')
        .select()
        .eq('user_id', userId)
        .order('added_at', ascending: false);

    final ownItems = (ownResponse as List)
        .map((json) => PantryItemModel.fromJson(json))
        .toList();

    // Get synced users' pantry items
    final syncedUsers = await getSyncedUsers();
    final allItems = List<PantryItemModel>.from(ownItems);

    for (final syncedUserId in syncedUsers) {
      final syncedResponse = await _supabase
          .from('pantry_items')
          .select()
          .eq('user_id', syncedUserId)
          .order('added_at', ascending: false);

      final syncedItems = (syncedResponse as List)
          .map((json) => PantryItemModel.fromJson(json))
          .toList();
      
      allItems.addAll(syncedItems);
    }

    // Remove duplicates and sort by date
    final uniqueItems = <String, PantryItemModel>{};
    for (final item in allItems) {
      uniqueItems[item.id] = item;
    }

    final result = uniqueItems.values.toList();
    result.sort((a, b) => b.addedAt.compareTo(a.addedAt));

    return result;
  }

  /// Get pantry items grouped by category
  Future<Map<String, List<PantryItemModel>>> getPantryItemsByCategory() async {
    final items = await getPantryItems();
    final grouped = <String, List<PantryItemModel>>{};

    for (final item in items) {
      final category = item.category ?? 'Uncategorized';
      if (!grouped.containsKey(category)) {
        grouped[category] = [];
      }
      grouped[category]!.add(item);
    }

    return grouped;
  }

  /// Add a new pantry item
  Future<PantryItemModel> addPantryItem({
    required String ingredientName,
    String? category,
    String? quantity,
    bool isLowStock = false,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final now = DateTime.now();
    final response = await _supabase
        .from('pantry_items')
        .insert({
          'user_id': userId,
          'ingredient_name': ingredientName,
          'category': category,
          'quantity': quantity,
          'is_low_stock': isLowStock,
          'added_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        })
        .select()
        .single();

    return PantryItemModel.fromJson(response);
  }

  /// Add multiple pantry items from a list
  Future<List<PantryItemModel>> addPantryItems(List<String> ingredientNames, {String? category}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final now = DateTime.now();
    final items = ingredientNames.map((name) => {
      'user_id': userId,
      'ingredient_name': name.trim(),
      'category': category,
      'quantity': null,
      'is_low_stock': false,
      'added_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    }).toList();

    final response = await _supabase
        .from('pantry_items')
        .insert(items)
        .select();

    return (response as List)
        .map((json) => PantryItemModel.fromJson(json))
        .toList();
  }

  /// Update a pantry item
  Future<PantryItemModel> updatePantryItem({
    required String id,
    String? ingredientName,
    String? category,
    String? quantity,
    bool? isLowStock,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final updateData = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (ingredientName != null) updateData['ingredient_name'] = ingredientName;
    if (category != null) updateData['category'] = category;
    if (quantity != null) updateData['quantity'] = quantity;
    if (isLowStock != null) updateData['is_low_stock'] = isLowStock;

    final response = await _supabase
        .from('pantry_items')
        .update(updateData)
        .eq('id', id)
        .select()
        .single();

    return PantryItemModel.fromJson(response);
  }

  /// Delete a pantry item
  Future<void> deletePantryItem(String id) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase
        .from('pantry_items')
        .delete()
        .eq('id', id);
  }

  /// Delete all pantry items for the current user
  Future<void> deleteAllPantryItems() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase
        .from('pantry_items')
        .delete()
        .eq('user_id', userId);
  }

  /// Check if user has ingredient in pantry (fuzzy match)
  Future<bool> hasIngredient(String ingredientName) async {
    final items = await getPantryItems();
    final lowerName = ingredientName.toLowerCase().trim();
    
    return items.any((item) {
      final itemName = item.ingredientName.toLowerCase().trim();
      // Exact match or contains
      return itemName == lowerName || 
             itemName.contains(lowerName) || 
             lowerName.contains(itemName);
    });
  }

  /// Get all ingredient names from pantry
  Future<List<String>> getPantryIngredientNames() async {
    final items = await getPantryItems();
    return items.map((item) => item.ingredientName).toList();
  }

  /// Get common categories
  static List<String> getCommonCategories() {
    return [
      'Produce',
      'Dairy',
      'Proteins',
      'Grains',
      'Spices & Seasonings',
      'Baking',
      'Canned Goods',
      'Frozen',
      'Beverages',
      'Condiments',
      'Oils & Vinegars',
      'Snacks',
      'Other',
    ];
  }

  /// ========================================
  /// PANTRY SYNC METHODS
  /// ========================================

  /// Send a pantry sync invitation to another user
  Future<void> inviteUserToSyncPantry(String recipientUserId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    if (userId == recipientUserId) {
      throw Exception('Cannot sync pantry with yourself');
    }

    // Check if invitation already exists
    final existing = await _supabase
        .from('synced_pantries')
        .select()
        .or('and(sender_id.eq.$userId,recipient_id.eq.$recipientUserId),and(sender_id.eq.$recipientUserId,recipient_id.eq.$userId)')
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
          .from('synced_pantries')
          .delete()
          .eq('id', existing['id']);
    }

    await _supabase.from('synced_pantries').insert({
      'sender_id': userId,
      'recipient_id': recipientUserId,
      'status': 'pending',
    });
  }

  /// Accept a pantry sync invitation
  Future<void> acceptPantrySyncInvite(String syncedPantryId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase
        .from('synced_pantries')
        .update({'status': 'accepted'})
        .eq('id', syncedPantryId)
        .eq('recipient_id', userId);
  }

  /// Decline a pantry sync invitation
  Future<void> declinePantrySyncInvite(String syncedPantryId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase
        .from('synced_pantries')
        .delete()
        .eq('id', syncedPantryId)
        .eq('recipient_id', userId);
  }

  /// Remove a synced pantry connection
  Future<void> removeSyncedPantry(String syncedPantryId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase
        .from('synced_pantries')
        .delete()
        .eq('id', syncedPantryId)
        .or('sender_id.eq.$userId,recipient_id.eq.$userId');
  }

  /// Get pending pantry sync invitations
  Future<List<Map<String, dynamic>>> getPendingSyncInvites() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('synced_pantries')
        .select('*, sender:users!sender_id(*)')
        .eq('recipient_id', userId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return (response as List).cast<Map<String, dynamic>>();
  }

  /// Get list of users currently synced with current user
  Future<List<String>> getSyncedUsers() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('synced_pantries')
        .select('sender_id, recipient_id')
        .eq('status', 'accepted')
        .or('sender_id.eq.$userId,recipient_id.eq.$userId');

    final syncedUsers = <String>[];
    for (final row in response as List) {
      final senderId = row['sender_id'] as String;
      final recipientId = row['recipient_id'] as String;
      
      if (senderId == userId) {
        syncedUsers.add(recipientId);
      } else {
        syncedUsers.add(senderId);
      }
    }

    return syncedUsers;
  }

  /// Get list of accepted synced pantries with user details
  Future<List<Map<String, dynamic>>> getAcceptedSyncedPantries() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Get pantries where current user is sender
    final sentResponse = await _supabase
        .from('synced_pantries')
        .select('id, status, created_at, recipient:users!recipient_id(id, username, display_name, profile_picture_url)')
        .eq('sender_id', userId)
        .order('created_at', ascending: false);

    // Get pantries where current user is recipient
    final receivedResponse = await _supabase
        .from('synced_pantries')
        .select('id, status, created_at, sender:users!sender_id(id, username, display_name, profile_picture_url)')
        .eq('recipient_id', userId)
        .order('created_at', ascending: false);

    final result = <Map<String, dynamic>>[];
    
    for (final row in sentResponse as List) {
      result.add({
        'id': row['id'],
        'status': row['status'],
        'created_at': row['created_at'],
        'user': row['recipient'],
        'role': 'sender',
      });
    }

    for (final row in receivedResponse as List) {
      result.add({
        'id': row['id'],
        'status': row['status'],
        'created_at': row['created_at'],
        'user': row['sender'],
        'role': 'recipient',
      });
    }

    return result;
  }
}

