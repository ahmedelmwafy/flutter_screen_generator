import 'dart:io';
import 'package:path/path.dart' as path;
import 'flutter_screen_generator.dart';
// Assume other imports like captilize, get_package_name, etc., exist and are correct
// Assume projectRoot and packageName are defined globally as before

// --- More Robust Function to Add Initialization Lines to main.dart ---

Future<void> addInitializationToMain() async {
  // Renamed for clarity
  if (projectRoot == null || packageName == null) {
    print('❌ Project root or package name not set. Cannot process main.dart.');
    return;
  }

  print('🔍 Checking for main.dart...');
  final mainFilePath = path.join(projectRoot!, 'lib', 'main.dart');
  final mainFile = File(mainFilePath);

  if (!await mainFile.exists()) {
    print('⚠️ lib/main.dart not found at $mainFilePath.');
    print('--- Creating basic main.dart file ---');

    // Basic content for a new main.dart file
    final basicMainContent = '''
import 'package:flutter/material.dart';
import 'package:$packageName/helpers/cach.dart'; // Assuming this path
import 'package:$packageName/helpers/dio.dart'; // Assuming this path


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await CachedHelper.init(); // Initialize SharedPreferences
  DioHelper.init(); // Initialize Dio

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '$packageName App', // Use package name for title
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Home Page'), // Placeholder home page
    );
  }
}

// Basic placeholder Home Page widget
class MyHomePage extends StatelessWidget {
  final String title;
  const MyHomePage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: const Center(
        child: Text('Welcome to your new app!'),
      ),
    );
  }
}
''';

    try {
      // Create the lib directory if it doesn't exist
      final libDir = path.dirname(mainFilePath);
      await Directory(libDir).create(recursive: true);

      // Write the basic content to the new file
      await mainFile.writeAsString(basicMainContent);
      print(
          '✅ Created main.dart with basic structure and initialization calls.');
      return; // File created, no further modification needed in this run
    } catch (e) {
      print('❌ Error creating main.dart file: $e');
      return; // Exit if file creation failed
    }
  }

  // --- If main.dart exists, proceed with the logic to update it ---
  print('✅ main.dart found. Checking content...');

  try {
    String content = await mainFile.readAsString();

    final cachedHelperInitLine = 'await CachedHelper.init();';
    final dioHelperInitLine = 'DioHelper.init();';
    final ensureInitializedLine = 'WidgetsFlutterBinding.ensureInitialized();';

    // --- Step 1: Find the main function signature and body ---
    // This regex attempts to capture the signature and the content within the braces.
    // It's more complex to handle nested braces, but for a typical main function, this should work.
    // It looks for 'main', optional async, optional (), whitespace, then captures everything between { and }
    final mainFunctionRegex = RegExp(
        r'(void\s+)?main\s*(\(.*\))?\s*(async)?\s*{\s*([\s\S]*?)\s*}', // Capture signature, optional async, params, and body content
        multiLine: true);

    final mainMatch = mainFunctionRegex.firstMatch(content);

    if (mainMatch == null) {
      print('❌ Could not find the main() function in main.dart.');
      print(
          'Please manually add the following lines inside your main() function:');
      print('  WidgetsFlutterBinding.ensureInitialized();');
      print('  await CachedHelper.init();');
      print('  DioHelper.init();');
      return;
    }

    String signaturePart = mainMatch.group(0)!.substring(
        0,
        mainMatch.group(0)!.indexOf('{') +
            1); // Part up to and including the opening brace
    String bodyContent =
        mainMatch.group(4)!; // The captured content within the braces

    bool isAsync = mainMatch.group(3) != null; // Check if 'async' was captured

    // Determine the indentation of the main function body
    String bodyIndent = '  '; // Default indentation
    final bodyLines = bodyContent.split('\n');
    for (final line in bodyLines) {
      final trimLine = line.trimLeft();
      if (trimLine.isNotEmpty) {
        final indentMatch = RegExp(r'^(\s*)').firstMatch(line);
        if (indentMatch != null && indentMatch.group(1) != null) {
          bodyIndent = indentMatch.group(1)!;
        }
        break; // Found indentation from the first non-empty line
      }
    }


    // Define the desired order and content of the setup lines
    final requiredSetupLines = [
      ensureInitializedLine,
      cachedHelperInitLine,
      dioHelperInitLine,
    ];

    // Check which lines are missing and build the list of lines to add
    List<String> linesToAddToBody = [];
    for (final requiredLine in requiredSetupLines) {
      if (!bodyContent.contains(requiredLine)) {
        linesToAddToBody.add(requiredLine);
      }
    }

    // --- Step 3: Replace the original body with the new body if changes are needed ---

    // Only proceed if there are lines to add or if main is not async
    if (linesToAddToBody.isNotEmpty || !isAsync) {
      String newBodyContent = '';

      // Add the lines to prepend at the beginning of the body
      for (final line in linesToAddToBody) {
        newBodyContent += bodyIndent + line + '\n';
      }

      // Add the original body content, excluding the lines we just added if they were already present
      final originalBodyLines = bodyContent.split('\n');
      for (final line in originalBodyLines) {
        final trimmedLine = line.trim();
        bool isRequiredSetupLine = requiredSetupLines
            .any((setupLine) => trimmedLine.contains(setupLine.trim()));
        if (trimmedLine.isNotEmpty && !isRequiredSetupLine) {
          newBodyContent +=
              line + '\n'; // Keep original lines with their indentation
        } else if (isRequiredSetupLine &&
            linesToAddToBody.contains(trimmedLine)) {
          // If the line is one of the required setup lines that we just added, skip it
          // This prevents duplication if the required line was the *only* content on its line in the original body
        } else if (isRequiredSetupLine &&
            !linesToAddToBody.contains(trimmedLine)) {
          // If the required line exists and we didn't need to add it (because it was already there), keep the original line
          newBodyContent += line + '\n';
        }
      }

      // Trim trailing newline if present
      if (newBodyContent.endsWith('\n')) {
        newBodyContent = newBodyContent.substring(0, newBodyContent.length - 1);
      }

      // Ensure async is in the signature
      String newSignaturePart = signaturePart;
      if (!isAsync) {
        newSignaturePart = signaturePart.replaceFirst('{', ' async{');
        print('ℹ️ Made main() async in main.dart to accommodate await.');
      }

      // Construct the new full main function block
      // Ensure the closing brace is on its own line with appropriate indentation
      String newMainFunctionBlock =
          '${newSignaturePart}\n${newBodyContent}\n${bodyIndent.replaceFirst('  ', '')}}';

      // Replace the entire original main function block with the new one
      String newContent =
          content.replaceFirst(mainMatch.group(0)!, newMainFunctionBlock);

      await mainFile.writeAsString(newContent);

      bool changed = linesToAddToBody.isNotEmpty ||
          !isAsync; // Check if any changes were actually made

      if (changed) {
        print(
            '✅ main.dart updated with necessary initialization calls and async keyword.');
      } else {
        print('✅ All required initialization lines found and main() is async.');
      }
    } else {
      print(
          '✅ All required initialization lines found in main.dart and main() is async.');
    }
  } catch (e) {
    print('❌ Error processing main.dart: $e');
    print('Please manually verify and update your main() function.');
  }
}

// Ensure other imported helper functions are defined in separate files and correctly imported.
// The provided code snippet assumes these are available.
