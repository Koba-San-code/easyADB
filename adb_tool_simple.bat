@echo off
REM -------------------------------------------------------------
REM ADB SIMPLE TOOL (clean build)
REM Basic operations: pick device, install/uninstall, list pkgs,
REM push/pull, screenshot, screenrecord, reboot, permissions,
REM wireless ADB, device info.
REM -------------------------------------------------------------
setlocal EnableExtensions EnableDelayedExpansion
title ADB Simple Tool
set "LOG_FILE=%~dp0adb_simple.log"
set "TMP_DIR=/data/local/tmp"
set "ADB=adb"
set "SCREEN_DIR=%~dp0screens"
set "PKG_DB=%~dp0Packages_states.txt"
set "PKG_STACK=%~dp0packages_stack.txt"
if not exist "%SCREEN_DIR%" mkdir "%SCREEN_DIR%" >nul 2>&1
goto :__start

:: Logging helper
:log
set "_LOG_ARGS=%*"
>>"%LOG_FILE%" echo [%date% %time%] %_LOG_ARGS%
set "_LOG_ARGS="
goto :eof

:require_adb
where %ADB% >nul 2>&1
if errorlevel 1 (
  if exist "%~dp0adb.exe" (
    set "ADB=%~dp0adb.exe"
  ) else (
    echo ERROR: adb not found in PATH and local folder.
    pause
    exit /b 1
  )
)
call :log use_adb=%ADB%
goto :eof

:pick_device
set "DEVICE_SERIAL="
for /f "skip=1 tokens=1,2" %%a in ('%ADB% devices') do (
  if "%%b"=="device" if not defined DEVICE_SERIAL set "DEVICE_SERIAL=%%a"
)
if defined DEVICE_SERIAL (
  set "ADB_CMD=%ADB% -s %DEVICE_SERIAL%"
  call :log selected=%DEVICE_SERIAL%
) else (
  set "ADB_CMD=%ADB%"
  call :log no_device
)
goto :eof

:check_any_device
set "_have=0"
for /f "skip=1 tokens=1,2" %%a in ('%ADB% devices') do (
  if "%%b"=="device" set "_have=1"
)
if "%_have%"=="0" (
  echo No authorized device found. Connect & authorize, then choose option 1.
)
set "_have="
goto :eof

:install_folder
call :check_any_device
echo Installing all *.apk in current folder...
for %%f in (*.apk) do (
  echo === Install: %%f ===
  %ADB_CMD% install -r "%%f" >nul 2>&1 && (echo OK: %%f & call :log OK install %%f) || (echo FAIL: %%f & call :log FAIL install %%f)
)
echo Done.
pause
goto :eof

:install_one
set "APK_PATH="
set /p "APK_PATH=APK path: "
if not defined APK_PATH goto :eof
if not exist "%APK_PATH%" (echo Not found.&goto :eof)
echo Installing %APK_PATH% ...
%ADB_CMD% install -r "%APK_PATH%" && (echo OK & call :log OK install "%APK_PATH%") || (echo FAIL & call :log FAIL install "%APK_PATH%")
pause
goto :eof

:uninstall_pkg
set "PKG="
set /p "PKG=Package to uninstall: "
if not defined PKG goto :eof
%ADB_CMD% uninstall "%PKG%" && (echo OK & call :log OK uninstall %PKG%) || (echo FAIL & call :log FAIL uninstall %PKG%)
pause
goto :eof

:list_packages
echo Listing packages (may take a while)...
%ADB_CMD% shell pm list packages 2>nul
pause
goto :eof

