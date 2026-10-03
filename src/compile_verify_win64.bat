@echo off
REM FastFile — compile check for Delphi 10.4 Sydney (Win64)
cd /d "%~dp0"

set "RSVARS=%ProgramFiles(x86)%\Embarcadero\Studio\21.0\bin\rsvars.bat"
if not exist "%RSVARS%" (
  echo ERROR: Delphi 10.4 rsvars.bat not found at:
  echo   %RSVARS%
  echo Adjust RSVARS in this script if your IDE is installed elsewhere.
  pause
  exit /b 1
)

call "%RSVARS%"
msbuild FastFile.dproj /p:Platform=Win64 /p:Config=Base /t:Build /v:minimal
if errorlevel 1 (
  echo COMPILE FAILED (Win64)
  pause
  exit /b 1
)
echo COMPILE OK (Win64) — output: Build\Win64\FastFile.exe
pause
