import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

enum LinkType {
  youtube,
  tiktok,
  instagram,
  recipeWebsite,
  general,
}

class RecipeUrlParserService {
  static String get _openAiApiKey {
    final key = dotenv.env['OPENAI_API_KEY'] ?? '';
    if (key.isEmpty) {
      print('⚠️ WARNING: OPENAI_API_KEY not found in .env file');
    }
    return key;
  }
  
  static String get _rapidApiKey {
    final key = dotenv.env['RAPIDAPI_KEY'] ?? '';
    if (key.isEmpty) {
      print('⚠️ WARNING: RAPIDAPI_KEY not found in .env file');
    } else {
      print('✅ RapidAPI key loaded: ${key.substring(0, 10)}...${key.substring(key.length - 4)}');
    }
    return key;
  }
  
  static const String _openAiBaseUrl = 'https://api.openai.com/v1/chat/completions';

  /// Detects the type of URL
  LinkType detectLinkType(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return LinkType.general;

    final host = uri.host.toLowerCase();

    // YouTube detection
    if (host.contains('youtube.com') || 
        host.contains('youtu.be') ||
        host.contains('m.youtube.com')) {
      return LinkType.youtube;
    }

    // TikTok detection
    if (host.contains('tiktok.com') ||
        host.contains('vm.tiktok.com')) {
      return LinkType.tiktok;
    }

    // Instagram detection
    if (host.contains('instagram.com') ||
        host.contains('instagr.am')) {
      return LinkType.instagram;
    }

    // Recipe website detection (common recipe sites)
    final recipeHosts = [
      'allrecipes.com',
      'foodnetwork.com',
      'bonappetit.com',
      'epicurious.com',
      'seriouseats.com',
      'tasty.co',
      'delish.com',
      'food.com',
      'yummly.com',
      'kingarthurbaking.com',
      'simplyrecipes.com',
      'thekitchn.com',
      'cookieandkate.com',
      'budgetbytes.com',
      'minimalistbaker.com',
      'pinchofyum.com',
      'skinnytaste.com',
      'sallysbakingaddiction.com',
    ];

    for (final recipeHost in recipeHosts) {
      if (host.contains(recipeHost)) {
        return LinkType.recipeWebsite;
      }
    }

    return LinkType.general;
  }

  /// Main method to extract recipe from any URL
  Future<Map<String, dynamic>> extractRecipeFromUrl(String url) async {
    print('Starting recipe extraction from URL: $url');
    
    final linkType = detectLinkType(url);
    print('Detected link type: $linkType');

    try {
      switch (linkType) {
        case LinkType.youtube:
          return await _extractFromYouTube(url);
        case LinkType.tiktok:
          return await _extractFromTikTok(url);
        case LinkType.instagram:
          return await _extractFromInstagram(url);
        case LinkType.recipeWebsite:
          return await _extractFromRecipeWebsite(url);
        case LinkType.general:
          return await _extractFromGeneralUrl(url);
      }
    } catch (e) {
      print('Recipe extraction failed: $e');
      rethrow;
    }
  }

