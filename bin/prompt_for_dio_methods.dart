import 'dart:io';
import 'flutter_screen_generator.dart';
import 'generate_dio_method.dart';
import 'add_import_string.dart';
import 'package:path/path.dart' as path;

Future<void> promptForDioMethods(String folderPath, String screenName,
      String cubitName, String stateName) async {
    // Get user confirmation first
    stdout.write(
        '\n❓ Do you want to add Dio methods (e.g., fetch${screenName}Data) to the $cubitName? (y/n): ');
    String? response = stdin.readLineSync()?.trim().toLowerCase();

    if (response != 'y' && response != 'yes') {
      print('⏩ Skipping Dio method generation for $screenName.');
      return; // Skip if user says no
    }

    print('--- Adding Dio methods for $screenName Cubit ---');

    final cubitFilePath = path.join(folderPath, 'cubit.dart');
    var cubitContent = await File(cubitFilePath).readAsString();
    bool cubitModified = false; // Track if cubit file was changed

    // Add DioHelper import if not already present
    final dioImportString = "import 'package:$packageName/helpers/dio.dart';";
    if (!cubitContent.contains(dioImportString)) {
      cubitContent = addImportString(cubitContent, dioImportString);
      cubitModified = true;
      print('➕ Added DioHelper import to cubit.');
    } else {
      print('✅ DioHelper import already exists in cubit.');
    }

    while (true) {
      print('\nChoose method type to add:');
      print('1: GET (fetch data)');
      print('2: POST (send data)');
      print('3: PUT (update data)');
      print('4: DELETE (delete data)');
      print('n: Finish adding methods');
      stdout.write(
          'Enter choice (1-4 or n): '); // Use stdout.write for inline prompt

      String? methodChoice = stdin.readLineSync()?.trim().toLowerCase();

      if (methodChoice == 'n') {
        // Only 'n' to finish, 'finish' is less likely
        print('👍 Finished adding methods for $screenName.');
        break; // Exit the loop
      }

      String? methodType;
      switch (methodChoice) {
        case '1':
          methodType = 'GET';
          break;
        case '2':
          methodType = 'POST';
          break;
        case '3':
          methodType = 'PUT';
          break;
        case '4':
          methodType = 'DELETE';
          break;
        default:
          print('❌ Invalid choice. Please enter 1, 2, 3, 4, or n.');
          continue; // Ask again
      }

      stdout.write(
          'Enter the URL path segment for the $methodType request (e.g., "users/profile"): ');
      String? pathSegment = stdin.readLineSync()?.trim();

      if (pathSegment == null || pathSegment.isEmpty) {
        print('❌ URL path segment cannot be empty.');
        continue; // Ask again
      }

      // Generate the method code using .then().catchError().whenComplete()
      final generatedMethodCode = generateDioMethodCode(
          methodType, pathSegment, screenName, stateName);

      // Find insertion point (just before the last closing brace of the class)
      final lastBraceIndex = cubitContent.lastIndexOf('}');
      if (lastBraceIndex != -1) {
        // Insert the new method code before the last brace, ensuring basic indentation
        final insertionPoint = lastBraceIndex;
        // Add a blank line before the new method for separation
        cubitContent = cubitContent.substring(0, insertionPoint) +
            '\n' + // Add a newline before the method
            generatedMethodCode +
            cubitContent.substring(insertionPoint);
        cubitModified = true;
        print(
            '✅ Added $methodType method \'_generateDioMethodCode\' for /$pathSegment to $cubitName.'); // Report the generated function name base
      } else {
        print(
            '❌ Could not find closing brace for class $cubitName. Cannot add method automatically.');
        print('   You may need to manually add the method code.');
        // Optionally print the code to console for manual copy-paste
        // print('\n--- Generated Code ---');
        // print(generatedMethodCode);
        // print('----------------------\n');
      }
    } // end while loop

    // Write the modified cubit file if changes were made
    if (cubitModified) {
      await File(cubitFilePath).writeAsString(cubitContent);
      print('✅ $cubitName file updated with added methods.');
    }
  } // end of _promptForDioMethods
