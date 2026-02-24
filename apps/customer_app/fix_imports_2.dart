import 'dart:io';

void main() {
  final baseDir = Directory('lib');
  if (!baseDir.existsSync()) return;

  final regexes = {
    RegExp(r"import\s+'[^']*?core/models/category\.dart';"): "import 'package:customer_app/core/models/category.dart';",
    RegExp(r"import\s+'[^']*?core/models/service\.dart';"): "import 'package:customer_app/core/models/service.dart';", // HomeService is in service.dart
    RegExp(r"import\s+'[^']*?core/models/address\.dart';"): "import 'package:customer_app/core/models/address.dart';",
    RegExp(r"import\s+'[^']*?core/services/category_service\.dart';"): "import 'package:customer_app/core/services/category_service.dart';",
    RegExp(r"import\s+'[^']*?core/services/functions_service\.dart';"): "import 'package:customer_app/core/services/functions_service.dart';",
    RegExp(r"import\s+'[^']*?core/services/auth_service\.dart';"): "import 'package:customer_app/core/services/auth_service.dart';",
    // also Phase 5 AppTheme package style
    RegExp(r"import\s+'[^']*?core/theme/app_theme\.dart';"): "import 'package:customer_app/core/theme/app_theme.dart';",
  };

  for (final entity in baseDir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      String content = entity.readAsStringSync();
      bool changed = false;

      // Import paths
      for (final entry in regexes.entries) {
        if (entry.key.hasMatch(content)) {
          content = content.replaceAllMapped(entry.key, (_) => entry.value);
          changed = true;
        }
      }
      
      // StreamBuilder type fix (basic check for raw StreamBuilder)
      final sbRegex = RegExp(r"StreamBuilder\s*\(");
      if (sbRegex.hasMatch(content)) {
        print('Found raw StreamBuilder in ${entity.path}');
        // Hard to auto fix, just printing to check
      }
      
      if (changed) {
        entity.writeAsStringSync(content);
        print('Fixed imports in ${entity.path}');
      }
    }
  }
}
