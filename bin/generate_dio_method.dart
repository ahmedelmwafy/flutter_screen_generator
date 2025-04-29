import 'dart:io';
import 'package:path/path.dart' as path;
// Assuming DioHelper is available in your project
// Assuming flutter_screen_generator.dart and prompt_for_dio_methods.dart are part of this script or imported

// --- Simple capitalize function (assuming it's not built-in or from a package) ---
String capitalize(String s) {
  if (s.isEmpty) {
    return s;
  }
  return s[0].toUpperCase() + s.substring(1);
}

// --- Global variables (assuming they are set elsewhere in your script) ---
// These variables will now be determined automatically within generateScreens.
// String? projectRoot;
// String? packageName;


// --- Revised generateDioMethodCode function ---
// Generates the Dart code for a single Dio method within a Cubit.
// It now takes the desired function name from the user.
String generateDioMethodCode(String methodType, String pathSegment,
    String screenName, String userFunctionName, String packageName) { // Added packageName parameter
  String params = '';
  String dioCallArgs =
      "path: '$pathSegment',"; // Start with the path argument
  String methodCall = '';

  // Determine parameters and DioHelper method based on HTTP method type
  switch (methodType) {
    case 'GET':
      dioCallArgs +=
          '\n        // queryParameters: queryParameters,'; // Commented out, user can uncomment
      methodCall = 'DioHelper.getData';
      break;
    case 'POST':
      params =
          '{required Map<String, dynamic> data}'; // POST typically requires data
      dioCallArgs += '\n        data: data,'; // Data is usually required for POST
      // Add queryParameters option too, commented out
      dioCallArgs += '\n        // queryParameters: queryParameters,';
      methodCall = 'DioHelper.postData';
      break;
    case 'PUT':
      params =
          '{required Map<String, dynamic> data}'; // PUT typically requires data
      dioCallArgs += '\n        data: data,'; // Data is usually required for PUT
      // Add queryParameters option too, commented out
      dioCallArgs += '\n        // queryParameters: queryParameters,';
      methodCall = 'DioHelper.putData';
      break;
    case 'DELETE':
      // DELETE might use query params or data depending on the API
      dioCallArgs += '\n        // data: data,'; // Commented out
      dioCallArgs += '\n        // queryParameters: queryParameters,'; // Commented out
      methodCall = 'DioHelper.deleteData';
      break;
    default:
      // Should not happen with proper validation before calling this function
      return '';
  }

  // Use the user-provided function name directly
  String generatedFunctionName = userFunctionName;
  String capitalizedFunctionName = capitalize(userFunctionName);

  // Loading variable name derived from the user-provided function name
  // Example: if userFunctionName is 'fetchUserData', loadingVarName is 'isFetchUserDataLoading'
  String loadingVarName =
      'is${generatedFunctionName[0].toLowerCase()}${generatedFunctionName.substring(1)}Loading';

  // Define indentation levels for generated code
  const String methodBodyIndent = '    '; // 4 spaces for the method body
  const String tryCatchIndent = '    ';    // 4 spaces for the try/catch block
  const String dioCallIndent = '    '; // 4 spaces for the DioHelper call
  const String dioArgsIndent = '        '; // 8 spaces for arguments inside DioHelper
  const String blockBodyIndent = '        '; // 8 spaces for code inside if/else/catch/finally blocks

  // Generate the Dart code for the Dio method
  String code = '''

${methodBodyIndent}// Loading state for the '$generatedFunctionName' request to /$pathSegment
${methodBodyIndent}bool $loadingVarName = false;

${methodBodyIndent}Future<void> $generatedFunctionName($params) async { // Use async for await
${methodBodyIndent}${tryCatchIndent}$loadingVarName = true;
${methodBodyIndent}${tryCatchIndent}emit(${capitalizedFunctionName}Loading()); // Emit specific loading state

${methodBodyIndent}${tryCatchIndent}try { // Use try-catch for error handling
${methodBodyIndent}${dioCallIndent}  final response = await $methodCall( // Await the Dio call
${methodBodyIndent}${dioArgsIndent}    $dioCallArgs
${methodBodyIndent}${dioCallIndent}  );

${methodBodyIndent}${blockBodyIndent}// Check for successful response status (e.g., 200 range)
${methodBodyIndent}${blockBodyIndent}  if (response != null && (response.statusCode! >= 200 && response.statusCode! < 300)) {
${methodBodyIndent}${blockBodyIndent}    // TODO: Process data from response.data if needed
${methodBodyIndent}${blockBodyIndent}    // Example: final model = YourModel.fromJson(response.data);
${methodBodyIndent}${blockBodyIndent}    // You might update state with the fetched data here
${methodBodyIndent}${blockBodyIndent}    print("✅ Success during \\"$generatedFunctionName\\" for /$pathSegment"); // Log success
${methodBodyIndent}${blockBodyIndent}    emit(${capitalizedFunctionName}Success()); // Emit specific success state
${methodBodyIndent}${blockBodyIndent}  } else {
${methodBodyIndent}${blockBodyIndent}    // Handle API errors (non-200 status codes)
${methodBodyIndent}${blockBodyIndent}    final statusCodeString = response?.statusCode?.toString() ?? 'N/A';
${methodBodyIndent}${blockBodyIndent}    print("❌ API Error during \\"$generatedFunctionName\\" for /$pathSegment: Status \$statusCodeString"); // Log API error
${methodBodyIndent}${blockBodyIndent}    emit(${capitalizedFunctionName}Error()); // Emit specific error state on API error status
${methodBodyIndent}${blockBodyIndent}  }
${methodBodyIndent}${tryCatchIndent}} catch (error) { // Catch network errors or exceptions during the request
${methodBodyIndent}${blockBodyIndent}print("❌ Error during \\"$generatedFunctionName\\" for /$pathSegment: \$error"); // Log the exception
${methodBodyIndent}${blockBodyIndent}emit(${capitalizedFunctionName}Error()); // Emit specific error state on exception
${methodBodyIndent}${tryCatchIndent}} finally { // Code that runs regardless of success or error
${methodBodyIndent}${tryCatchIndent}  $loadingVarName = false; // Set loading to false
${methodBodyIndent}${tryCatchIndent}  // Optional: Emit a state to update loading status if needed separately
${methodBodyIndent}${tryCatchIndent}  // emit(${capitalizedFunctionName}LoadingStateUpdated(false));
${methodBodyIndent}${tryCatchIndent}}
${methodBodyIndent}} // End of method
''';

  return code;
}