:packages_panel
cls
echo ================= PACKAGE PANEL =================
echo Device: %DEVICE_SERIAL%
echo DB: %PKG_DB%
echo.
echo 1) Show packages (filter/status/type)
echo 2) Disable package (by # or name)
echo 3) Enable package (by # or name)
echo 4) Uninstall package (by # or name)
echo 5) Refresh statuses (rebuild DB)
echo 6) Export list (by status)
echo 7) Mass disable (from file/list)
echo 8) Mass enable (from file/list)
echo 9) Undo last change
echo 0) Back
echo.
set /p "PCHOICE=Select: "
if "%PCHOICE%"=="1" (call :packages_show) else if "%PCHOICE%"=="2" (call :packages_disable) else if "%PCHOICE%"=="3" (call :packages_enable) else if "%PCHOICE%"=="4" (call :packages_uninstall) else if "%PCHOICE%"=="5" (call :packages_refresh) else if "%PCHOICE%"=="6" (call :packages_export) else if "%PCHOICE%"=="7" (call :packages_mass_disable) else if "%PCHOICE%"=="8" (call :packages_mass_enable) else if "%PCHOICE%"=="9" (call :packages_undo) else if "%PCHOICE%"=="0" (goto :eof) else (echo Invalid & pause)
goto :packages_panel
goto :eof

:packages_refresh
echo Refreshing package DB (full)...
call :require_adb
if not defined ADB_CMD call :pick_device
set "TMP_ALL=%~dp0_pkgs_all.tmp"
set "TMP_DISABLED=%~dp0_pkgs_disabled.tmp"
set "TMP_SYS=%~dp0_pkgs_sys.tmp"
set "TMP_USER=%~dp0_pkgs_user.tmp"
set "TMP_ALL_CLEAN=%~dp0_pkgs_all_clean.tmp"
set "TMP_DISABLED_CLEAN=%~dp0_pkgs_disabled_clean.tmp"
set "TMP_SYS_CLEAN=%~dp0_pkgs_sys_clean.tmp"
set "TMP_USER_CLEAN=%~dp0_pkgs_user_clean.tmp"
del /f /q "%TMP_ALL%" "%TMP_DISABLED%" "%TMP_SYS%" "%TMP_USER%" "%TMP_ALL_CLEAN%" "%TMP_DISABLED_CLEAN%" "%TMP_SYS_CLEAN%" "%TMP_USER_CLEAN%" >nul 2>&1
%ADB_CMD% shell pm list packages 2>nul > "%TMP_ALL%"
%ADB_CMD% shell pm list packages -d 2>nul > "%TMP_DISABLED%"
%ADB_CMD% shell pm list packages -s 2>nul > "%TMP_SYS%"
%ADB_CMD% shell pm list packages -3 2>nul > "%TMP_USER%"
for /f "tokens=2 delims=:" %%p in (%TMP_ALL%) do if not "%%p"=="" echo %%p>>"%TMP_ALL_CLEAN%"
for /f "tokens=2 delims=:" %%p in (%TMP_DISABLED%) do if not "%%p"=="" echo %%p>>"%TMP_DISABLED_CLEAN%"
for /f "tokens=2 delims=:" %%p in (%TMP_SYS%) do if not "%%p"=="" echo %%p>>"%TMP_SYS_CLEAN%"
for /f "tokens=2 delims=:" %%p in (%TMP_USER%) do if not "%%p"=="" echo %%p>>"%TMP_USER_CLEAN%"
del /f /q "%PKG_DB%.new" >nul 2>&1
(
  for /f "usebackq tokens=*" %%p in ("%TMP_ALL_CLEAN%") do (
    set "status=enabled"
    findstr /i /x "%%p" "%TMP_DISABLED_CLEAN%" >nul 2>&1 && set "status=disabled"
    set "ptype=other"
    findstr /i /x "%%p" "%TMP_SYS_CLEAN%" >nul 2>&1 && set "ptype=system"
    findstr /i /x "%%p" "%TMP_USER_CLEAN%" >nul 2>&1 && set "ptype=user"
    echo %%p^|!status!^|!ptype!
  )
  if exist "%PKG_DB%" for /f "usebackq tokens=1,2,3 delims=|" %%l in ("%PKG_DB%") do (
    findstr /i /x "%%l" "%TMP_ALL_CLEAN%" >nul 2>&1 || (
      set "oldtype=%%n"
      if "!oldtype!"=="" set "oldtype=other"
      echo %%l^|deleted^|!oldtype!
    )
  )
) > "%PKG_DB%.new"
sort "%PKG_DB%.new" /o "%PKG_DB%" >nul 2>&1
del /f /q "%PKG_DB%.new" "%TMP_ALL%" "%TMP_DISABLED%" "%TMP_SYS%" "%TMP_USER%" "%TMP_ALL_CLEAN%" "%TMP_DISABLED_CLEAN%" "%TMP_SYS_CLEAN%" "%TMP_USER_CLEAN%" >nul 2>&1
echo Done.
call :log packages_refreshed
pause
goto :eof

