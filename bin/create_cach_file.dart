import 'dart:io';
import 'package:path/path.dart' as path;

// Assume projectRoot is defined elsewhere, similar to your DioHelper script
// For a standalone script, you might determine it differently.
String? projectRoot; // Define or get your project root path

Future<void> createCachedHelperFile() async {
  print('🔍 Checking for CachedHelper file...');

  // --- Start: Improved Project Root Finding ---
  if (projectRoot == null) {
    String currentDir = Directory.current.path;
    String previousDir = ''; // Keep track of the previous directory

    while (currentDir != previousDir) {
      // Loop until we can't go up any further
      final pubspecPath = path.join(currentDir, 'pubspec.yaml');
      if (await File(pubspecPath).exists()) {
        projectRoot = currentDir;
        break; // Found the project root
      }
      previousDir = currentDir; // Store the current directory
      currentDir = path.dirname(currentDir); // Move up one directory
    }

    if (projectRoot == null) {
      print(
          '❌ Could not determine project root (pubspec.yaml not found by searching upwards). Cannot create file.');
      print(
          'Please ensure you are running this script from within your Flutter project directory or its subdirectories.');
      return;
    }
    print('✅ Project root found at: $projectRoot');
  }
  // --- End: Improved Project Root Finding ---

  final cacheHelperDir = path.join(projectRoot!, 'lib', 'helpers');
  final cacheHelperPath = path.join(cacheHelperDir, 'cach.dart');
  final file = File(cacheHelperPath);

  bool fileExists = await file.exists();

  if (fileExists) {
    print('✅ CachedHelper file already exists at $cacheHelperPath.');
    // We assume if it exists, it contains the necessary class.
    // If you needed to update it, you would add more logic here.
  } else {
    print('--- Creating CachedHelper file ---');
    final cacheHelperCode = '''
import 'package:shared_preferences/shared_preferences.dart';

class CachedHelper {
  static SharedPreferences? _sharedPreferences;

  static Future<void> init() async {
    _sharedPreferences = await SharedPreferences.getInstance();
  }

    static Future<bool> setUserToken(value) async {
    return await _sharedPreferences!.setString('access_token', value);
  }


  static String getUserToken() {
    // Use the null-aware access operator (?.) before !, just in case init wasn't called
    return _sharedPreferences?.getString('access_token') ?? '';
  }
  }

''';

    try {
      await Directory(cacheHelperDir).create(recursive: true);
      await file.writeAsString(cacheHelperCode);
      print('✅ CachedHelper file created at $cacheHelperPath.');
    } catch (e) {
      print('❌ Error creating CachedHelper file: $e');
    }
  }
}

// To run this from a script, you would call:
// createCachedHelperFile();
// Note: You need to ensure 'projectRoot' is correctly set before calling this function,
// or rely on the improved logic added above.