// --- Revised promptForDioMethods function ---
// Prompts the user for API methods and updates the state and cubit files accordingly.
Future<void> promptForDioMethods(String folderPath, String screenName, String cubitName, String stateName, String packageName) async { // Added packageName parameter
  print('\n--- Prompting for Dio Methods for $screenName ---');
  final cubitFilePath = path.join(folderPath, 'cubit.dart');
  final stateFilePath = path.join(folderPath, 'state.dart');

  List<Map<String, String>> apiCalls = [];

  // Loop to ask the user if they want to add API methods
  while (true) {
    stdout.write('Add a Dio method for $screenName? (yes/no/y/n): '); // Updated prompt
    String addMethod = stdin.readLineSync()?.toLowerCase() ?? 'n';
    if (addMethod != 'yes' && addMethod != 'y') { // Check for 'yes' or 'y'
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
    stdout.write('Enter path segment (e.g., /users/login): ');
    String pathSegment = stdin.readLineSync() ?? '';
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
    String functionName = stdin.readLineSync() ?? '';
     if (functionName.isEmpty) {
      print('Function name cannot be empty.');
      continue; // Ask again for the same method
    }
     // Basic validation for function name: starts with lowercase, contains only letters and numbers
    if (!RegExp(r'^[a-z][a-zA-Z0-9]*$').hasMatch(functionName)) {
        print('Invalid function name. Must start with a lowercase letter and contain only letters and numbers.');
        continue; // Ask again for the same method
    }


    // Store the collected API call details
    apiCalls.add({
      'method': methodType,
      'path': pathSegment,
      'functionName': functionName,
    });
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
      await File(stateFilePath).writeAsString(currentStateContent + stateContentToAdd);
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
           String updatedCubitContent = currentCubitContent.substring(0, lastBraceIndex) +
                                        cubitContentToAdd +
                                        '\n}'; // Add the closing brace back
            // Write the updated content back to the cubit file
            await File(cubitFilePath).writeAsString(updatedCubitContent);
            print('✅ Added Dio methods to $cubitFilePath');
       } else {
           print('❌ Could not find the end of the Cubit class in $cubitFilePath. Could not add methods.');
       }


    } catch (e) {
      print('❌ Error updating cubit file $cubitFilePath: $e');
    }

  } else {
    print('No Dio methods added for $screenName.');
  }
}

