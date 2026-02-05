# Production Hardware & Security Guide

This guide ensures your platform is ready for public launch.

## 1. Firebase App Check

App Check is critical to prevent API abuse. We have added the dependencies and initialization.

### Actions Required:
1.  Go to **Firebase Console** > **App Check**.
2.  Click **Get Started**.
3.  Register **Play Integrity** for both Android apps.
4.  Add the **SHA-256 fingerprint** of your upload/release keystore.
    - Run: `keytool -list -v -keystore path/to/your-release-key.jks`
5.  Enable App Check enforcement for:
    - **Cloud Firestore**
    - **Cloud Storage**
    - **Cloud Functions** (Wait 24h after launch to enforce fully if needed, but enable monitoring immediately).

## 2. Generate Release Keystore

You cannot release to the Play Store with the default debug key.

### Actions Required:
1.  Run this command (or use Android Studio):
    ```bash
    keytool -genkey -v -keystore upload-keystore.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000
    ```
2.  Place `upload-keystore.jks` in a secure location (outside the repo).
3.  Create a file named `key.properties` in `apps/customer_app/android/` and `apps/technician_app/android/`.
4.  Copy the content from `key.properties.example` and fill in your passwords/paths.
    - **Do NOT commit `key.properties` or `*.jks` to git.**

## 3. Razorpay Production Keys

The backend is configured to read keys from Firebase Config.

### Actions Required:
1.  Get your **Live** Key ID and Secret from Razorpay Dashboard.
2.  Run this command to set them in production:
    ```bash
    firebase functions:config:set razorpay.key_id="rzp_live_..." razorpay.key_secret="<your_live_secret>"
    ```
3.  Also configure other settings:
    ```bash
    firebase functions:config:set matching.radius_km="15"
    firebase functions:config:set matching.max_candidates="10"
    ```
4.  Deploy updated functions:
    ```bash
    firebase deploy --only functions
    ```

## 4. Google Play Store Release

Your apps are now configured with production package names:
- Customer: `com.homefix.customer`
- Technician: `com.homefix.technician`

### Actions Required:
1.  Create these apps in **Google Play Console**.
2.  Build the release bundles:
    ```bash
    cd apps/customer_app
    flutter build appbundle --release
    
    cd ../technician_app
    flutter build appbundle --release
    ```
3.  Upload the `.aab` files to the **Internal Testing** track first.

## 5. Verify Crashlytics

1.  After uploading to Play Store (Internal Test), download the app.
2.  Force a crash (e.g., add a temporary button `throw Exception("Test Crash")`).
3.  Verify it appears in **Firebase Console > Crashlytics**.

## 6. Support & Maintenance

- Monitor **Firebase Performance** tab for slow startup.
- valid `google-services.json` must be present in `apps/customer_app/android/app/` and `technician_app/android/app/`.

**LAUNCH STATUS: READY (Pending Key Generation & Console Setup)**
