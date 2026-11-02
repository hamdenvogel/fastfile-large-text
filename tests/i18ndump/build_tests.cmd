@echo off
call "%ProgramFiles(x86)%\Embarcadero\Studio\21.0\bin\rsvars.bat"
if errorlevel 1 exit /b 1
cd /d "%~dp0"
if not exist dcu mkdir dcu
set S=..\..\src;..\..\src\FastMM4-master;..\..\src\FastCode.Libraries-0.6.4;..\..\..\acnt_reg;..\..\..\Findfile
set NS=Vcl;Vcl.Imaging;Vcl.Touch;Vcl.Samples;Vcl.Shell;System;Xml;Data;Datasnap;Web;Soap;Winapi;System.Win;Data.Win;Datasnap.Win;Web.Win;Soap.Win;Xml.Win
dcc64 -B -Q -NS%NS% -U%S% -I%S% -R%S% -E. -NUdcu LanguageTests.dpr
if errorlevel 1 exit /b 1
LanguageTests.exe "%~dp0..\.."
if errorlevel 1 exit /b 1
dcc64 -B -Q -NS%NS% -U%S% -I%S% -R%S% -E. -NUdcu ..\agent\NewLanguagesTest.dpr
if errorlevel 1 exit /b 1
NewLanguagesTest.exe
if errorlevel 1 exit /b 1
python -m unittest discover -s . -p test_extra_i18n.py
if errorlevel 1 exit /b 1
