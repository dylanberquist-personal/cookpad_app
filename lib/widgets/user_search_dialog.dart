import 'package:flutter/material.dart';
import '../config/supabase_config.dart';
import '../models/user_model.dart';

class UserSearchDialog extends StatefulWidget {
  final String title;
  final Future<bool> Function(UserModel) onUserSelected;

  const UserSearchDialog({
    super.key,
    required this.title,
    required this.onUserSelected,
  });

  @override
  State<UserSearchDialog> createState() => _UserSearchDialogState();
}

class _UserSearchDialogState extends State<UserSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _searchResults = [];
  bool _isSearching = false;
  String? _errorMessage;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final currentUserId = SupabaseConfig.client.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Search users by username or display name
      final response = await SupabaseConfig.client
          .from('users')
          .select()
          .or('username.ilike.%$query%,display_name.ilike.%$query%')
          .neq('id', currentUserId) // Exclude current user
          .limit(20);

      final users = (response as List)
          .map((json) => UserModel.fromJson(json))
          .toList();

      setState(() {
        _searchResults = users;
        _isSearching = false;
        if (users.isEmpty) {
          _errorMessage = 'No users found';
        }
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _errorMessage = 'Error searching users: ${e.toString()}';
        _searchResults = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600, maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Search field
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by username...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _searchUsers('');
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  _searchUsers(value);
                },
              ),
            ),

            // Results
            Flexible(
              child: _isSearching
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : _searchResults.isEmpty && _searchController.text.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.person_search,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Search for a user',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: _searchResults.length,
                              itemBuilder: (context, index) {
                                final user = _searchResults[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: user.profilePictureUrl != null
                                        ? NetworkImage(user.profilePictureUrl!)
                                        : null,
                                    child: user.profilePictureUrl == null
                                        ? Icon(
                                            Icons.person,
                                            color: Colors.grey[600],
                                          )
                                        : null,
                                  ),
                                  title: Text(
                                    user.username,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: user.displayName != null
                                      ? Text(user.displayName!)
                                      : null,
                                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                  onTap: () async {
                                    // Call the callback and wait for result
                                    final success = await widget.onUserSelected(user);
                                    if (context.mounted) {
                                      Navigator.of(context).pop(success);
                                    }
                                  },
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

