@echo off
REM Compila FastFile + copia ScriptEngine para a pasta do EXE.
REM Execute na pasta Src (onde esta FastFile.dpr).

set SRC=%~dp0
set DCC32=C:\Arquivos de programas\Borland\Delphi7\Bin\dcc32.exe
if not exist "%DCC32%" set DCC32=C:\Program Files\Borland\Delphi7\Bin\dcc32.exe
if not exist "%DCC32%" (
  echo Delphi 7 dcc32.exe nao encontrado. Compile pelo IDE: Project - Build FastFile
  exit /b 1
)

cd /d "%SRC%"
echo Compilando FastFile.dpr ...
"%DCC32%" -B FastFile.dpr
if errorlevel 1 exit /b 1

set EXEDIR=%SRC%
if exist "%SRC%FastFile.exe" set EXEDIR=%SRC%

set SE_PY=%SRC%data-lake-duckdb-main\ScriptEngine.py
set SE_BAT=%SRC%data-lake-duckdb-main\build_exe_scriptengine.bat
if exist "%SE_BAT%" (
  echo Gerando ScriptEngine.exe ...
  pushd "%SRC%data-lake-duckdb-main"
  call build_exe_scriptengine.bat
  popd
)

if exist "%SRC%data-lake-duckdb-main\ScriptEngine.exe" (
  copy /Y "%SRC%data-lake-duckdb-main\ScriptEngine.exe" "%EXEDIR%ScriptEngine.exe"
  echo ScriptEngine.exe copiado para %EXEDIR%
) else (
  echo AVISO: ScriptEngine.exe nao gerado. Macro tail precisa dele junto ao FastFile.exe
)

echo.
echo OK. Execute: %EXEDIR%FastFile.exe
echo Menu: Opcoes - Macro tail - Reprocessar linhas novas  ou  Ctrl+Shift+R
pause
