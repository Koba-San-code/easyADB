## ADB Simple Tool – Documentation

A minimal console tool for daily Android device management via ADB with optional scrcpy integration. Now includes package management panel with state database and undo functionality.

### Components
- `adb_tool_simple.bat` – main script.
- `adb.exe` (if present locally; otherwise uses system adb from PATH).
- `scrcpy/` (optional portable scrcpy; fallback to global `scrcpy`).
- `adb_simple.log` – operation log.
- `Packages_states.txt` – package "database": `name|status|type`.
- `packages_stack.txt` – undo stack (sequence of status changes).
- `screens/` folder – screenshots and screen recordings.

### Main Menu (current)
1. Refresh / Pick device – select first available device.
2. Install ALL APK – install all `*.apk` files in current folder.
3. Install ONE APK – install single APK.
4. Package manager – enter package management panel.
5. Push / Pull – file/folder transfer with OK/FAIL logging.
6. Screenshot – screen capture.
7. Screenrecord – screen recording (up to 180 sec).
8. Reboot menu – reboot / recovery / bootloader.
9. Grant permission – `pm grant`.
10. Revoke permission – `pm revoke`.
11. Wireless ADB – tcpip 5555 / connect / auto-detect IP / disconnect.
12. Device info – SDK + root check.
13. Cleanup temp – removes `/data/local/tmp/shot.png` & `rec.mp4`.
14. Screen stream – scrcpy (with `--audio` attempt).
0. Exit – quit.

### Package Manager Panel
Access via menu item 4.
Sub-menu:
1) Show packages – display with filters:
	- Substring filter (by name substring)
	- Status filter: enabled / disabled / deleted / any
	- Type filter: system / user / other / any (type determined by `pm list packages -s` / `-3`)
	Shows counters: total, enabled, disabled, deleted.
2) Disable package – by number (from current display) or exact name.
3) Enable package – same as above.
4) Uninstall package – changes status in DB to deleted (name remains in list).
5) Refresh statuses – full rescan; updates statuses and types, adds new packages, marks missing as deleted.
6) Export list – creates `packages_export_<status>.txt` by selected status.
7) Mass disable – from file (1 name per line) or inline list (space/comma separators).
8) Mass enable – same as disable.
9) Undo last change – rollback last action (enable/disable status returns; uninstall only marks back previous status without APK reinstallation).
0) Back – return to main menu.

### Package Database Format
`Packages_states.txt` lines like:
```
package.name|enabled|system
package.name2|disabled|user
package.removed|deleted|other
```
Statuses: enabled / disabled / deleted.
Types: system / user / other.

### Undo Stack
`packages_stack.txt` lines:
```
package.name|previous_status|new_status|action
```
`undo` removes last line and attempts reverse action (enable<->disable). For uninstall only restores status in DB (physical installation must be done manually).

### Logging
File: `adb_simple.log`.
Main tokens: script_entry, started, exit, selected=SERIAL, no_device, OK/FAIL install, OK/FAIL uninstall, push_OK / push_FAIL / pull_OK / pull_FAIL, screenshot, screenrecord, cleanup_tmp, scrcpy_exit, packages_refreshed, disable_OK / disable_FAIL, enable_OK / enable_FAIL, uninstall_OK / uninstall_FAIL, export_<status>, undo.
Line format:
```
[DD.MM.YYYY HH:MM:SS,ms] token ...
```

### Architecture
Single .bat file, functions via labels + `call`. Entry point `:__start` jumps over definitions. `ADB_CMD` formed after device selection (or equals `adb`). Package work uses temporary .tmp files and `sort` sorting.

### Features
- Temporary files on device: `/data/local/tmp/shot.png`, `/data/local/tmp/rec.mp4`.
- When no device present, most operations simply won't execute — use item 1 first.
- For mass lists you can mix spaces and commas.
- Pipes in list output are escaped (`^|`).
- Deleted status doesn't remove line from DB, serves for audit.

### scrcpy
Search: local `scrcpy\scrcpy.exe` then global `scrcpy`. First tries `--audio`, otherwise retry without audio. For flag customization edit `:scrcpy_stream` label.

### Typical Scenarios
1. Mass disable unwanted system packages: Refresh → Show (filter system) → Export disabled → Mass disable.
2. Analyze new packages after firmware update: Refresh → Show (filter any) → compare by added lines.
3. Quick recording and screenshots: items 6–7.
4. Undo erroneous disable: Undo last change.

