import 'dart:io';

import 'package:path/path.dart' as path;

import 'flutter_screen_generator.dart';
Future<void> addDioInitToMain() async {
    print('🔍 Checking for DioHelper.init() in lib/main.dart...');
    final mainFilePath = path.join(projectRoot!, 'lib', 'main.dart');
    final file = File(mainFilePath);

    if (!await file.exists()) {
      print(
          '❌ lib/main.dart not found at $mainFilePath. Cannot add DioHelper.init().');
      return;
    }

    try {
      var content = await file.readAsLines();
      bool modified = false; // Declare 'modified' variable here
      bool initCallFound = false;
      bool importFound = false;
      int mainFunctionStartIndex = -1;
      int mainFunctionBodyStartIndex = -1; // After the opening {

      for (int i = 0; i < content.length; i++) {
        final line = content[i].trim();

        // Check for existing import
        if (line.contains("import 'package:$packageName/helpers/dio.dart';")) {
          importFound = true;
        }

        // Find the main function signature (basic check)
        if (mainFunctionStartIndex == -1 &&
            (line.startsWith('void main(') ||
                line.startsWith('Future<void> main('))) {
          mainFunctionStartIndex = i;
          // Find the opening brace for the function body
          int braceIndex = i;
          while (braceIndex < content.length &&
              !content[braceIndex].contains('{')) {
            braceIndex++;
          }
          if (braceIndex < content.length) {
            mainFunctionBodyStartIndex = braceIndex;
          }
        }

        // Check for DioHelper.init() call within the estimated main function body
        // Check lines from the line *after* the opening brace
        if (mainFunctionBodyStartIndex != -1 &&
            i > mainFunctionBodyStartIndex) {
          if (line.contains('DioHelper.init();')) {
            initCallFound = true;
            // No need to check further within main once found
            break;
          }
          // Basic check to stop if we hit the closing brace of main
          if (content[i].trim() == '}') {
            // This might be the end of main if we are past the start index
            // More robust logic would track scope {}. Simple is okay for common case.
            // Let's assume the first } after the main signature is the end of main
            if (i > mainFunctionBodyStartIndex) break;
          }
        }
      }

      if (initCallFound) {
        print('✅ DioHelper.init() already exists in lib/main.dart.');
      } else if (mainFunctionBodyStartIndex == -1) {
        print(
            '⚠️ Could not find the `main()` function body opening brace `{` in lib/main.dart. Cannot add DioHelper.init().');
      } else {
        print('➕ Adding DioHelper.init() to lib/main.dart...');
        // Insert the call right after the opening brace of main
        // Determine indentation - look at the line after the brace (if it exists)
        String indentation = '  '; // Default indentation
        if (mainFunctionBodyStartIndex + 1 < content.length) {
          final nextLine = content[mainFunctionBodyStartIndex + 1];
          if (nextLine.trim().isNotEmpty && !nextLine.trim().startsWith('//')) {
            // Use non-empty, non-comment line
            final leadingWhitespace =
                nextLine.substring(0, nextLine.indexOf(nextLine.trimLeft()));
            if (leadingWhitespace.isNotEmpty) {
              indentation = leadingWhitespace;
            }
          }
        }

        // Insert the init call and an empty line after the opening brace
        content.insert(
            mainFunctionBodyStartIndex + 1, '${indentation}DioHelper.init();');
        content.insert(mainFunctionBodyStartIndex + 2,
            ''); // Add an empty line for spacing
        modified = true; // Mark as modified

        print('✅ DioHelper.init() added to main function.');

        // Add the import if not found
        if (!importFound) {
          print('➕ Adding DioHelper import to lib/main.dart...');
          // Find a good place to insert the import (usually after other imports)
          int lastImportIndex = -1;
          for (int i = 0; i < content.length; i++) {
            if (content[i].trim().startsWith('import ')) {
              lastImportIndex = i;
            } else if (lastImportIndex != -1 &&
                content[i].trim().isNotEmpty &&
                !content[i].trim().startsWith('//') &&
                !content[i].trim().startsWith('/*')) {
              // Stop after finding the first non-comment/non-empty line after imports
              break;
            }
          }

          if (lastImportIndex != -1) {
            content.insert(lastImportIndex + 1,
                "import 'package:$packageName/helpers/dio.dart';");
            // Add an empty line after the new import if the next line is not empty/comment
            if (lastImportIndex + 2 < content.length &&
                content[lastImportIndex + 2].trim().isNotEmpty) {
              content.insert(lastImportIndex + 2, '');
            }
          } else {
            // If no imports found, add at the very top
            content.insert(
                0, "import 'package:$packageName/helpers/dio.dart';\n");
            // Ensure there's a blank line after the new import if the file wasn't empty
            if (content.length > 1 && content[1].trim().isNotEmpty) {
              content.insert(1, '');
            }
          }
          modified = true; // Mark as modified
          print('✅ DioHelper import added.');
        } else {
          print('✅ DioHelper import already exists.');
        }
      }

      // Only write if modifications were made
      if (modified) {
        // Use writeAsString with join for writing lines
        await file.writeAsString(content.join('\n'));
        print('✅ lib/main.dart updated.');
      } else {
        print('✅ lib/main.dart requires no changes.');
      }
    } catch (e) {
      print('❌ Error modifying lib/main.dart: $e');
    }
  }
