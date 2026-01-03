@echo off
echo Building Android App Bundle (AAB)...
if not exist builds mkdir builds
godot --headless --export-release "Android" builds/Power11.aab
if %ERRORLEVEL% NEQ 0 (
    echo Build Failed!
    echo Please make sure you have installed the Android Build Template in Godot (Project > Install Android Build Template).
    pause
    exit /b %ERRORLEVEL%
)
echo Build Success! AAB saved to builds/Power11.aab
pause