### Limitations
- No automatic restoration (reinstall) after uninstall (only status returns).
- Split-APK / .apks archives not supported.
- Undo stores only sequentially accumulated stack; after exit stack doesn't clear (can manually clear file).

### Extension / Customization
Adding new function: create label `:my_action`, call it from if chain in `:main_menu`, add logging and (if needed) update documentation.

### Troubleshooting
- Empty window / instant exit: check `goto :__start` after initialization.
- adb not found: place `adb.exe` nearby or add to PATH.
- No packages / empty list: check connection (`adb devices`), then Refresh statuses.
- scrcpy won't start: test `scrcpy --version` in separate window.

### Quick Start
1. Connect device and confirm RSA.
2. Run `adb_tool_simple.bat`.
3. Item 1 (Refresh) — see serial.
4. Item 4 (Package manager) → 5 (Refresh statuses) to build DB.
5. Use needed operations.

## Detailed Usage Guide

### Preparation

#### Step 1: Android Device Setup
1. **Enable Developer Mode:**
   - Go to "Settings" → "About phone"
   - Tap 7 times on "Build number"
   - Message "You are now a developer" appears

2. **Enable USB Debugging:**
   - Return to "Settings" → "System" → "Developer options"
   - Enable "USB debugging"
   - Also recommended to enable "Install via USB"

3. **Connect Device:**
   - Use quality USB cable (not charge-only)
   - On first connection RSA key confirmation dialog appears
   - Must check "Always allow from this computer" and press "OK"

#### Step 2: ADB Connection Check
```batch
# Run adb_tool_simple.bat
# Select item 1 (Refresh / Pick device)
```
**What happens:** Script executes `adb devices` and shows connected device list. If device shows as "unauthorized", repeat RSA confirmation step.

**Expected result:**
```
Selected device: ABC123DEF456 (where ABC123DEF456 is your device serial number)
```

### Working with APK Files

#### Installing Single APK
**Scenario:** You have an APK file to install on device.

1. Place APK file in script folder
2. Run script → Item 3 (Install ONE APK)
3. Enter filename (e.g. `myapp.apk`) or full path
4. Wait for installation completion

**Log example:**
```
[13.08.2025 21:30:15,123] install_OK myapp.apk
```

#### Mass APK Installation
**Scenario:** You have folder with multiple APK files for installation.

1. Place all APK files in script folder
2. Item 2 (Install ALL APK)
3. Script automatically finds all *.apk files and installs them in sequence

**What happens:** Script executes `dir /b *.apk` and for each found file calls `adb install -r "filename.apk"`. Flag `-r` allows reinstalling existing applications.

### Application Package Management

#### Initial Package Manager Setup
**Must execute on first use:**

1. Item 4 (Package manager)
2. Item 5 (Refresh statuses)

**What happens:** Script scans all installed packages and creates `Packages_states.txt` database. May take 10-30 seconds depending on app count.

#### Viewing Installed Applications
**Item 1 (Show packages)** - most used function for app analysis.

**Type filtering:**
- `system` - system applications (pre-installed)
- `user` - user applications (installed by you)
- `other` - miscellaneous (rarely used)
- `any` - all applications

**Status filtering:**
- `enabled` - active applications
- `disabled` - disabled applications
- `deleted` - removed applications (remain in DB for audit)
- `any` - all statuses

**Substring filtering:** Enter part of package name for search.

**Practical example:**
```
Substring filter: google
Status filter: enabled
Type filter: system
```
Shows all active Google system applications.

#### Disabling Unwanted Applications

**Method 1: By number from list**
1. Show packages → find application in list
2. Remember its number (e.g. 15)
3. Disable package → enter number 15

**Method 2: By exact name**
1. Disable package → enter full package name
2. Example: `com.facebook.system`

**Important:** Disabling only changes status in Android system (`pm disable`). Application remains installed but doesn't start or update.

#### Mass Application Disabling

**From file:**
1. Create text file with package list (one per line)
2. Mass disable → enter file path
3. Example file `disable_list.txt`:
```
com.facebook.appmanager
com.facebook.system
com.facebook.services
```

**Inline list:**
1. Mass disable → choose inline input
2. Enter packages separated by space or comma:
```
com.facebook.appmanager com.facebook.system, com.facebook.services
```