:packages_show
if not exist "%PKG_DB%" call :packages_refresh
if not exist "%PKG_DB%" (echo DB missing.&pause&goto :eof)
set "FILTER="
set "FSTATUS=any"
set "FTYPE=any"
set /p "FILTER=Substring filter (blank=all): "
set /p "FSTATUS=Status filter [enabled|disabled|deleted|any]: "
if /i not "%FSTATUS%"=="enabled" if /i not "%FSTATUS%"=="disabled" if /i not "%FSTATUS%"=="deleted" set "FSTATUS=any"
set /p "FTYPE=Type filter [system|user|other|any]: "
if /i not "%FTYPE%"=="system" if /i not "%FTYPE%"=="user" if /i not "%FTYPE%"=="other" set "FTYPE=any"
set /a TOTAL=0
set /a CNT_ENABLED=0
set /a CNT_DISABLED=0
set /a CNT_DELETED=0
for /f "usebackq tokens=1,2,3 delims=|" %%a in ("%PKG_DB%") do (
  set "pn=%%a"
  set "ps=%%b"
  set "pt=%%c"
  if "!pt!"=="" set "pt=other"
  set /a TOTAL+=1
  if /i "!ps!"=="enabled" set /a CNT_ENABLED+=1
  if /i "!ps!"=="disabled" set /a CNT_DISABLED+=1
  if /i "!ps!"=="deleted" set /a CNT_DELETED+=1
)
echo Totals: all=%TOTAL% enabled=%CNT_ENABLED% disabled=%CNT_DISABLED% deleted=%CNT_DELETED%
echo.
set /a _idx=0
echo #  ^| Status     ^| Type    ^| Package
echo --------------------------------------------------------------
for /f "usebackq tokens=1,2,3 delims=|" %%a in ("%PKG_DB%") do (
  set "pn=%%a"
  set "ps=%%b"
  set "pt=%%c"
  if "!pt!"=="" set "pt=other"
  set "_show=1"
  if not "!FILTER!"=="" (echo !pn!| find /i "!FILTER!" >nul 2>&1 || set "_show=0")
  if /i not "!FSTATUS!"=="any" if /i not "!ps!"=="!FSTATUS!" set "_show=0"
  if /i not "!FTYPE!"=="any" if /i not "!pt!"=="!FTYPE!" set "_show=0"
  if "!_show!"=="1" (
    set /a _idx+=1
    echo !_idx! ^| !ps! ^| !pt! ^| !pn!
  )
)
set _idx=
pause
goto :eof

:packages_resolve_input
REM Input: %1 variable name for result
set "_RES_VAR=%~1"
set "INPUT="
set /p "INPUT=Package name or #: "
if not defined INPUT goto :eof
set "FIRST=%INPUT:~0,1%"
set "TARGET_PKG="
if "%FIRST%" GEQ "0" if "%FIRST%" LEQ "9" (
  set /a WANT_NUM=%INPUT%
  if not exist "%PKG_DB%" call :packages_refresh
  set /a _idx=0
  for /f "usebackq tokens=1,2 delims=|" %%a in ("%PKG_DB%") do (
    set /a _idx+=1
    if !_idx!==!WANT_NUM! if not defined TARGET_PKG set "TARGET_PKG=%%a"
  )
  set _idx=
) else (
  set "TARGET_PKG=%INPUT%"
)
if not defined TARGET_PKG (echo Not found.&goto :eof)
set "%_RES_VAR%=%TARGET_PKG%"
goto :eof

