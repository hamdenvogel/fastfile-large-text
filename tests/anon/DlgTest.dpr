program DlgTest;

{$APPTYPE CONSOLE}

{ Abre o dialogo de descaracterizacao com amostras falsas, tira prints e clica nos botoes. }

uses
  Winapi.Windows, System.SysUtils, System.Classes, Vcl.Forms, Vcl.Controls, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Graphics, Vcl.Imaging.pngimage,
  uI18n, uAnonymize, uAnonymizeDialog;

type
  THarness = class
    Timer: TTimer;
    Step: Integer;
    procedure Tick(Sender: TObject);
    function Provide(AScope: TAnonScope; AFromLine, AToLine: Int64;
      out ASamples: TAnonSamples; out AScopeBytes: Int64): Boolean;
  end;

const
  LINES: array[0..4] of string = (
    'id,nome,cidade,cpf,email,data,valor',
    '7749,Dr. Octavio Grecco,Sao Paulo,123.456.789-09,octavio@empresa.com.br,2022-10-13,3664.50',
    '424668,Dra. Marcia Toraiwa Weshita,Campinas,987.654.321-00,marcia@x.com,2021-05-02,120.00',
    '756125,Dra. Pamela Fernanda Alves,Santos,111.222.333-96,pamela@y.org,2020-01-31,99.90',
    '544831,Empresario Marcos Ricci,Sorocaba,222.333.444-05,marcos@z.net,2019-12-24,5000.00');

function PrintWindow(hwnd: HWND; hdcBlt: HDC; nFlags: UINT): BOOL; stdcall;
  external user32 name 'PrintWindow';

function FindButton(AParent: TWinControl; const ACaption: string): TButton;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to AParent.ControlCount - 1 do
  begin
    if (AParent.Controls[I] is TButton) and (TButton(AParent.Controls[I]).Caption = ACaption) then
      Exit(TButton(AParent.Controls[I]));
    if AParent.Controls[I] is TWinControl then
    begin
      Result := FindButton(TWinControl(AParent.Controls[I]), ACaption);
      if Result <> nil then Exit;
    end;
  end;
end;

function FindListView(AParent: TWinControl): TListView;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to AParent.ControlCount - 1 do
  begin
    if AParent.Controls[I] is TListView then
      Exit(TListView(AParent.Controls[I]));
    if AParent.Controls[I] is TWinControl then
    begin
      Result := FindListView(TWinControl(AParent.Controls[I]));
      if Result <> nil then Exit;
    end;
  end;
end;

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
var
  F: TCustomForm;
  Lv: TListView;
  B: TButton;
begin
  F := Screen.ActiveForm;
  if F = nil then Exit;
  Inc(Step);
  Lv := FindListView(F);
  if Lv <> nil then
    Writeln(Format('step %d: preview rows=%d', [Step, Lv.Items.Count]));
  case Step of
    1:
      begin
        Shot(F, 'dlg1.png');
        B := FindButton(F, TrText('Anon.Refresh'));
        Writeln('refresh button found: ', B <> nil, ' enabled: ', (B <> nil) and B.Enabled);
        if B <> nil then B.Click;
      end;
    2:
      begin
        Shot(F, 'dlg2.png');
        B := FindButton(F, TrText('Anon.Apply'));
        Writeln('apply button found: ', B <> nil, ' enabled: ', (B <> nil) and B.Enabled);
        if B <> nil then B.Click;
      end;
    3:
      begin
        Writeln('active form at confirm: ', F.ClassName, ' "', F.Caption, '"');
        Shot(F, 'dlg3.png');
        F.ModalResult := mrCancel;
      end;
  else
    Timer.Enabled := False;
    F.ModalResult := mrCancel;
  end;
end;

function THarness.Provide(AScope: TAnonScope; AFromLine, AToLine: Int64;
  out ASamples: TAnonSamples; out AScopeBytes: Int64): Boolean;
var
  I: Integer;
  Off: Int64;
begin
  Writeln('provider called, scope=', Ord(AScope));
  SetLength(ASamples, Length(LINES));
  Off := 0;
  for I := 0 to High(LINES) do
  begin
    ASamples[I].LineNo := I + 1;
    ASamples[I].AbsOffset := Off;
    ASamples[I].Raw := UTF8Encode(LINES[I]) + #13#10;
    ASamples[I].Truncated := False;
    Inc(Off, Length(ASamples[I].Raw));
  end;
  AScopeBytes := Off;
  Result := True;
end;

var
  H: THarness;
  P: TAnonDialogParams;
  R: TAnonDialogResult;
  Ok: Boolean;
begin
  Application.Initialize;
  SetCurrentLanguage(alPortuguese);
  H := THarness.Create;
  H.Timer := TTimer.Create(nil);
  H.Timer.Interval := 1500;
  H.Timer.OnTimer := H.Tick;
  FillChar(P, SizeOf(P), 0);
  P.FileName := 'teste.csv';
  P.Encoding := 'UTF-8';
  P.FileSize := 500;
  P.SelectedCount := 2;
  P.TotalLines := 5;
  P.TotalLinesExact := True;
  P.InitialScope := ascSelection;
  Ok := ShowAnonymizeDialog(nil, P, H.Provide, R);
  Writeln('dialog result ok=', Ok, ' scope=', Ord(R.Scope));
end.
