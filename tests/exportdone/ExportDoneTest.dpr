program ExportDoneTest;

{ Opens the "file created" dialog in a few languages and saves a screenshot of each. }

uses
  Winapi.Windows, System.SysUtils, System.Classes, Vcl.Forms, Vcl.Controls, Vcl.ExtCtrls, Vcl.Graphics,
  Vcl.Imaging.pngimage, uI18n, uExportDoneDlg;

type
  THarness = class
    Timer: TTimer;
    ShotName: string;
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
    if not PrintWindow(F.Handle, B.Canvas.Handle, 2) then
      BitBlt(B.Canvas.Handle, 0, 0, F.Width, F.Height, GetDC(0), F.Left, F.Top, SRCCOPY);
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

procedure THarness.Tick(Sender: TObject);
begin
  if Screen.ActiveForm = nil then Exit;
  Timer.Enabled := False;
  Shot(Screen.ActiveForm, ShotName);
  Screen.ActiveForm.ModalResult := mrCancel;
end;

var
  H: THarness;
  Sample: string;
  SL, Parts: TStringList;
  I: Integer;
const
  LANGS: array[0..3] of TAppLanguage = (alPortuguese, alGerman, alJapanese, alChineseTraditional);
  NAMES: array[0..3] of string = ('pt', 'de', 'ja', 'zhtw');
begin
  Application.Initialize;
  Sample := ExtractFilePath(ParamStr(0)) + 'FastFile_Export_202210_doctoralia_br_Allyne_20261007_162512.csv';
  SL := TStringList.Create;
  try
    for I := 1 to 40 do
      SL.Add(Format('%d;Allyne %d;Sao Paulo', [I, I]));
    SL.SaveToFile(Sample);
  finally
    SL.Free;
  end;
  H := THarness.Create;
  H.Timer := TTimer.Create(nil);
  H.Timer.Interval := 900;
  H.Timer.OnTimer := H.Tick;
  for I := 0 to High(LANGS) do
  begin
    SetCurrentLanguage(LANGS[I]);
    H.ShotName := 'done_' + NAMES[I] + '.png';
    H.Timer.Enabled := True;
    ShowGeneratedFileDialog(Sample, 40);
  end;
  Parts := TStringList.Create;
  try
    for I := 1 to 12 do
    begin
      Parts.Add(ChangeFileExt(Sample, '') + Format('.part%.3d.csv', [I]));
      CopyFile(PChar(Sample), PChar(Parts[I - 1]), False);
    end;
    for I := 0 to 1 do
    begin
      SetCurrentLanguage(LANGS[I * 2]);
      while Parts.Count > 12 - I * 9 do
        Parts.Delete(Parts.Count - 1);
      H.ShotName := 'parts_' + NAMES[I * 2] + '.png';
      H.Timer.Enabled := True;
      ShowGeneratedFilesDialog(Parts, -1, Format(TrText('ExportDone.Elapsed'), ['00:00:00.113']));
    end;
    for I := 1 to 12 do
      DeleteFile(ChangeFileExt(Sample, '') + Format('.part%.3d.csv', [I]));
  finally
    Parts.Free;
  end;
  DeleteFile(Sample);
end.
