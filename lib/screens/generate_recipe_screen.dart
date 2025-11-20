import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart' hide Step;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../services/ai_recipe_service.dart';
import '../../services/recipe_service_supabase.dart';
import '../../services/auth_service.dart';
import '../../services/pantry_service.dart';
import '../../services/preferences_service.dart';
import '../../config/supabase_config.dart';
import '../../models/ai_chat_model.dart';
import '../../models/recipe_model.dart';
import '../../models/user_model.dart';
import '../../models/pantry_item_model.dart';
import 'recipe_detail_screen_new.dart';

class GenerateRecipeScreen extends StatefulWidget {
  final RecipeModel? remixRecipe;

  const GenerateRecipeScreen({super.key, this.remixRecipe});

  @override
  State<GenerateRecipeScreen> createState() => _GenerateRecipeScreenState();
}

class _GenerateRecipeScreenState extends State<GenerateRecipeScreen> with WidgetsBindingObserver {
  final _aiService = AiRecipeService();
  final _recipeService = RecipeServiceSupabase();
  final _authService = AuthService();
  final _pantryService = PantryService();
  final _preferencesService = PreferencesService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  
  AiChatSessionModel? _currentSession;
  List<ChatMessageModel> _messages = [];
  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _remixRecipeSent = false; // Track if remix recipe has been sent
  Map<int, Map<String, dynamic>?> _recipeDataCache = {}; // Cache parsed recipe data by message index
  File? _selectedImage; // Store selected image for OCR
  bool _isProcessingOCR = false; // Track OCR processing state
  bool _considerPantry = false; // Track if pantry should be considered
  bool _pantryEnabled = false; // Track if pantry feature is enabled
  List<PantryItemModel> _pantryItems = []; // Store pantry items
  bool _isInitialized = false; // Track if widget is initialized

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserProfile();
    _initializeSession();
    _loadPantryStatus().then((_) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reload pantry status when app resumes
      _loadPantryStatus();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload pantry status when dependencies change (including route changes)
    // Only reload if widget is initialized to avoid unnecessary calls
    if (_isInitialized) {
      _loadPantryStatus();
    }
  }

