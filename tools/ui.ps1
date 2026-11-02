param(
  [string]$Cmd = 'shot',
  [int]$X = 0,
  [int]$Y = 0,
  [string]$Out = 'C:\Users\hamde\AppData\Local\Temp\ff_shot.png',
  [string]$Text = ''
)
# Drives the FastFile test build WITHOUT touching the real mouse/keyboard:
#   shot            -> PrintWindow of the main window to $Out
#   click X Y       -> left click at client coords of the main window (posted messages)
#   rclick X Y      -> right click
#   type Text       -> WM_CHAR to the focused control of the app thread
#   key VK          -> WM_KEYDOWN/UP (virtual key code in -X)
Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;
public class U {
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
  [StructLayout(LayoutKind.Sequential)] public struct POINT { public int X, Y; }
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint dx, uint dy, uint d, IntPtr e);
  [DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte sc, uint f, IntPtr e);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr dc, uint f);
  [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
  [DllImport("user32.dll")] public static extern IntPtr ChildWindowFromPointEx(IntPtr h, POINT p, uint f);
  [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr h, ref POINT p);
  [DllImport("user32.dll")] public static extern bool ScreenToClient(IntPtr h, ref POINT p);
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] public static extern int GetWindowTextLength(IntPtr h);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
  public delegate bool EnumProc(IntPtr h, IntPtr l);
  [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc p, IntPtr l);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  [DllImport("user32.dll")] public static extern int GetClassName(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
}
"@
[U]::SetProcessDPIAware() | Out-Null
$p = Get-Process FastFile -ErrorAction Stop | Select-Object -First 1
$h = $p.MainWindowHandle

function Get-Wins {
  $list = New-Object System.Collections.ArrayList
  $cb = [U+EnumProc]{ param($w, $l)
    $pid2 = 0
    [U]::GetWindowThreadProcessId($w, [ref]$pid2) | Out-Null
    if ($pid2 -eq $p.Id -and [U]::IsWindowVisible($w)) {
      $sb = New-Object System.Text.StringBuilder 256
      [U]::GetClassName($w, $sb, 256) | Out-Null
      $tt = New-Object System.Text.StringBuilder 256
      [U]::GetWindowText($w, $tt, 256) | Out-Null
      $r = New-Object U+RECT
      [U]::GetWindowRect($w, [ref]$r) | Out-Null
      [void]$list.Add([pscustomobject]@{ H = $w; Class = $sb.ToString(); Title = $tt.ToString(); L=$r.L; T=$r.T; W=($r.R-$r.L); Ht=($r.B-$r.T) })
    }
    return $true
  }
  [U]::EnumWindows($cb, [IntPtr]::Zero) | Out-Null
  return $list
}

function Shot($hwnd, $path) {
  $r = New-Object U+RECT
  [U]::GetWindowRect($hwnd, [ref]$r) | Out-Null
  $w = $r.R - $r.L; $hh = $r.B - $r.T
  $bmp = New-Object System.Drawing.Bitmap $w, $hh
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $dc = $g.GetHdc()
  [U]::PrintWindow($hwnd, $dc, 2) | Out-Null
  $g.ReleaseHdc($dc)
  $g.Dispose()
  $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose()
}

function Click($hwnd, $x, $y, $right) {
  # (x,y) relative to the WINDOW's top-left (as seen in a 'shot' image)
  $r = New-Object U+RECT
  [U]::GetWindowRect($hwnd, [ref]$r) | Out-Null
  $pt = New-Object U+POINT
  $pt.X = $r.L + $x; $pt.Y = $r.T + $y
  $target = $hwnd
  for ($i = 0; $i -lt 8; $i++) {
    $c = New-Object U+POINT
    $c.X = $pt.X; $c.Y = $pt.Y
    [U]::ScreenToClient($target, [ref]$c) | Out-Null
    $child = [U]::ChildWindowFromPointEx($target, $c, 1 -bor 2)  # skip invisible/disabled
    if ($child -eq [IntPtr]::Zero -or $child -eq $target) { break }
    $target = $child
  }
  $cp = New-Object U+POINT
  $cp.X = $pt.X; $cp.Y = $pt.Y
  [U]::ScreenToClient($target, [ref]$cp) | Out-Null
  $lp = [IntPtr](($cp.Y -shl 16) -bor ($cp.X -band 0xFFFF))
  if ($right) { $dn = 0x204; $up = 0x205; $wp = 2 } else { $dn = 0x201; $up = 0x202; $wp = 1 }
  [U]::PostMessage($target, 0x200, [IntPtr]::Zero, $lp) | Out-Null
  Start-Sleep -Milliseconds 80
  [U]::PostMessage($target, $dn, [IntPtr]$wp, $lp) | Out-Null
  Start-Sleep -Milliseconds 80
  [U]::PostMessage($target, $up, [IntPtr]::Zero, $lp) | Out-Null
  "clicked on " + $target
}

