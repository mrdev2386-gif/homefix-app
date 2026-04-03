import re

# Read the file
with open('firestore_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace multi-line patterns - functions instance
content = re.sub(
    r'final functions = FirebaseFunctions\.instanceFor\(\s*region:\s*[\'"]asia-south1[\'"]\s*,?\s*\);',
    '',
    content,
    flags=re.MULTILINE | re.DOTALL
)

# Replace multi-line patterns - retry functions instance
content = re.sub(
    r'final retryFunctions = FirebaseFunctions\.instanceFor\(\s*region:\s*[\'"]asia-south1[\'"]\s*,?\s*\);',
    '',
    content,
    flags=re.MULTILINE | re.DOTALL
)

# Replace functions.httpsCallable with FunctionsService.instance.httpsCallable
content = re.sub(r'functions\.httpsCallable', 'FunctionsService.instance.httpsCallable', content)

# Replace retryFunctions.httpsCallable with FunctionsService.instance.httpsCallable
content = re.sub(r'retryFunctions\.httpsCallable', 'FunctionsService.instance.httpsCallable', content)

# Write back
with open('firestore_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Replacement complete - all instances fixed")
