import 'dart:io';

import 'package:path/path.dart' as path;

String capitalize(String input) {
  if (input.isEmpty) return input;
  return input[0].toUpperCase() + input.substring(1);
}

/// Searches upwards from the current directory for a pubspec.yaml file
/// to find the project root.
Future<String?> findProjectRoot() async {
  var directory = Directory.current;
  // Added a safety break to prevent infinite loops in case of unusual file systems
  int maxDepth = 10;
  int currentDepth = 0;
  try {
    while (currentDepth < maxDepth) {
      final pubspecPath = path.join(directory.path, 'pubspec.yaml');
      if (await File(pubspecPath).exists()) {
        return directory.path; // Found the project root
      }
      final parent = directory.parent;
      if (parent.path == directory.path) {
        // Reached file system root
        break;
      }
      directory = parent;
      currentDepth++;
    }
  } catch (e) {
    print('Error searching for pubspec.yaml: $e');
    return null;
  }

  return null; // pubspec.yaml not found within the search depth
}
