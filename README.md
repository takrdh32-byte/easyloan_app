# QuickLoan Android App

HTML WebView app converted to native Android APK.

## Build karne ke 2 tarike hain:

---

## 1. GitHub Actions se Build (Recommended)

1. GitHub pe naya repository banao
2. Saara code push karo:
   ```
   git init
   git add .
   git commit -m "Initial commit"
   git remote add origin https://github.com/TUMHARA_USERNAME/QuickLoanApp.git
   git push -u origin main
   ```
3. Actions tab mein jayao → "Build QuickLoan APK" workflow run hoga automatically
4. Build complete hone ke baad → **Artifacts** section se APK download karo

---

## 2. Android Studio se Local Build

1. Android Studio mein project open karo
2. **Build → Build Bundle(s)/APK(s) → Build APK(s)**
3. APK milegi: `app/build/outputs/apk/debug/app-debug.apk`

---

## Signed APK ke liye (Play Store upload)

GitHub Secrets mein ye add karo:
| Secret Name | Value |
|---|---|
| `KEYSTORE_BASE64` | `base64 -w 0 release-key.jks` command ka output |
| `KEYSTORE_PASSWORD` | Keystore password |
| `KEY_ALIAS` | Key alias (e.g. `quickloan`) |
| `KEY_PASSWORD` | Key password |

Keystore banane ka command:
```bash
keytool -genkey -v -keystore release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias quickloan
```

---

## App Features
- Full QuickLoan HTML app as native Android APK
- Android 5.0+ (API 21) support
- File upload support
- Share/download loan agreements
- Back button navigation
- Immersive full-screen mode
- Gold "Q" launcher icon
