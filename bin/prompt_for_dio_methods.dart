import 'dart:io';
import 'generate_dio_method.dart';
import 'package:path/path.dart' as path;

// --- Revised promptForDioMethods function ---
// Prompts the user for API methods and updates the state and cubit files accordingly.
Future<void> promptForDioMethods(String folderPath, String screenName,
    String cubitName, String stateName, String packageName) async {
  // Added packageName parameter
  print('\n--- Prompting for Dio Methods for $screenName ---');
  final cubitFilePath = path.join(folderPath, 'cubit.dart');
  final stateFilePath = path.join(folderPath, 'state.dart');

  List<Map<String, String>> apiCalls = [];

  // Loop to ask the user if they want to add API methods
  while (true) {
    stdout.write(
        'Add a Dio method for $screenName? (yes/no) write "y" or "n" '); // Updated prompt
    String addMethod = stdin.readLineSync()?.toLowerCase() ?? 'n';
    if (addMethod != 'yes' && addMethod != 'y') {
      // Check for 'yes' or 'y'
      break; // Exit loop if user doesn't want to add more methods
    }

    // Prompt for HTTP method using numbered options
    String methodType = '';
    while (methodType.isEmpty) {
      stdout.write('Select HTTP method:\n');
      stdout.write('1. GET\n');
      stdout.write('2. POST\n');
      stdout.write('3. PUT\n');
      stdout.write('4. DELETE\n');
      stdout.write('Enter number: ');
      String? choice = stdin.readLineSync();

      switch (choice) {
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
          print('Invalid choice. Please enter 1, 2, 3, or 4.');
      }
    }

    // Prompt for API path segment
    // Prompt for API path segment
    stdout.write('Enter path segment (e.g., /users/login): ');
    String pathSegment = stdin.readLineSync()?.trim() ?? ''; // Trim whitespace
    if (pathSegment.isEmpty) {
      print('Path segment cannot be empty.');
      continue; // Ask again for the same method
    }
    // Ensure path starts with '/'
    if (!pathSegment.startsWith('/')) {
      pathSegment = '/$pathSegment';
    }

    // Prompt for desired function name
    stdout.write('Enter desired function name (e.g., loginUser): ');
    String functionName = stdin.readLineSync()?.trim() ?? ''; // Trim whitespace
    if (functionName.isEmpty) {
      print('Function name cannot be empty.');
      continue; // Ask again for the same method
    }
    // Basic validation for function name: starts with lowercase, contains only letters and numbers
    if (!RegExp(r'^[a-z][a-zA-Z0-9]*$').hasMatch(functionName)) {
      print(
          'Invalid function name. Must start with a lowercase letter and contain only letters and numbers.');
      continue; // Ask again for the same method
    }

    // --- Confirmation Step ---
    print('\n--- Confirm API Call Details ---');
    print('Method: $methodType');
    print('Path: $pathSegment');
    print('Function Name: $functionName');
    stdout.write('Confirm details? (y/n): '); // Updated confirmation prompt
    String? confirmInput = stdin.readLineSync();
    String confirm = confirmInput?.trim().toLowerCase() ?? 'n';

    if (confirm == 'y') {
      // Check only for 'y'
      // Store the collected API call details
      apiCalls.add({
        'method': methodType,
        'path': pathSegment,
        'functionName': functionName,
      });
      print('✅ API call details confirmed.');
    } else {
      print('❌ API call details not confirmed. Starting over for this method.');
      continue; // Ask again for the same method details
    }
    // --- End Confirmation Step ---
  }

  // --- Update State File with Specific States ---
  if (apiCalls.isNotEmpty) {
    try {
      // Read the current content of the state file
      String currentStateContent = await File(stateFilePath).readAsString();
      String stateContentToAdd = '\n// --- Specific states for API calls ---';

      // Generate specific states for each collected function name
      for (var call in apiCalls) {
        String functionName = call['functionName']!;
        String capitalizedFunctionName = capitalize(functionName);
        stateContentToAdd += '''


class ${capitalizedFunctionName}Loading extends $stateName {}
class ${capitalizedFunctionName}Success extends $stateName {}
class ${capitalizedFunctionName}Error extends $stateName {}
''';
      }
      // Append the generated states to the state file
      await File(stateFilePath)
          .writeAsString(currentStateContent + stateContentToAdd);
      print('✅ Added specific states to $stateFilePath');
    } catch (e) {
      print('❌ Error updating state file $stateFilePath: $e');
    }

    // --- Update Cubit File with Dio Methods ---
    try {
      // Read the current content of the cubit file
      String currentCubitContent = await File(cubitFilePath).readAsString();
      String cubitContentToAdd = '\n// --- API Methods ---';

      // Generate the Dio method code for each collected API call
      for (var call in apiCalls) {
        String methodType = call['method']!;
        String pathSegment = call['path']!;
        String functionName = call['functionName']!;

        cubitContentToAdd += generateDioMethodCode(
          methodType,
          pathSegment,
          screenName, // screenName is still useful for base state name if needed
          functionName, // Pass the user-provided function name
          packageName, // Pass the packageName
        );
      }

      // Find the last closing brace '}' of the Cubit class to insert methods before it
      // This assumes a standard Cubit file structure. More complex files might need parsing.
      int lastBraceIndex = currentCubitContent.lastIndexOf('}');
      if (lastBraceIndex != -1) {
        // Insert the generated methods before the last brace
        String updatedCubitContent =
            currentCubitContent.substring(0, lastBraceIndex) +
                cubitContentToAdd +
                '\n}'; // Add the closing brace back
        // Write the updated content back to the cubit file
        await File(cubitFilePath).writeAsString(updatedCubitContent);
        print('✅ Added Dio methods to $cubitFilePath');
      } else {
        print(
            '❌ Could not find the end of the Cubit class in $cubitFilePath. Could not add methods.');
      }
    } catch (e) {
      print('❌ Error updating cubit file $cubitFilePath: $e');
    }
  } else {
    print('No Dio methods added for $screenName.');
  }
}
