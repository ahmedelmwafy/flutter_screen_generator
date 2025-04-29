import 'dart:io';
import 'package:path/path.dart' as path;
import 'captilize.dart'; // Assuming these imports are other helper files
import 'get_package_name.dart';
import 'generate_screens.dart';
import 'add_dio_init.dart'; // Assuming this exists and works
import 'enchure_dio_dep.dart'; // Assuming this exists and works
import 'create_dio_file.dart'; // Assuming this exists and works
import 'create_cach_file.dart'; // Assuming this exists and works
import 'add_initialization_to_main.dart'; // Assuming this exists and works
// Define these globally as they are used by the helper functions
String? projectRoot;
String? packageName;


void main(List<String> args) async {
  if (args.isEmpty) {
    print('❌ Please provide at least one screen name as an argument.');
    print('Example: dart run bin/flutter_screen_generator.dart home settings profile');
    exit(1); // Exit with an error code
  }

  // Find project root and package name once at the start
   projectRoot = await findProjectRoot();
   if (projectRoot == null) {
     print(
         '❌ Could not find project root. Make sure you are inside a Flutter/Dart project directory with a pubspec.yaml.');
     exit(1); // Exit if project root not found
   }

   packageName = await getPackageName(projectRoot!);
   if (packageName == null) {
     print(
         '❌ Could not find package name in pubspec.yaml at ${path.join(projectRoot!, 'pubspec.yaml')}.');
      exit(1); // Exit if package name not found
   }

   print('✅ Project root found at: $projectRoot');
   print('✅ Package name: $packageName');


  final generator = ScreenGenerator();
  await generator.run(args);
}


// --- Helper functions (Ensure these are defined in separate files or within this script) ---

// You need to ensure findProjectRoot, getPackageName,
// generateScreens, ensureDioDependencies, createDioHelperFile,
// addDioInitToMain, and createCachedHelperFile are defined and
// accessible by the main function or the ScreenGenerator class.
// Based on your imports, they are likely in other files.
// For demonstration, I'll include a basic findProjectRoot and getPackageName
// and assume the others exist as implied by your imports.


// --- New function to add CachedHelper.init() to main.dart ---



class ScreenGenerator {

  Future<void> run(List<String> screenNames) async {

    // --- New DioHelper Setup Steps ---
    // These run once before screen generation
    await _setupDioHelper();
    // ---------------------------------

    // Generate screens and potentially add methods
    await generateScreens(screenNames); // Ensure generateScreens exists

    print('\n--- Setup Complete ---');
    print(
        'Remember to run `flutter pub get` (or `dart pub get`) to fetch new dependencies.');
    print(
        'Update the `baseUrl` in `lib/helpers/dio.dart` (if not done yet).');
  }

  Future<void> _setupDioHelper() async {
    print('\n--- Setting up Helpers ---');
    // Ensure dio and shared_preferences dependencies are added
    await ensureDioDependencies(); // Ensure this exists and adds dio and shared_preferences

    // Create the helper files if they don't exist
    await createCachedHelperFile(); // Ensure this exists
    await createDioHelperFile(); // Ensure this exists

    // Add init calls to main.dart
    await addDioInitToMain(); // Ensure this exists
    await addInitializationToMain(); // <-- Call the new function here
  }

}

// Ensure other imported helper functions like:
// - captilize
// - generateScreens
// - addDioInitToMain
// - ensureDioDependencies
// - createDioHelperFile
// - createCachedHelperFile
// are defined in separate files and correctly imported, or included in this script.
// The provided code snippet assumes these are available.

// Example minimal implementation for createCachedHelperFile if you don't have it separately:
/*
Future<void> createCachedHelperFile() async {
   if (projectRoot == null) return; // Needs projectRoot to be set

   print('🔍 Checking for CachedHelper file...');
   final cacheHelperDir = path.join(projectRoot!, 'lib', 'helpers');
   final cacheHelperPath = path.join(cacheHelperDir, 'cach.dart');
   final file = File(cacheHelperPath);

   if (await file.exists()) {
     print('✅ CachedHelper file already exists at $cacheHelperPath.');
   } else {
     print('--- Creating CachedHelper file ---');
     final cacheHelperCode = '''
import 'package:shared_preferences/shared_preferences.dart';

class CachedHelper {
  static SharedPreferences? _sharedPreferences;

  static Future<void> init() async {
    _sharedPreferences = await SharedPreferences.getInstance();
  }
  static String getUserToken() {
    return _sharedPreferences?.getString('access_token') ?? '';
  }

  static Future<bool> setProductList(List<String> value) async {
    if (_sharedPreferences == null) return false;
    return await _sharedPreferences!.setStringList('Id', value);
  }

  // Add other methods as needed
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
*/