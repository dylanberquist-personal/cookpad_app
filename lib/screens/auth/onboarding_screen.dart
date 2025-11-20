import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/preferences_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _authService = AuthService();
  final _preferencesService = PreferencesService();
  String? _selectedSkillLevel;
  final List<String> _dietaryRestrictions = [];
  final List<String> _cuisinePreferences = [];

  final List<String> _skillLevels = ['beginner', 'intermediate', 'advanced'];
  final List<String> _dietaryOptions = [
    'vegetarian',
    'vegan',
    'gluten-free',
    'dairy-free',
    'nut-free',
    'keto',
    'paleo',
    'pescatarian',
    'carnivore',
  ];
  final List<String> _cuisineOptions = [
    'Italian',
    'Asian',
    'Mexican',
    'American',
    'Mediterranean',
    'Indian',
    'French',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tell us about yourself',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'This helps us personalize your experience',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            const Text(
              'Cooking Skill Level',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _skillLevels.map((level) {
                final isSelected = _selectedSkillLevel == level;
                return FilterChip(
                  label: Text(level.toUpperCase()),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedSkillLevel = selected ? level : null;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            const Text(
              'Dietary Restrictions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ..._dietaryOptions.map((option) {
                  final isSelected = _dietaryRestrictions.contains(option);
                  return FilterChip(
                    label: Text(option),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _dietaryRestrictions.add(option);
                        } else {
                          _dietaryRestrictions.remove(option);
                        }
                      });
                    },
                  );
                }).toList(),
                // Custom dietary restrictions
                ..._dietaryRestrictions
                    .where((r) => !_dietaryOptions.contains(r))
                    .map((restriction) {
                  return FilterChip(
                    label: Text(restriction),
                    selected: true,
                    onSelected: (selected) {
                      setState(() {
                        _dietaryRestrictions.remove(restriction);
                      });
                    },
                  );
                }).toList(),
                // Add custom option button
                ActionChip(
                  label: const Text('+'),
                  onPressed: _showAddCustomDietaryDialog,
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'Cuisine Preferences (Optional)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _cuisineOptions.map((cuisine) {
                final isSelected = _cuisinePreferences.contains(cuisine);
                return FilterChip(
                  label: Text(cuisine),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _cuisinePreferences.add(cuisine);
                      } else {
                        _cuisinePreferences.remove(cuisine);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedSkillLevel == null ? null : _completeOnboarding,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _completeOnboarding() async {
    try {
      await _authService.updateUserProfile(
        skillLevel: _selectedSkillLevel!,
        dietaryRestrictions: _dietaryRestrictions,
        cuisinePreferences: _cuisinePreferences.isNotEmpty ? _cuisinePreferences : null,
      );
      
      // Reset dietary hint if user has dietary restrictions
      if (_dietaryRestrictions.isNotEmpty) {
        await _preferencesService.resetDietaryHint();
      }
      
      // Navigation handled by AuthWrapper
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _showAddCustomDietaryDialog() async {
    final TextEditingController controller = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Custom'),
        content: TextField(
          controller: controller,
          maxLength: 25,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter dietary restriction',
            border: OutlineInputBorder(),
            counterText: '',
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) {
                Navigator.pop(context, value);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        if (!_dietaryRestrictions.contains(result)) {
          _dietaryRestrictions.add(result);
        }
      });
    }
  }
}