:packages_disable
if not exist "%PKG_DB%" call :packages_refresh
call :packages_resolve_input TARGET_PKG
if not defined TARGET_PKG goto :eof
for /f "usebackq tokens=1,2,3 delims=|" %%a in ("%PKG_DB%") do if /i "%%a"=="%TARGET_PKG%" set "PREV_STATUS=%%b"
%ADB_CMD% shell pm disable-user --user 0 "%TARGET_PKG%" >nul 2>&1 && (echo Disabled & call :log disable_OK %TARGET_PKG% & call :packages_update_status "%TARGET_PKG%" disabled & echo %TARGET_PKG%^|%PREV_STATUS%^|disabled^|disable>>"%PKG_STACK%") || (echo FAIL & call :log disable_FAIL %TARGET_PKG%)
pause
goto :eof

:packages_enable
if not exist "%PKG_DB%" call :packages_refresh
call :packages_resolve_input TARGET_PKG
if not defined TARGET_PKG goto :eof
for /f "usebackq tokens=1,2,3 delims=|" %%a in ("%PKG_DB%") do if /i "%%a"=="%TARGET_PKG%" set "PREV_STATUS=%%b"
%ADB_CMD% shell pm enable "%TARGET_PKG%" >nul 2>&1 && (echo Enabled & call :log enable_OK %TARGET_PKG% & call :packages_update_status "%TARGET_PKG%" enabled & echo %TARGET_PKG%^|%PREV_STATUS%^|enabled^|enable>>"%PKG_STACK%") || (echo FAIL & call :log enable_FAIL %TARGET_PKG%)
pause
goto :eof

:packages_uninstall
if not exist "%PKG_DB%" call :packages_refresh
call :packages_resolve_input TARGET_PKG
if not defined TARGET_PKG goto :eof
for /f "usebackq tokens=1,2,3 delims=|" %%a in ("%PKG_DB%") do if /i "%%a"=="%TARGET_PKG%" set "PREV_STATUS=%%b"
%ADB_CMD% uninstall "%TARGET_PKG%" >nul 2>&1 && (echo Uninstalled & call :log uninstall_OK %TARGET_PKG% & call :packages_update_status "%TARGET_PKG%" deleted & echo %TARGET_PKG%^|%PREV_STATUS%^|deleted^|uninstall>>"%PKG_STACK%") || (echo FAIL & call :log uninstall_FAIL %TARGET_PKG%)
pause
goto :eof

:packages_update_status
REM Args: %1 package, %2 new_status
set "_UP_PKG=%~1"
set "_NEW_STATUS=%~2"
if not exist "%PKG_DB%" goto :eof
del /f /q "%PKG_DB%.tmp" >nul 2>&1
for /f "usebackq tokens=1,2,3 delims=|" %%a in ("%PKG_DB%") do (
  set "tptype=%%c"
  if "!tptype!"=="" set "tptype=other"
  if /i "%%a"=="%_UP_PKG%" (echo %%a^|%_NEW_STATUS%^|!tptype!>>"%PKG_DB%.tmp") else (echo %%a^|%%b^|!tptype!>>"%PKG_DB%.tmp")
)
move /y "%PKG_DB%.tmp" "%PKG_DB%" >nul 2>&1
goto :eof

