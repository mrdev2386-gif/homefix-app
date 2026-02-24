import 'dart:io';

void main() {
  final baseDir = Directory('lib');
  if (!baseDir.existsSync()) {
    print('lib directory not found');
    return;
  }

  // Files to process for Phase 1
  final phase1Dirs = [
    'lib/features/custom_request',
    'lib/features/home',
    'lib/features/profile',
  ];

  for (final dirPath in phase1Dirs) {
    final dir = Directory(dirPath);
    if (dir.existsSync()) {
      for (final entity in dir.listSync(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          fixPhase1(entity);
        }
      }
    }
  }

  // Phase 2 and 3: Replace globally
  for (final entity in baseDir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      fixPhase2and3(entity);
    }
  }
}

void fixPhase1(File file) {
  String content = file.readAsStringSync();
  final regex = RegExp(r"import\s+'(\.\./)+core/([^']+)';");
  if (regex.hasMatch(content)) {
    content = content.replaceAllMapped(regex, (match) {
      return "import 'package:customer_app/core/${match.group(2)}';";
    });
    file.writeAsStringSync(content);
    print('Fixed imports in ${file.path}');
  }
}

void fixPhase2and3(File file) {
  String content = file.readAsStringSync();
  bool changed = false;

  // Phase 2: Google Fonts
  if (content.contains('GoogleFonts.') && !content.contains("import 'package:google_fonts/google_fonts.dart';")) {
    content = "import 'package:google_fonts/google_fonts.dart';\n$content";
    changed = true;
    print('Added GoogleFonts import to ${file.path}');
  }

  // Phase 3: MainAxisAlignment.between
  if (content.contains('MainAxisAlignment.between')) {
    content = content.replaceAll('MainAxisAlignment.between', 'MainAxisAlignment.spaceBetween');
    changed = true;
    print('Fixed MainAxisAlignment in ${file.path}');
  }

  if (changed) {
    file.writeAsStringSync(content);
  }
}