$main = Get-Wins | Where-Object { $_.Class -eq 'TfrmMain' } | Select-Object -First 1
if ($main) { $h = $main.H }

switch ($Cmd) {
  'shot'   { Shot $h $Out; "saved $Out" }
  'mclick' {
    # real mouse click, ONLY if the FastFile main window is the foreground window
    [U]::ShowWindow($h, 5) | Out-Null
    [U]::SetForegroundWindow($h) | Out-Null
    Start-Sleep -Milliseconds 400
    if ([U]::GetForegroundWindow() -ne $h) { "ABORT: FastFile is not in the foreground"; break }
    $r = New-Object U+RECT
    [U]::GetWindowRect($h, [ref]$r) | Out-Null
    [U]::SetCursorPos($r.L + $X, $r.T + $Y) | Out-Null
    Start-Sleep -Milliseconds 150
    if ([U]::GetForegroundWindow() -ne $h) { "ABORT: foreground changed"; break }
    [U]::mouse_event(0x0002, 0, 0, 0, [IntPtr]::Zero)
    Start-Sleep -Milliseconds 60
    [U]::mouse_event(0x0004, 0, 0, 0, [IntPtr]::Zero)
    "clicked at $($r.L + $X),$($r.T + $Y)"
  }
  'mrclick' {
    [U]::ShowWindow($h, 5) | Out-Null
    [U]::SetForegroundWindow($h) | Out-Null
    Start-Sleep -Milliseconds 400
    if ([U]::GetForegroundWindow() -ne $h) { "ABORT: FastFile is not in the foreground"; break }
    $r = New-Object U+RECT
    [U]::GetWindowRect($h, [ref]$r) | Out-Null
    [U]::SetCursorPos($r.L + $X, $r.T + $Y) | Out-Null
    Start-Sleep -Milliseconds 150
    if ([U]::GetForegroundWindow() -ne $h) { "ABORT: foreground changed"; break }
    [U]::mouse_event(0x0008, 0, 0, 0, [IntPtr]::Zero)
    Start-Sleep -Milliseconds 60
    [U]::mouse_event(0x0010, 0, 0, 0, [IntPtr]::Zero)
    "rclicked at $($r.L + $X),$($r.T + $Y)"
  }
  'mkey' {
    # $Text = key combo like "ctrl+1" / "f5" / "esc"
    [U]::ShowWindow($h, 5) | Out-Null
    [U]::SetForegroundWindow($h) | Out-Null
    Start-Sleep -Milliseconds 400
    if ([U]::GetForegroundWindow() -ne $h) { "ABORT: FastFile is not in the foreground"; break }
    $map = @{ 'ctrl'=0x11; 'shift'=0x10; 'alt'=0x12; 'esc'=0x1B; 'enter'=0x0D; 'f1'=0x70; 'f2'=0x71; 'f3'=0x72; 'f4'=0x73; 'f5'=0x74; 'f6'=0x75; 'f7'=0x76; 'f8'=0x77; 'f9'=0x78; 'f10'=0x79; 'f11'=0x7A; 'f12'=0x7B; 'tab'=0x09; 'space'=0x20; 'down'=0x28; 'up'=0x26; 'left'=0x25; 'right'=0x27 }
    $codes = @()
    foreach ($k in $Text.ToLower().Split('+')) {
      if ($map.ContainsKey($k)) { $codes += $map[$k] }
      elseif ($k.Length -eq 1) { $codes += [int][char]$k.ToUpper() }
    }
    foreach ($c in $codes) { [U]::keybd_event([byte]$c, 0, 0, [IntPtr]::Zero) ; Start-Sleep -Milliseconds 30 }
    [array]::Reverse($codes)
    foreach ($c in $codes) { [U]::keybd_event([byte]$c, 0, 2, [IntPtr]::Zero) ; Start-Sleep -Milliseconds 30 }
    "keys $Text"
  }
  'sshot'  {
    [U]::SetProcessDPIAware() | Out-Null
    [U]::ShowWindow($h, 5) | Out-Null
    [U]::SetForegroundWindow($h) | Out-Null
    Start-Sleep -Milliseconds 700
    $r = New-Object U+RECT
    [U]::GetWindowRect($h, [ref]$r) | Out-Null
    $w = $r.R - $r.L; $hh = $r.B - $r.T
    $bmp = New-Object System.Drawing.Bitmap $w, $hh
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen($r.L, $r.T, 0, 0, (New-Object System.Drawing.Size $w, $hh))
    $g.Dispose()
    $bmp.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    "saved $Out ($w x $hh at $($r.L),$($r.T))"
  }
  'click'  { Click $h $X $Y $false }
  'rclick' { Click $h $X $Y $true }
  'wins'   { Get-Wins | Format-Table H, Class, Title, L, T, W, Ht -AutoSize | Out-String -Width 250 }
  'shotwin' { Shot ([IntPtr]$X) $Out; "saved $Out" }
}