:packages_export
if not exist "%PKG_DB%" call :packages_refresh
set "EX_STATUS="
set /p "EX_STATUS=Export status (enabled/disabled/deleted): "
if /i not "%EX_STATUS%"=="enabled" if /i not "%EX_STATUS%"=="disabled" if /i not "%EX_STATUS%"=="deleted" (echo Invalid.&pause&goto :eof)
set "OUT_FILE=%~dp0packages_export_%EX_STATUS%.txt"
del /f /q "%OUT_FILE%" >nul 2>&1
for /f "usebackq tokens=1,2,3 delims=|" %%a in ("%PKG_DB%") do if /i "%%b"=="%EX_STATUS%" echo %%a>>"%OUT_FILE%"
echo Saved: %OUT_FILE%
call :log export_%EX_STATUS%
pause
goto :eof

:packages_mass_disable
echo Mass disable: file path (one package per line) or leave blank for inline list
set "LIST_PATH="
set /p "LIST_PATH=File: "
set "INLINE_LIST="
if not defined LIST_PATH set /p "INLINE_LIST=Inline list (space/comma separated): "
if not defined LIST_PATH if not defined INLINE_LIST goto :eof
if defined LIST_PATH if not exist "%LIST_PATH%" (echo File not found.&pause&goto :eof)
if defined LIST_PATH (
  for /f "usebackq tokens=*" %%p in ("%LIST_PATH%") do call :_packages_mass_disable_one "%%p"
) else (
  for %%p in (%INLINE_LIST:,= %) do call :_packages_mass_disable_one "%%p"
)
echo Done.
pause
goto :eof

:_packages_mass_disable_one
set "PKX=%~1"
if "%PKX%"=="" goto :eof
for /f "usebackq tokens=1,2,3 delims=|" %%a in ("%PKG_DB%") do if /i "%%a"=="%PKX%" set "PREV_STATUS=%%b"
%ADB_CMD% shell pm disable-user --user 0 "%PKX%" >nul 2>&1 && (echo Disabled %PKX% & call :packages_update_status "%PKX%" disabled & echo %PKX%^|%PREV_STATUS%^|disabled^|disable>>"%PKG_STACK%" & call :log disable_OK %PKX%) || (echo FAIL %PKX% & call :log disable_FAIL %PKX%)
goto :eof

:packages_mass_enable
echo Mass enable: file path (one package per line) or leave blank for inline list
set "LIST_PATH="
set /p "LIST_PATH=File: "
set "INLINE_LIST="
if not defined LIST_PATH set /p "INLINE_LIST=Inline list (space/comma separated): "
if not defined LIST_PATH if not defined INLINE_LIST goto :eof
if defined LIST_PATH if not exist "%LIST_PATH%" (echo File not found.&pause&goto :eof)
if defined LIST_PATH (
  for /f "usebackq tokens=*" %%p in ("%LIST_PATH%") do call :_packages_mass_enable_one "%%p"
) else (
  for %%p in (%INLINE_LIST:,= %) do call :_packages_mass_enable_one "%%p"
)
echo Done.
pause
goto :eof

:_packages_mass_enable_one
set "PKX=%~1"
if "%PKX%"=="" goto :eof
for /f "usebackq tokens=1,2,3 delims=|" %%a in ("%PKG_DB%") do if /i "%%a"=="%PKX%" set "PREV_STATUS=%%b"
%ADB_CMD% shell pm enable "%PKX%" >nul 2>&1 && (echo Enabled %PKX% & call :packages_update_status "%PKX%" enabled & echo %PKX%^|%PREV_STATUS%^|enabled^|enable>>"%PKG_STACK%" & call :log enable_OK %PKX%) || (echo FAIL %PKX% & call :log enable_FAIL %PKX%)
goto :eof

