import 'package:flutter/material.dart' hide Step;
import 'package:flutter/services.dart';
import '../models/recipe.dart';
import '../services/recipe_service.dart';

class AddRecipeScreen extends StatefulWidget {
  final Recipe? recipe;

  const AddRecipeScreen({super.key, this.recipe});

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final RecipeService _recipeService = RecipeService();
  
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _cookingTimeController = TextEditingController();
  final TextEditingController _servingsController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();

  List<Ingredient> _ingredients = [];
  List<Step> _steps = [];
  final TextEditingController _ingredientNameController = TextEditingController();
  final TextEditingController _ingredientQuantityController = TextEditingController();
  final TextEditingController _ingredientUnitController = TextEditingController();
  final TextEditingController _stepController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.recipe != null) {
      _titleController.text = widget.recipe!.title;
      _descriptionController.text = widget.recipe!.description;
      _cookingTimeController.text = widget.recipe!.cookingTime.toString();
      _servingsController.text = widget.recipe!.servings.toString();
      _authorController.text = widget.recipe!.author;
      _imageUrlController.text = widget.recipe!.imageUrl ?? '';
      _ingredients = List.from(widget.recipe!.ingredients);
      _steps = List.from(widget.recipe!.steps);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _cookingTimeController.dispose();
    _servingsController.dispose();
    _authorController.dispose();
    _imageUrlController.dispose();
    _ingredientNameController.dispose();
    _ingredientQuantityController.dispose();
    _ingredientUnitController.dispose();
    _stepController.dispose();
    super.dispose();
  }

  void _addIngredient() {
    if (_ingredientNameController.text.isNotEmpty &&
        _ingredientQuantityController.text.isNotEmpty) {
      setState(() {
        _ingredients.add(Ingredient(
          name: _ingredientNameController.text,
          quantity: _ingredientQuantityController.text,
          unit: _ingredientUnitController.text.isEmpty
              ? null
              : _ingredientUnitController.text,
        ));
        _ingredientNameController.clear();
        _ingredientQuantityController.clear();
        _ingredientUnitController.clear();
      });
    }
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
    });
  }

  void _addStep() {
    if (_stepController.text.isNotEmpty) {
      setState(() {
        _steps.add(Step(
          stepNumber: _steps.length + 1,
          instruction: _stepController.text,
        ));
        _stepController.clear();
      });
    }
  }

  void _removeStep(int index) {
    setState(() {
      _steps.removeAt(index);
      // Re-number steps
      for (int i = 0; i < _steps.length; i++) {
        _steps[i] = Step(
          stepNumber: i + 1,
          instruction: _steps[i].instruction,
          imageUrl: _steps[i].imageUrl,
        );
      }
    });
  }

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) return;
    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one ingredient')),
      );
      return;
    }
    if (_steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one step')),
      );
      return;
    }

    final recipe = Recipe(
      id: widget.recipe?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      description: _descriptionController.text,
      imageUrl: _imageUrlController.text.isEmpty ? null : _imageUrlController.text,
      ingredients: _ingredients,
      steps: _steps,
      cookingTime: int.parse(_cookingTimeController.text),
      servings: int.parse(_servingsController.text),
      author: _authorController.text,
      createdAt: widget.recipe?.createdAt ?? DateTime.now(),
      likes: widget.recipe?.likes ?? 0,
    );

    if (widget.recipe != null) {
      await _recipeService.updateRecipe(recipe);
    } else {
      await _recipeService.addRecipe(recipe);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe != null ? 'Edit Recipe' : 'Add Recipe'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveRecipe,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Recipe Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a recipe title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cookingTimeController,
                    decoration: const InputDecoration(
                      labelText: 'Cooking Time (min)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _servingsController,
                    decoration: const InputDecoration(
                      labelText: 'Servings',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _authorController,
              decoration: const InputDecoration(
                labelText: 'Author',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter author name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                labelText: 'Image URL (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Ingredients', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ingredientQuantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _ingredientUnitController,
                    decoration: const InputDecoration(
                      labelText: 'Unit (optional)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _ingredientNameController,
                    decoration: const InputDecoration(
                      labelText: 'Ingredient Name',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  onPressed: _addIngredient,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._ingredients.asMap().entries.map(
              (entry) => Card(
                child: ListTile(
                  title: Text(
                    '${entry.value.quantity}${entry.value.unit != null ? ' ${entry.value.unit}' : ''} ${entry.value.name}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeIngredient(entry.key),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Steps', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _stepController,
                    decoration: const InputDecoration(
                      labelText: 'Instruction',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  onPressed: _addStep,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._steps.map(
              (step) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text('${step.stepNumber}'),
                  ),
                  title: Text(step.instruction),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeStep(step.stepNumber - 1),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
