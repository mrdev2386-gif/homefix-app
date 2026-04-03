import re

# Read the file
with open('firestore_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace patterns
content = re.sub(
    r'final functions = FirebaseFunctions\.instanceFor\([^)]+\);\s*final callable = functions\.httpsCallable',
    'final callable = FunctionsService.instance.httpsCallable',
    content
)

content = re.sub(
    r'final retryFunctions = FirebaseFunctions\.instanceFor\([^)]+\);\s*final retryCallable = retryFunctions\.httpsCallable',
    'final retryCallable = FunctionsService.instance.httpsCallable',
    content
)

# Write back
with open('firestore_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Replacement complete")