:packages_undo
if not exist "%PKG_STACK%" (echo Nothing to undo.&pause&goto :eof)
set "LAST_LINE="
for /f "usebackq delims=" %%l in ("%PKG_STACK%") do set "LAST_LINE=%%l"
if not defined LAST_LINE (echo Nothing to undo.&pause&goto :eof)
for /f "tokens=1,2,3,4 delims=|" %%a in ("%PKG_STACK%") do set "_TMP_DUMP=1" >nul
for /f "tokens=1,2,3,4 delims=|" %%p in ("%PKG_STACK%") do set "_TMP_DUMP=1" >nul
for /f "tokens=1,2,3,4 delims=|" %%a in ("%PKG_STACK%") do (
  rem just to force delayed expansion caching
)
for /f "tokens=1,2,3,4 delims=|" %%a in ("%PKG_STACK%") do set "_TMP_LAST=%%a|%%b|%%c|%%d" >nul
for /f "tokens=1,2,3,4 delims=|" %%a in ("%PKG_STACK%") do (
  rem placeholder
)
for /f "tokens=1,2,3,4 delims=|" %%x in ("%PKG_STACK%") do set "_DISCARD=1" >nul
for /f "tokens=1,2,3,4 delims=|" %%a in ("%PKG_STACK%") do set "_UNUSED=1" >nul
for /f "tokens=1,2,3,4 delims=|" %%a in ("%PKG_STACK%") do set "_UNUSED2=1" >nul
for /f "tokens=1,2,3,4 delims=|" %%a in ("%PKG_STACK%") do set "_UNUSED3=1" >nul
for /f "tokens=1,2,3,4 delims=|" %%a in ("%PKG_STACK%") do set "_UNUSED4=1" >nul
for /f "tokens=1,2,3,4 delims=|" %%a in ("%PKG_STACK%") do set "_UNUSED5=1" >nul
for /f "tokens=1,2,3,4 delims=|" %%A in ("%PKG_STACK%") do set "_UNUSED6=1" >nul
REM Extract last line components
for /f "tokens=1,2,3,4 delims=|" %%a in ("%PKG_STACK%") do set "PKG_LAST=%%a" & set "PREV_LAST=%%b" & set "NEW_LAST=%%c" & set "ACT_LAST=%%d"
REM Recompute last line precisely
for /f "usebackq tokens=1,2,3,4 delims=|" %%a in ("%PKG_STACK%") do set "LAST_LINE=%%a|%%b|%%c|%%d"
REM Build without last line
del /f /q "%PKG_STACK%.tmp" >nul 2>&1
set "_cur="
for /f "usebackq tokens=1,2,3,4 delims=|" %%a in ("%PKG_STACK%") do (
  set "_line=%%a|%%b|%%c|%%d"
  if not "!_line!"=="!LAST_LINE!" echo !_line!>>"%PKG_STACK%.tmp"
)
move /y "%PKG_STACK%.tmp" "%PKG_STACK%" >nul 2>&1
echo Undo: %PKG_LAST% (%ACT_LAST% -> %PREV_LAST%)
REM Perform reverse action if possible
if /i "%ACT_LAST%"=="disable" if /i "%PREV_LAST%"=="enabled" (%ADB_CMD% shell pm enable "%PKG_LAST%" >nul 2>&1)
if /i "%ACT_LAST%"=="enable" if /i "%PREV_LAST%"=="disabled" (%ADB_CMD% shell pm disable-user --user 0 "%PKG_LAST%" >nul 2>&1)
if /i "%ACT_LAST%"=="uninstall" (
  echo (Package was uninstalled; automatic reinstall not supported. Status restored only.)
)
call :packages_update_status "%PKG_LAST%" "%PREV_LAST%"
call :log undo %PKG_LAST% %ACT_LAST%
pause
goto :eof