// --- generateScreens function (as provided by the user) ---
// This function orchestrates the screen and related file generation.
Future<void> generateScreens(List<String> screenNames) async {
    print('\n--- Generating Screens ---');

    // --- Automatically determine projectRoot and packageName ---
    String? projectRoot = Directory.current.path;
    String? packageName;

    try {
        final pubspecFile = File(path.join(projectRoot, 'pubspec.yaml'));
        if (await pubspecFile.exists()) {
            final lines = await pubspecFile.readAsLines();
            for (var line in lines) {
                if (line.trim().startsWith('name:')) {
                    packageName = line.split(':')[1].trim();
                    break;
                }
            }
        }
    } catch (e) {
        print('❌ Error reading pubspec.yaml: $e');
    }

    if (packageName == null) {
        print('Error: Could not determine project root or package name. Make sure you are running this script from the project root directory.');
        return; // Exit if essential variables are not set
    }
    print('✅ Determined project root: $projectRoot');
    print('✅ Determined package name: $packageName');
    // --- End of automatic determination ---


    for (var folderName in screenNames) {
      // Construct the target folder path relative to the project root
      final folderPath = path.join(projectRoot, 'lib', 'screens', folderName);
      final cubitName = '${capitalize(folderName)}Cubit';
      final stateName = '${capitalize(folderName)}State';
      final viewName = capitalize(folderName);

      // File contents remain largely the same, ensuring package imports use the correct packageName
      // Using .replaceFirst to insert the package name
      final cubitFile = '''
import 'package:flutter_bloc/flutter_bloc.dart';
// Use the determined package name for imports
import 'package:\$packageName/screens/\$folderName/state.dart';
import 'package:myapp/helpers/dio.dart'; // Added the requested import here

class \$cubitName extends Cubit<\$stateName> {
  \$cubitName() : super(${capitalize(folderName)}Initial());
  static \$cubitName get(context) => BlocProvider.of(context);
}
''';

      // Moved stateFile definition inside the loop
      final stateFile = '''
class \$stateName {}

class ${capitalize(folderName)}Initial extends \$stateName {}

// Generic loading state for any operation in this cubit
class ${capitalize(folderName)}Loading extends \$stateName {}

// Generic success state for any operation in this cubit
class ${capitalize(folderName)}Success extends \$stateName {}

// Generic error state for any operation in this cubit
class ${capitalize(folderName)}Error extends \$stateName {}

// You can add more specific states here if needed, e.g.:
// class FetchDataLoading extends \${stateName}Loading {}
// class FetchDataSuccess extends \${stateName}Success {}
// class FetchDataError extends \${stateName}Error {}
''';

      final viewFile = '''
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// Use the determined package name for imports
import 'package:\$packageName/screens/\$folderName/cubit.dart';
import 'package:\$packageName/screens/\$folderName/state.dart';

class \$viewName extends StatelessWidget {
  const \$viewName({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Using the cascade operator to instantiate the cubit and call a method
      // Note: This assumes you will add a fetch method named fetch\${viewName}Data
      // If you add methods with different names, you'll need to adjust this line
      create: (context) => \$cubitName(),
      child: Builder(
        builder: (context) {
          final cubit = \$cubitName.get(context);
          return BlocBuilder<\$cubitName, \$stateName>(
            builder: (context, state) {
              // TODO: Build your screen UI here based on the state and loading variables
              // Check the state type: state is \${stateName}Loading, state is \${stateName}Success, etc.
              // Or check the boolean loading variables in the cubit: cubit.isFetchUserDataLoading
              return  Scaffold(
                 appBar: AppBar(
                    title: Text('\$viewName Screen'),
                 ),
                 body: Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [

                        ],
                    ),
                 ),
              );
            },
          );
        },
      ),
    );
  }
}
''';

      try {
        await Directory(folderPath).create(recursive: true);
        // Use .replaceFirst to insert the package name
        await File(path.join(folderPath, 'cubit.dart')).writeAsString(
            cubitFile.replaceFirst(
                'package:\$packageName', 'package:${packageName}'));
        await File(path.join(folderPath, 'state.dart')).writeAsString(
            stateFile.replaceFirst(
                'package:\$packageName', 'package:${packageName}'));
        await File(path.join(folderPath, 'view.dart')).writeAsString(
            viewFile.replaceFirst(
                'package:\$packageName', 'package:${packageName}'));
        print('✅ Created screen: $folderName at $folderPath');

        // --- Prompt for Dio methods for this specific screen ---
        // Pass the determined packageName to promptForDioMethods
        await promptForDioMethods(folderPath, viewName, cubitName, stateName, packageName);
        // ----------------------------------------------------
      } catch (e) {
        print('❌ Error creating screen $folderName: $e');
      }
    } // end of screenNames loop
  } // end of _generateScreens