#### Exporting Lists for Analysis
**Scenario:** Need to create application state backup or share list.

1. Export list → choose status (enabled/disabled/deleted/any)
2. Creates file `packages_export_enabled.txt` with list

**File contents:**
```
com.android.chrome
com.google.android.gms
com.whatsapp
...
```

#### Undo Function
**When to use:** Accidentally disabled important app or want to revert last change.

1. Undo last change
2. Script automatically determines last action and performs reverse operation

**Limitations:** 
- For uninstall only restores status in DB (physical installation needs manual work)
- Only last operation can be undone

### File Transfer

#### Push (sending files to device)
**Scenario:** Need to copy file from computer to phone.

1. Item 5 (Push / Pull)
2. Choose Push
3. Enter local path: `C:\Users\User\Desktop\photo.jpg`
4. Enter device path: `/sdcard/Download/photo.jpg`

**For folders:** Add flag for recursive copying
```
Local path: C:\MyFolder
Device path: /sdcard/MyFolder
```

#### Pull (getting files from device)
**Scenario:** Need to copy file from phone to computer.

1. Push / Pull → Pull
2. Device path: `/sdcard/Download/document.pdf`
3. Local path: `C:\Downloads\document.pdf`

**Popular Android paths:**
- `/sdcard/Download/` - downloads folder
- `/sdcard/DCIM/Camera/` - camera photos
- `/sdcard/Pictures/` - images
- `/sdcard/Documents/` - documents

### Screenshots and Screen Recording

#### Taking Screenshots
1. Item 6 (Screenshot)
2. File automatically saved to `screens/` folder as `screenshot_YYYY-MM-DD_HH-MM-SS.png`

**Technical implementation:**
```batch
adb shell screencap -p /data/local/tmp/shot.png
adb pull /data/local/tmp/shot.png screens/screenshot_timestamp.png
adb shell rm /data/local/tmp/shot.png
```

#### Screen Recording
1. Item 7 (Screenrecord)
2. Enter recording time (maximum 180 seconds)
3. Recording starts automatically
4. File saved to `screens/` as `screenrec_YYYY-MM-DD_HH-MM-SS.mp4`

**During recording:** Use device normally. Everything on screen is recorded.

### Device Management

#### Device Reboot
**Item 8 (Reboot menu)** provides three options:

1. **Normal reboot** - regular restart
2. **Recovery mode** - boot to recovery mode (for updates)
3. **Bootloader** - boot to fastboot mode (for flashing)

**Warning:** Recovery and Bootloader modes are for advanced users.

#### Permission Management
**Granting permissions (Grant):**
1. Item 9 (Grant permission)
2. Enter package name: `com.example.app`
3. Enter permission: `android.permission.CAMERA`

**Revoking permissions (Revoke):**
1. Item 10 (Revoke permission)
2. Same as grant, but removes permission

**Popular permissions:**
- `android.permission.CAMERA` - camera
- `android.permission.RECORD_AUDIO` - microphone
- `android.permission.ACCESS_FINE_LOCATION` - location
- `android.permission.READ_EXTERNAL_STORAGE` - read files
- `android.permission.WRITE_EXTERNAL_STORAGE` - write files

### Wireless Connection (Wireless ADB)

#### Wi-Fi ADB Setup
**Requirements:** Device and computer must be on same Wi-Fi network.

1. **Initial setup (with USB cable):**
   - Connect device via USB
   - Item 11 (Wireless ADB)
   - Choose tcpip mode enable option
   - Device switches to Wi-Fi ADB mode on port 5555

2. **Wi-Fi connection:**
   - Disconnect USB cable
   - In Wireless ADB menu choose connection
   - Script automatically detects device IP address
   - If auto-detection fails, enter IP manually

3. **Disabling Wi-Fi mode:**
   - Choose disconnect to return to USB mode

**Wi-Fi ADB advantages:** Cable-free operation, convenient for app testing.

### Using scrcpy for Screen Mirroring

#### Starting scrcpy
1. Item 14 (Screen stream)
2. Script automatically:
   - Checks for scrcpy in `scrcpy/` folder
   - If not found, uses global installation
   - Tries launch with audio (`--audio`)
   - On error retries without audio

**scrcpy capabilities:**
- Real-time device screen display
- Device control via mouse and keyboard
- Audio transmission (when supported)
- Video recording directly in scrcpy