:push_pull
echo 1) Push file/folder
echo 2) Pull file/folder
set /p "PP=Choice: "
if "%PP%"=="1" (
  set /p "SRC=Local path: "
  set /p "DST=Remote path: "
  if defined SRC if defined DST (
    %ADB_CMD% push "%SRC%" "%DST%" >nul 2>&1 && (
      echo OK
      call :log push_OK "%SRC%" "%DST%"
    ) || (
      echo FAIL
      call :log push_FAIL "%SRC%" "%DST%"
    )
  )
) else if "%PP%"=="2" (
  set /p "SRC=Remote path: "
  set /p "DST=Local path: "
  if defined SRC if defined DST (
    %ADB_CMD% pull "%SRC%" "%DST%" >nul 2>&1 && (
      echo OK
      call :log pull_OK "%SRC%" "%DST%"
    ) || (
      echo FAIL
      call :log pull_FAIL "%SRC%" "%DST%"
    )
  )
) else echo Invalid.
pause
goto :eof

:screenshot
if not exist "%SCREEN_DIR%" mkdir "%SCREEN_DIR%" >nul 2>&1
set "SHOT_REMOTE=%TMP_DIR%/shot.png"
set "SHOT_LOCAL=%SCREEN_DIR%\shot_%DATE: =_%_%TIME::=_%"
set "SHOT_LOCAL=%SHOT_LOCAL:/=-%.png"
echo Capturing screenshot...
%ADB_CMD% shell screencap -p "%SHOT_REMOTE%" && %ADB_CMD% pull "%SHOT_REMOTE%" "%SHOT_LOCAL%" >nul && echo Saved: %SHOT_LOCAL% && call :log screenshot %SHOT_LOCAL% || echo FAIL
%ADB_CMD% shell rm -f "%SHOT_REMOTE%" >nul 2>&1
pause
goto :eof

:screenrecord
set /p "DUR=Seconds (max 180, default 30): "
if not defined DUR set "DUR=30"
echo Recording %DUR%s ... (will block until done)
set "REC_REMOTE=%TMP_DIR%/rec.mp4"
set "REC_LOCAL=%SCREEN_DIR%\rec_%DATE: =_%_%TIME::=_%"
set "REC_LOCAL=%REC_LOCAL:/=-%.mp4"
if not exist "%SCREEN_DIR%" mkdir "%SCREEN_DIR%" >nul 2>&1
%ADB_CMD% shell screenrecord --time-limit %DUR% "%REC_REMOTE%"
echo Pulling...
%ADB_CMD% pull "%REC_REMOTE%" "%REC_LOCAL%" >nul && echo Saved: %REC_LOCAL% && call :log screenrecord %REC_LOCAL%
%ADB_CMD% shell rm -f "%REC_REMOTE%" >nul 2>&1
pause
goto :eof

:cleanup_tmp
echo Cleaning temporary remote files...
%ADB_CMD% shell rm -f %TMP_DIR%/shot.png %TMP_DIR%/rec.mp4 >nul 2>&1
echo Done.
call :log cleanup_tmp
pause
goto :eof

:scrcpy_stream
echo Launching scrcpy (screen + audio if supported)...
set "SCRCPY_EXE="
if exist "%~dp0scrcpy\scrcpy.exe" (
  set "SCRCPY_EXE=%~dp0scrcpy\scrcpy.exe"
) else (
  set "SCRCPY_EXE=scrcpy"
)
if defined DEVICE_SERIAL (
  "%SCRCPY_EXE%" --serial %DEVICE_SERIAL% --audio 2>nul || "%SCRCPY_EXE%" --serial %DEVICE_SERIAL%
) else (
  "%SCRCPY_EXE%" --audio 2>nul || "%SCRCPY_EXE%"
)
call :log scrcpy_exit code=%ERRORLEVEL%
echo (scrcpy finished / closed)
pause
goto :eof

:reboot_menu
echo 1) Reboot normal
echo 2) Reboot recovery
echo 3) Reboot bootloader
set /p "RB=Choice: "
if "%RB%"=="1" (%ADB_CMD% reboot) else if "%RB%"=="2" (%ADB_CMD% reboot recovery) else if "%RB%"=="3" (%ADB_CMD% reboot bootloader) else echo Invalid.
pause
goto :eof

