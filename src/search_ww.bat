@echo off
findstr /I /N /C:"WordWrap" *.pas *.dfm > out.txt
exit /b 0