  Future<void> _loadPantryStatus() async {
    final isEnabled = await _preferencesService.isPantryEnabled();
    setState(() {
      _pantryEnabled = isEnabled;
    });
    if (isEnabled) {
      try {
        final items = await _pantryService.getPantryItems();
        setState(() {
          _pantryItems = items;
        });
      } catch (e) {
        // Silently fail - pantry items are optional
      }
    } else {
      setState(() {
        _pantryItems = [];
      });
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = await _authService.getCurrentUserProfile();
      setState(() {
        _currentUser = user;
      });
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }


  Future<void> _initializeSession() async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final session = await _aiService.createChatSession(userId);
      setState(() {
        _currentSession = session;
        _messages = session.messages;
        _recipeDataCache = {};
      });
      
      // If remixRecipe is provided and hasn't been sent yet, send it as the first message
      if (widget.remixRecipe != null && !_remixRecipeSent && _messages.isEmpty) {
        await _sendRemixRecipe();
        _remixRecipeSent = true;
      }
      
      // Parse all messages for recipes
      for (int i = 0; i < _messages.length; i++) {
        _parseRecipeFromMessage(i);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _sendRemixRecipe() async {
    if (widget.remixRecipe == null || _currentSession == null) return;

    // Format recipe as a user message (recipe card format)
    final recipe = widget.remixRecipe!;
    final recipeMessage = _formatRecipeAsMessage(recipe);

    // Add user message
    final userMsg = ChatMessageModel(
      role: 'user',
      content: recipeMessage,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      // Get AI response asking how to change the recipe
      final assistantResponse = await _aiService.generateRemixPrompt(
        recipeTitle: recipe.title,
        chatHistory: _messages,
      );

      final assistantMsg = ChatMessageModel(
        role: 'assistant',
        content: assistantResponse,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(assistantMsg);
        _isLoading = false;
      });

      // Update session
      if (_currentSession != null) {
        await _aiService.updateChatSession(
          sessionId: _currentSession!.id,
          messages: [..._messages],
        );
      }

      _scrollToBottom();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  String _formatRecipeAsMessage(RecipeModel recipe) {
    // Format recipe as a JSON structure that can be displayed as a recipe card
    final recipeJson = {
      'title': recipe.title,
      'description': recipe.description,
      'ingredients': recipe.ingredients.map((ing) => {
        'name': ing.name,
        'quantity': ing.quantity,
        'unit': ing.unit,
      }).toList(),
      'instructions': recipe.instructions.map((inst) => {
        'step_number': inst.stepNumber,
        'instruction': inst.instruction,
      }).toList(),
      'prep_time': recipe.prepTime,
      'cook_time': recipe.cookTime,
      'total_time': recipe.totalTime,
      'servings': recipe.servings,
      'difficulty_level': recipe.difficultyLevel.name,
      'meal_type': recipe.mealType.name,
      'cuisine_type': recipe.cuisineType,
      'tags': recipe.tags,
    };

    // Return as JSON string wrapped in markdown code block
    return '```json\n${jsonEncode(recipeJson)}\n```';
  }

  Future<void> _startNewChat() async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final session = await _aiService.createChatSession(userId);
      setState(() {
        _currentSession = session;
        _messages = session.messages;
        _recipeDataCache = {};
      });
      // Parse all messages for recipes
      for (int i = 0; i < _messages.length; i++) {
        _parseRecipeFromMessage(i);
      }
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _loadChatSession(String sessionId) async {
    try {
      final session = await _aiService.getChatSession(sessionId);
      if (session != null) {
        setState(() {
          _currentSession = session;
          _messages = session.messages;
          _recipeDataCache = {};
        });
        // Parse all messages for recipes
        for (int i = 0; i < _messages.length; i++) {
          _parseRecipeFromMessage(i);
        }
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading chat: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _showChatHistory() async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final sessions = await _aiService.getUserChatSessions(userId);
      // Filter to only sessions with recipeId (saved recipes)
      final recipeSessions = sessions.where((s) => s.recipeId != null).toList();

      if (!mounted) return;

      if (recipeSessions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No saved recipe chats yet')),
        );
        return;
      }

      // Fetch recipe titles for sessions
      final Map<String, String> recipeTitles = {};
      for (final session in recipeSessions) {
        if (session.recipeId != null) {
          try {
            final recipe = await _recipeService.getRecipeById(session.recipeId!);
            if (recipe != null) {
              recipeTitles[session.id] = recipe.title;
            }
          } catch (e) {
            recipeTitles[session.id] = 'Unknown Recipe';
          }
        }
      }

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history, color: Colors.orange),
                    const SizedBox(width: 12),
                    const Text(
                      'Chat History',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: recipeSessions.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final session = recipeSessions[index];
                      final title = recipeTitles[session.id] ?? 'Unknown Recipe';
                      return _ChatHistoryItem(
                        title: title,
                        onTap: () {
                          Navigator.pop(context);
                          _loadChatSession(session.id);
                        },
                        onLongPress: () => _showDeleteChatDialog(session.id, title),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading chat history: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _showDeleteChatDialog(String sessionId, String recipeTitle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chat'),
        content: Text('Are you sure you want to delete the chat for "$recipeTitle"? This action cannot be undone.'),
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
        await _aiService.deleteChatSession(sessionId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Chat deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          // Close the chat history dialog if it's still open and reopen it to refresh
          Navigator.pop(context);
          _showChatHistory();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting chat: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _sendMessage() async {
    if ((_messageController.text.trim().isEmpty && _selectedImage == null) || _isLoading) return;
    if (_currentSession == null) {
      await _initializeSession();
      return;
    }

    String userMessage = _messageController.text.trim();
    
    // If there's a selected image, perform OCR first
    if (_selectedImage != null) {
      try {
        setState(() => _isProcessingOCR = true);
        final extractedText = await _extractTextFromImage(_selectedImage!);
        if (extractedText.isNotEmpty) {
          // Combine user message with extracted text
          if (userMessage.isNotEmpty) {
            userMessage = '$userMessage\n\nExtracted recipe from image:\n$extractedText';
          } else {
            userMessage = 'Extracted recipe from image:\n$extractedText';
          }
        }
        setState(() {
          _selectedImage = null;
          _isProcessingOCR = false;
        });
      } catch (e) {
        setState(() {
          _selectedImage = null;
          _isProcessingOCR = false;
        });
        if (mounted) {
          String errorMessage = 'Error extracting text from image: ${e.toString()}';
          
          // Provide helpful guidance for common errors
          if (e.toString().contains('MissingPluginException')) {
            errorMessage = 'OCR plugin not found. Please:\n'
                '1. Stop the app completely\n'
                '2. Run: flutter clean && flutter pub get\n'
                '3. Rebuild and restart the app\n'
                '4. Ensure you are testing on Android or iOS device';
          } else if (e.toString().contains('only supported on Android and iOS')) {
            errorMessage = 'OCR is only available on Android and iOS devices. Please test on a mobile device.';
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              duration: const Duration(seconds: 5),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }
    
    _messageController.clear();

    // Add user message
    final userMsg = ChatMessageModel(
      role: 'user',
      content: userMessage,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      // Get pantry items if feature is enabled and user wants to consider them
      List<PantryItemModel>? pantryItems;
      if (_pantryEnabled && _considerPantry && _pantryItems.isNotEmpty) {
        pantryItems = _pantryItems;
      }

      final assistantResponse = await _aiService.generateRecipeChat(
        userMessage: userMessage,
        chatHistory: _messages,
        pantryItems: pantryItems,
      );

      final assistantMsg = ChatMessageModel(
        role: 'assistant',
        content: assistantResponse,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(assistantMsg);
        _isLoading = false;
        // Try to parse recipe from message
        _parseRecipeFromMessage(_messages.length - 1);
      });

      // Update session
      if (_currentSession != null) {
        await _aiService.updateChatSession(
          sessionId: _currentSession!.id,
          messages: [..._messages],
        );
      }

      _scrollToBottom();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _parseRecipeFromMessage(int messageIndex) {
    if (messageIndex >= _messages.length) return;
    final message = _messages[messageIndex];
    // Parse recipe from both user and assistant messages
    if (message.role != 'assistant' && message.role != 'user') return;

    // Try to extract JSON from message
    try {
      final jsonMatch = RegExp(r'```json\s*(\{[\s\S]*?\})\s*```', multiLine: true).firstMatch(message.content);
      if (jsonMatch != null) {
        final jsonString = jsonMatch.group(1)!;
        final recipeJson = jsonDecode(jsonString) as Map<String, dynamic>;
        _recipeDataCache[messageIndex] = recipeJson;
        return;
      }

      // Try to find JSON without markdown
      final jsonMatch2 = RegExp(r'\{[\s\S]*?\}').firstMatch(message.content);
      if (jsonMatch2 != null) {
        try {
          final jsonString = jsonMatch2.group(0)!;
          final recipeJson = jsonDecode(jsonString) as Map<String, dynamic>;
          // Check if it looks like a recipe
          if (recipeJson.containsKey('title') && 
              recipeJson.containsKey('ingredients') && 
              recipeJson.containsKey('instructions')) {
            _recipeDataCache[messageIndex] = recipeJson;
            return;
          }
        } catch (e) {
          // Not valid JSON
        }
      }
    } catch (e) {
      // Could not parse recipe
    }
  }

  bool _isRecipeMessage(int index) {
    if (_recipeDataCache.containsKey(index)) return true;
    
    // Also check if message contains recipe-like structure
    if (index >= _messages.length) return false;
    final message = _messages[index];
    // Check both user and assistant messages for recipes
    if (message.role != 'assistant' && message.role != 'user') return false;
    
    final content = message.content.toLowerCase();
    // Check for recipe indicators
    final hasRecipeIndicators = (
      content.contains('recipe') ||
      content.contains('ingredients') ||
      content.contains('instructions') ||
      content.contains('prep time') ||
      content.contains('cook time')
    ) && (
      content.contains('title') ||
      content.contains('servings') ||
      content.contains('difficulty')
    );
    
    if (hasRecipeIndicators) {
      // Try to parse
      _parseRecipeFromMessage(index);
      return _recipeDataCache.containsKey(index);
    }
    
    return false;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<String> _extractTextFromImage(File imageFile) async {
    try {
      // Check if platform is supported (Android or iOS)
      if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
        throw Exception('OCR is only supported on Android and iOS devices. Please use a mobile device.');
      }

      final inputImage = InputImage.fromFilePath(imageFile.path);
      // Use Latin script recognizer for better compatibility
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      
      final recognizedText = await textRecognizer.processImage(inputImage);
      
      String extractedText = recognizedText.text;
      
      // Clean up
      await textRecognizer.close();
      
      if (extractedText.isEmpty) {
        throw Exception('No text could be extracted from the image. Please ensure the image contains clear, readable text.');
      }
      
      return extractedText;
    } catch (e) {
      // Re-throw with more context if it's already an Exception
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to extract text from image: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking photo: ${e.toString()}')),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  Future<void> _showSaveRecipeDialog(int messageIndex) async {
    if (_messages.isEmpty || _isSaving || !_isRecipeMessage(messageIndex)) return;

    bool isPublic = true;
    List<XFile> selectedImages = [];
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Save Recipe'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Save this recipe to your profile?'),
                  const SizedBox(height: 16),
                  RadioListTile<bool>(
                    title: const Text('Public'),
                    subtitle: const Text('Anyone can see this recipe'),
                    value: true,
                    groupValue: isPublic,
                    onChanged: (value) {
                      setDialogState(() => isPublic = value!);
                    },
                  ),
                  RadioListTile<bool>(
                    title: const Text('Private'),
                    subtitle: const Text('Only you can see this recipe'),
                    value: false,
                    groupValue: isPublic,
                    onChanged: (value) {
                      setDialogState(() => isPublic = value!);
                    },
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text('Add Recipe Image (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (selectedImages.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...selectedImages.asMap().entries.map((entry) {
                          final index = entry.key;
                          final image = entry.value;
                          return Stack(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: FileImage(File(image.path)),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: -8,
                                right: -8,
                                child: IconButton(
                                  icon: const Icon(Icons.close, size: 20),
                                  color: Colors.red,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    setDialogState(() {
                                      selectedImages.removeAt(index);
                                    });
                                  },
                                ),
                              ),
                            ],
                          );
                        }),
                        if (selectedImages.length < 5)
                          GestureDetector(
                            onTap: () async {
                              final ImagePicker picker = ImagePicker();
                              final XFile? image = await picker.pickImage(
                                source: ImageSource.gallery,
                                maxWidth: 2000,
                                maxHeight: 2000,
                                imageQuality: 85,
                              );
                              if (image != null) {
                                setDialogState(() {
                                  selectedImages.add(image);
                                });
                              }
                            },
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.add, size: 32, color: Colors.grey),
                            ),
                          ),
                      ],
                    )
                  else
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text('Add Image'),
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();
                        final XFile? image = await picker.pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 2000,
                          maxHeight: 2000,
                          imageQuality: 85,
                        );
                        if (image != null) {
                          setDialogState(() {
                            selectedImages.add(image);
                          });
                        }
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
                onPressed: () => Navigator.pop(context, {
                  'save': true,
                  'isPublic': isPublic,
                  'images': selectedImages,
                }),
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    if (result != null && result['save'] == true) {
      await _saveRecipe(
        messageIndex: messageIndex,
        isPublic: result['isPublic'] as bool,
        images: result['images'] as List<XFile>? ?? [],
      );
    }
  }

  Future<void> _saveRecipe({
    required int messageIndex,
    required bool isPublic,
    required List<XFile> images,
  }) async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to save recipes')),
        );
      }
      return;
    }

    if (messageIndex >= _messages.length || !_isRecipeMessage(messageIndex)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No recipe to save')),
        );
      }
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Get recipe data from cache or extract from message
      Map<String, dynamic> recipeJson;
      if (_recipeDataCache.containsKey(messageIndex)) {
        recipeJson = _recipeDataCache[messageIndex]!;
      } else {
        // Extract from messages up to this point
        final messagesUpToRecipe = _messages.sublist(0, messageIndex + 1);
        recipeJson = await _aiService.extractRecipeFromChat(messagesUpToRecipe);
      }
      