:grant_perm
set /p "PKG=Package: "
set /p "PERM=Permission: "
if not defined PKG goto :eof
if not defined PERM goto :eof
%ADB_CMD% shell pm grant "%PKG%" "%PERM%" && echo OK || echo FAIL
pause
goto :eof

:revoke_perm
set /p "PKG=Package: "
set /p "PERM=Permission: "
if not defined PKG goto :eof
if not defined PERM goto :eof
%ADB_CMD% shell pm revoke "%PKG%" "%PERM%" && echo OK || echo FAIL
pause
goto :eof

:wireless
echo 1) Enable tcpip 5555 on current device
echo 2) Connect host:port
echo 3) Auto-connect (detect device IP)
echo 4) Disconnect all
set /p "W=Choice: "
if "%W%"=="1" (
  %ADB_CMD% tcpip 5555
) else if "%W%"=="2" (
  set /p "HP=host:port: "
  if defined HP %ADB% connect %HP%
) else if "%W%"=="3" (
  set "_route="
  for /f "usebackq tokens=*" %%r in (`%ADB_CMD% shell ip route 2^>nul`) do if not defined _route set "_route=%%r"
  for /f "tokens=3" %%i in ("%_route%") do set "_ip=%%i"
  if defined _ip %ADB% connect %_ip%:5555
  echo IP=%_ip%
) else if "%W%"=="4" (
  %ADB% disconnect
) else echo Invalid.
pause
goto :eof

:device_info
echo SDK LEVEL:
%ADB_CMD% shell getprop ro.build.version.sdk 2>nul
echo Root check:
%ADB_CMD% shell id 2>nul | find "uid=0" && echo ROOT or echo NOT root
pause
goto :eof

:main_menu
cls
echo ======================================
echo          ADB SIMPLE TOOL
echo ======================================
echo Device: %DEVICE_SERIAL%
echo.
echo 1) Refresh / Pick device
echo 2) Install ALL APK (current folder)
echo 3) Install ONE APK
echo 4) Package manager
echo 5) Push / Pull
echo 6) Screenshot
echo 7) Screenrecord
echo 8) Reboot menu
echo 9) Grant permission
echo 10) Revoke permission
echo 11) Wireless ADB
echo 12) Device info
echo 13) Cleanup temp
echo 14) Screen stream 
echo 0) Exit
echo.
set /p "CHOICE=Select: "
if "%CHOICE%"=="1" (call :pick_device) else if "%CHOICE%"=="2" (call :install_folder) else if "%CHOICE%"=="3" (call :install_one) else if "%CHOICE%"=="4" (call :packages_panel) else if "%CHOICE%"=="5" (call :push_pull) else if "%CHOICE%"=="6" (call :screenshot) else if "%CHOICE%"=="7" (call :screenrecord) else if "%CHOICE%"=="8" (call :reboot_menu) else if "%CHOICE%"=="9" (call :grant_perm) else if "%CHOICE%"=="10" (call :revoke_perm) else if "%CHOICE%"=="11" (call :wireless) else if "%CHOICE%"=="12" (call :device_info) else if "%CHOICE%"=="13" (call :cleanup_tmp) else if "%CHOICE%"=="14" (call :scrcpy_stream) else if "%CHOICE%"=="0" (goto :end) else (echo Invalid & pause)
goto :main_menu

:__start
REM ===== ENTRY POINT =====
set "DEBUG=1"
call :log script_entry
if defined DEBUG echo [DEBUG] Starting script...
call :require_adb
if defined DEBUG echo [DEBUG] ADB resolved to: %ADB%
call :pick_device
if defined DEBUG echo [DEBUG] Device serial (may be empty): %DEVICE_SERIAL%
call :log started
if defined DEBUG echo [DEBUG] Jumping to main menu
goto :main_menu

:end
call :log exit
echo Bye.
endlocal
exit /b 0
