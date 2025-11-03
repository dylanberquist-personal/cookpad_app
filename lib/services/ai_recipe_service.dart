import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../config/supabase_config.dart';
import '../models/ai_chat_model.dart';
import '../models/pantry_item_model.dart';

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

    buffer.writeln('When generating recipes, provide:');
    buffer.writeln('1. A clear recipe title');
    buffer.writeln('2. A brief description');
    buffer.writeln('3. A list of ingredients with quantities');
    buffer.writeln('4. Step-by-step instructions');
    buffer.writeln('5. Prep time, cook time, and total time');
    buffer.writeln('6. Difficulty level (easy, medium, or hard)');

    return buffer.toString();
  }

  Future<AiChatSessionModel> createChatSession(String userId) async {
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
}
