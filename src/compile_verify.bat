@echo off
cd /d "%~dp0"
set DCC32="C:\Program Files (x86)\Borland\Delphi7\Bin\dcc32.exe"
set INC=c:\Hamden\Sistemas\Backend\delphi\delphi7\FastFile\Components\Findfile;c:\Hamden\Sistemas\Backend\delphi\delphi7\FastFile\Components\acnt_reg;FastMM4-master;FastCode.Libraries-0.6.4;..\..\acnt_reg;.
%DCC32% -I"%INC%" -U"%INC%" FastFile.dpr
if errorlevel 1 (
  echo COMPILE FAILED
  pause
  exit /b 1
)
echo COMPILE OK
pause
