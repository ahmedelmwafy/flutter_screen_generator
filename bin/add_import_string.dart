String addImportString(String fileContent, String importString) {
    final lines = fileContent.split('\n');
    final trimmedImportString = importString.trim();

    // Check if import already exists
    if (lines.any((line) => line.trim() == trimmedImportString)) {
      return fileContent; // No change needed
    }

    int lastImportIndex = -1;
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].trim().startsWith('import ')) {
        lastImportIndex = i;
      } else if (lastImportIndex != -1 &&
          lines[i].trim().isNotEmpty &&
          !lines[i].trim().startsWith('//') &&
          !lines[i].trim().startsWith('/*')) {
        // Stop after finding the first non-comment/non-empty line after imports
        break;
      }
    }

    List<String> newLines = List.from(lines); // Create a mutable copy

    if (lastImportIndex != -1) {
      newLines.insert(lastImportIndex + 1, importString);
      // Add an empty line after the new import if the next line is not empty/comment
      if (lastImportIndex + 2 < newLines.length &&
          newLines[lastImportIndex + 2].trim().isNotEmpty) {
        newLines.insert(lastImportIndex + 2, '');
      }
    } else {
      // If no imports found, add at the very top
      newLines.insert(0, importString);
      // Ensure there's a blank line after the new import if the file wasn't empty
      if (newLines.length > 1 && newLines[1].trim().isNotEmpty) {
        newLines.insert(1, '');
      }
    }

    return newLines.join('\n');
  }
