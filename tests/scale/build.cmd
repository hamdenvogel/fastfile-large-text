@echo off
call "%ProgramFiles(x86)%\Embarcadero\Studio\21.0\bin\rsvars.bat"
if not exist dcu mkdir dcu
set S=..\..\src;..\..\src\FastMM4-master;..\..\..\acnt_reg;..\..\..\Findfile
dcc64 -B -Q -NSVcl;Vcl.Imaging;Vcl.Touch;Vcl.Samples;Vcl.Shell;System;Xml;Data;Winapi;System.Win;Data.Win;Xml.Win -U%S% -I%S% -R%S% -E. -NUdcu FitTest.dpr
