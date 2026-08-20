# KhataPay - Release Guide for Uptodown

## 📱 App Details for Uptodown

| Field | Value |
|---|---|
| **App Name** | KhataPay |
| **Package Name** | `com.khatapay.khatapay` |
| **Version** | 1.0.0 |
| **Category** | Business |
| **Platform** | Android 5.0+ (API 21+) |
| **Size** | ~20-30 MB (varies by build) |
| **Price** | Free |

---

## 🏗️ Building the Release APK

### Option 1: GitHub Actions (Recommended - No Android SDK needed)

The `.github/workflows/android-release.yml` workflow automatically builds the APK when you push to `main`:

1. **Push to GitHub**:
   ```bash
   git add .
   git commit -m "Release v1.0.0"
   git push origin main
   ```

2. **Wait for the workflow** to complete (Actions tab in GitHub)

3. **Download the APK** from:
   - The **GitHub Release** (auto-created with tag)
   - The **Artifacts** section of the workflow run

### Option 2: Build Locally (Requires Android SDK)

1. Install [Android Studio](https://developer.android.com/studio) (includes Android SDK)
2. Set `ANDROID_HOME` environment variable
3. Build:
   ```bash
   flutter build apk --release
   ```
4. APK location: `build/app/outputs/flutter-apk/app-release.apk`

---

## 🔑 App Signing (Important!)

For Uptodown, the APK must be **signed**. The workflow currently uses debug signing (works for testing). For production:

### Generate a Release Keystore
```bash
keytool -genkey -v -keystore khatapay-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### Configure Signing
1. Create `android/key.properties` (copy from `key.properties.example`):
   ```
   storePassword=YOUR_PASSWORD
   keyPassword=YOUR_PASSWORD
   keyAlias=upload
   storeFile=../keystore/khatapay-release.jks
   ```
2. Place your keystore at `android/keystore/khatapay-release.jks`
3. Rebuild the APK

> ⚠️ **IMPORTANT**: Never commit `key.properties` or your `.jks` file to GitHub!

---

## 📤 Uploading to Uptodown

### Step 1: Create a Developer Account
1. Go to [Uptodown Developers](https://www.uptodown.com/developers)
2. Register as a developer
3. Complete your developer profile

### Step 2: Submit the App
1. Go to **"Submit App"**
2. Fill in the app details:

| Field | Value |
|---|---|
| **App Name** | KhataPay |
| **Description** | Business management app for tracking employees, salaries, income, and expenses. Features include employee management, attendance tracking, salary disbursement with UPI payment, account module for income/expense tracking, and detailed financial reports. |
| **Category** | Business |
| **Version** | 1.0.0 |
| **Package** | com.khatapay.khatapay |
| **Price** | Free |
| **Website** | (Your website or GitHub repo) |

3. **Upload the APK** file
4. **Upload screenshots** (at least 3-5):
   - Login screen
   - Dashboard
   - Employee list
   - Salary disbursements
   - Reports

### Step 3: App Icon & Banner
- **Icon**: 512x512 PNG
- **Banner**: 1024x500 PNG (optional)

### Step 4: Publish
1. Review all details
2. Submit for review
3. Uptodown typically approves within 24-48 hours

---

## 📸 Screenshots to Take

1. **Login Screen** - The welcome/login page
2. **Dashboard** - Shows income/expense cards and charts
3. **Employees** - Employee list view
4. **Salary** - Disbursement list with status badges
5. **Accounts** - Income/expense transaction list
6. **Reports** - P&L report with pie charts

---

## 🔄 Updating the App

When you release a new version:
1. Update `version` in `pubspec.yaml` (e.g., `1.0.1+2`)
2. Push to GitHub → workflow builds new APK
3. Download the new APK
4. Upload to Uptodown as a new version

---

## 🛠️ Troubleshooting

| Issue | Solution |
|---|---|
| **Build fails in GitHub Actions** | Check the Actions tab for error logs |
| **APK too large** | Run `flutter build apk --release --split-per-abi` to create smaller APKs |
| **App crashes on install** | Make sure `minSdk` is compatible with your target devices |
| **Login not working** | Verify Supabase credentials in `lib/core/constants/app_constants.dart` |
| **UPI payments not working** | Ensure the device has a UPI app installed (GPay, PhonePe, etc.) |