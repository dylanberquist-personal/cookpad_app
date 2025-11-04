import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../config/supabase_config.dart';
import '../models/ai_chat_model.dart';
import '../models/pantry_item_model.dart';
import '../models/recipe_model.dart';
import '../models/nutrition_model.dart';

class AiRecipeService {
  final _supabase = SupabaseConfig.client;
  static String get _openAiApiKey => dotenv.env['OPENAI_API_KEY'] ?? '';
  static const String _openAiBaseUrl = 'https://api.openai.com/v1/chat/completions';

  Future<String> generateRecipeChat({
    required String userMessage,
    required List<ChatMessageModel> chatHistory,
    List<PantryItemModel>? pantryItems,
    List<String>? dietaryRestrictions,
    String? cuisineType,
    String? mealType,
    int? maxCookingTime,
    String? skillLevel,
    int? servings,
  }) async {
    // Build context from user preferences and pantry
    final systemMessage = _buildSystemMessage(
      pantryItems: pantryItems,
      dietaryRestrictions: dietaryRestrictions,
      cuisineType: cuisineType,
      mealType: mealType,
      maxCookingTime: maxCookingTime,
      skillLevel: skillLevel,
      servings: servings,
    );

    // Format chat history for OpenAI
    final messages = [
      {'role': 'system', 'content': systemMessage},
      ...chatHistory.map((m) => {
            'role': m.role,
            'content': m.content,
          }),
      {'role': 'user', 'content': userMessage},
    ];

    try {
      final response = await http.post(
        Uri.parse(_openAiBaseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openAiApiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4-turbo-preview',
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 2000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = data['choices'] as List;
        if (choices.isNotEmpty) {
          final message = choices[0]['message'] as Map<String, dynamic>;
          return message['content'] as String;
        }
      }

      throw Exception('Failed to generate recipe: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error calling OpenAI API: $e');
    }
  }

  String _buildSystemMessage({
    List<PantryItemModel>? pantryItems,
    List<String>? dietaryRestrictions,
    String? cuisineType,
    String? mealType,
    int? maxCookingTime,
    String? skillLevel,
    int? servings,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('You are a helpful recipe generation assistant. Generate recipes based on user requests.');
    buffer.writeln();

    if (pantryItems != null && pantryItems.isNotEmpty) {
      buffer.writeln('Available ingredients:');
      for (final item in pantryItems) {
        buffer.writeln('- ${item.ingredientName}${item.quantity != null ? ' (${item.quantity})' : ''}');
      }
      buffer.writeln();
    }

    if (dietaryRestrictions != null && dietaryRestrictions.isNotEmpty) {
      buffer.writeln('Dietary restrictions: ${dietaryRestrictions.join(', ')}');
      buffer.writeln();
    }

    if (cuisineType != null) {
      buffer.writeln('Cuisine type: $cuisineType');
      buffer.writeln();
    }

    if (mealType != null) {
      buffer.writeln('Meal type: $mealType');
      buffer.writeln();
    }

    if (maxCookingTime != null) {
      buffer.writeln('Maximum cooking time: $maxCookingTime minutes');
      buffer.writeln();
    }

    if (skillLevel != null) {
      buffer.writeln('Cooking skill level: $skillLevel');
      buffer.writeln();
    }

    if (servings != null) {
      buffer.writeln('Number of servings: $servings');
      buffer.writeln();
    }

    buffer.writeln('When generating recipes, ALWAYS format them in a structured way with clear sections:');
    buffer.writeln('1. **Recipe Title**: Clear, descriptive title');
    buffer.writeln('2. **Description**: Brief description of the recipe');
    buffer.writeln('3. **Ingredients**: List ingredients with quantities and units (e.g., "2 cups flour", "1 tsp salt")');
    buffer.writeln('4. **Instructions**: Numbered step-by-step instructions');
    buffer.writeln('5. **Time**: Prep time, cook time, and total time in minutes');
    buffer.writeln('6. **Servings**: Number of servings');
    buffer.writeln('7. **Difficulty**: easy, medium, or hard');
    buffer.writeln('8. **Meal Type**: breakfast, lunch, dinner, snack, or dessert');
    buffer.writeln('');
    buffer.writeln('IMPORTANT: Format recipes consistently with clear headers and structured sections.');
    buffer.writeln('After the recipe text, include a JSON block with this exact structure:');
    buffer.writeln('```json');
    buffer.writeln('{');
    buffer.writeln('  "title": "Recipe Title",');
    buffer.writeln('  "description": "Brief description",');
    buffer.writeln('  "ingredients": [{"name": "Ingredient", "quantity": "amount", "unit": "unit"}],');
    buffer.writeln('  "instructions": [{"step_number": 1, "instruction": "Step text"}],');
    buffer.writeln('  "prep_time": 0,');
    buffer.writeln('  "cook_time": 0,');
    buffer.writeln('  "total_time": 0,');
    buffer.writeln('  "servings": 1,');
    buffer.writeln('  "difficulty_level": "easy|medium|hard",');
    buffer.writeln('  "meal_type": "breakfast|lunch|dinner|snack|dessert",');
    buffer.writeln('  "cuisine_type": "optional",');
    buffer.writeln('  "tags": ["tag1", "tag2"]');
    buffer.writeln('}');
    buffer.writeln('```');

    return buffer.toString();
  }

  Future<AiChatSessionModel> createChatSession(String userId) async {
    // Ensure user exists in users table before creating chat session
    await _ensureUserExists(userId);
    
    final response = await _supabase
        .from('ai_chat_sessions')
        .insert({
          'user_id': userId,
          'messages': [],
        })
        .select()
        .single();

    return AiChatSessionModel.fromJson(response);
  }

  Future<void> _ensureUserExists(String userId) async {
    // Check if user exists in users table
    final existingUser = await _supabase
        .from('users')
        .select('id')
        .eq('id', userId)
        .maybeSingle();

    if (existingUser == null) {
      // Get user email from auth
      final authUser = _supabase.auth.currentUser;
      if (authUser == null || authUser.id != userId) {
        throw Exception('User not authenticated');
      }

      // Create user record in users table
      // Generate unique username from email
      final email = authUser.email ?? '';
      var username = email.split('@').first;
      
      // Check if username already exists, append numbers if needed
      int counter = 1;
      var finalUsername = username;
      while (true) {
        final exists = await _supabase
            .from('users')
            .select('id')
            .eq('username', finalUsername)
            .maybeSingle();
        
        if (exists == null) break;
        finalUsername = '$username$counter';
        counter++;
      }

      await _supabase.from('users').insert({
        'id': userId,
        'email': email,
        'username': finalUsername,
        'skill_level': 'beginner',
        'dietary_restrictions': [],
        'chef_score': 0.0,
      });
    }
  }

  Future<AiChatSessionModel> updateChatSession({
    required String sessionId,
    required List<ChatMessageModel> messages,
    String? recipeId,
  }) async {
    await _supabase
        .from('ai_chat_sessions')
        .update({
          'messages': messages.map((m) => m.toJson()).toList(),
          'recipe_id': recipeId,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', sessionId);

    final response = await _supabase
        .from('ai_chat_sessions')
        .select()
        .eq('id', sessionId)
        .single();

    return AiChatSessionModel.fromJson(response);
  }

  Future<List<AiChatSessionModel>> getUserChatSessions(String userId) async {
    final response = await _supabase
        .from('ai_chat_sessions')
        .select()
        .eq('user_id', userId)
        .order('updated_at', ascending: false);

    return (response as List)
        .map((json) => AiChatSessionModel.fromJson(json))
        .toList();
  }

  Future<AiChatSessionModel?> getChatSession(String sessionId) async {
    final response = await _supabase
        .from('ai_chat_sessions')
        .select()
        .eq('id', sessionId)
        .maybeSingle();

    return response != null ? AiChatSessionModel.fromJson(response) : null;
  }

  Future<void> deleteChatSession(String sessionId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Verify the session belongs to the user
    final session = await getChatSession(sessionId);
    if (session == null) throw Exception('Chat session not found');
    if (session.userId != userId) throw Exception('Unauthorized');

    await _supabase
        .from('ai_chat_sessions')
        .delete()
        .eq('id', sessionId);
  }

  /// Extracts a structured recipe from chat messages by asking AI to format it as JSON
  Future<Map<String, dynamic>> extractRecipeFromChat(List<ChatMessageModel> messages) async {
    // Build the conversation summary for extraction
    final conversationText = messages.map((m) => '${m.role}: ${m.content}').join('\n\n');
    
    final extractionPrompt = '''
Based on the following conversation, extract the recipe information and return it as a JSON object with this exact structure:

{
  "title": "Recipe Title",
  "description": "Brief description of the recipe",
  "ingredients": [
    {"name": "Ingredient Name", "quantity": "amount", "unit": "unit if applicable"}
  ],
  "instructions": [
    {"step_number": 1, "instruction": "Step instruction"}
  ],
  "prep_time": 0,
  "cook_time": 0,
  "total_time": 0,
  "servings": 1,
  "difficulty_level": "easy" or "medium" or "hard",
  "meal_type": "breakfast" or "lunch" or "dinner" or "snack" or "dessert",
  "cuisine_type": "optional cuisine type",
  "tags": ["tag1", "tag2"]
}

Return ONLY the JSON object, no other text.

Conversation:
$conversationText
''';

    try {
      final response = await http.post(
        Uri.parse(_openAiBaseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openAiApiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4-turbo-preview',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a recipe extraction assistant. Extract recipe information from conversations and return it as JSON. Return ONLY valid JSON, no markdown formatting or explanations.',
            },
            {
              'role': 'user',
              'content': extractionPrompt,
            },
          ],
          'temperature': 0.3,
          'max_tokens': 2000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = data['choices'] as List;
        if (choices.isNotEmpty) {
          final message = choices[0]['message'] as Map<String, dynamic>;
          final content = message['content'] as String;
          
          // Try to extract JSON from the response (might be wrapped in markdown)
          final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
          if (jsonMatch != null) {
            final jsonString = jsonMatch.group(0)!;
            final recipeJson = jsonDecode(jsonString) as Map<String, dynamic>;
            return recipeJson;
          }
          
          // If no JSON found, try parsing the whole content
          final recipeJson = jsonDecode(content) as Map<String, dynamic>;
          return recipeJson;
        }
      }

      throw Exception('Failed to extract recipe: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error extracting recipe from chat: $e');
    }
  }

  /// Converts extracted recipe JSON to RecipeModel
  RecipeModel parseRecipeFromJson(Map<String, dynamic> json, {required String userId, bool isPublic = true}) {
    // Parse ingredients
    final ingredientsJson = json['ingredients'] as List<dynamic>? ?? [];
    final ingredients = ingredientsJson.map((item) {
      final itemMap = item as Map<String, dynamic>;
      return IngredientModel(
        name: itemMap['name'] as String? ?? '',
        quantity: itemMap['quantity'] as String? ?? '',
        unit: itemMap['unit'] as String?,
        category: itemMap['category'] as String?,
      );
    }).toList();

    // Parse instructions
    final instructionsJson = json['instructions'] as List<dynamic>? ?? [];
    final instructions = instructionsJson.map((item) {
      final itemMap = item as Map<String, dynamic>;
      return InstructionStepModel(
        stepNumber: itemMap['step_number'] as int? ?? 1,
        instruction: itemMap['instruction'] as String? ?? '',
        imageUrl: itemMap['image_url'] as String?,
      );
    }).toList();

    // Parse difficulty level
    final difficultyStr = (json['difficulty_level'] as String? ?? 'easy').toLowerCase();
    final difficultyLevel = difficultyStr == 'hard'
        ? DifficultyLevel.hard
        : difficultyStr == 'medium'
            ? DifficultyLevel.medium
            : DifficultyLevel.easy;

    // Parse meal type
    final mealTypeStr = (json['meal_type'] as String? ?? 'dinner').toLowerCase();
    final mealType = MealType.values.firstWhere(
      (e) => e.name == mealTypeStr,
      orElse: () => MealType.dinner,
    );

    // Parse times
    final prepTime = json['prep_time'] as int? ?? 0;
    final cookTime = json['cook_time'] as int? ?? 0;
    final totalTime = json['total_time'] as int? ?? (prepTime + cookTime);
    final servings = json['servings'] as int? ?? 1;

    // Parse tags
    final tagsJson = json['tags'] as List<dynamic>? ?? [];
    final tags = tagsJson.map((e) => e.toString()).toList();

    final now = DateTime.now();

    return RecipeModel(
      id: '', // Will be generated by database
      userId: userId,
      title: json['title'] as String? ?? 'Untitled Recipe',
      description: json['description'] as String? ?? '',
      ingredients: ingredients,
      instructions: instructions,
      prepTime: prepTime,
      cookTime: cookTime,
      totalTime: totalTime,
      servings: servings,
      difficultyLevel: difficultyLevel,
      cuisineType: json['cuisine_type'] as String?,
      mealType: mealType,
      nutrition: null, // Can be added later if needed
      tags: tags,
      sourceType: SourceType.ai,
      sourceUrl: null,
      isPublic: isPublic,
      averageRating: 0.0,
      ratingCount: 0,
      favoriteCount: 0,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Generates nutrition information for a recipe using AI
  Future<NutritionModel> generateNutritionInfo(RecipeModel recipe) async {
    final prompt = '''
Based on the following recipe, estimate the nutrition information per serving. Return ONLY valid JSON, no markdown formatting or explanations.

Recipe:
Title: ${recipe.title}
Description: ${recipe.description}
Servings: ${recipe.servings}

Ingredients:
${recipe.ingredients.map((ing) => '- ${ing.quantity} ${ing.unit ?? ''} ${ing.name}').join('\n')}

Instructions:
${recipe.instructions.map((inst) => '${inst.stepNumber}. ${inst.instruction}').join('\n')}

Return a JSON object with the following structure:
{
  "calories_per_serving": <number>,
  "protein": <number in grams>,
  "carbohydrates": <number in grams>,
  "fats": <number in grams>,
  "fiber": <number in grams, optional>,
  "sugar": <number in grams, optional>,
  "sodium": <number in mg, optional>,
  "vitamins": {
    "<vitamin_name>": <amount in mg or mcg>
  },
  "minerals": {
    "<mineral_name>": <amount in mg>
  },
  "serving_size": "<MUST be a specific unit like '200g', '7oz', '1 patty (25% of total mixture)', '1 slice (1/8 of recipe)', etc. NEVER use generic terms like '1 serving' or 'per serving'. Use weight (g/oz) or specific portion descriptions>"
}

IMPORTANT: The serving_size field MUST always use specific units:
- Weight units: "200g", "7oz", "150g", etc.
- Specific portions: "1 patty (25% of total mixture)", "1 slice (1/12 of recipe)", "1 cup (250ml)", etc.
NEVER use generic terms like "1 serving" or "per serving" - always be specific.
''';

    try {
      final response = await http.post(
        Uri.parse(_openAiBaseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openAiApiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4-turbo-preview',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a nutrition estimation assistant. Estimate nutrition information for recipes based on ingredients and cooking methods. Return ONLY valid JSON, no markdown formatting or explanations.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.3,
          'max_tokens': 1500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = data['choices'] as List;
        if (choices.isNotEmpty) {
          final message = choices[0]['message'] as Map<String, dynamic>;
          final content = message['content'] as String;
          
          // Try to extract JSON from the response (might be wrapped in markdown)
          final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
          if (jsonMatch != null) {
            final jsonString = jsonMatch.group(0)!;
            final nutritionJson = jsonDecode(jsonString) as Map<String, dynamic>;
            
            return NutritionModel.fromJson(nutritionJson);
          }
          
          // If no JSON found, try parsing the whole content
          final nutritionJson = jsonDecode(content) as Map<String, dynamic>;
          return NutritionModel.fromJson(nutritionJson);
        }
      }

      throw Exception('Failed to generate nutrition info: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error generating nutrition info: $e');
    }
  }

  /// Regenerates nutrition information with a more detailed, accurate calculation method
  Future<NutritionModel> regenerateNutritionInfo(RecipeModel recipe) async {
    // Build detailed ingredient list with quantities
    final ingredientsList = recipe.ingredients.map((ing) {
      final quantity = ing.quantity;
      final unit = ing.unit ?? '';
      final name = ing.name;
      return '$quantity $unit $name'.trim();
    }).join('\n');

    // Build cooking steps summary
    final cookingSteps = recipe.instructions.map((inst) => inst.instruction).join('\n');

    final prompt = '''
You are a professional nutritionist calculating the precise nutritional information for a recipe.

CALCULATION METHODOLOGY:
1. Analyze EACH ingredient individually and calculate its nutritional content
2. Convert all quantities to standard units (grams) for accuracy
3. Account for cooking methods:
   - Oil absorption during frying/sautéing (typically 10-20% of oil used)
   - Water loss during cooking (meats lose 20-30% weight, vegetables 10-20%)
   - Evaporation and reduction effects
4. Sum all ingredients to get total recipe nutrition
5. Divide by number of servings to get per-serving values
6. Use standard nutritional databases (USDA FoodData Central values)

Recipe Details:
Title: ${recipe.title}
Description: ${recipe.description}
Total Servings: ${recipe.servings}
Preparation Time: ${recipe.prepTime} minutes
Cooking Time: ${recipe.cookTime} minutes

Ingredients (with quantities):
$ingredientsList

Cooking Instructions:
$cookingSteps

IMPORTANT CALCULATION RULES:
- For each ingredient, look up standard nutritional values per 100g
- Convert ingredient quantities to grams using standard conversions:
  * 1 cup flour ≈ 120g
  * 1 cup sugar ≈ 200g
  * 1 cup butter ≈ 227g
  * 1 cup milk ≈ 240g
  * 1 large egg ≈ 50g
  * 1 cup oil ≈ 220g
  * 1 tsp salt ≈ 6g
  * 1 tbsp ≈ 15g
  * 1 cup liquid ≈ 240ml (use density for specific liquids)
- For cooking methods:
  * Frying: Add 10-15% of oil used to total calories/fats
  * Baking/Roasting: Account for water loss (reduce weight by 15-25% for meats)
  * Boiling: Some nutrients may leach into water (reduce by 10-15% for water-soluble vitamins)
- Calculate total recipe nutrition, then divide by ${recipe.servings} servings
- Round final values appropriately (calories to nearest integer, macros to 1 decimal)

Return ONLY valid JSON with this exact structure:
{
  "calories_per_serving": <integer - total calories per serving>,
  "protein": <number - grams of protein per serving, 1 decimal>,
  "carbohydrates": <number - grams of carbs per serving, 1 decimal>,
  "fats": <number - grams of fats per serving, 1 decimal>,
  "fiber": <number - grams of fiber per serving, 1 decimal, optional>,
  "sugar": <number - grams of sugar per serving, 1 decimal, optional>,
  "sodium": <number - milligrams of sodium per serving, 0 decimals, optional>,
  "vitamins": {
    "<vitamin_name>": <number - amount in mg or mcg>
  },
  "minerals": {
    "<mineral_name>": <number - amount in mg>
  },
  "serving_size": "<MUST be specific: weight in grams like '250g' or '7oz', or specific portion like '1 patty (200g)' or '1 slice (1/8 recipe, 150g)'. NEVER use generic '1 serving'>"
}

CRITICAL: The serving_size must ALWAYS be a specific weight or portion description. Examples:
- "250g" (if per serving is 250 grams)
- "7oz" (if per serving is 7 ounces)  
- "1 patty (200g)" (if it's a specific item with weight)
- "1 slice (1/12 of recipe, 180g)" (if it's a fraction with weight)
NEVER return "1 serving" or "per serving" - always include specific units.
''';

    try {
      final response = await http.post(
        Uri.parse(_openAiBaseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openAiApiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4-turbo-preview',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a professional nutritionist with expertise in calculating accurate nutritional information from recipes. You use standard nutritional databases and account for cooking methods. Always return valid JSON only, no explanations or markdown.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.2, // Lower temperature for more consistent, accurate results
          'max_tokens': 2000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = data['choices'] as List;
        if (choices.isNotEmpty) {
          final message = choices[0]['message'] as Map<String, dynamic>;
          final content = message['content'] as String;
          
          // Try to extract JSON from the response (might be wrapped in markdown)
          final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
          if (jsonMatch != null) {
            final jsonString = jsonMatch.group(0)!;
            final nutritionJson = jsonDecode(jsonString) as Map<String, dynamic>;
            
            return NutritionModel.fromJson(nutritionJson);
          }
          
          // If no JSON found, try parsing the whole content
          final nutritionJson = jsonDecode(content) as Map<String, dynamic>;
          return NutritionModel.fromJson(nutritionJson);
        }
      }

      throw Exception('Failed to regenerate nutrition info: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error regenerating nutrition info: $e');
    }
  }

  /// Generates a prompt asking the user how they want to change a recipe being remixed
  Future<String> generateRemixPrompt({
    required String recipeTitle,
    required List<ChatMessageModel> chatHistory,
  }) async {
    final systemMessage = '''You are a helpful recipe generation assistant. The user has shared a recipe they want to remix/change. 

Your job is to ask them how they would like to modify the recipe. Be friendly and helpful, and suggest specific aspects they might want to change (ingredients, cooking method, difficulty, time, servings, dietary restrictions, etc.).

Keep your response brief and conversational. Ask something like "How would you like to change this recipe?" or "What aspects of this recipe would you like to modify?"''';

    final messages = [
      {'role': 'system', 'content': systemMessage},
      ...chatHistory.map((m) => {
            'role': m.role,
            'content': m.content,
          }),
    ];

    try {
      final response = await http.post(
        Uri.parse(_openAiBaseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openAiApiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4-turbo-preview',
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 200,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = data['choices'] as List;
        if (choices.isNotEmpty) {
          final message = choices[0]['message'] as Map<String, dynamic>;
          return message['content'] as String;
        }
      }

      // Fallback response if API call fails
      return 'How would you like to change this recipe? You can modify ingredients, cooking methods, difficulty, time, servings, or add dietary restrictions.';
    } catch (e) {
      // Fallback response if there's an error
      return 'How would you like to change this recipe? You can modify ingredients, cooking methods, difficulty, time, servings, or add dietary restrictions.';
    }
  }
}
