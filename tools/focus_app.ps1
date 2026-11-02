Add-Type @"
using System;
using System.Runtime.InteropServices;
public class W {
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c);
}
"@
$p = Get-Process FastFile -ErrorAction SilentlyContinue | Select-Object -First 1
if ($p) {
  [W]::ShowWindow($p.MainWindowHandle, 9) | Out-Null
  [W]::SetForegroundWindow($p.MainWindowHandle) | Out-Null
  "focused " + $p.Id
} else { "no process" }
