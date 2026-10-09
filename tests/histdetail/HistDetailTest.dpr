program HistDetailTest;

{$APPTYPE CONSOLE}

{ Abre a janela de detalhe do historico com eventos falsos, tira prints de cada aba. }

uses
  Winapi.Windows, System.SysUtils, System.Classes, Vcl.Forms, Vcl.Controls, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Graphics, Vcl.Imaging.pngimage,
  uI18n, uHistLineDetailDlg;

type
  THarness = class
    Timer: TTimer;
    Step: Integer;
    procedure Tick(Sender: TObject);
  end;

function PrintWindow(hwnd: HWND; hdcBlt: HDC; nFlags: UINT): BOOL; stdcall;
  external user32 name 'PrintWindow';

function FindCtl(AParent: TWinControl; AClass: TClass; const ACaption: string): TControl;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to AParent.ControlCount - 1 do
  begin
    if (AParent.Controls[I] is AClass) and
       ((ACaption = '') or ((AParent.Controls[I] is TButton) and
        (TButton(AParent.Controls[I]).Caption = ACaption))) then
      Exit(AParent.Controls[I]);
    if AParent.Controls[I] is TWinControl then
    begin
      Result := FindCtl(TWinControl(AParent.Controls[I]), AClass, ACaption);
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
      Writeln('saved ', ExtractFilePath(ParamStr(0)) + AName);
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
  B: TButton;
  Pg: TPageControl;
begin
  F := Screen.ActiveForm;
  if F = nil then Exit;
  Inc(Step);
  Writeln('step ', Step, ' form=', F.ClassName);
  case Step of
    1:
      begin
        B := TButton(FindCtl(F, TButton, TrText('HistDetail.NextChange')));
        Writeln('next change found: ', B <> nil);
        if B <> nil then B.Click;
        if B <> nil then B.Click;
      end;
    2:
      begin
        Shot(F, 'hd1.png');
        Pg := TPageControl(FindCtl(F, TPageControl, ''));
        Pg.ActivePageIndex := 1;
      end;
    3:
      begin
        Shot(F, 'hd2.png');
        Pg := TPageControl(FindCtl(F, TPageControl, ''));
        Pg.ActivePageIndex := 2;
      end;
    4: Shot(F, 'hd3.png');
  else
    Timer.Enabled := False;
    F.ModalResult := mrCancel;
  end;
end;

function Run(AStart0, ALen: Integer): THistDetailSpan;
begin
  Result.Start0 := AStart0;
  Result.Len := ALen;
end;

var
  H: THarness;
  It: THistDetailItems;
begin
  Application.Initialize;
  if ParamStr(1) = 'en' then
    SetCurrentLanguage(alEnglish)
  else
    SetCurrentLanguage(alPortuguese);
  H := THarness.Create;
  H.Timer := TTimer.Create(nil);
  H.Timer.Interval := 1200;
  H.Timer.OnTimer := H.Tick;
  SetLength(It, 3);
  It[0].Stamp := '2026-10-04 11:21:35';
  It[0].Op := 'EDT';
  It[0].Line := 5;
  It[0].HasLines := True;
  It[0].Before := '544831,Dra.,Marilene Ricci Ganem,São Paulo,sao-paulo,sao-paulo-sp,alergista,114,2022-10-18T12:21:51-03:00,1,http://www.doctoralia.com.br/marilene-ricci-ganem,2022-10-28 20:55:02';
  It[0].After := '804019,Dra.,Siqueira Pedro Lucas,Léa Renan,sao-paulo,sao-paulo-sp,alergista,368,2022-12-28T02:13:14-03:00,1,http://www.doctoralia.com.br/marilene-ricci-ganem,2025-11-17 16:36:16';
  SetLength(It[0].BeforeRuns, 3);
  It[0].BeforeRuns[0] := Run(0, 6);
  It[0].BeforeRuns[1] := Run(12, 30);
  It[0].BeforeRuns[2] := Run(75, 3);
  SetLength(It[0].AfterRuns, 3);
  It[0].AfterRuns[0] := Run(0, 6);
  It[0].AfterRuns[1] := Run(12, 30);
  It[0].AfterRuns[2] := Run(75, 3);
  It[0].Summary := '2026-10-04 11:21:35  [EDT]  linha 5'#13#10'  antes: 544831,Dra.,Marilene...'#13#10'  depois: 804019,Dra.,Siqueira...';
  It[0].Selected := True;
  It[1] := It[0];
  It[1].Line := 6;
  It[1].Op := 'EDTx3';
  It[1].Selected := True;
  It[2].Stamp := '2026-10-04 11:22:10';
  It[2].Op := 'BINS';
  It[2].Line := 9;
  It[2].Summary := 'Inserção em lote: 3 linha(s) na linha 9';
  ShowHistLineDetailDialog(nil, 'C:\Hamden\Files\2018_doctoralia_br.csv', It, 0);
  Writeln('closed');
end.
