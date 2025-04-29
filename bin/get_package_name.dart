import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

Future<String?> getPackageName(String projectRoot) async {
    final file = File(path.join(projectRoot, 'pubspec.yaml'));
    if (!await file.exists()) {
      // This should ideally not happen if _findProjectRoot succeeded
      print('❌ pubspec.yaml not found at expected location: ${file.path}');
      return null;
    }
    try {
      final content = await file.readAsString();
      final yamlMap = loadYaml(content);
      return yamlMap['name']?.toString();
    } catch (e) {
      print('❌ Error reading pubspec.yaml or parsing YAML: $e');
      return null;
    }
  }