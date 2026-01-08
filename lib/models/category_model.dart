class Category {
  final String id;
  final String name;
  final String iconKey;

  Category({
    required this.id,
    required this.name,
    required this.iconKey,
  });

  //Converts Firebase Data -> Dart Object
  factory Category.fromSnapshot(String id, Map<String, dynamic> data) {
    return Category(
      id: id,
      name: data['name'] ?? 'Unknown',
      iconKey: data['icon_key'] ?? 'default',
    );
  }

  //HELPER: The "Translator" (Text -> Emoji String)
  String getEmoji() {
    switch (iconKey) {
      case 'cow':
        return '🐄';
      case 'pig':
        return '🐖';
      case 'goat':
        return '🐐';
      case 'chicken':
        return '🐓';
      case 'duck':
        return '🦆';
      case 'carabao':
        return '🐃';
      case 'other':
        return '📦';
      case 'all':
        return '🏠';
      default:
        return '🐾';
    }
  }
}