#### scrcpy Customization
To change launch parameters edit `:scrcpy_stream` function in script:

```batch
# Useful flag examples:
--max-size 1024          # resolution limit
--bit-rate 2M            # video bitrate
--crop 1224:1440:0:0     # screen cropping
--lock-video-orientation # rotation lock
```

### Utility Functions

#### Device Information
**Item 12 (Device info)** shows:
- Android SDK version
- Root access presence
- Device model
- Additional system information

#### Temporary File Cleanup
**Item 13 (Cleanup temp)** removes:
- `/data/local/tmp/shot.png` - temporary screenshot
- `/data/local/tmp/rec.mp4` - temporary screen recording

**When to use:** When device storage is low or after multiple screenshot operations.

### Monitoring and Logging

#### Log Analysis
File `adb_simple.log` contains history of all operations:

```
[13.08.2025 21:30:15,123] script_entry
[13.08.2025 21:30:16,456] selected=ABC123DEF456
[13.08.2025 21:30:45,789] install_OK myapp.apk
[13.08.2025 21:31:12,321] disable_OK com.facebook.system
[13.08.2025 21:31:30,654] screenshot
```

**Error finding:** Look for `_FAIL` tokens for problem diagnosis.

#### State Backup
**Important files to preserve:**
- `Packages_states.txt` - current state of all packages
- `packages_stack.txt` - change history for undo
- `adb_simple.log` - complete operation log

**Restoration:** Copy these files to new script installation to preserve history.

### Practical Usage Scenarios

#### Scenario 1: New Android Device Optimization
1. **Pre-installed app analysis:**
   ```
   Package manager → Refresh statuses
   Show packages → type: system, status: enabled
   Export list → enabled (for backup)
   ```

2. **Disabling unwanted software:**
   ```
   Show packages → substring: "facebook"
   Mass disable → Facebook app list
   Show packages → substring: "google" → selective disabling
   ```

3. **Result verification:**
   ```
   Show packages → status: disabled
   Export list → disabled (for documentation)
   ```

#### Scenario 2: Device Preparation for App Testing
1. **Environment setup:**
   ```
   Wireless ADB → enable tcpip mode
   Disconnect USB, work via Wi-Fi
   Screen stream → launch scrcpy for monitoring
   ```

2. **Test APK installation:**
   ```
   Install ONE APK → test_app_v1.0.apk
   Screenshot → before testing
   ```

3. **Test documentation:**
   ```
   Screenrecord → record testing process
   Push/Pull → exchange test data
   Screenshot → after testing
   ```

#### Scenario 3: Recovery from Failed Changes
1. **Quick undo:**
   ```
   Package manager → Undo last change
   ```

2. **Mass restoration:**
   ```
   Mass enable → from previously exported enabled list
   Refresh statuses → check state
   ```

3. **Problem analysis:**
   ```
   Device info → system check
   View adb_simple.log → search for errors
   ```

### Security Tips

#### What can be safely disabled:
- Social network apps (Facebook, Twitter)
- Games and entertainment apps
- Duplicate apps (multiple browsers)
- Carrier apps (if not used)

#### What should NOT be disabled:
- `com.android.systemui` - system interface
- `com.google.android.gms` - Google Play Services
- `com.android.phone` - phone functions
- `com.android.settings` - system settings

#### Safety measures:
- Always create Export list before mass changes
- Test disabling one app at a time
- Keep critical package list handy
- Use Undo for quick recovery

### Performance Optimization

#### Speeding up work with many packages:
1. Use filters to narrow lists
2. Export frequently used lists to files
3. Apply mass operations instead of individual ones

#### Workflow organization:
1. Create folders for different projects with corresponding APKs
2. Document changes through Export lists
3. Regularly do Refresh statuses after system updates

### License / Usage
Script provided "as is". Use at your own risk. ADB and scrcpy have their own licenses.

## Additional Features and Extensions

### Creating Custom Scripts
For automating repetitive tasks you can create batch files that use ADB Simple Tool functionality:

**Automatic device setup example (`auto_setup.bat`):**
```batch
@echo off
echo Automatic Android device setup...

REM Creating unwanted packages list
echo com.facebook.appmanager > unwanted_packages.txt
echo com.facebook.system >> unwanted_packages.txt
echo com.facebook.services >> unwanted_packages.txt

echo Unwanted packages list created
echo Run ADB Simple Tool and execute:
echo 1. Package manager
echo 2. Mass disable
echo 3. Select file: unwanted_packages.txt
pause
```

