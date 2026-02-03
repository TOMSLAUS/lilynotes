# CI/CD Signing Setup Guide

This guide explains how to configure code signing for the GitHub Actions workflows.

## Required Secrets

### Android Secrets
| Secret | Description |
|--------|-------------|
| `KEYSTORE_BASE64` | Base64-encoded upload keystore file |
| `KEYSTORE_PASSWORD` | Password for the keystore |
| `KEY_ALIAS` | Alias of the signing key |
| `KEY_PASSWORD` | Password for the key |

### iOS Secrets
| Secret | Description |
|--------|-------------|
| `IOS_CERTIFICATE_P12_BASE64` | Base64-encoded App Store distribution certificate |
| `IOS_CERTIFICATE_PASSWORD` | Password used when exporting the .p12 |
| `IOS_PROVISIONING_PROFILE_BASE64` | Base64-encoded provisioning profile |
| `IOS_TEAM_ID` | Your Apple Developer Team ID (10-character string) |

---

## Android Setup

### Step 1: Generate an Upload Keystore

If you don't already have a keystore, create one:

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA \
  -keysize 2048 -validity 10000 -alias upload
```

You'll be prompted for:
- Keystore password
- Key password (can be the same)
- Your name, organization, etc.

**Important:** Store this keystore securely. If you lose it, you cannot update your app on Google Play.

### Step 2: Base64-Encode the Keystore

**macOS/Linux:**
```bash
base64 -i upload-keystore.jks | pbcopy  # macOS (copies to clipboard)
base64 upload-keystore.jks              # Linux (prints to terminal)
```

**Windows (PowerShell):**
```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("upload-keystore.jks")) | Set-Clipboard
```

### Step 3: Add Secrets to GitHub

1. Go to your repository on GitHub
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret** and add:
   - `KEYSTORE_BASE64`: Paste the base64 string
   - `KEYSTORE_PASSWORD`: Your keystore password
   - `KEY_ALIAS`: `upload` (or whatever alias you used)
   - `KEY_PASSWORD`: Your key password

---

## iOS Setup

### Step 1: Create an App Store Distribution Certificate

1. Open **Keychain Access** on your Mac
2. Go to **Keychain Access** → **Certificate Assistant** → **Request a Certificate from a Certificate Authority**
3. Enter your email and select "Saved to disk"
4. Go to [Apple Developer Portal](https://developer.apple.com/account/resources/certificates/list)
5. Click **+** to create a new certificate
6. Select **Apple Distribution** (for App Store)
7. Upload your Certificate Signing Request
8. Download and double-click to install the certificate

### Step 2: Export the Certificate as .p12

1. Open **Keychain Access**
2. Find your "Apple Distribution" certificate (under "My Certificates")
3. Right-click → **Export**
4. Choose `.p12` format
5. Set a password (you'll need this for `IOS_CERTIFICATE_PASSWORD`)

### Step 3: Create a Provisioning Profile

1. Go to [Apple Developer Portal](https://developer.apple.com/account/resources/profiles/list)
2. Click **+** to create a new profile
3. Select **App Store Connect** under Distribution
4. Select your app's App ID (`com.lilynotes.app`)
5. Select the distribution certificate you created
6. Name it `LilyNotes App Store` (must match `ExportOptions.plist`)
7. Download the `.mobileprovision` file

### Step 4: Find Your Team ID

1. Go to [Apple Developer Membership](https://developer.apple.com/account/#/membership/)
2. Your Team ID is listed there (10-character alphanumeric string)

### Step 5: Base64-Encode the Files

**Certificate (.p12):**
```bash
base64 -i Certificates.p12 | pbcopy  # macOS
base64 Certificates.p12              # Linux
```

**Windows (PowerShell):**
```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("Certificates.p12")) | Set-Clipboard
```

**Provisioning Profile:**
```bash
base64 -i LilyNotes_App_Store.mobileprovision | pbcopy  # macOS
base64 LilyNotes_App_Store.mobileprovision              # Linux
```

### Step 6: Add Secrets to GitHub

1. Go to your repository on GitHub
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret** and add:
   - `IOS_CERTIFICATE_P12_BASE64`: Paste the certificate base64 string
   - `IOS_CERTIFICATE_PASSWORD`: Password you set when exporting
   - `IOS_PROVISIONING_PROFILE_BASE64`: Paste the profile base64 string
   - `IOS_TEAM_ID`: Your 10-character Team ID

### Step 7: Update ExportOptions.plist (if needed)

If your provisioning profile has a different name than "LilyNotes App Store", update `ios/ExportOptions.plist`:

```xml
<key>provisioningProfiles</key>
<dict>
    <key>com.lilynotes.app</key>
    <string>YOUR_PROFILE_NAME_HERE</string>
</dict>
```

---

## Triggering a Build

### Automatic Builds
Builds trigger automatically when you push to the `main` branch.

### Manual Builds
1. Go to your repository on GitHub
2. Click the **Actions** tab
3. Select either **Android Build** or **iOS Build** from the left sidebar
4. Click **Run workflow** → **Run workflow**

---

## Troubleshooting

### Android: "Keystore was tampered with"
- The `KEYSTORE_BASE64` secret may be corrupted
- Re-encode the keystore and update the secret

### Android: "Cannot recover key"
- Check that `KEY_PASSWORD` matches the key password (not keystore password)

### iOS: "No signing certificate found"
- Verify the certificate hasn't expired
- Re-export and re-encode the .p12 file

### iOS: "Provisioning profile doesn't match"
- Ensure the profile name in `ExportOptions.plist` matches exactly
- Verify the profile includes the correct App ID and certificate

### iOS: "Code signing is required"
- Ensure your provisioning profile is for "App Store Connect" distribution
- Verify the `IOS_TEAM_ID` is correct

---

## Security Notes

- Never commit keystores, certificates, or provisioning profiles to the repository
- Use GitHub's secret scanning to detect accidentally committed secrets
- Rotate credentials if they may have been exposed
- Consider using GitHub Environments for additional protection on production secrets
