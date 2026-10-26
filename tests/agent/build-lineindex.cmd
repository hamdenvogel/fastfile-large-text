@echo off
setlocal
call "%ProgramFiles(x86)%\Embarcadero\Studio\21.0\bin\rsvars.bat"
if errorlevel 1 exit /b 1
cd /d "%~dp0"
set OUT=%~1
if "%OUT%"=="" set OUT=%~dp0search-run
if not exist "%OUT%\dcu" mkdir "%OUT%\dcu"
set S=..\..\src;..\..\src\FastMM4-master;..\..\src\FastCode.Libraries-0.6.4;..\..\..\acnt_reg;..\..\..\Findfile
dcc64 -Q -NSVcl;Vcl.Imaging;Vcl.Touch;Vcl.Samples;Vcl.Shell;System;Xml;Data;Datasnap;Web;Soap;Winapi;System.Win;Data.Win;Datasnap.Win;Web.Win;Soap.Win;Xml.Win -U%S% -I%S% -R%S% -E"%OUT%" -NU"%OUT%\dcu" LineIndexScanTest.dpr
if errorlevel 1 exit /b 1
if /I "%NO_RUN%"=="1" exit /b 0
"%OUT%\LineIndexScanTest.exe"
exit /b %ERRORLEVEL%
