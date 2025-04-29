import 'dart:io';

import 'flutter_screen_generator.dart';
import 'package:path/path.dart' as path;

Future<void> createDioHelperFile() async {
  print('🔍 Checking for DioHelper file...');
  final dioHelperDir = path.join(projectRoot!, 'lib', 'helpers');
  final dioHelperPath = path.join(dioHelperDir, 'dio.dart');
  final file = File(dioHelperPath);

  bool fileExists = await file.exists();
  String fileContent = '';
  bool baseUrlPlaceholderFound = false;

  if (fileExists) {
    print('✅ DioHelper file already exists at $dioHelperPath.');
    try {
      fileContent = await file.readAsString();
      // Check for the specific placeholder or if baseUrl seems set
      if (fileContent
          .contains("static const String baseUrl = 'YOUR_BASE_URL_HERE';")) {
        baseUrlPlaceholderFound = true;
        print('❕ Found BaseUrl placeholder in existing DioHelper file.');
      } else if (fileContent.contains("static const String baseUrl = ")) {
        // More general check if baseUrl is set
        print('✅ BaseUrl seems to be set in existing DioHelper file.');
        // If file exists and URL is set, we're done with this step unless placeholder was specifically found
        if (!baseUrlPlaceholderFound) return;
      } else {
        print('❓ BaseUrl definition not found in existing DioHelper file.');
        baseUrlPlaceholderFound = true; // Treat as if placeholder is needed
      }
    } catch (e) {
      print('❌ Error reading existing DioHelper file: $e');
      // Continue to create/overwrite if there was an error reading
      fileExists = false; // Treat as if file didn't exist for creation logic
    }
  }

  // If file doesn't exist OR placeholder was found OR baseUrl definition was missing
  if (!fileExists || baseUrlPlaceholderFound) {
    print('--- Setting up DioHelper Base URL ---');
    String? baseUrl;
    while (baseUrl == null || baseUrl.isEmpty || !baseUrl.startsWith('http')) {
      stdout.write(
          '❓ Please enter your API Base URL (e.g., https://api.example.com): ');
      baseUrl = stdin.readLineSync()?.trim();
      if (baseUrl == null || baseUrl.isEmpty) {
        print('❌ Base URL cannot be empty.');
      } else if (!baseUrl.startsWith('http')) {
        print('❌ Base URL should start with http:// or https://');
      }
    }

    // This is the new content for the dio.dart file
    final dioHelperCode = '''
import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
// Make sure you have a lib/helpers/cach.dart file with CachedHelper
// It should contain a static method getUserToken() that returns a String.
// If your token logic is different, you'll need to adjust _generateHeaders.
import 'package:\$_packageName/helpers/cach.dart'; // Placeholder for package name
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DioHelper {
  static Dio? dio;

  // Base URL will be set here by the script
  static const String baseUrl = '$baseUrl';

  static void init() {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        receiveDataWhenStatusError: true,
      ),
    );
    dio!.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: true,
        error: true,
        compact: true,
        maxWidth: 90,
      ),
    );
    log('✅ DioHelper initialized with baseUrl: \$baseUrl');
  }

  static Map<String, String> _generateHeaders() {
    // !! IMPORTANT: Ensure CachedHelper.getUserToken() exists and works !!
    // Assumes CachedHelper is in lib/helpers/cach.dart and has this method
    // Adjust this if your token logic is different
    String userToken = '';
    try {
       userToken = CachedHelper.getUserToken();
    } catch (e) {
       log('Warning: CachedHelper.getUserToken() failed: \$e.Proceeding without token.');
    }

    return {
      if (userToken.isNotEmpty) 'Authorization': 'Bearer \$userToken',
      'Accept': 'application/json',
      HttpHeaders.contentTypeHeader: 'application/json',
    };
  }

  static Future<Response?> getData({
    required String path,
    data, // Added data parameter based on the second snippet
    Map<String, dynamic>? queryParameters,
  }) async {
    return _makeRequest(
      () => dio!.get(
        path,
        data: data, // Added data here
        queryParameters: queryParameters,
        options: Options(
          validateStatus: (_) => true,
          headers: _generateHeaders(),
        ),
      ),
    );
  }

  static Future<Response?> putData({
    required String path,
    required Map<String, dynamic> data,
    Map<String, dynamic>? queryParameters, // Added based on common use cases
  }) async {
    return _makeRequest(
      () => dio!.put(
        path,
        data: data,
         queryParameters: queryParameters, // Added here
        options: Options(
          validateStatus: (_) => true,
          headers: _generateHeaders(),
        ),
      ),
    );
  }

  static Future<Response?> patchData({
    required String path,
    required data,
     Map<String, dynamic>? queryParameters, // Added based on common use cases
  }) async {
    return _makeRequest(
      () => dio!.patch(
        path,
        data: data,
        queryParameters: queryParameters, // Added here
        options: Options(
          validateStatus: (_) => true,
          headers: _generateHeaders(),
        ),
      ),
    );
  }

  static Future<Response?> postData({
    required String path,
    data,
    queryParameters,
  }) async {
    return _makeRequest(
      () => dio!.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          validateStatus: (_) => true,
          headers: _generateHeaders(),
        ),
      ),
    );
  }

  static Future<Response?> deleteData(
      {required String path, data, queryParameters}) async {
    return _makeRequest(
      () => dio!.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          validateStatus: (_) => true,
          headers: _generateHeaders(),
        ),
      ),
    );
  }

  static void _handleError(DioException e) {
    final errorMessage = _handleResponse(e.response);

    // Using Fluttertoast as in the provided code
    try {
       Fluttertoast.showToast(
         msg: errorMessage,
         toastLength: Toast.LENGTH_LONG,
         gravity: ToastGravity.BOTTOM,
         backgroundColor: Colors.red,
         textColor: Colors.white,
         fontSize: 16.0,
       );
    } catch (toastError) {
       log('Error showing toast: \$toastError');
       // Fallback print if toast fails (e.g., not in a Flutter context)
       print('API Error: \$errorMessage');
    }

    log('Error: \$errorMessage');
  }

  static String _handleResponse(Response? response) {
    // Check for messageText in the response data if it's a Map
    if (response != null &&
        response.data != null &&
        response.data is Map &&
        response.data['messageText'] != null) {
      return response.data['messageText'].toString(); // Ensure it's a string
    }

    switch (response?.statusCode) {
      case 400:
        return 'Bad request';
      case 401:
      case 403:
        return 'Unauthorized';
      case 404:
        return 'Not found';
      case 405:
        return 'Method not allowed';
      case 422:
        return 'Validation error';
      case 500:
        return 'Server error';
      default:
        // Fallback for unexpected status codes or no response
        return response?.statusMessage ?? 'Unknown error';
    }
  }

  static Future<Response?> _makeRequest(
      Future<Response> Function() request) async {
     // Ensure dio is initialized
    if (dio == null) {
       log('❌ DioHelper not initialized. Call DioHelper.init() first.');
       // Fail fast if not initialized
       return null;
    }

    try {
      final response = await request();

      // Handle specific response codes like 401
      if (response.statusCode == 401) {
        log('Received 401 Unauthorized. Attempting to clear cached data.');
        // clearCachedData() needs to be available (defined below or imported)
        await clearCachedData();
        // Optional: Add logic here to navigate to login screen
      }

      return response;
    } on SocketException catch (e) {
      log('SocketException: \${e.message}');
       // Show a user-friendly message for network errors
      try {
          Fluttertoast.showToast(msg: 'No Internet connection'); // Common SocketException cause
      } catch(toastError) {
          log('Error showing toast for SocketException: \$toastError');
          print('Network Error: No Internet connection');
      }
       // Re-throw to allow calling code to catch network errors
      rethrow;

    } on DioException catch (e) {
      log('DioException: \${e.message}');
      _handleError(e); // Use the existing error handler for DioExceptions
       // Re-throw to allow calling code to catch API errors
      rethrow;
    } catch (e) {
       // Catch any other unexpected errors during the request process
       log('An unexpected error occurred during the request: \$e');
        try {
            Fluttertoast.showToast(msg: 'An unexpected error occurred.');
        } catch(toastError) {
            log('Error showing toast for unexpected error: \$toastError');
            print('An unexpected error occurred.');
        }
        // Re-throw the exception
        rethrow;
    }
     // If we reach here without exceptions, the request was successful.
     // The response is returned.
  }
}

// Assuming clearCachedData is part of this file or globally available as in your snippet.
Future<void> clearCachedData() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    log('Cached data cleared.');
     // If you have a RouteManager or similar for navigation, you might uncomment this:
     // RouteManager.navigateAndPopAll(const SplashScreen());
  } catch(e) {
     log('Error clearing cached data: \$e');
  }
}

'''; // End of dioHelperCode multi-line string

    if (!fileExists || (fileExists && baseUrlPlaceholderFound)) {
      print(
          '➕ Writing DioHelper file at $dioHelperPath with provided Base URL...');
      try {
        await Directory(dioHelperDir).create(recursive: true);

        // Replace the placeholder with the actual package name for the cachHelper import
        // Note: The placeholder is now inside the new dioHelperCode string
        await file.writeAsString(dioHelperCode.replaceFirst(
            "import 'package:\$_packageName/helpers/cach.dart';",
            "import 'package:${packageName!}/helpers/cach.dart';"));
        print('✅ DioHelper file created/updated.');
      } catch (e) {
        print('❌ Error creating/updating DioHelper file: $e');
      }
    }
    print(
        '❗ Ensure you have the `lib/helpers/cach.dart` file with the `CachedHelper` class containing `static String getUserToken()`.');
  }
}
