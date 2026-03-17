#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import os

# Force UTF-8 output on Windows
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

PROJECT_ID = 'homefix-aa42d'

def set_admin_role_via_console(email):
    """
    Provide manual Firebase Console instructions
    """
    try:
        print(f'\nSetting admin role for: {email}')
        print(f'Note: This requires manual setup via Firebase Console')
        print(f'\nManual Steps:')
        print(f'   1. Go to Firebase Console: https://console.firebase.google.com/project/{PROJECT_ID}')
        print(f'   2. Navigate to Authentication > Users')
        print(f'   3. Find user with email: {email}')
        print(f'   4. Click on the user to open details')
        print(f'   5. Scroll to "Custom claims" section')
        print(f'   6. Click "Edit" and add:')
        print(f'      {{"admin": true}}')
        print(f'   7. Click "Save"')
        print(f'\nAfter setting the claim:')
        print(f'   1. Log out from admin panel')
        print(f'   2. Log back in')
        print(f'   3. Token will refresh with admin claim')
        print(f'   4. Try approving a booking\n')
        
        return True
        
    except Exception as error:
        print(f'Error: {str(error)}')
        return False

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print('Error: Email address required')
        print('\nUsage:')
        print('   python setAdminRole.py <admin-email>')
        print('\nExample:')
        print('   python setAdminRole.py cryptosourav23@gmail.com\n')
        sys.exit(1)

    email = sys.argv[1]
    
    if set_admin_role_via_console(email):
        sys.exit(0)
    else:
        sys.exit(1)
