import 'dart:io';
import 'package:flutter/material.dart' hide Step;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../services/pantry_service.dart';
import '../services/preferences_service.dart';
import '../models/pantry_item_model.dart';
import '../widgets/notification_badge_icon.dart';
import 'main_navigation.dart';

class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  final _pantryService = PantryService();
  final _preferencesService = PreferencesService();
  bool _isEnabled = false;
  bool _isLoading = true;
  Map<String, List<PantryItemModel>> _itemsByCategory = {};
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final isEnabled = await _preferencesService.isPantryEnabled();
    setState(() {
      _isEnabled = isEnabled;
      _isLoading = false;
    });
    if (_isEnabled) {
      await _loadPantryItems();
    }
  }

  Future<void> _loadPantryItems() async {
    try {
      final itemsByCategory = await _pantryService.getPantryItemsByCategory();
      setState(() {
        _itemsByCategory = itemsByCategory;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading pantry: $e')),
        );
      }
    }
  }

  Future<void> _togglePantryFeature() async {
    final newState = await _preferencesService.togglePantry();
    setState(() {
      _isEnabled = newState;
    });

    if (newState) {
      await _loadPantryItems();
    }
    // Note: Pantry items are preserved even when feature is disabled
  }

  Future<void> _clearAllPantryItems() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Pantry Items'),
        content: const Text(
          'Are you sure you want to delete all pantry items? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _pantryService.deleteAllPantryItems();
        setState(() {
          _itemsByCategory = {};
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All pantry items cleared'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error clearing items: $e')),
          );
        }
      }
    }
  }

  Future<void> _showAddItemDialog() async {
    final nameController = TextEditingController();
    final quantityController = TextEditingController();
    String? selectedCategory;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Add Pantry Item'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Ingredient Name',
                      hintText: 'e.g., Tomatoes',
                      border: OutlineInputBorder(),
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity (Optional)',
                      hintText: 'e.g., 2 lbs',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Category (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    value: selectedCategory,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('None')),
                      ...PantryService.getCommonCategories().map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedCategory = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.trim().isNotEmpty) {
                    Navigator.pop(context, {
                      'name': nameController.text.trim(),
                      'quantity': quantityController.text.trim().isEmpty
                          ? null
                          : quantityController.text.trim(),
                      'category': selectedCategory,
                    });
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );

    if (result != null) {
      try {
        await _pantryService.addPantryItem(
          ingredientName: result['name'] as String,
          category: result['category'] as String?,
          quantity: result['quantity'] as String?,
        );
        await _loadPantryItems();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Item added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding item: $e')),
          );
        }
      }
    }
  }

  Future<void> _showEditItemDialog(PantryItemModel item) async {
    final nameController = TextEditingController(text: item.ingredientName);
    final quantityController = TextEditingController(text: item.quantity ?? '');
    String? selectedCategory = item.category;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Pantry Item'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Ingredient Name',
                      border: OutlineInputBorder(),
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity (Optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Category (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    value: selectedCategory,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('None')),
                      ...PantryService.getCommonCategories().map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedCategory = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.trim().isNotEmpty) {
                    Navigator.pop(context, {
                      'name': nameController.text.trim(),
                      'quantity': quantityController.text.trim().isEmpty
                          ? null
                          : quantityController.text.trim(),
                      'category': selectedCategory,
                    });
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    if (result != null) {
      try {
        await _pantryService.updatePantryItem(
          id: item.id,
          ingredientName: result['name'] as String,
          category: result['category'] as String?,
          quantity: result['quantity'] as String?,
        );
        await _loadPantryItems();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Item updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating item: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteItem(PantryItemModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.ingredientName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _pantryService.deletePantryItem(item.id);
        await _loadPantryItems();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Item deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting item: $e')),
          );
        }
      }
    }
  }

  Future<void> _showImportDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Pantry Items'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.text_fields),
              title: const Text('Import from Text'),
              subtitle: const Text('Paste a list of items'),
              onTap: () => Navigator.pop(context, 'text'),
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Import from Image'),
              subtitle: const Text('Take a photo or select from gallery'),
              onTap: () => Navigator.pop(context, 'image'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (result == 'text') {
      _showTextImportDialog();
    } else if (result == 'image') {
      _showImageImportDialog();
    }
  }

  Future<void> _showTextImportDialog() async {
    final textController = TextEditingController();
    String? selectedCategory;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Import from Text'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Enter items separated by commas or new lines:',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: textController,
                    decoration: const InputDecoration(
                      labelText: 'Items',
                      hintText: 'Tomatoes, Onions, Garlic\nOr one per line',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 10,
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Category for All Items (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    value: selectedCategory,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('None')),
                      ...PantryService.getCommonCategories().map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedCategory = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (textController.text.trim().isNotEmpty) {
                    Navigator.pop(context, {
                      'text': textController.text.trim(),
                      'category': selectedCategory,
                    });
                  }
                },
                child: const Text('Import'),
              ),
            ],
          );
        },
      ),
    );

    if (result != null) {
      try {
        final text = result['text'] as String;
        final category = result['category'] as String?;
        
        // Parse items - split by comma or newline
        final items = text
            .split(RegExp(r'[,;\n]'))
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();

        if (items.isNotEmpty) {
          await _pantryService.addPantryItems(items, category: category);
          await _loadPantryItems();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${items.length} item(s) imported successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error importing items: $e')),
          );
        }
      }
    }
  }

  Future<void> _showImageImportDialog() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 85,
      );

      if (image == null) return;

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final extractedText = await _extractTextFromImage(File(image.path));
        
        if (!mounted) return;
        Navigator.pop(context); // Close loading dialog

        if (extractedText.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No text could be extracted from the image'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        // Show dialog to review extracted text
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Extracted Text'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Review the extracted text and import items:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: TextEditingController(text: extractedText),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 10,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Import Items'),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          // Parse and import items
          final items = extractedText
              .split(RegExp(r'[,;\n]'))
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();

          if (items.isNotEmpty) {
            await _pantryService.addPantryItems(items);
            await _loadPantryItems();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${items.length} item(s) imported successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }
        }
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context); // Close loading dialog
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error extracting text: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: ${e.toString()}')),
        );
      }
    }
  }

  Future<String> _extractTextFromImage(File imageFile) async {
    try {
      if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
        throw Exception('OCR is only supported on Android and iOS devices');
      }

      final inputImage = InputImage.fromFilePath(imageFile.path);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      
      final recognizedText = await textRecognizer.processImage(inputImage);
      String extractedText = recognizedText.text;
      
      await textRecognizer.close();
      
      if (extractedText.isEmpty) {
        throw Exception('No text could be extracted from the image');
      }
      
      return extractedText;
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to extract text from image: $e');
    }
  }

  List<PantryItemModel> get _filteredItems {
    if (_selectedCategory == 'All') {
      return _itemsByCategory.values.expand((items) => items).toList();
    }
    return _itemsByCategory[_selectedCategory] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Pantry'),
        actions: [
          if (_isEnabled) ...[
            if (_itemsByCategory.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete_sweep),
                onPressed: _clearAllPantryItems,
                tooltip: 'Clear All Items',
              ),
            IconButton(
              icon: const Icon(Icons.upload_file),
              onPressed: _showImportDialog,
              tooltip: 'Import Items',
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showAddItemDialog,
              tooltip: 'Add Item',
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Enable/Disable Toggle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? (_isEnabled ? Colors.green.shade900.withOpacity(0.3) : Colors.grey.shade800)
                  : (_isEnabled ? Colors.green.shade50 : Colors.grey.shade100),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pantry Management',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? (_isEnabled ? Colors.green.shade300 : Colors.grey.shade400)
                              : (_isEnabled ? Colors.green.shade700 : Colors.grey.shade700),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isEnabled
                            ? 'Track your ingredients and get recipe suggestions'
                            : 'Enable to track your ingredients',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isEnabled,
                  onChanged: (_) => _togglePantryFeature(),
                ),
              ],
            ),
          ),
          // Pantry Content
          if (_isEnabled)
            Expanded(
              child: _itemsByCategory.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.kitchen,
                            size: 64,
                            color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Your pantry is empty',
                            style: TextStyle(
                              fontSize: 18,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add items manually or import from text/image',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // Category Filter
                        if (_itemsByCategory.length > 1)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  _CategoryChip(
                                    label: 'All',
                                    isSelected: _selectedCategory == 'All',
                                    onTap: () {
                                      setState(() {
                                        _selectedCategory = 'All';
                                      });
                                    },
                                  ),
                                  ..._itemsByCategory.keys.map(
                                    (category) => _CategoryChip(
                                      label: category,
                                      isSelected: _selectedCategory == category,
                                      onTap: () {
                                        setState(() {
                                          _selectedCategory = category;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        // Items List
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _loadPantryItems,
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              itemCount: _filteredItems.length,
                              separatorBuilder: (context, index) => Divider(
                                height: 1,
                                thickness: 1,
                                color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                                indent: 16,
                                endIndent: 16,
                              ),
                              itemBuilder: (context, index) {
                                final item = _filteredItems[index];
                                return _PantryItemTile(
                                  item: item,
                                  onEdit: () => _showEditItemDialog(item),
                                  onDelete: () => _deleteItem(item),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
          ),
        ],
      ),
      floatingActionButton: _isEnabled
          ? FloatingActionButton(
              onPressed: _showAddItemDialog,
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: SizedBox(
        height: 60,
        child: NavigationBar(
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

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).primaryColor.withOpacity(isDark ? 0.2 : 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).primaryColor
                : (isDark ? Colors.grey.shade600 : Colors.grey.shade300),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected 
                ? Theme.of(context).primaryColor
                : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
          ),
        ),
      ),
    );
  }
}

class _PantryItemTile extends StatelessWidget {
  final PantryItemModel item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PantryItemTile({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: onEdit,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Low stock indicator (minimal dot)
            if (item.isLowStock)
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade400,
                  shape: BoxShape.circle,
                ),
              ),
            // Item content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.ingredientName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey[200] : Colors.black87,
                    ),
                  ),
                  if (item.quantity != null || item.category != null) ...[
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (item.quantity != null)
                          Text(
                            item.quantity!,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                        if (item.category != null) ...[
                          if (item.quantity != null)
                            Container(
                              width: 2,
                              height: 2,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                                shape: BoxShape.circle,
                              ),
                            ),
                          Text(
                            item.category!,
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Actions menu
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                size: 18,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18, color: Colors.grey.shade700),
                      const SizedBox(width: 8),
                      const Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: Colors.red.shade400),
                      const SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red.shade400)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit();
                } else if (value == 'delete') {
                  onDelete();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
