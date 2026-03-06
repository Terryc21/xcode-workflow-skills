---
name: release-screenshots
description: 'Capture App Store screenshots across all required device sizes using simulator automation. Triggers: "release screenshots", "app store screenshots", "capture screenshots".'
version: 2.1.0
author: Terry Nyberg
license: MIT
allowed-tools: [Bash, Read, Glob, Write, AskUserQuestion]
metadata:
  tier: execution
  category: release
---

# Release Screenshots

> **Quick Ref:** Capture App Store screenshots across all required device sizes (6.9", 6.5", 5.5") using simulator automation.

**YOU MUST EXECUTE THIS WORKFLOW. Do not just describe it.**

---

## Step 1: Gather Requirements

```
AskUserQuestion with questions:
[
  {
    "question": "Which screens do you want to capture?",
    "header": "Screens",
    "options": [
      {"label": "Main screens", "description": "Home, list, detail, settings — the typical set"},
      {"label": "All screens", "description": "Every major screen in the app"},
      {"label": "I'll specify", "description": "I'll list the exact screens to capture"}
    ],
    "multiSelect": false
  },
  {
    "question": "Which device sizes do you need?",
    "header": "Devices",
    "options": [
      {"label": "All iPhone (Recommended)", "description": "6.9\" + 6.5\" + 5.5\" — covers all App Store requirements"},
      {"label": "6.9\" only", "description": "iPhone 16 Pro Max — newest required size"},
      {"label": "Custom selection", "description": "I'll specify which sizes"}
    ],
    "multiSelect": false
  }
]
```

---

## App Store Required Sizes

### iPhone Screenshots (Required)

| Display Size | Simulator Name | Resolution |
|--------------|----------------|------------|
| **6.9"** | iPhone 16 Pro Max | 1320 x 2868 |
| **6.5"** | iPhone 11 Pro Max | 1242 x 2688 |
| **5.5"** | iPhone 8 Plus | 1242 x 2208 |

### iPad Screenshots (If Universal App)

| Display Size | Simulator Name | Resolution |
|--------------|----------------|------------|
| **12.9"** | iPad Pro 12.9-inch (6th generation) | 2048 x 2732 |

---

## Step 2: Setup

```bash
# Create output directories
mkdir -p ~/Downloads/AppStoreScreenshots/{iPhone-6.9,iPhone-6.5,iPhone-5.5}

# Find available schemes
xcodebuild -list -json 2>/dev/null | head -30

# List available simulators
xcrun simctl list devices available | grep -E "iPhone|iPad"
```

---

## Step 3: Capture Screenshots

For each device size, repeat this process:

### Boot and prepare simulator

```bash
# Boot the target simulator
xcrun simctl boot "iPhone 16 Pro Max"

# Set clean status bar (9:41, full battery, full signal)
xcrun simctl status_bar "iPhone 16 Pro Max" override \
  --time "9:41" \
  --batteryState charged \
  --batteryLevel 100 \
  --cellularMode active \
  --cellularBars 4

# Optional: Set appearance mode
xcrun simctl ui "iPhone 16 Pro Max" appearance light
```

### Build and install

```bash
# Find bundle ID
xcodebuild -showBuildSettings -scheme <SCHEME> 2>/dev/null | grep PRODUCT_BUNDLE_IDENTIFIER

# Build for the simulator
xcodebuild build \
  -scheme <SCHEME> \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' \
  2>&1 | tail -5

# Launch the app
xcrun simctl launch "iPhone 16 Pro Max" <BUNDLE_ID>
```

### Capture each screen

```bash
# Wait for app to fully launch
sleep 3

# Capture screenshot
xcrun simctl io "iPhone 16 Pro Max" screenshot \
  ~/Downloads/AppStoreScreenshots/iPhone-6.9/01-Home.png
```

Navigate to the next screen (manually or via UI test), then capture again.

### Repeat for next device

```bash
# Shutdown current simulator
xcrun simctl shutdown "iPhone 16 Pro Max"

# Boot next device
xcrun simctl boot "iPhone 11 Pro Max"
# ... repeat status bar, build, install, capture
```

---

## Step 4: Verify Output

```bash
# Check all screenshots were captured
ls -la ~/Downloads/AppStoreScreenshots/*/

# Verify dimensions match App Store requirements
for f in ~/Downloads/AppStoreScreenshots/**/*.png; do
  echo "=== $f ==="
  sips -g pixelWidth -g pixelHeight "$f" 2>/dev/null
done
```

**Display a verification summary inline:**

```markdown
## Screenshot Capture Summary

| Device | Screenshots | Status |
|--------|------------|--------|
| iPhone 16 Pro Max (6.9") | 5 of 5 | ✓ All captured |
| iPhone 11 Pro Max (6.5") | 5 of 5 | ✓ All captured |
| iPhone 8 Plus (5.5") | 5 of 5 | ✓ All captured |

### Dimension Verification

| File | Expected | Actual | Status |
|------|----------|--------|--------|
| iPhone-6.9/01-Home.png | 1320x2868 | 1320x2868 | ✓ |
| ... | ... | ... | ... |

**Output:** ~/Downloads/AppStoreScreenshots/
```

### Expected folder structure

```
~/Downloads/AppStoreScreenshots/
├── iPhone-6.9/
│   ├── 01-Home.png
│   ├── 02-ItemList.png
│   └── 03-Detail.png
├── iPhone-6.5/
│   └── ...
└── iPhone-5.5/
    └── ...
```

---

## Step 5: Follow-up

```
AskUserQuestion with questions:
[
  {
    "question": "How would you like to proceed?",
    "header": "Next",
    "options": [
      {"label": "Add device frames", "description": "Use fastlane frameit to add device bezels"},
      {"label": "Capture dark mode set", "description": "Repeat with appearance set to dark"},
      {"label": "Capture localized set", "description": "Switch language and repeat for another locale"},
      {"label": "Done", "description": "Screenshots are ready for upload"}
    ],
    "multiSelect": false
  }
]
```

### Localization Workflow

If user selects "Capture localized set":

```bash
# Set simulator language (e.g., Spanish)
xcrun simctl shutdown "iPhone 16 Pro Max"
xcrun simctl boot "iPhone 16 Pro Max" -- -AppleLanguages "(es)" -AppleLocale "es_ES"

# Re-apply status bar, build, install, capture
# Save to locale-specific subfolder:
mkdir -p ~/Downloads/AppStoreScreenshots/es/iPhone-6.9/
```

---

## Tips for Best Results

- **Reset simulator state** for clean screenshots: `xcrun simctl erase "iPhone 16 Pro Max"`
- **Wait 2-3 seconds** after navigation for animations to complete
- **Status bar override resets** when simulator restarts — set it after boot
- **6.9" and 6.7" screenshots** can be reused (same aspect ratio)
- **Create a test account** with sample data for consistent screenshots

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Simulator won't boot | Run `xcrun simctl shutdown all && killall Simulator` then retry |
| Wrong screen captured | Wait longer between navigation and capture |
| Screenshots too small/large | Verify correct simulator with `xcrun simctl list devices booted` |
| Status bar shows wrong time | Re-run `xcrun simctl status_bar` after boot |
| App not launching | Check bundle ID with `xcodebuild -showBuildSettings \| grep PRODUCT_BUNDLE_IDENTIFIER` |
