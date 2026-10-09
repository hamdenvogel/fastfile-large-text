program ExpireBadgeTest;

{$APPTYPE CONSOLE}

{ Proposed-edits countdown badge: prints of the normal, last-seconds, translated and expired states. }

uses
  Winapi.Windows, System.SysUtils, System.Classes, Vcl.Forms, Vcl.Controls, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.Graphics, Vcl.Imaging.pngimage,
  uI18n, uAgentPatch, uAgentWorkspace;

type
  THarness = class
    Timer: TTimer;
    Host: TForm;
    W: TfrmAgentWorkspace;
    Step: Integer;
    procedure Tick(Sender: TObject);
    procedure SetLeft(AMs: Integer);
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

procedure THarness.SetLeft(AMs: Integer);
begin
  W.FDecisionLeftMs := AMs;
  W.FDecisionTick := GetTickCount;
end;

procedure THarness.Tick(Sender: TObject);
var
  E: TAgentEdit;
begin
  Inc(Step);
  case Step of
    1:
      begin
        E := TAgentEdit.Create;
        E.Kind := aekReplace;
        E.Path := 'C:\temp\clientes.csv';
        E.LineStart := 4;
        E.LineEnd := 4;
        E.NewText := 'teste';
        W.FEdits.Add(E);
        W.lstEdits.Items.Add('clientes.csv  -  Substituir linha 4');
        W.pgResults.ActivePage := W.tabEdits;
        W.FDecisionTotalMs := 20000;
        SetLeft(13300);
        W.tmrDecision.Enabled := True;
      end;
    2: Shot(Host, 'badge_normal.png');
    3: SetLeft(3700);
    4: Shot(Host, 'badge_urgent.png');
    5:
      begin
        SetCurrentLanguage(alGerman);
        W.ApplyLanguage;
        SetLeft(9200);
      end;
    6: Shot(Host, 'badge_de.png');
    7:
      begin
        SetCurrentLanguage(alPortuguese);
        W.ApplyLanguage;
        SetLeft(50);
      end;
    8: Shot(Host, 'badge_expired.png');
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
  H := THarness.Create;
  Application.CreateForm(TForm, H.Host);
  H.Host.Position := poDesigned;
  H.Host.Left := 0;
  H.Host.Top := 0;
  H.Host.ClientWidth := StrToIntDef(ParamStr(1), 1230);
  H.Host.ClientHeight := StrToIntDef(ParamStr(2), 580);
  H.W := TfrmAgentWorkspace.ExecuteEmbedded(H.Host, H.Host);
  H.Timer := TTimer.Create(nil);
  H.Timer.Interval := 1300;
  H.Timer.OnTimer := H.Tick;
  Application.Run;
end.