  /// Extract recipe from YouTube video using multiple methods
  Future<Map<String, dynamic>> _extractFromYouTube(String url) async {
    print('Extracting from YouTube: $url');
    try {
      final yt = YoutubeExplode();
      
      // Get video ID from URL
      final videoId = VideoId.parseVideoId(url);
      if (videoId == null) {
        throw Exception('Invalid YouTube URL - could not parse video ID');
      }
      
      print('YouTube video ID: $videoId');

      // Get video info
      final video = await yt.videos.get(videoId);
      
      // Method 1: Try to get captions
      String transcript = '';
      try {
        final manifest = await yt.videos.closedCaptions.getManifest(videoId);
        if (manifest.tracks.isNotEmpty) {
          // Prefer English captions
          var track = manifest.tracks.firstWhere(
            (t) => t.language.code.startsWith('en'),
            orElse: () => manifest.tracks.first,
          );
          
          final captionTrack = await yt.videos.closedCaptions.get(track);
          final captions = await captionTrack.captions.toList();
          transcript = captions.map((c) => c.text).join(' ');
          print('Extracted ${captions.length} caption segments');
        }
      } catch (e) {
        print('No captions available: $e');
      }

      yt.close();

      // Method 2: Try RapidAPI Video Transcript Scraper
      final apiData = await _fetchVideoDataViaAPI(url);
      String apiTranscript = '';
      String videoMetadata = '';
      
      if (apiData.isNotEmpty && apiData['video_info'] != null) {
        final videoInfo = apiData['video_info'] as Map<String, dynamic>;
        
        // Extract metadata
        final buffer = StringBuffer();
        if (videoInfo['channel'] != null) buffer.writeln('Channel: ${videoInfo['channel']}');
        if (videoInfo['duration'] != null) buffer.writeln('Duration: ${videoInfo['duration']} seconds');
        if (videoInfo['views'] != null) buffer.writeln('Views: ${videoInfo['views']}');
        if (videoInfo['published_date'] != null) buffer.writeln('Published: ${videoInfo['published_date']}');
        if (videoInfo['keywords'] != null && videoInfo['keywords'] is List) {
          buffer.writeln('Keywords: ${(videoInfo['keywords'] as List).join(', ')}');
        }
        if (videoInfo['category'] != null) buffer.writeln('Category: ${videoInfo['category']}');
        
        videoMetadata = buffer.toString();
        
        // Extract transcript
        if (apiData['transcript'] != null) {
          apiTranscript = _extractTranscriptText(apiData['transcript'] as List?);
          print('Extracted API transcript: ${apiTranscript.length} characters');
        }
      }
      
      // No need for frame analysis - the transcript has everything!

      // Combine all extracted data
      // Prefer API transcript over basic captions if available
      final bestTranscript = apiTranscript.isNotEmpty ? apiTranscript : transcript;
      
      final combinedInfo = '''
TITLE: ${video.title}

DESCRIPTION:
${video.description}

DURATION: ${video.duration}

${bestTranscript.isNotEmpty ? 'FULL TRANSCRIPT:\n$bestTranscript\n\n' : ''}

${videoMetadata.isNotEmpty ? 'VIDEO METADATA:\n$videoMetadata\n\n' : ''}
''';

      print('Total content length: ${combinedInfo.length} characters');
      print('Has transcript: ${bestTranscript.isNotEmpty}');
      print('Has video metadata: ${videoMetadata.isNotEmpty}');

      // Check if we have enough content
      if (combinedInfo.length < 200) {
        throw Exception(
          'Insufficient content to extract recipe. '
          'This video shows the recipe visually without providing text details. '
          'Try:\n'
          '• Looking for the recipe in the video description or pinned comment\n'
          '• Checking if the creator has a linked blog/website\n'
          '• Manually watching and transcribing the recipe'
        );
      }

      return await _extractRecipeWithAI(
        combinedInfo,
        'This is content from a YouTube cooking video with a FULL TRANSCRIPT of everything spoken. '
        'CRITICAL: Extract EVERY ingredient mentioned in the transcript with EXACT measurements. '
        'CRITICAL: Extract EVERY cooking step with specific details (temperatures, times, pan sizes, etc.). '
        'The transcript contains precise measurements like "1/4 cup", "2/3 cup", "180°C", "30-35 minutes" - extract ALL of these EXACTLY. '
        'Do NOT generalize (e.g., "butter" is wrong if transcript says "1/4 cup melted butter"). '
        'Do NOT omit steps or ingredients. Extract the COMPLETE recipe with ALL details from the transcript.',
      );
    } catch (e) {
      if (e.toString().contains('Insufficient content')) {
        rethrow;
      }
      throw Exception('Failed to extract recipe from YouTube: $e');
    }
  }

