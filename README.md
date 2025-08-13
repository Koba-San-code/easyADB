# ADB Simple Tool

[![Language](https://img.shields.io/badge/Language-Batch-blue)](adb_tool_simple.bat)
[![Platform](https://img.shields.io/badge/Platform-Windows-green)](README.md)
[![License](https://img.shields.io/badge/License-As%20Is-orange)](README.md)

A minimal console tool for daily Android device management via ADB with optional scrcpy integration. Features package management with state database and undo functionality.

**Available languages:** [English](README.md) • [Русский](README_ru.md)

## Features

- **Device Management**: Auto-detect and select Android devices
- **APK Installation**: Install single APK or batch install all APKs in folder
- **Package Manager**: Advanced package control with status tracking and undo
- **File Transfer**: Push/Pull files and folders with operation logging
- **Screen Tools**: Screenshots and screen recording (up to 180 seconds)
- **Device Control**: Reboot options (normal/recovery/bootloader)
- **Permissions**: Grant/revoke app permissions
- **Wireless ADB**: TCP/IP connection management with auto IP detection
- **Screen Streaming**: Integrated scrcpy with audio support
- **Operation Logging**: Comprehensive activity logging

## Components

- `adb_tool_simple.bat` - Main script (single file, no dependencies)
- `adb.exe` - Local ADB binary (fallback to system PATH if missing)
- `scrcpy/` - Optional portable scrcpy (fallback to global installation)
- `adb_simple.log` - Operation log file
- `Packages_states.txt` - Package database: `name|status|type`
- `packages_stack.txt` - Undo stack for package operations
- `screens/` - Screenshots and screen recordings output folder

## Main Menu

1. **Refresh / Pick device** - Select first available device
2. **Install ALL APK** - Batch install all `*.apk` files in current folder
3. **Install ONE APK** - Install single APK file
4. **Package manager** - Enter package management panel
5. **Push / Pull** - File/folder transfer with logging
6. **Screenshot** - Capture device screen
7. **Screenrecord** - Record screen (up to 180 seconds)
8. **Reboot menu** - Reboot options (normal/recovery/bootloader)
9. **Grant permission** - Grant app permission (`pm grant`)
10. **Revoke permission** - Revoke app permission (`pm revoke`)
11. **Wireless ADB** - TCP/IP connection management
12. **Device info** - Show SDK version and root status
13. **Cleanup temp** - Remove temporary files from device
14. **Screen stream** - Launch scrcpy with audio support
0. **Exit** - Quit application

## Package Manager Panel

Access via Main Menu → 4. Package manager

### Sub-menu Options:

1. **Show packages** - Display packages with filters:
   - **Substring filter**: Filter by package name
   - **Status filter**: enabled / disabled / deleted / any
   - **Type filter**: system / user / other / any
   - Shows counters: total, enabled, disabled, deleted

2. **Disable package** - Disable by number or exact name
3. **Enable package** - Enable by number or exact name
4. **Uninstall package** - Mark as deleted in database
5. **Refresh statuses** - Full rescan: update statuses/types, add new packages
6. **Export list** - Generate `packages_export_<status>.txt` files
7. **Mass disable** - Bulk disable from file or inline list
8. **Mass enable** - Bulk enable from file or inline list
9. **Undo last change** - Revert last operation
0. **Back** - Return to main menu

### Package Database Format

`Packages_states.txt` contains lines:
```
package.name|enabled|system
package.name2|disabled|user
package.removed|deleted|other
```

**Statuses**: `enabled` / `disabled` / `deleted`  
**Types**: `system` / `user` / `other`

### Undo Stack

`packages_stack.txt` stores operation history:
```
package.name|previous_status|new_status|action
```

Undo reverts the last operation (enable↔disable). For uninstall, only restores database status (manual reinstall required).

## Quick Start

1. Connect Android device and accept RSA fingerprint
2. Run `adb_tool_simple.bat`
3. Select **1** (Refresh) to detect device
4. Select **4** (Package manager) → **5** (Refresh statuses) to build database
5. Use desired operations

## Common Use Cases

- **Mass system app management**: Refresh → Show (filter system) → Export → Mass disable
- **Firmware update analysis**: Refresh → Show → compare new packages
- **Quick screenshots/recording**: Menu items 6-7
- **Mistake recovery**: Undo last change

## Logging

All operations are logged to `adb_simple.log` with timestamps:
```
[DD.MM.YYYY HH:MM:SS,ms] token ...
```

**Key tokens**: `script_entry`, `selected=SERIAL`, `OK/FAIL install`, `push_OK/FAIL`, `screenshot`, `screenrecord`, `packages_refreshed`, `disable_OK/FAIL`, `undo`

## Technical Details

- **Architecture**: Single .bat file with label-based functions
- **Device targeting**: Uses `ADB_CMD` after device selection
- **Temporary files**: `/data/local/tmp/shot.png`, `/data/local/tmp/rec.mp4`
- **Sorting**: Uses Windows `sort` command for package lists
- **Error handling**: Graceful fallback when no device connected

## scrcpy Integration

Search order: `scrcpy\scrcpy.exe` → global `scrcpy`  
Attempts with `--audio` flag, falls back without audio on failure.  
To customize flags, edit `:scrcpy_stream` label in the script.

## Requirements

- Windows (batch script)
- ADB (included or in PATH)
- Android device with USB debugging enabled
- Optional: scrcpy for screen streaming

## Limitations

- No automatic reinstall after uninstall (database status only)
- No split-APK (.apks) support
- Undo stack persists between sessions (manual cleanup if needed)

## Customization

To add new features:
1. Create label `:my_action`
2. Add to if-chain in `:main_menu`
3. Add logging calls
4. Update documentation

## Troubleshooting

- **Empty window/instant exit**: Check `goto :__start` after initialization
- **ADB not found**: Place `adb.exe` in script folder or add to PATH
- **No packages/empty list**: Check connection (`adb devices`), run Refresh statuses
- **scrcpy won't start**: Test `scrcpy --version` in separate terminal

## License

Provided "as is". Use at your own risk.  
ADB and scrcpy have their own respective licenses.

---

For additional automation (batch reinstall, package groups), the architecture can be extended - please submit feature requests.
