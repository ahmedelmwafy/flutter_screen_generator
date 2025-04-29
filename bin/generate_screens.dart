import 'dart:io';
import 'captilize.dart';
import 'package:path/path.dart' as path;
import 'flutter_screen_generator.dart';
import 'prompt_for_dio_methods.dart';

Future<void> generateScreens(List<String> screenNames) async {
    print('\n--- Generating Screens ---');
    for (var folderName in screenNames) {
      // Construct the target folder path relative to the project root
      final folderPath = path.join(projectRoot!, 'lib', 'screens', folderName);
      final cubitName = '${capitalize(folderName)}Cubit';
      final stateName = '${capitalize(folderName)}State';
      final viewName = capitalize(folderName);

      // File contents remain largely the same, ensuring package imports use the correct packageName
      // Using .replaceFirst to insert the package name
      final cubitFile = '''
import 'package:flutter_bloc/flutter_bloc.dart';
// Use the determined package name for imports
import 'package:$packageName/screens/$folderName/state.dart';

class $cubitName extends Cubit<$stateName> {
  $cubitName() : super(${capitalize(folderName)}Initial());
  static $cubitName get(context) => BlocProvider.of(context);
}
''';

      // Moved stateFile definition inside the loop
      final stateFile = '''
class $stateName {}

class ${capitalize(folderName)}Initial extends $stateName {}

// Generic loading state for any operation in this cubit
class ${capitalize(folderName)}Loading extends $stateName {}

// Generic success state for any operation in this cubit
class ${capitalize(folderName)}Success extends $stateName {}

// Generic error state for any operation in this cubit
class ${capitalize(folderName)}Error extends $stateName {}

// You can add more specific states here if needed, e.g.:
// class FetchDataLoading extends ${stateName}Loading {}
// class FetchDataSuccess extends ${stateName}Success {}
// class FetchDataError extends ${stateName}Error {}
''';

      final viewFile = '''
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// Use the determined package name for imports
import 'package:$packageName/screens/$folderName/cubit.dart';
import 'package:$packageName/screens/$folderName/state.dart';

class $viewName extends StatelessWidget {
  const $viewName({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Using the cascade operator to instantiate the cubit and call a method
      // Note: This assumes you will add a fetch method named fetch${viewName}Data
      // If you add methods with different names, you'll need to adjust this line
      create: (context) => $cubitName(),
      child: Builder(
        builder: (context) {
          final cubit = $cubitName.get(context);
          return BlocBuilder<$cubitName, $stateName>(
            builder: (context, state) {
              // TODO: Build your screen UI here based on the state and loading variables
              // Check the state type: state is ${stateName}Loading, state is ${stateName}Success, etc.
              // Or check the boolean loading variables in the cubit: cubit.isFetchUserDataLoading
              return  Scaffold(
                 appBar: AppBar(
                    title: Text('$viewName Screen'),
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
                'package:\$packageName', 'package:${packageName!}'));
        await File(path.join(folderPath, 'state.dart')).writeAsString(
            stateFile.replaceFirst(
                'package:\$packageName', 'package:${packageName!}'));
        await File(path.join(folderPath, 'view.dart')).writeAsString(
            viewFile.replaceFirst(
                'package:\$packageName', 'package:${packageName!}'));
        print('✅ Created screen: $folderName at $folderPath');

        // --- Prompt for Dio methods for this specific screen ---
        await promptForDioMethods(folderPath, viewName, cubitName, stateName);
        // ----------------------------------------------------
      } catch (e) {
        print('❌ Error creating screen $folderName: $e');
      }
    } // end of screenNames loop
  } // end of _generateScreens
