@echo off
call "%ProgramFiles(x86)%\Embarcadero\Studio\21.0\bin\rsvars.bat"
cd /d "%~dp0"
if not exist dcu mkdir dcu
set S=..\..\src;..\..\src\FastMM4-master;..\..\src\FastCode.Libraries-0.6.4;..\..\..\acnt_reg;..\..\..\Findfile
dcc64 -B -Q -NSVcl;Vcl.Imaging;Vcl.Touch;Vcl.Samples;Vcl.Shell;System;Xml;Data;Datasnap;Web;Soap;Winapi;System.Win;Data.Win;Datasnap.Win;Web.Win;Soap.Win;Xml.Win -U%S% -I%S% -R%S% -E. -NUdcu ExportDoneTest.dpr