  /// Extract recipe from Instagram post/reel
  Future<Map<String, dynamic>> _extractFromInstagram(String url) async {
    print('Extracting from Instagram: $url');
    try {
      String content = '';
      String transcript = '';
      
      // Method 1: Try RapidAPI Video Transcript Scraper
      final apiData = await _fetchVideoDataViaAPI(url);
      if (apiData.isNotEmpty) {
        print('Successfully got Instagram data from API');
        
        // Extract video info
        if (apiData['video_info'] != null) {
          final videoInfo = apiData['video_info'] as Map<String, dynamic>;
          if (videoInfo['title'] != null) content += 'Title: ${videoInfo['title']}\n';
          if (videoInfo['description'] != null) content += 'Caption: ${videoInfo['description']}\n';
          if (videoInfo['duration'] != null) content += 'Duration: ${videoInfo['duration']} seconds\n';
        }
        
        // Extract transcript if available
        if (apiData['transcript'] != null) {
          transcript = _extractTranscriptText(apiData['transcript'] as List?);
          print('Extracted transcript: ${transcript.length} characters');
        }
      }
      
      // Method 2: Fallback to basic scraping
      if (content.isEmpty) {
        print('Falling back to basic scraping...');
        final response = await http.get(
          Uri.parse(url),
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          },
        );

        if (response.statusCode == 200) {
          final document = html_parser.parse(response.body);

          // Try meta tags
          final ogDesc = document.querySelector('meta[property="og:description"]');
          if (ogDesc != null && ogDesc.attributes['content'] != null) {
            content += ogDesc.attributes['content']!;
          }

          final metaDesc = document.querySelector('meta[name="description"]');
          if (metaDesc != null && metaDesc.attributes['content'] != null) {
            content += '\n${metaDesc.attributes['content']}';
          }
        }
      }

      // Combine all content - transcript has everything we need!
      final fullContent = '''
$content

${transcript.isNotEmpty ? 'FULL TRANSCRIPT:\n$transcript\n\n' : ''}
''';

      if (fullContent.trim().isEmpty || fullContent.length < 30) {
        throw Exception(
          'Could not extract content from Instagram post. '
          'Instagram heavily restricts access and recipes are often shown visually. '
          'Try:\n'
          '• Copying the recipe from the caption manually\n'
          '• Checking for a "link in bio" to the full recipe\n'
          '• Looking in comments for detailed instructions'
        );
      }

      print('Instagram content length: ${fullContent.length} characters');
      print('Has transcript: ${transcript.isNotEmpty}');

      return await _extractRecipeWithAI(
        fullContent,
        'This is content from an Instagram post/reel including the full transcript. '
        'CRITICAL: Extract EVERY ingredient with EXACT measurements from the transcript. '
        'CRITICAL: Extract EVERY cooking step with specific details (temperatures, times, etc.). '
        'Use EXACT measurements from the transcript - do not generalize. '
        'Extract the COMPLETE recipe with ALL details.',
      );
    } catch (e) {
      if (e.toString().contains('Could not extract content')) {
        rethrow;
      }
      throw Exception('Failed to extract recipe from Instagram: $e');
    }
  }

  /// Extract recipe from TikTok video
  Future<Map<String, dynamic>> _extractFromTikTok(String url) async {
    print('Extracting from TikTok: $url');
    try {
      String content = '';
      String transcript = '';
      
      // Method 1: Try RapidAPI Video Transcript Scraper
      final apiData = await _fetchVideoDataViaAPI(url);
      if (apiData.isNotEmpty) {
        print('Successfully got TikTok data from API');
        
        // Extract video info
        if (apiData['video_info'] != null) {
          final videoInfo = apiData['video_info'] as Map<String, dynamic>;
          if (videoInfo['title'] != null) content += 'Title: ${videoInfo['title']}\n';
          if (videoInfo['description'] != null) content += 'Description: ${videoInfo['description']}\n';
          if (videoInfo['duration'] != null) content += 'Duration: ${videoInfo['duration']} seconds\n';
          if (videoInfo['views'] != null) content += 'Views: ${videoInfo['views']}\n';
        }
        
        // Extract transcript
        if (apiData['transcript'] != null) {
          transcript = _extractTranscriptText(apiData['transcript'] as List?);
          print('Extracted transcript: ${transcript.length} characters');
        }
      }
      
      // Method 2: Fallback to basic scraping
      if (content.isEmpty) {
        print('Falling back to basic scraping...');
        final response = await http.get(
          Uri.parse(url),
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          },
        );

        if (response.statusCode == 200) {
          final document = html_parser.parse(response.body);
          
          // Try to extract JSON-LD data
          final scripts = document.querySelectorAll('script[type="application/ld+json"]');
          for (final script in scripts) {
            try {
              final jsonData = jsonDecode(script.text);
              if (jsonData is Map) {
                if (jsonData['name'] != null) content += 'Title: ${jsonData['name']}\n';
                if (jsonData['description'] != null) content += 'Description: ${jsonData['description']}\n';
              }
            } catch (e) {
              // Continue
            }
          }

          // Try meta tags
          final metaDesc = document.querySelector('meta[name="description"]');
          if (metaDesc != null && metaDesc.attributes['content'] != null) {
            content += 'Content: ${metaDesc.attributes['content']}\n';
          }

          final ogDesc = document.querySelector('meta[property="og:description"]');
          if (ogDesc != null && ogDesc.attributes['content'] != null) {
            content += 'Details: ${ogDesc.attributes['content']}\n';
          }
        }
      }

      // Combine content with transcript
      final combinedContent = '''
$content

${transcript.isNotEmpty ? 'TRANSCRIPT/CAPTIONS:\n$transcript' : ''}
''';

      if (combinedContent.trim().isEmpty) {
        throw Exception(
          'Could not extract content from TikTok video. '
          'TikTok blocks automated access and recipes are shown visually. '
          'Try:\n'
          '• Copying the recipe from the caption or comments manually\n'
          '• Checking the creator\'s Instagram or website\n'
          '• Watching and transcribing the recipe yourself'
        );
      }

      print('TikTok content length: ${combinedContent.length} characters');
      print('Has transcript: ${transcript.isNotEmpty}');

      return await _extractRecipeWithAI(
        combinedContent,
        'This is content from a TikTok recipe video including full transcript/captions. '
        'CRITICAL: Extract EVERY ingredient with EXACT measurements from the transcript. '
        'CRITICAL: Extract EVERY cooking step with specific details. '
        'Use the EXACT wording for measurements and temperatures from the transcript. '
        'Do NOT generalize or omit details - extract the COMPLETE recipe.',
      );
    } catch (e) {
      if (e.toString().contains('Could not extract content')) {
        rethrow;
      }
      throw Exception('Failed to extract recipe from TikTok: $e');
    }
  }

  /// Extract recipe from recipe websites
  Future<Map<String, dynamic>> _extractFromRecipeWebsite(String url) async {
    print('Extracting from recipe website: $url');
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        },
      );

      print('Recipe website response status: ${response.statusCode}');
      
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch recipe website (status: ${response.statusCode})');
      }

      final document = html_parser.parse(response.body);
      
      // Try to find Recipe Schema (JSON-LD)
      print('Attempting to extract recipe schema...');
      final recipeSchema = _extractRecipeSchema(document);
      if (recipeSchema != null) {
        print('Recipe schema found and extracted successfully');
        return recipeSchema;
      }

      print('No recipe schema found, falling back to AI extraction');
      // Fallback: Extract text content and use AI
      String content = _extractRecipeContent(document);
      print('Extracted content length: ${content.length} characters');
      
      return await _extractRecipeWithAI(
        content,
        'This is content from a recipe website. Extract the recipe information including title, ingredients, instructions, cooking time, etc.',
      );
    } catch (e) {
      throw Exception('Failed to extract recipe from website: $e');
    }
  }

  /// Extract recipe from general URLs
  Future<Map<String, dynamic>> _extractFromGeneralUrl(String url) async {
    print('Extracting from general URL: $url');
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        },
      );

      print('General URL response status: ${response.statusCode}');
      
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch URL (status: ${response.statusCode})');
      }

      final document = html_parser.parse(response.body);
      
      // Check for recipe schema first
      final recipeSchema = _extractRecipeSchema(document);
      if (recipeSchema != null) {
        return recipeSchema;
      }

      // Extract all text content
      String content = document.body?.text ?? '';
      
      // Clean up excessive whitespace
      content = content.replaceAll(RegExp(r'\s+'), ' ').trim();
      
      // Check if we have enough content
      if (content.length < 100) {
        throw Exception(
          'Insufficient content extracted from URL. '
          'The page may be dynamically loaded with JavaScript, protected, or contain mostly visual content. '
          'If this is a social media post (Instagram, Facebook, etc.), try:\n'
          '• Copying the recipe text manually from the post\n'
          '• Looking for a link to the creator\'s blog/website with the full recipe'
        );
      }

      // Limit content length for API
      if (content.length > 10000) {
        content = content.substring(0, 10000);
      }

      print('Extracted content length: ${content.length} characters');

      return await _extractRecipeWithAI(
        content,
        'This is content from a webpage. Try to extract recipe information if it contains a recipe. '
        'Extract any ingredients, measurements, and cooking instructions found. '
        'If no clear recipe is found, return an error.',
      );
    } catch (e) {
      if (e.toString().contains('Insufficient content')) {
        rethrow;
      }
      throw Exception('Failed to extract content from URL: $e');
    }
  }

  /// Extract recipe schema (JSON-LD) from HTML document
  Map<String, dynamic>? _extractRecipeSchema(Document document) {
    try {
      final scripts = document.querySelectorAll('script[type="application/ld+json"]');
      
      for (final script in scripts) {
        try {
          final jsonData = jsonDecode(script.text);
          
          // Handle both single objects and arrays
          List<dynamic> items = [];
          if (jsonData is List) {
            items = jsonData;
          } else if (jsonData is Map) {
            items = [jsonData];
          }

          // Look for Recipe schema
          for (final item in items) {
            if (item is Map && 
                (item['@type'] == 'Recipe' || 
                 (item['@type'] is List && (item['@type'] as List).contains('Recipe')))) {
              return _parseRecipeSchema(Map<String, dynamic>.from(item));
            }
          }
        } catch (e) {
          // Continue to next script
          continue;
        }
      }
    } catch (e) {
      print('Error extracting recipe schema: $e');
    }
    return null;
  }

  /// Parse Recipe schema into our format
  Map<String, dynamic> _parseRecipeSchema(Map<String, dynamic> schema) {
    // Extract ingredients
    List<Map<String, dynamic>> ingredients = [];
    final recipeIngredients = schema['recipeIngredient'] ?? [];
    for (var ing in recipeIngredients) {
      if (ing is String) {
        // Parse ingredient string (e.g., "2 cups flour")
        final parts = ing.trim().split(RegExp(r'\s+'));
        if (parts.length >= 2) {
          ingredients.add({
            'name': parts.skip(2).join(' '),
            'quantity': parts[0],
            'unit': parts.length > 2 ? parts[1] : '',
          });
        } else {
          ingredients.add({
            'name': ing,
            'quantity': '',
            'unit': '',
          });
        }
      }
    }

    // Extract instructions
    List<Map<String, dynamic>> instructions = [];
    final recipeInstructions = schema['recipeInstructions'] ?? [];
    int stepNum = 1;
    
    for (var inst in recipeInstructions) {
      if (inst is String) {
        instructions.add({
          'step_number': stepNum++,
          'instruction': inst,
        });
      } else if (inst is Map) {
        String text = inst['text'] ?? inst['description'] ?? '';
        if (text.isNotEmpty) {
          instructions.add({
            'step_number': stepNum++,
            'instruction': text,
          });
        }
      }
    }

    // Parse duration strings (e.g., "PT30M" = 30 minutes)
    int parseDuration(String? duration) {
      if (duration == null) return 0;
      final match = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?').firstMatch(duration);
      if (match != null) {
        final hours = int.tryParse(match.group(1) ?? '0') ?? 0;
        final minutes = int.tryParse(match.group(2) ?? '0') ?? 0;
        return hours * 60 + minutes;
      }
      return 0;
    }

    final prepTime = parseDuration(schema['prepTime'] as String?);
    final cookTime = parseDuration(schema['cookTime'] as String?);
    final totalTime = parseDuration(schema['totalTime'] as String?);

    return {
      'title': schema['name'] ?? 'Untitled Recipe',
      'description': schema['description'] ?? '',
      'ingredients': ingredients,
      'instructions': instructions,
      'prep_time': prepTime,
      'cook_time': cookTime,
      'total_time': totalTime > 0 ? totalTime : (prepTime + cookTime),
      'servings': _parseServings(schema['recipeYield']),
      'difficulty_level': 'medium',
      'meal_type': 'dinner',
      'cuisine_type': schema['recipeCuisine'] ?? '',
      'tags': (schema['recipeCategory'] is List) 
          ? (schema['recipeCategory'] as List).map((e) => e.toString()).toList() 
          : [],
    };
  }

  /// Parse servings from various formats
  int _parseServings(dynamic yield_) {
    if (yield_ == null) return 4;
    if (yield_ is int) return yield_;
    if (yield_ is String) {
      final match = RegExp(r'(\d+)').firstMatch(yield_);
      if (match != null) {
        return int.tryParse(match.group(1)!) ?? 4;
      }
    }
    return 4;
  }

  /// Fetch video data via RapidAPI Video Transcript Scraper (works for all platforms)
  Future<Map<String, dynamic>> _fetchVideoDataViaAPI(String url) async {
    if (_rapidApiKey.isEmpty) {
      print('⚠️ RapidAPI key not configured, skipping API extraction');
      print('   Add RAPIDAPI_KEY to your .env file to enable video transcript extraction');
      return {};
    }

    try {
      print('🎬 Fetching video data via RapidAPI Video Transcript Scraper...');
      print('   URL: $url');
      print('   API Key: ${_rapidApiKey.substring(0, 10)}...${_rapidApiKey.substring(_rapidApiKey.length - 4)}');
      
      final requestBody = {
        'video_url': url,
        // Optional: specify language if needed (e.g., 'en', 'es', 'fr')
        // 'language': 'en',
      };
      
      print('   Request body: ${jsonEncode(requestBody)}');
      
      final response = await http.post(
        Uri.parse('https://video-transcript-scraper.p.rapidapi.com/transcript'),
        headers: {
          'Content-Type': 'application/json',
          'x-rapidapi-key': _rapidApiKey,
          'x-rapidapi-host': 'video-transcript-scraper.p.rapidapi.com',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));

      print('📡 API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ API call successful');
        final data = jsonDecode(response.body);
        print('   Response preview: ${jsonEncode(data).substring(0, 200)}...');
        
        if (data['status'] == 'success' && data['data'] != null) {
          print('✅ Successfully fetched video data from API');
          
          // Log what we got
          final videoInfo = data['data']['video_info'];
          final transcript = data['data']['transcript'];
          
          if (videoInfo != null) {
            print('   Video title: ${videoInfo['title']}');
            print('   Duration: ${videoInfo['duration']} seconds');
          }
          
          if (transcript != null && transcript is List) {
            print('   Transcript segments: ${transcript.length}');
            final totalText = _extractTranscriptText(transcript);
            print('   Transcript length: ${totalText.length} characters');
          }
          
          return data['data'] as Map<String, dynamic>;
        } else {
          print('❌ API returned unsuccessful status: ${data['status']}');
          print('   Full response: ${response.body}');
          return {};
        }
      }
      
      print('❌ API returned error status: ${response.statusCode}');
      print('   Error response body: ${response.body}');
      
      // Common error codes
      if (response.statusCode == 401) {
        print('   ⚠️ Error 401: Invalid API key or not subscribed to the API');
      } else if (response.statusCode == 403) {
        print('   ⚠️ Error 403: Access forbidden - check API subscription');
      } else if (response.statusCode == 404) {
        print('   ⚠️ Error 404: Endpoint not found - verify API URL');
      } else if (response.statusCode == 429) {
        print('   ⚠️ Error 429: Rate limit exceeded - upgrade plan or wait');
      }
      
      return {};
    } catch (e, stackTrace) {
      print('❌ Video API extraction failed with exception: $e');
      print('   Stack trace: $stackTrace');
      return {};
    }
  }

  /// Extract transcript text from API response
  String _extractTranscriptText(List<dynamic>? transcript) {
    if (transcript == null || transcript.isEmpty) return '';
    
    final buffer = StringBuffer();
    for (final segment in transcript) {
      if (segment is Map && segment['text'] != null) {
        buffer.write(segment['text']);
        buffer.write(' ');
      }
    }
    return buffer.toString().trim();
  }

  // Vision API removed - we have full transcripts from Video Transcript Scraper!
  // No need to analyze images when we have the exact spoken words.


  /// Extract recipe-relevant content from HTML document
  String _extractRecipeContent(Document document) {
    StringBuffer content = StringBuffer();

    // Extract title
    final title = document.querySelector('h1')?.text ?? 
                  document.querySelector('title')?.text ?? '';
    if (title.isNotEmpty) {
      content.writeln('Title: $title');
    }

    // Look for common recipe sections
    final selectors = [
      '.recipe',
      '.recipe-content',
      '.recipe-card',
      '[class*="recipe"]',
      '[class*="ingredient"]',
      '[class*="instruction"]',
      '[class*="direction"]',
      'article',
    ];

    for (final selector in selectors) {
      final elements = document.querySelectorAll(selector);
      for (final element in elements) {
        final text = element.text.trim();
        if (text.isNotEmpty && text.length > 20) {
          content.writeln(text);
        }
      }
    }

    String result = content.toString();
    
    // Clean up and limit length
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (result.length > 8000) {
      result = result.substring(0, 8000);
    }

    return result;
  }

  /// Use AI to extract and structure recipe information
  Future<Map<String, dynamic>> _extractRecipeWithAI(
    String content,
    String context,
  ) async {
    print('Using AI to extract recipe...');
    print('Content preview (first 200 chars): ${content.substring(0, content.length < 200 ? content.length : 200)}');
    
    final prompt = '''
$context

Content:
$content

Extract and format this as a structured recipe JSON with the following format:
{
  "title": "Recipe Title",
  "description": "Brief description",
  "ingredients": [
    {"name": "ingredient name", "quantity": "amount", "unit": "unit"}
  ],
  "instructions": [
    {"step_number": 1, "instruction": "step text"}
  ],
  "prep_time": 0,
  "cook_time": 0,
  "total_time": 0,
  "servings": 4,
  "difficulty_level": "easy|medium|hard",
  "meal_type": "breakfast|lunch|dinner|snack|dessert",
  "cuisine_type": "cuisine type if mentioned",
  "tags": ["tag1", "tag2"]
}

Return ONLY the JSON object, no markdown formatting or explanations.
If no recipe is found or the content is insufficient, return: {"error": "No recipe found in content"}
''';

    try {
      print('Calling OpenAI API for recipe extraction...');
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
              'content': 'You are a precise recipe extraction assistant. Your job is to extract COMPLETE recipes with EXACT details. '
                        'CRITICAL RULES:\n'
                        '1. Extract EVERY ingredient with EXACT measurements from the source\n'
                        '2. Extract EVERY instruction step with ALL specific details (temperatures, times, pan sizes, techniques)\n'
                        '3. Do NOT generalize or summarize - use EXACT quantities and wording from the source\n'
                        '4. Do NOT skip ingredients or steps\n'
                        '5. If source says "1/4 cup melted butter", write exactly that, not just "butter"\n'
                        '6. If source says "bake at 180°C for 30-35 minutes", include those exact details\n'
                        'Return ONLY valid JSON, no markdown formatting or explanations.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.1,  // Lower temperature for more precise extraction
          'max_tokens': 3000,  // Increased for detailed recipes
        }),
      );

      print('OpenAI API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = data['choices'] as List;
        if (choices.isNotEmpty) {
          final message = choices[0]['message'] as Map<String, dynamic>;
          final content = message['content'] as String;
          
          print('OpenAI response preview: ${content.substring(0, content.length < 100 ? content.length : 100)}');
          
          // Try to extract JSON from response
          final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
          if (jsonMatch != null) {
            final jsonString = jsonMatch.group(0)!;
            final recipeJson = jsonDecode(jsonString) as Map<String, dynamic>;
            
            // Check for error
            if (recipeJson.containsKey('error')) {
              throw Exception(
                'No recipe found in content. '
                'The content may not contain a complete recipe or the recipe information is presented visually (in video/images). '
                'Try:\n'
                '• Looking for a written version of the recipe in the description or comments\n'
                '• Checking the creator\'s website or blog for the full recipe\n'
                '• Manually copying the recipe text if visible'
              );
            }
            
            print('Successfully extracted recipe: ${recipeJson['title']}');
            return recipeJson;
          }
          
          throw Exception('Could not parse AI response as JSON. Response: ${content.substring(0, content.length < 200 ? content.length : 200)}');
        }
      }

      throw Exception('Failed to extract recipe with AI (status: ${response.statusCode})');
    } catch (e) {
      if (e.toString().contains('No recipe found in content')) {
        rethrow;
      }
      throw Exception('Error calling AI API: $e');
    }
  }
}

