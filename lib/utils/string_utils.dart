/// String utility functions for formatting and capitalization.
String toTitleCase(String? input) {
  if (input == null || input.trim().isEmpty) return '';

  final words = input.trim().split(RegExp(r'\s+'));
  return words.map((word) {
    if (word.isEmpty) return '';
    if (word.contains('-')) {
      return word.split('-').map((sub) {
        if (sub.isEmpty) return '';
        return sub[0].toUpperCase() + (sub.length > 1 ? sub.substring(1).toLowerCase() : '');
      }).join('-');
    }
    return word[0].toUpperCase() + (word.length > 1 ? word.substring(1).toLowerCase() : '');
  }).join(' ');
}