      // Upload images to Supabase storage if provided
      List<String> imageUrls = [];
      if (images.isNotEmpty) {
        final supabase = SupabaseConfig.client;
        final userId = supabase.auth.currentUser?.id;
        if (userId == null) {
          throw Exception('User not authenticated');
        }

        for (int i = 0; i < images.length; i++) {
          final file = File(images[i].path);
          final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
          final filePath = '$userId/$fileName';

          await supabase.storage.from('recipe-images').upload(
            filePath,
            file,
          );

          final imageUrl = supabase.storage.from('recipe-images').getPublicUrl(filePath);
          imageUrls.add(imageUrl);
        }
      }
      
      // Parse JSON to RecipeModel
      final recipe = _aiService.parseRecipeFromJson(
        recipeJson,
        userId: userId,
        isPublic: isPublic,
      );

      // Create recipe with image URLs
      final recipeWithImages = RecipeModel(
        id: recipe.id,
        userId: recipe.userId,
        title: recipe.title,
        description: recipe.description,
        ingredients: recipe.ingredients,
        instructions: recipe.instructions,
        prepTime: recipe.prepTime,
        cookTime: recipe.cookTime,
        totalTime: recipe.totalTime,
        servings: recipe.servings,
        difficultyLevel: recipe.difficultyLevel,
        cuisineType: recipe.cuisineType,
        mealType: recipe.mealType,
        nutrition: recipe.nutrition,
        tags: recipe.tags,
        sourceType: recipe.sourceType,
        sourceUrl: recipe.sourceUrl,
        isPublic: recipe.isPublic,
        averageRating: recipe.averageRating,
        ratingCount: recipe.ratingCount,
        favoriteCount: recipe.favoriteCount,
        createdAt: recipe.createdAt,
        updatedAt: recipe.updatedAt,
        imageUrls: imageUrls.isNotEmpty ? imageUrls : null,
      );

