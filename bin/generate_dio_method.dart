import 'captilize.dart';
String generateDioMethodCode(String methodType, String pathSegment,
      String screenName, String stateName) {
    // Determine function name, loading variable name, and state names
    String functionNamePrefix = '';
    String params = '';
    String dioCallArgs =
        "path: '$pathSegment',"; // Start with the path argument
    String methodCall = '';

    switch (methodType) {
      case 'GET':
        functionNamePrefix = 'fetch';
        params = '{Map<String, dynamic>? queryParameters}';
        // Indent subsequent args relative to the function call arguments start
        dioCallArgs +=
            '\n        // queryParameters: queryParameters,'; // Commented out, user can uncomment
        methodCall = 'DioHelper.getData';
        break;
      case 'POST':
        functionNamePrefix = 'send';
        params =
            '{required Map<String, dynamic> data}'; // POST typically requires data
        dioCallArgs +=
            '\n        // data: data,'; // Commented out, user can uncomment
        // Add queryParameters option too, commented out
        dioCallArgs += '\n        // queryParameters: queryParameters,';
        methodCall = 'DioHelper.postData';
        break;
      case 'PUT':
        functionNamePrefix = 'update';
        params =
            '{required Map<String, dynamic> data}'; // PUT typically requires data
        dioCallArgs += '\n        // data: data,'; // Commented out
        // Add queryParameters option too, commented out
        dioCallArgs += '\n        // queryParameters: queryParameters,';
        methodCall = 'DioHelper.putData';
        break;
      case 'DELETE':
        functionNamePrefix = 'delete';
        params =
            '{Map<String, dynamic>? queryParameters}'; // DELETE might use query params or data
        // Add data option too, commented out
        dioCallArgs += '\n        // data: data,';
        dioCallArgs +=
            '\n        // queryParameters: queryParameters,'; // Commented out
        methodCall = 'DioHelper.deleteData';
        break;
      default:
        // Should not happen based on _promptForDioMethods logic
        return ''; // Return empty string for invalid type
    }

    // Example function name: fetchUserData, sendLoginData, updateItemData, deleteRecordData
    String generatedFunctionName =
        '$functionNamePrefix${capitalize(screenName)}Data'; // e.g. fetchMasaaslData
    // Corrected loading variable name to start with lowercase 'i'
    String loadingVarName =
        'is${generatedFunctionName[0].toLowerCase()}${generatedFunctionName.substring(1)}Loading'; // e.g. isfetchMasaaslDataLoading

    // Use consistent indentation within the generated method
    String methodBodyIndentation =
        '  '; // Indentation level for the method body (inside the Future<void> function)
    String thenCatchIndentation =
        '    '; // Indentation inside .then(), .catchError(), .whenComplete()
    String thenCatchBodyIndentation =
        '      '; // Indentation inside the blocks {} of then/catch/whenComplete

    String code = '''

${methodBodyIndentation}// Loading state for the '$generatedFunctionName' request to /$pathSegment
${methodBodyIndentation}bool $loadingVarName = false;

${methodBodyIndentation}Future<void> $generatedFunctionName($params) {
${methodBodyIndentation}${methodBodyIndentation}$loadingVarName = true;
${methodBodyIndentation}${methodBodyIndentation}emit(${capitalize(screenName)}Loading()); // Emit generic loading state

${methodBodyIndentation}${methodBodyIndentation}return $methodCall(
${methodBodyIndentation}${methodBodyIndentation}  $dioCallArgs // Add data or queryParameters here if needed
${methodBodyIndentation}${methodBodyIndentation}).then((response) { // Use .then() to handle the response
${methodBodyIndentation}${thenCatchBodyIndentation}// This block runs if the Future completes successfully (even if API returns 400, 500 etc, if validateStatus is true)
${methodBodyIndentation}${thenCatchBodyIndentation}// Check for successful response status (e.g., 200 range)
${methodBodyIndentation}${thenCatchBodyIndentation}// Print the response object
${methodBodyIndentation}${thenCatchBodyIndentation}print("Response for \\"$generatedFunctionName\\" for /$pathSegment: \$response"); // Changed print to use double quotes and escape inner quotes
${methodBodyIndentation}${thenCatchBodyIndentation}if (response != null && (response.statusCode! >= 200 && response.statusCode! < 300)) {
${methodBodyIndentation}${thenCatchBodyIndentation}  // TODO: Process data from response.data if needed
${methodBodyIndentation}${thenCatchBodyIndentation}  print("✅ Success during \\"$generatedFunctionName\\" for /$pathSegment"); // Changed print to use double quotes and escape inner quotes
${methodBodyIndentation}${thenCatchBodyIndentation}  emit(${capitalize(screenName)}Success()); // Corrected state emit name
${methodBodyIndentation}${thenCatchBodyIndentation}} else {
${methodBodyIndentation}${thenCatchBodyIndentation}  // TODO: Handle API errors (non-200 status codes like 401, 404, 500)
${methodBodyIndentation}${thenCatchBodyIndentation}  // Explicitly get status code string to avoid potential analysis issues
${methodBodyIndentation}${thenCatchBodyIndentation}  final statusCodeString = response?.statusCode?.toString() ?? 'N/A';
${methodBodyIndentation}${thenCatchBodyIndentation}  print("❌ API Error during \\"$generatedFunctionName\\" for /$pathSegment: Status \$statusCodeString"); // Changed print to use double quotes and escape inner quotes
${methodBodyIndentation}${thenCatchBodyIndentation}}
${methodBodyIndentation}${thenCatchIndentation}}).catchError((error) { // Use .catchError() to handle exceptions
${methodBodyIndentation}${thenCatchBodyIndentation}// This block runs if the Future fails (e.g., network error, exception in DioHelper)
${methodBodyIndentation}${thenCatchBodyIndentation}print("❌ Error during \\"$generatedFunctionName\\" for /$pathSegment: \$error"); // Changed print to use double quotes and escape inner quotes
${methodBodyIndentation}${thenCatchBodyIndentation}emit(${capitalize(screenName)}Error()); // Corrected state emit name
${methodBodyIndentation}${thenCatchIndentation}}).whenComplete(() { // Use .whenComplete() for finally logic
${methodBodyIndentation}${thenCatchBodyIndentation}// This block runs regardless of success or error
${methodBodyIndentation}${thenCatchBodyIndentation}$loadingVarName = false;
${methodBodyIndentation}${thenCatchBodyIndentation}// To notify UI about loading state change independent of success/error,
${methodBodyIndentation}${thenCatchBodyIndentation}// you might need a state that includes this boolean or a separate state update mechanism.
${methodBodyIndentation}${thenCatchBodyIndentation}// The current boilerplate relies on the Success/Error state change triggering a rebuild.
${methodBodyIndentation}${thenCatchBodyIndentation}// You could also emit a state here like emit(${stateName}LoadingStateUpdated(false));
${methodBodyIndentation}${thenCatchIndentation}});
${methodBodyIndentation}} // End of method
'''; // Added a newline at the start for separation

    // The indentation is built into the string template
    return code;
  }
