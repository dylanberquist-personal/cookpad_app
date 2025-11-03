import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _authService = AuthService();
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
              children: _dietaryOptions.map((option) {
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
      // Navigation handled by AuthWrapper
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }
}
