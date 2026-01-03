@echo off
echo Building APK...
if not exist builds mkdir builds
godot --headless --export-release "Android" builds/Power11.apk
if %ERRORLEVEL% NEQ 0 (
    echo Build Failed!
    pause
    exit /b %ERRORLEVEL%
)
echo Build Success! APK saved to builds/Power11.apk
pause
