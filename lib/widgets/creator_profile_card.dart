import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import '../models/user_model.dart';
import '../screens/my_profile_detail_screen.dart';

/// A card widget that displays the creator's profile information
/// and allows navigation to their profile screen
class CreatorProfileCard extends StatefulWidget {
  final UserModel? creator;
  final String? userId;
  final String? username;
  final bool showBorder;

  const CreatorProfileCard({
    super.key,
    this.creator,
    this.userId,
    this.username,
    this.showBorder = true,
  }) : assert(
          creator != null || userId != null,
          'Either creator or userId must be provided',
        );

  @override
  State<CreatorProfileCard> createState() => _CreatorProfileCardState();
}

class _CreatorProfileCardState extends State<CreatorProfileCard> {
  Color? _backgroundColor;
  bool _isLoadingColor = true;

  @override
  void initState() {
    super.initState();
    _loadBackgroundColor();
  }

  Future<void> _loadBackgroundColor() async {
    final profilePictureUrl = widget.creator?.profilePictureUrl;
    
    if (profilePictureUrl == null) {
      if (mounted) {
        setState(() {
          _backgroundColor = Theme.of(context).primaryColor.withOpacity(0.1);
          _isLoadingColor = false;
        });
      }
      return;
    }

    try {
      final imageProvider = NetworkImage(profilePictureUrl);
      final paletteGenerator = await PaletteGenerator.fromImageProvider(imageProvider);
      final dominantColor = paletteGenerator.dominantColor?.color;
      
      if (mounted) {
        setState(() {
          _backgroundColor = dominantColor != null
              ? dominantColor.withOpacity(0.15) // Light tint for readability
              : Theme.of(context).primaryColor.withOpacity(0.1);
          _isLoadingColor = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _backgroundColor = Theme.of(context).primaryColor.withOpacity(0.1);
          _isLoadingColor = false;
        });
      }
    }
  }

  void _navigateToProfile(BuildContext context) {
    final targetUserId = widget.creator?.id ?? widget.userId;
    if (targetUserId == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MyProfileDetailScreen(userId: targetUserId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.creator?.displayName ?? widget.creator?.username ?? widget.username ?? 'Unknown';
    final usernameText = widget.creator != null 
        ? '@${widget.creator!.username}' 
        : widget.username != null 
            ? '@${widget.username}' 
            : null;
    final profilePictureUrl = widget.creator?.profilePictureUrl;
    final chefScore = widget.creator?.chefScore ?? 0.0;

    // Use loading color or calculated color, fallback to theme color
    final cardColor = _isLoadingColor 
        ? Theme.of(context).primaryColor.withOpacity(0.1)
        : (_backgroundColor ?? Theme.of(context).primaryColor.withOpacity(0.1));

    return InkWell(
      onTap: () => _navigateToProfile(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: widget.showBorder
              ? Border.all(
                  color: Colors.grey[200]!,
                  width: 1,
                )
              : null,
        ),
        child: Row(
          children: [
            // Profile Picture
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey[300],
              backgroundImage: profilePictureUrl != null
                  ? NetworkImage(profilePictureUrl)
                  : null,
              child: profilePictureUrl == null
                  ? Text(
                      displayName.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (usernameText != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      usernameText,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (chefScore > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 14,
                          color: Colors.amber[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Chef Score: ${chefScore.toStringAsFixed(1)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.amber[700],
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Arrow Icon
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}

