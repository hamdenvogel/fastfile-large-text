Stop-Process -Name FastFile -ErrorAction SilentlyContinue
Start-Sleep 1
$dir = Join-Path $PSScriptRoot '..\src\Build\Win64'
Start-Process (Join-Path $dir 'FastFile.exe') -WorkingDirectory $dir
Start-Sleep 8
& (Join-Path $PSScriptRoot 'focus_app.ps1')
Start-Sleep 2
& (Join-Path $PSScriptRoot 'focus_app.ps1')
