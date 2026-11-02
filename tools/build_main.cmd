@echo off
call "%ProgramFiles(x86)%\Embarcadero\Studio\21.0\bin\rsvars.bat"
cd /d "%~dp0..\src"
msbuild FastFile.dproj /p:Platform=Win64 /p:Config=Base /t:Build /v:minimal > "%~dp0build_main.log" 2>&1
echo exit=%errorlevel% >> "%~dp0build_main.log"