      // Save recipe to database (pass original recipe ID if this is a remix)
      final savedRecipe = await _recipeService.createRecipe(
        recipeWithImages,
        originalRecipeId: widget.remixRecipe?.id,
      );

      // Update chat session with recipe ID
      if (_currentSession != null) {
        await _aiService.updateChatSession(
          sessionId: _currentSession!.id,
          messages: _messages,
          recipeId: savedRecipe.id,
        );
        setState(() {
          _currentSession = AiChatSessionModel(
            id: _currentSession!.id,
            userId: _currentSession!.userId,
            recipeId: savedRecipe.id,
            messages: _currentSession!.messages,
            createdAt: _currentSession!.createdAt,
            updatedAt: DateTime.now(),
          );
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recipe "${recipe.title}" saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving recipe: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _viewRecipe() async {
    if (_currentSession?.recipeId == null) return;

    try {
      final recipe = await _recipeService.getRecipeById(_currentSession!.recipeId!);
      if (recipe != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailScreenNew(recipe: recipe),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading recipe: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Recipe'),
        actions: [
          // Pantry toggle (only show if pantry feature is enabled)
          if (_pantryEnabled)
            Tooltip(
              message: _considerPantry
                  ? 'Using pantry items'
                  : 'Not using pantry items',
              child: IconButton(
                icon: Icon(
                  _considerPantry ? Icons.kitchen : Icons.kitchen_outlined,
                  color: _considerPantry ? Colors.orange : Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _considerPantry = !_considerPantry;
                  });
                },
              ),
            ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _startNewChat,
            tooltip: 'New Chat',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showChatHistory,
            tooltip: 'Chat History',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.auto_awesome, size: 64, color: Colors.orange),
                        const SizedBox(height: 16),
                        const Text(
                          'Start a conversation to generate a recipe',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tell me what you want to cook!',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        return const _LoadingIndicator();
                      }
                      final message = _messages[index];
                      final isRecipe = _isRecipeMessage(index);
                      final isUserMessage = message.role == 'user';
                      return _ChatBubble(
                        message: message,
                        isRecipe: isRecipe,
                        recipeData: _recipeDataCache[index],
                        isSaved: _currentSession?.recipeId != null && !isUserMessage,
                        onSave: () => _showSaveRecipeDialog(index),
                        onView: _viewRecipe,
                        isSaving: _isSaving && index == _messages.length - 1,
                        userProfilePictureUrl: _currentUser?.profilePictureUrl,
                      );
                    },
                  ),
          ),
          if (_selectedImage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: FileImage(_selectedImage!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Image selected',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isProcessingOCR ? 'Processing OCR...' : 'Ready to extract recipe',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: _isProcessingOCR ? null : _removeImage,
                    tooltip: 'Remove image',
                  ),
                ],
              ),
            ),
          _ChatInput(
            controller: _messageController,
            onSend: _sendMessage,
            isLoading: _isLoading || _isProcessingOCR,
            onPickImage: _pickImage,
            onTakePhoto: _takePhoto,
            hasSelectedImage: _selectedImage != null,
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isRecipe;
  final Map<String, dynamic>? recipeData;
  final bool isSaved;
  final VoidCallback onSave;
  final VoidCallback onView;
  final bool isSaving;
  final String? userProfilePictureUrl;

  const _ChatBubble({
    required this.message,
    required this.isRecipe,
    this.recipeData,
    required this.isSaved,
    required this.onSave,
    required this.onView,
    required this.isSaving,
    this.userProfilePictureUrl,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white,
                backgroundImage: const AssetImage('Assets/Logo_without_text.png'),
                onBackgroundImageError: (exception, stackTrace) {
                  // Fallback handled by child
                },
                child: null,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (isRecipe)
                  _RecipeCard(
                    message: message,
                    recipeData: recipeData,
                    isSaved: isSaved,
                    onSave: isUser ? () {} : onSave, // Don't allow saving user's remix recipe
                    onView: onView,
                    isSaving: isSaving,
                    isUserMessage: isUser,
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.orange : Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      message.content,
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[300],
              backgroundImage: userProfilePictureUrl != null
                  ? NetworkImage(userProfilePictureUrl!)
                  : null,
              child: userProfilePictureUrl == null
                  ? const Icon(Icons.person, size: 20)
                  : null,
            ),
          ],
        ],
      ),
    );
  }
}

