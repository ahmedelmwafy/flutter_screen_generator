import 'dart:io';
import 'flutter_screen_generator.dart';
import 'package:path/path.dart' as path;

Future<void> ensureDioDependencies() async {
    print('🔍 Checking and adding Dio dependencies to pubspec.yaml...');
    final pubspecPath = path.join(projectRoot!, 'pubspec.yaml');
    final file = File(pubspecPath);

    if (!await file.exists()) {
      print(
          '❌ pubspec.yaml not found at $pubspecPath. Cannot add dependencies.');
      return;
    }

    try {
      var content = await file.readAsLines();
      final dependencies = [
        'dio:', // Still use keys with colon for versions map lookup
        'pretty_dio_logger:',
        'shared_preferences:',
        'fluttertoast:',
        'flutter_bloc:', // Ensure flutter_bloc is also checked/added
      ];
      // Use simple version ranges. User will run pub get to resolve.
      final versions = {
        'dio:': ' ^5.0.0',
        'pretty_dio_logger:': ' ^1.4.0',
        'shared_preferences:': ' ^2.5.3',
        'fluttertoast:': ' ^8.2.12',
        'flutter_bloc:': ' ^9.1.0', // Assuming a recent version for Bloc
      };

      int dependenciesIndex = -1;
      int lastDepIndex = -1;
      List<String> malformedDependencies =
          []; // List to store malformed dependency names

      // Find the start and end of the dependencies section and identify malformed lines
      for (int i = 0; i < content.length; i++) {
        final line = content[i]; // Keep original line for identification
        final trimmedLine = line.trim();

        if (trimmedLine == 'dependencies:') {
          dependenciesIndex = i;
          lastDepIndex = i; // Start tracking last dep index from here
        } else if (dependenciesIndex != -1) {
          // Look for lines that signal the end of the dependencies block
          if (trimmedLine.isNotEmpty &&
              !trimmedLine.startsWith(' ') &&
              trimmedLine.endsWith(':') &&
              trimmedLine != 'dev_dependencies:') {
            // Found the start of the next section, stop searching
            break;
          }
          // Find the last non-comment, non-empty line within dependencies
          if (trimmedLine.isNotEmpty && !trimmedLine.startsWith('#')) {
            lastDepIndex = i;

            // Check if the line looks like just 'package_name:'
            // This is a simple check and might have false positives/negatives
            if (trimmedLine.endsWith(':') &&
                !trimmedLine.contains(' ') &&
                !trimmedLine.contains('sdk:') &&
                trimmedLine != 'dependencies:') {
              malformedDependencies.add(trimmedLine.substring(
                  0, trimmedLine.length - 1)); // Add package name
            }
          }
        }
      }

      if (dependenciesIndex == -1) {
        print('⚠️ Could not find "dependencies:" section in pubspec.yaml.');
        // Simple insertion at the end if section not found - might need manual fix
        print('❕ Attempting to add dependencies section at the end.');
        content.add('\ndependencies:');
        dependenciesIndex = content.length - 1;
        lastDepIndex = dependenciesIndex; // New last index is the added line
      }

      bool modified = false;
      List<String> linesToAdd = [];

      for (var dep in dependencies) {
        final depName = dep.replaceFirst(':', '');
        // Check if dependency exists, allowing for version specifiers like ^, >, etc.
        bool found = content.any(
          (line) =>
              line.trim().startsWith('$depName:') ||
              line.trim().startsWith('$depName '),
        );

        if (!found) {
          print('➕ Adding $depName to dependencies...');
          // CORRECTED LINE: Add ':' after depName
          linesToAdd.add('  $depName:${versions[dep] ?? ''}');
          modified = true;
        } else {
          print('✅ $depName already exists in dependencies.');
        }
      }

      if (modified) {
        // Insert new dependencies after the last existing dependency or the section header
        // Ensure index is valid, especially if dependenciesIndex was -1
        int insertIndex =
            (lastDepIndex != -1) ? lastDepIndex + 1 : content.length;
        content.insertAll(insertIndex, linesToAdd);

        // Use writeAsString with join for writing lines
        await file.writeAsString(content.join('\n'));
        print('✅ pubspec.yaml updated.');
      } else {
        print('✅ No dependencies needed to be added.');
      }

      // Report any malformed dependencies found
      if (malformedDependencies.isNotEmpty) {
        print('\n⚠️ WARNING: Found malformed dependencies in pubspec.yaml:');
        for (var dep in malformedDependencies) {
          print('  - "$dep:"');
        }
        print(
            '   Please manually add a version constraint (e.g., "^latest_version") to these dependencies in your pubspec.yaml file.');
      }
    } catch (e) {
      print('❌ Error modifying pubspec.yaml: $e');
    }
    // Always remind user to run pub get after potentially modifying pubspec
    print(
        '❕ Remember to run `flutter pub get` (or `dart pub get`) to fetch/update dependencies.');
  }

