import '../config/supabase_config.dart';
import '../models/pantry_item_model.dart';

class PantryService {
  final _supabase = SupabaseConfig.client;

  /// Get all pantry items for the current user
  Future<List<PantryItemModel>> getPantryItems() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('pantry_items')
        .select()
        .eq('user_id', userId)
        .order('added_at', ascending: false);

    return (response as List)
        .map((json) => PantryItemModel.fromJson(json))
        .toList();
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
        .eq('user_id', userId) // Ensure user owns the item
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
        .eq('id', id)
        .eq('user_id', userId); // Ensure user owns the item
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
}

