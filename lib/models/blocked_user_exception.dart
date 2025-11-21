/// Exception thrown when a user tries to interact with content from a user who has blocked them
class BlockedUserException implements Exception {
  final String message;
  final String action; // e.g., "favorite", "rate", "comment"

  BlockedUserException({
    required this.action,
    this.message = 'You cannot interact with this content because the creator has blocked you.',
  });

  @override
  String toString() => message;
}

