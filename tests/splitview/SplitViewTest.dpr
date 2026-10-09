program SplitViewTest;

{ Opens a file in the real main form, splits it (same path as the Agent's split_equal_parts),
  auto-confirms dialogs and prints the window before and after: the list must keep its content. }

uses
  Winapi.Windows, System.SysUtils, System.Classes, Vcl.Forms, Vcl.Controls, Vcl.ExtCtrls,
  Vcl.Graphics, Vcl.ComCtrls, Vcl.Imaging.pngimage,
  UnDM, uFastFileAssistantHost, MainUnit;

type
  THarness = class
    Timer: TTimer;
    Step: Integer;
    Src: string;
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
    finally
      P.Free;
    end;
  finally
    B.Free;
  end;
end;

procedure Log(const S: string);
var
  F: TextFile;
begin
  AssignFile(F, ExtractFilePath(ParamStr(0)) + 'splitview_out.txt');
  if FileExists(ExtractFilePath(ParamStr(0)) + 'splitview_out.txt') then
    Append(F)
  else
    Rewrite(F);
  Writeln(F, FormatDateTime('hh:nn:ss.zzz', Now), ' ', S);
  CloseFile(F);
end;

procedure CloseModals;
var
  I: Integer;
  F: TForm;
begin
  for I := Screen.FormCount - 1 downto 0 do
  begin
    F := Screen.Forms[I];
    if (fsModal in F.FormState) and F.Visible then
    begin
      Log('closing modal ' + F.ClassName + ' "' + F.Caption + '"');
      F.ModalResult := mrOk;
    end;
  end;
end;

procedure RowText;
var
  LV: TListView;
  It: TListItem;
  S: string;
begin
  LV := frmMain.ListView1;
  Log(Format('items=%d', [LV.Items.Count]));
  if LV.Items.Count = 0 then Exit;
  It := LV.Items[0];
  S := It.Caption;
  if It.SubItems.Count > 0 then
    S := S + ' | ' + It.SubItems[0];
  Log('row0=' + S);
end;

procedure THarness.Tick(Sender: TObject);
var
  St: TAssistantChainStep;
begin
  Inc(Step);
  CloseModals;
  case Step of
    3:
      if ParamStr(2) = 'noread' then
      begin
        { Path typed / restored in the file box, but never read. }
        frmMain.edtFileName.Text := Src;
        Log('path set without reading');
      end
      else
      begin
        St := Default(TAssistantChainStep);
        St.ActionId := 'open_and_read_file';
        St.Path := Src;
        AssistantHostExecuteAction(St);
        Log('open requested');
      end;
    12:
      begin
        RowText;
        Shot(frmMain, 'before.png');
        St := Default(TAssistantChainStep);
        St.ActionId := 'split_equal_parts';
        St.Path := Src;
        St.Parts := 3;
        AssistantHostExecuteAction(St);
        Log('split requested');
      end;
    40:
      begin
        RowText;
        Shot(frmMain, 'after.png');
      end;
    42:
      begin
        Timer.Enabled := False;
        Application.Terminate;
      end;
  end;
end;

var
  H: THarness;
begin
  Application.Initialize;
  H := THarness.Create;
  H.Src := ParamStr(1);
  DataModule1 := TDataModule1.Create(Application);
  Application.CreateForm(TfrmMain, frmMain);
  H.Timer := TTimer.Create(nil);
  H.Timer.Interval := 500;
  H.Timer.OnTimer := H.Tick;
  Application.Run;
end.