### Integration with Other Tools

#### Usage with Android Studio
1. Set up Wireless ADB for wireless development
2. Use Screen stream for app demonstrations
3. Apply Package manager for testing on "clean" devices

#### Compatibility with Other ADB Tools
ADB Simple Tool works correctly alongside:
- Android Studio ADB
- Scrcpy (direct launch)
- Other ADB utilities

**Warning:** Avoid simultaneous use of multiple ADB servers on different ports.

### Advanced Techniques

#### Creating Device Profiles
For different device types (work, gaming, testing) create separate file sets:

```
profiles/
├── gaming_device/
│   ├── packages_to_disable.txt
│   └── packages_to_enable.txt
├── work_device/
│   ├── packages_to_disable.txt
│   └── packages_to_enable.txt
└── test_device/
    ├── packages_to_disable.txt
    └── packages_to_enable.txt
```

#### Automation via Task Scheduler
Create Windows tasks for regular:
- Device screenshot creation
- Package list export for change monitoring
- Temporary file cleanup

### Diagnostics and Problem Solving

#### Common Errors and Solutions

**Error: "device unauthorized"**
- Cause: RSA key not confirmed
- Solution: Reconnect device, confirm dialog on screen

**Error: "no devices/emulators found"**
- Cause: Device not connected or USB debugging disabled
- Solution: Check connection, developer settings

**Error: "Installation failed: INSTALL_FAILED_INSUFFICIENT_STORAGE"**
- Cause: Insufficient device storage
- Solution: Free space or use Cleanup temp

**Error: "Permission denial" during push/pull**
- Cause: No access to specified folder
- Solution: Use /sdcard/ instead of internal system folders

**Error: scrcpy won't start**
- Cause: Missing scrcpy or wrong version
- Solution: Download latest version from https://github.com/Genymobile/scrcpy

#### Debug Mode for Developers
For detailed diagnostics add to script beginning:
```batch
set DEBUG=1
```
This enables additional logging of all ADB commands.

### Security and Recommendations

#### Data Security Recommendations
1. **Don't use on corporate devices** without IT department permission
2. **Create backups** before mass changes
3. **Test on secondary devices** before applying to main one
4. **Document all changes** through Export lists

#### Privacy Compliance
- Get explicit permission when working with others' devices
- Don't save screenshots/recordings without user consent
- Clear logs when transferring script to other users

### Frequently Asked Questions (FAQ)

**Q: Can the script be used on multiple devices simultaneously?**
A: Script works with one device at a time. For multiple devices run separate script instances in different folders.

**Q: Do settings persist after device reboot?**
A: Yes, disabled packages remain disabled. Temporary files (/data/local/tmp/) may be cleared by system.

**Q: Can apps removed via Uninstall be restored?**
A: Uninstall only marks package as deleted in database. For restoration need to reinstall APK file.

**Q: Does script work with Android emulators?**
A: Yes, script is compatible with Android emulators (Android Studio AVD, Bluestacks, etc.).

**Q: Can screenshot folder be changed?**
A: Yes, edit SCREEN_DIR variable at script beginning.

### Command Line for Advanced Users

For integration into custom scripts you can use direct ADB commands:

```batch
REM Getting package list
adb shell pm list packages

REM Disabling package
adb shell pm disable-user --user 0 com.example.package

REM Enabling package
adb shell pm enable com.example.package

REM Checking package status
adb shell pm list packages -d | findstr "com.example.package"

REM Creating screenshot
adb shell screencap -p /sdcard/screenshot.png
adb pull /sdcard/screenshot.png
adb shell rm /sdcard/screenshot.png
```

### System Change Monitoring

#### Tracking New Applications
Regularly execute Export list and compare files to detect:
- New installed applications
- Package status changes
- Potentially unwanted software

#### Creating System State Reports
```batch
REM Creating full report
echo === DEVICE STATE REPORT === > device_report.txt
echo Date: %date% %time% >> device_report.txt
adb get-serialno >> device_report.txt
adb shell getprop ro.build.version.release >> device_report.txt
echo === DISABLED PACKAGES === >> device_report.txt
type packages_export_disabled.txt >> device_report.txt
```

---
If additional automation is needed (e.g. batch reinstall from catalog or group labels), architecture can be extended — submit feature requests.