class _RecipeCard extends StatefulWidget {
  final ChatMessageModel message;
  final Map<String, dynamic>? recipeData;
  final bool isSaved;
  final VoidCallback onSave;
  final VoidCallback onView;
  final bool isSaving;
  final bool isUserMessage;

  const _RecipeCard({
    required this.message,
    this.recipeData,
    required this.isSaved,
    required this.onSave,
    required this.onView,
    required this.isSaving,
    this.isUserMessage = false,
  });

  @override
  State<_RecipeCard> createState() => _RecipeCardState();
}

class _RecipeCardState extends State<_RecipeCard> {
  bool _ingredientsExpanded = false;
  bool _instructionsExpanded = false;

  @override
  Widget build(BuildContext context) {
    // Extract recipe info from message or recipeData
    String title = '';
    String description = '';
    List<String> ingredients = [];
    List<String> instructions = [];
    int prepTime = 0;
    int cookTime = 0;
    int servings = 1;
    String difficulty = 'easy';

    if (widget.recipeData != null) {
      title = widget.recipeData!['title'] as String? ?? '';
      description = widget.recipeData!['description'] as String? ?? '';
      prepTime = widget.recipeData!['prep_time'] as int? ?? 0;
      cookTime = widget.recipeData!['cook_time'] as int? ?? 0;
      servings = widget.recipeData!['servings'] as int? ?? 1;
      difficulty = (widget.recipeData!['difficulty_level'] as String? ?? 'easy').toLowerCase();
      
      final ingredientsList = widget.recipeData!['ingredients'] as List?;
      if (ingredientsList != null) {
        ingredients = ingredientsList.map((ing) {
          if (ing is Map) {
            final name = ing['name'] as String? ?? '';
            final quantity = ing['quantity'] as String? ?? '';
            final unit = ing['unit'] as String? ?? '';
            return '$quantity ${unit.isNotEmpty ? '$unit ' : ''}$name'.trim();
          }
          return ing.toString();
        }).toList();
      }
      
      final instructionsList = widget.recipeData!['instructions'] as List?;
      if (instructionsList != null) {
        instructions = instructionsList.map((inst) {
          if (inst is Map) {
            return inst['instruction'] as String? ?? '';
          }
          return inst.toString();
        }).toList();
      }
    } else {
      // Try to parse from message content
      final content = widget.message.content;
      final lines = content.split('\n');
      bool inIngredients = false;
      bool inInstructions = false;
      
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.toLowerCase().contains('recipe title') || 
            trimmed.toLowerCase().startsWith('**recipe title')) {
          title = trimmed.replaceAll(RegExp(r'\*\*|Recipe Title[:]?\s*', caseSensitive: false), '').trim();
        } else if (trimmed.toLowerCase().contains('description')) {
          description = trimmed.replaceAll(RegExp(r'\*\*|Description[:]?\s*', caseSensitive: false), '').trim();
        } else if (trimmed.toLowerCase().contains('ingredients')) {
          inIngredients = true;
          inInstructions = false;
        } else if (trimmed.toLowerCase().contains('instructions') || 
                   trimmed.toLowerCase().contains('steps')) {
          inIngredients = false;
          inInstructions = true;
        } else if (inIngredients && trimmed.isNotEmpty && !trimmed.startsWith('#')) {
          ingredients.add(trimmed.replaceAll(RegExp(r'^[-*•]\s*'), ''));
        } else if (inInstructions && trimmed.isNotEmpty && !trimmed.startsWith('#')) {
          instructions.add(trimmed.replaceAll(RegExp(r'^\d+[\.\)]\s*'), ''));
        }
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.orange.withOpacity(0.5) : Colors.orange.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.orange.withOpacity(0.2)
                  : Colors.orange.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.restaurant_menu, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title.isNotEmpty ? title : 'Recipe',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.orange[300] : Colors.orange,
                    ),
                      ),
                    ),
                  ],
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Recipe Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time and servings
                Row(
                  children: [
                    if (prepTime > 0 || cookTime > 0)
                      _InfoChip(
                        icon: Icons.timer,
                        label: '${prepTime + cookTime} min',
                      ),
                    if (servings > 0) ...[
                      const SizedBox(width: 8),
                      _InfoChip(
                        icon: Icons.people,
                        label: '$servings serving${servings > 1 ? 's' : ''}',
                      ),
                    ],
                    if (difficulty.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      _InfoChip(
                        icon: Icons.speed,
                        label: difficulty,
                      ),
                    ],
                  ],
                ),
                
                // Ingredients
                if (ingredients.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Ingredients',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...(_ingredientsExpanded ? ingredients : ingredients.take(5)).map((ing) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• ',
                          style: TextStyle(
                            color: isDark ? Colors.orange[300] : Colors.orange,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            ing,
                            style: TextStyle(
                              color: isDark ? Colors.grey[200] : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                  if (ingredients.length > 5)
                    InkWell(
                      onTap: () {
                        setState(() {
                          _ingredientsExpanded = !_ingredientsExpanded;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Text(
                              _ingredientsExpanded
                                  ? 'Show less'
                                  : '... and ${ingredients.length - 5} more',
                              style: TextStyle(
                                color: isDark ? Colors.orange[300] : Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _ingredientsExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              size: 16,
                              color: isDark ? Colors.orange[300] : Colors.orange,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
                
                // Instructions preview
                if (instructions.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Instructions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...(_instructionsExpanded ? instructions : instructions.take(3).toList()).asMap().entries.map((entry) {
                    final index = entry.key;
                    final inst = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${index + 1}. ',
                            style: TextStyle(
                              color: isDark ? Colors.orange[300] : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              _instructionsExpanded
                                  ? inst
                                  : (inst.length > 100
                                      ? '${inst.substring(0, 100)}...'
                                      : inst),
                              style: TextStyle(
                                color: isDark ? Colors.grey[200] : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (instructions.length > 3)
                    InkWell(
                      onTap: () {
                        setState(() {
                          _instructionsExpanded = !_instructionsExpanded;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Text(
                              _instructionsExpanded
                                  ? 'Show less'
                                  : '... and ${instructions.length - 3} more steps',
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _instructionsExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              size: 16,
                              color: Colors.orange,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
          
          // Action buttons (only show for assistant messages, not user remix messages)
          if (!widget.isUserMessage)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (widget.isSaved)
                    ElevatedButton.icon(
                      onPressed: widget.isSaving ? null : widget.onView,
                      icon: const Icon(Icons.visibility, size: 18),
                      label: const Text('View Recipe'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: widget.isSaving ? null : widget.onSave,
                      icon: widget.isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.save, size: 18),
                      label: Text(widget.isSaving ? 'Saving...' : 'Save Recipe'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
            )
          else
            // For user messages, show a small label indicating it's the original recipe
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_fix_high, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    'Original Recipe (Remix)',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.orange.withOpacity(0.2)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isDark ? Colors.orange[300] : Colors.orange,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.orange[300] : Colors.orange,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isLoading;
  final VoidCallback? onPickImage;
  final VoidCallback? onTakePhoto;
  final bool hasSelectedImage;

  const _ChatInput({
    required this.controller,
    required this.onSend,
    required this.isLoading,
    this.onPickImage,
    this.onTakePhoto,
    this.hasSelectedImage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (onPickImage != null || onTakePhoto != null)
            PopupMenuButton<String>(
              icon: Icon(
                hasSelectedImage ? Icons.image : Icons.add_photo_alternate,
                color: hasSelectedImage ? Colors.orange : Colors.grey[700],
              ),
              tooltip: 'Attach photo',
              onSelected: (value) {
                if (value == 'gallery' && onPickImage != null) {
                  onPickImage!();
                } else if (value == 'camera' && onTakePhoto != null) {
                  onTakePhoto!();
                }
              },
              itemBuilder: (context) => [
                if (onPickImage != null)
                  const PopupMenuItem(
                    value: 'gallery',
                    child: Row(
                      children: [
                        Icon(Icons.photo_library, size: 20),
                        SizedBox(width: 8),
                        Text('Choose from Gallery'),
                      ],
                    ),
                  ),
                if (onTakePhoto != null)
                  const PopupMenuItem(
                    value: 'camera',
                    child: Row(
                      children: [
                        Icon(Icons.camera_alt, size: 20),
                        SizedBox(width: 8),
                        Text('Take Photo'),
                      ],
                    ),
                  ),
              ],
            ),
          if (onPickImage != null || onTakePhoto != null)
            const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hasSelectedImage
                    ? 'Add description (optional)...'
                    : 'Describe the recipe you want...',
                border: const OutlineInputBorder(),
              ),
              maxLines: null,
              enabled: !isLoading,
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            onPressed: isLoading ? null : onSend,
          ),
        ],
      ),
    );
  }
}

class _LoadingIndicator extends StatefulWidget {
  const _LoadingIndicator();

  @override
  State<_LoadingIndicator> createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<_LoadingIndicator>
    with SingleTickerProviderStateMixin {
  static const List<String> _loadingMessages = [
    'Preheating the oven...',
    'Firing up the grill...',
    'Washing the dishes...',
    'Sharpening the knives...',
    'Gathering ingredients...',
    'Measuring spices...',
    'Chopping vegetables...',
    'Mixing the batter...',
    'Seasoning to perfection...',
    'Stirring the pot...',
    'Tasting the flavors...',
    'Adjusting the temperature...',
    'Checking the recipe...',
    'Preparing the mise en place...',
    'Caramelizing the onions...',
    'Melting the butter...',
    'Whisking the eggs...',
    'Rolling out the dough...',
    'Simmering the sauce...',
    'Plating the dish...',
  ];

  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Change message every 2 seconds
    Future.delayed(const Duration(seconds: 2), _changeMessage);
  }

  void _changeMessage() {
    if (!mounted) return;
    setState(() {
      _currentIndex = (_currentIndex + 1) % _loadingMessages.length;
    });
    Future.delayed(const Duration(seconds: 2), _changeMessage);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.orange.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white,
              backgroundImage: const AssetImage('Assets/Logo_without_text.png'),
              onBackgroundImageError: (exception, stackTrace) {
                // Fallback handled by child
              },
              child: null,
            ),
          ),
          const SizedBox(width: 8),
          FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _loadingMessages[_currentIndex],
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatHistoryItem extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ChatHistoryItem({
    required this.title,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.restaurant_menu,
                color: Colors.orange,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
