unit uExportDialog;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Math, UnConsts;

type
  TfrmExportDialog = class(TForm)
    lblInstruction: TLabel;
    edtLines: TEdit;
    lblExample: TLabel;
    lblLimit: TLabel;
    chkSaveToFile: TCheckBox;
    btnConfirm: TButton;
    btnCancel: TButton;
    Bevel1: TBevel;
    procedure btnConfirmClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
  private
    FTotalLines: Int64;
    procedure ApplyLimitHint;
  public
    class function Execute(var Input: String; var SaveToFile: Boolean;
      ATotalLines: Int64 = 0): Boolean;
  end;

{ Counts lines implied by "1-4,10;20" without expanding into a list. }
function EstimateExportLineCount(const Input: String; ATotalLines: Int64 = 0): Int64;
function ExportLineLimitForDestination(SaveToFile: Boolean): Int64;
function ExportLineLimitExceededMessage(SaveToFile: Boolean; const LineCount: Int64): string;

implementation

uses
  uI18n, uFastFileMsgDlg;

{$R *.dfm}

procedure ShowAppMessage(const Msg: string);
begin
  FastFileMsgInfo(TrText(Msg));
end;

function ExportLineLimitForDestination(SaveToFile: Boolean): Int64;
begin
  if SaveToFile then
    Result := EXPORT_FILE_MAX_LINES
  else
    Result := EXPORT_CLIPBOARD_MAX_LINES;
end;

function ExportLineLimitExceededMessage(SaveToFile: Boolean; const LineCount: Int64): string;
var
  MaxAllowed: Int64;
begin
  MaxAllowed := ExportLineLimitForDestination(SaveToFile);
  if SaveToFile then
    Result := Format(TrText('Too many lines to export to a file (%d; max %d). Reduce the range.'),
      [LineCount, MaxAllowed])
  else
    Result := Format(TrText('Too many lines to export to the clipboard (%d; max %d). Reduce the range or save to a text file.'),
      [LineCount, MaxAllowed]);
end;

function EstimateExportLineCount(const Input: String; ATotalLines: Int64 = 0): Int64;
var
  S: String;
  i: Integer;
  Parts, Range: TStringList;
  V1, V2, Lo, Hi: Int64;

  function ClampToFile(const V: Int64): Int64;
  begin
    if V < 1 then
    begin
      Result := 0;
      Exit;
    end;
    if (ATotalLines > 0) and (V > ATotalLines) then
      Result := ATotalLines
    else
      Result := V;
  end;

begin
  Result := 0;
  Parts := TStringList.Create;
  Range := TStringList.Create;
  try
    S := StringReplace(Input, ' ', '', [rfReplaceAll]);
    S := StringReplace(S, ';', ',', [rfReplaceAll]);
    Parts.Delimiter := ',';
    Parts.DelimitedText := S;

    for i := 0 to Parts.Count - 1 do
    begin
      if Pos('-', Parts[i]) > 0 then
      begin
        Range.Clear;
        Range.Delimiter := '-';
        Range.DelimitedText := Parts[i];
        if Range.Count = 2 then
        begin
          V1 := StrToInt64Def(Range[0], 0);
          V2 := StrToInt64Def(Range[1], 0);
          if (V1 < 1) and (V2 < 1) then
            Continue;
          Lo := ClampToFile(Min(V1, V2));
          Hi := ClampToFile(Max(V1, V2));
          if (Lo < 1) or (Hi < 1) or (Hi < Lo) then
            Continue;
          { Cap runaway ranges before Int64 math if TotalLines unknown. }
          if (ATotalLines <= 0) and ((Hi - Lo + 1) > EXPORT_FILE_MAX_LINES) then
          begin
            Result := Hi - Lo + 1;
            Exit;
          end;
          Inc(Result, Hi - Lo + 1);
        end;
      end
      else if Trim(Parts[i]) <> '' then
      begin
        V1 := StrToInt64Def(Parts[i], 0);
        if V1 < 1 then
          Continue;
        if (ATotalLines > 0) and (V1 > ATotalLines) then
          Continue;
        Inc(Result);
      end;
      if Result > EXPORT_FILE_MAX_LINES then
        Exit;
    end;
  finally
    Parts.Free;
    Range.Free;
  end;
end;

class function TfrmExportDialog.Execute(var Input: String; var SaveToFile: Boolean;
  ATotalLines: Int64): Boolean;
var
  frm: TfrmExportDialog;
begin
  Result := False;
  frm := TfrmExportDialog.Create(nil);
  try
    frm.FTotalLines := ATotalLines;
    ApplyTranslationsToForm(frm);
    frm.ApplyLimitHint;
    if frm.ShowModal = mrOk then
    begin
      Input := frm.edtLines.Text;
      SaveToFile := frm.chkSaveToFile.Checked;
      Result := True;
    end;
  finally
    frm.Free;
  end;
end;

procedure TfrmExportDialog.ApplyLimitHint;
begin
  if Assigned(lblLimit) then
    lblLimit.Caption := Format(
      TrText('Maximum: %s lines (file) / %s lines (clipboard).'),
      [FormatFloat('#,##0', EXPORT_FILE_MAX_LINES),
       FormatFloat('#,##0', EXPORT_CLIPBOARD_MAX_LINES)]);
end;

procedure TfrmExportDialog.btnConfirmClick(Sender: TObject);
var
  LineCount, MaxAllowed: Int64;
begin
  if Trim(edtLines.Text) = '' then
  begin
    ShowAppMessage('Line parameters are required.');
    edtLines.SetFocus;
    Exit;
  end;

  LineCount := EstimateExportLineCount(edtLines.Text, FTotalLines);
  if LineCount <= 0 then
  begin
    ShowAppMessage('Nothing to export');
    edtLines.SetFocus;
    Exit;
  end;

  MaxAllowed := ExportLineLimitForDestination(chkSaveToFile.Checked);
  if LineCount > MaxAllowed then
  begin
    FastFileMsgInfo(ExportLineLimitExceededMessage(chkSaveToFile.Checked, LineCount));
    edtLines.SetFocus;
    Exit;
  end;

  ModalResult := mrOk;
end;

procedure TfrmExportDialog.btnCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

end.
