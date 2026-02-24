---
name: release-screenshots
description: Capture App Store screenshots across all required device sizes using XcodeBuildMCP automation
version: 1.0.0
author: Terry Nyberg
license: MIT
allowed-tools: [mcp__XcodeBuildMCP, Bash]
metadata:
  tier: execution
  category: release
---

# Release Screenshots

> **Quick Ref:** Automate App Store screenshots across all required device sizes (6.9", 6.5", 5.5") using XcodeBuildMCP.

**YOU MUST EXECUTE THIS WORKFLOW. Do not just describe it.**

Automate capturing App Store screenshots across all required device sizes.

## When to Use This Skill

Use this skill when:
- Preparing screenshots for App Store submission
- Updating screenshots after UI changes
- Capturing screenshots for multiple device sizes
- Creating a consistent screenshot set across devices

## App Store Required Sizes

### iPhone Screenshots (Required)

| Display Size | Devices | Resolution | Simulator Name |
|--------------|---------|------------|----------------|
| **6.9"** | iPhone 16 Pro Max | 1320 x 2868 | iPhone 16 Pro Max |
| **6.7"** | iPhone 16 Plus, 15 Plus, 14 Plus | 1290 x 2796 | iPhone 16 Plus |
| **6.5"** | iPhone 11 Pro Max, XS Max | 1242 x 2688 | iPhone 11 Pro Max |
| **5.5"** | iPhone 8 Plus | 1242 x 2208 | iPhone 8 Plus |

### iPad Screenshots (If Universal App)

| Display Size | Devices | Resolution | Simulator Name |
|--------------|---------|------------|----------------|
| **12.9" (6th gen)** | iPad Pro 12.9" | 2048 x 2732 | iPad Pro 12.9-inch (6th generation) |
| **12.9" (2nd gen)** | iPad Pro 12.9" (older) | 2048 x 2732 | iPad Pro 12.9-inch (2nd generation) |

## Workflow

### Phase 1: Setup

1. **Confirm screens to capture**

Ask the user which screens they want to screenshot:
```
Which screens do you want to capture? (e.g., Home, Item Detail, Settings, etc.)
```

2. **Confirm device sizes**

```
Which device sizes do you need?

iPhone (select all that apply):
[ ] 6.9" - iPhone 16 Pro Max (required for new submissions)
[ ] 6.7" - iPhone 16 Plus
[ ] 6.5" - iPhone 11 Pro Max (required)
[ ] 5.5" - iPhone 8 Plus (required)

iPad (if universal app):
[ ] 12.9" iPad Pro (6th gen)
[ ] 12.9" iPad Pro (2nd gen)
```

3. **Create output directory**

```bash
mkdir -p ~/Downloads/AppStoreScreenshots/{iPhone-6.9,iPhone-6.7,iPhone-6.5,iPhone-5.5,iPad-12.9}
```

### Phase 2: Capture Screenshots

For each device size, follow this process:

#### Step 1: List available simulators
```
mcp__XcodeBuildMCP__list_sims({ enabled: true })
```

#### Step 2: Set session defaults for target device
```
mcp__XcodeBuildMCP__session-set-defaults({
  simulatorName: "iPhone 16 Pro Max",
  scheme: "<APP_SCHEME>"
})
```

#### Step 3: Boot simulator
```
mcp__XcodeBuildMCP__boot_sim()
```

#### Step 4: Build and run app
```
mcp__XcodeBuildMCP__build_run_sim()
```

#### Step 5: Wait for app launch, then navigate to first screen
- Use `mcp__XcodeBuildMCP__tap()` to navigate
- Use `mcp__XcodeBuildMCP__snapshot_ui()` to see current UI state
- Use `mcp__XcodeBuildMCP__type_text()` if needed

#### Step 6: Capture screenshot
```
mcp__XcodeBuildMCP__screenshot({ returnFormat: "path" })
```

#### Step 7: Move screenshot to organized folder
```bash
mv /path/to/screenshot.png ~/Downloads/AppStoreScreenshots/iPhone-6.9/01-Home.png
```

#### Step 8: Navigate to next screen and repeat

#### Step 9: Switch to next device and repeat all screens

### Phase 3: Automation Script

For hands-off capture, create a navigation script:

```swift
// Define screens to capture with navigation steps
let screens = [
    ("01-Home", []),  // No navigation needed, starts here
    ("02-ItemList", [.tap(id: "tab-items")]),
    ("03-ItemDetail", [.tap(id: "item-row-0")]),
    ("04-AddItem", [.tap(id: "action-add")]),
    ("05-Settings", [.tap(id: "tab-settings")])
]
```

Then for each device:
```
1. Boot simulator
2. Build and install app
3. For each screen:
   a. Execute navigation steps
   b. Wait for animations (0.5s delay)
   c. Capture screenshot
   d. Save with proper name
4. Shutdown simulator
5. Move to next device
```

### Phase 4: Output Organization

Final folder structure:
```
~/Downloads/AppStoreScreenshots/
├── iPhone-6.9/
│   ├── 01-Home.png
│   ├── 02-ItemList.png
│   ├── 03-ItemDetail.png
│   ├── 04-AddItem.png
│   └── 05-Settings.png
├── iPhone-6.7/
│   └── ...
├── iPhone-6.5/
│   └── ...
├── iPhone-5.5/
│   └── ...
└── iPad-12.9/
    └── ...
```

## Quick Capture Commands

### Single Device Quick Capture

```
# Boot and run on iPhone 16 Pro Max
mcp__XcodeBuildMCP__session-set-defaults({ simulatorName: "iPhone 16 Pro Max" })
mcp__XcodeBuildMCP__boot_sim()
mcp__XcodeBuildMCP__build_run_sim()

# Wait for app to launch, then capture
mcp__XcodeBuildMCP__screenshot({ returnFormat: "path" })
```

### Navigate and Capture

```
# See current UI
mcp__XcodeBuildMCP__snapshot_ui()

# Tap element by accessibility identifier
mcp__XcodeBuildMCP__tap({ id: "tab-items" })

# Wait briefly for animations
# Then capture
mcp__XcodeBuildMCP__screenshot({ returnFormat: "path" })
```

### Capture All Required Devices (Sequential)

```bash
# Define devices
DEVICES=("iPhone 16 Pro Max" "iPhone 16 Plus" "iPhone 11 Pro Max" "iPhone 8 Plus")
FOLDERS=("iPhone-6.9" "iPhone-6.7" "iPhone-6.5" "iPhone-5.5")

# For each device, Claude will:
# 1. Set simulator defaults
# 2. Boot and run app
# 3. Navigate through screens
# 4. Capture and organize screenshots
```

## Tips for Best Results

### Before Capturing

1. **Reset simulator state** (optional, for clean screenshots)
   ```bash
   xcrun simctl erase "iPhone 16 Pro Max"
   ```

2. **Set appearance mode**
   ```bash
   xcrun simctl ui "iPhone 16 Pro Max" appearance light
   # or: appearance dark
   ```

3. **Set status bar** (clean time, full battery)
   ```bash
   xcrun simctl status_bar "iPhone 16 Pro Max" override \
     --time "9:41" \
     --batteryState charged \
     --batteryLevel 100 \
     --cellularMode active \
     --cellularBars 4
   ```

4. **Disable keyboard autocorrect bar** for cleaner shots

### During Capture

- Wait 0.5-1s after navigation for animations to complete
- Use `snapshot_ui()` to verify correct screen before capturing
- Check for any alerts or dialogs that might appear

### After Capturing

- Verify all screenshots have correct dimensions
- Check for any UI cut-offs or issues
- Consider adding device frames with fastlane frameit or Rotato

## Adding Device Frames (Optional)

After capturing raw screenshots, add device frames:

### Using fastlane frameit

```bash
# Install
gem install fastlane

# Add frames
cd ~/Downloads/AppStoreScreenshots
fastlane frameit
```

### Using Rotato (Mac App)

1. Open Rotato
2. Import screenshots
3. Select device frame
4. Export with frame

## Localization Support

For localized screenshots, repeat the process with different locale settings:

```bash
# Set simulator locale
xcrun simctl spawn "iPhone 16 Pro Max" defaults write \
  -globalDomain AppleLocale -string "fr_FR"
xcrun simctl spawn "iPhone 16 Pro Max" defaults write \
  -globalDomain AppleLanguages -array "fr"
```

Then organize by locale:
```
~/Downloads/AppStoreScreenshots/
├── en-US/
│   ├── iPhone-6.9/
│   └── ...
├── fr-FR/
│   ├── iPhone-6.9/
│   └── ...
```

## Troubleshooting

### Simulator won't boot
```bash
xcrun simctl shutdown all
killall Simulator
# Then try again
```

### Wrong screen captured
- Use `snapshot_ui()` to verify current state
- Add longer delays between navigation steps
- Check for unexpected alerts/dialogs

### Screenshots too small/large
- Verify correct simulator is running
- Check `xcrun simctl list devices` for device names

## Example Session

```
User: /release-screenshots

Claude: I'll help you capture App Store screenshots. First, which screens do you want to capture?

User: Home screen, Item list, Item detail, and Settings

Claude: Got it. Which device sizes do you need?
- iPhone 6.9" (iPhone 16 Pro Max) - recommended
- iPhone 6.5" (iPhone 11 Pro Max) - required
- iPhone 5.5" (iPhone 8 Plus) - required
- iPad 12.9" (if universal)

User: All iPhone sizes, no iPad

Claude: I'll capture 4 screens across 3 iPhone sizes (12 total screenshots).
Starting with iPhone 16 Pro Max...

[Proceeds to boot sim, build app, navigate, and capture each screen]
[Then repeats for iPhone 11 Pro Max and iPhone 8 Plus]

Claude: Done! Screenshots saved to:
~/Downloads/AppStoreScreenshots/
├── iPhone-6.9/ (4 screenshots)
├── iPhone-6.5/ (4 screenshots)
└── iPhone-5.5/ (4 screenshots)

Would you like me to add device frames using fastlane frameit?
```

## Notes

- Always capture iPhone 6.5" and 5.5" - these are required by App Store
- iPhone 6.9"/6.7" screenshots can be reused (same aspect ratio)
- Status bar override resets when simulator restarts
- Consider creating a test account with sample data for consistent screenshots
