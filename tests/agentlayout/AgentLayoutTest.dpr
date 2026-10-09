program AgentLayoutTest;

{$APPTYPE CONSOLE}

{ Embeds the agent workspace in a host window of the given client size and saves a print. }

uses
  Winapi.Windows, System.SysUtils, System.Classes, Vcl.Forms, Vcl.Controls, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.Graphics, Vcl.Imaging.pngimage,
  uI18n, uAgentWorkspace;

type
  THarness = class
    Timer: TTimer;
    Host: TForm;
    Step: Integer;
    procedure Tick(Sender: TObject);
  end;

function PrintWindow(hwnd: HWND; hdcBlt: HDC; nFlags: UINT): BOOL; stdcall;
  external user32 name 'PrintWindow';

procedure Shot(F: TCustomForm; const AName: string);
var
  B: TBitmap;
  P: TPngImage;
begin
  B := TBitmap.Create;
  try
    B.SetSize(F.Width, F.Height);
    F.Repaint;
    PrintWindow(F.Handle, B.Canvas.Handle, 2);
    P := TPngImage.Create;
    try
      P.Assign(B);
      P.SaveToFile(ExtractFilePath(ParamStr(0)) + AName);
      Writeln('saved ', AName);
    finally
      P.Free;
    end;
  finally
    B.Free;
  end;
end;

procedure Dump(C: TControl; const AIndent: string);
var
  I: Integer;
begin
  if (C is TWinControl) or (C is TLabel) then
    Writeln(AIndent, C.ClassName, ' ', C.Name, ' L=', C.Left, ' T=', C.Top, ' W=', C.Width, ' H=', C.Height);
  if (C is TWinControl) and (Length(AIndent) < 12) then
    for I := 0 to TWinControl(C).ControlCount - 1 do
      Dump(TWinControl(C).Controls[I], AIndent + '  ');
end;

procedure THarness.Tick(Sender: TObject);
begin
  Inc(Step);
  case Step of
    1:
      begin
        Shot(Host, 'layout_' + ParamStr(1) + 'x' + ParamStr(2) + '.png');
        if ParamStr(3) = 'dump' then
          Dump(Host, '');
      end;
  else
    Timer.Enabled := False;
    Host.Close;
  end;
end;

var
  H: THarness;
begin
  Application.Initialize;
  SetCurrentLanguage(alPortuguese);
  Writeln('ppi=', Screen.PixelsPerInch);
  H := THarness.Create;
  Application.CreateForm(TForm, H.Host);
  H.Host.Position := poDesigned;
  H.Host.Left := 0;
  H.Host.Top := 0;
  H.Host.ClientWidth := StrToIntDef(ParamStr(1), 815);
  H.Host.ClientHeight := StrToIntDef(ParamStr(2), 390);
  TfrmAgentWorkspace.ExecuteEmbedded(H.Host, H.Host);
  H.Timer := TTimer.Create(nil);
  H.Timer.Interval := 1500;
  H.Timer.OnTimer := H.Tick;
  Application.Run;
end.
