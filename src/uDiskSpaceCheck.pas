unit uDiskSpaceCheck;

{ Verificacao de espaco em disco: estimativas, aviso com opcao de continuar,
  checagem atomica (rewrite temp) e mensagens de falha em threads.
  API de volume unica: UnUtils.VolumeFreeBytes / VolumeHasMinFreeBytes. }

interface

uses
  SysUtils, Classes;

const
  DISK_SPACE_SAFETY_MARGIN = 64 * 1024 * 1024;

function DiskSpaceRequiredForAtomicRewrite(const AFileSize: Int64): Int64;
function VolumeHasSpaceForAtomicRewrite(const APath: string; const AFileSize: Int64): Boolean;

function MergeFilesCanUseAppendAtEnd(const ADestSize, AInsertOffset, AFromLine, AToLine,
  ASrcStartOffset, ASrcRangeSize: Int64): Boolean;
function EstimateMergeFilesPeakBytes(const ADestExists: Boolean;
  const ADestSize, ASrcRangeSize, AInsertOffset: Int64;
  const AFromLine, AToLine: Int64): Int64; overload;
function EstimateMergeFilesPeakBytes(const ADestExists: Boolean;
  const ADestSize, ASrcRangeSize: Int64): Int64; overload;
function EstimateMergeDeltaPeakBytes(const AFileSize: Int64): Int64;
function EstimateSplitOutputPeakBytes(const ASrcSize: Int64): Int64;
function EstimateSplitFractionPeakBytes(const ASrcSize: Int64;
  const APartFrom, APartTo, APartCount: Integer): Int64;
function EstimateCompareMergeApplyPeakBytes(const ATargetFileSize: Int64): Int64;

{ False = utilizador cancelou; True = prosseguir (espaco OK ou aceitou o risco). }
function ConfirmDiskSpaceForPaths(const AOperationLabel: string;
  const APath1: string; const ARequired1: Int64;
  const APath2: string = ''; const ARequired2: Int64 = 0): Boolean;

function ConfirmDiskSpaceForMergeFiles(const ADestPath, ASourcePath: string;
  const ADestSize, ASrcRangeSize, AInsertOffset: Int64;
  const AFromLine, AToLine: Int64): Boolean;
function ConfirmDiskSpaceForMergeLines(const AFilePath: string): Boolean;
function ConfirmDiskSpaceForSplitEqual(const ASourcePath: string): Boolean;
function ConfirmDiskSpaceForSplitPattern(const ASourcePath: string): Boolean;
function ConfirmDiskSpaceForSplitFraction(const ASourcePath: string;
  const APartFrom, APartTo, APartCount: Integer): Boolean;
function ConfirmDiskSpaceForCompareMergeApply(const ATargetPath: string): Boolean;

function IsDiskOrMemoryStreamError(const E: Exception): Boolean;
function DiskOperationFailureMessage(const E: Exception): string;

implementation

uses
  Windows, Controls, Forms, Dialogs, StdCtrls, ExtCtrls, UnUtils, uI18n,
  uFastFilePaths, UnConsts;

const
  DISK_SPACE_DLG_EXPORT = mrAbort;
  { Delphi 7: 1024^3*1024 em Integer estoura na compilacao — literais Int64. }
  C_BYTES_PER_KB = 1024;
  C_BYTES_PER_MB = Int64(1048576);
  C_BYTES_PER_GB = Int64(1073741824);
  C_BYTES_PER_TB = Int64(1099511627776);

function FormatByteSize(const ABytes: Int64): string;
var
  V: Double;
begin
  if ABytes < 0 then
    Result := Format('0 %s', [TrText('DiskSpace.Unit.B')])
  else if ABytes < C_BYTES_PER_KB then
    Result := Format('%d %s', [ABytes, TrText('DiskSpace.Unit.B')])
  else if ABytes < C_BYTES_PER_MB then
  begin
    V := ABytes / C_BYTES_PER_KB;
    Result := Format('%.1f %s', [V, TrText('DiskSpace.Unit.KB')]);
  end
  else if ABytes < C_BYTES_PER_GB then
  begin
    V := ABytes / C_BYTES_PER_MB;
    Result := Format('%.1f %s', [V, TrText('DiskSpace.Unit.MB')]);
  end
  else if ABytes < C_BYTES_PER_TB then
  begin
    V := ABytes / C_BYTES_PER_GB;
    Result := Format('%.2f %s', [V, TrText('DiskSpace.Unit.GB')]);
  end
  else
  begin
    V := ABytes / C_BYTES_PER_TB;
    Result := Format('%.2f %s', [V, TrText('DiskSpace.Unit.TB')]);
  end;
end;

function FormatByteSizeAbout(const ABytes: Int64): string;
begin
  Result := Format(TrText('DiskSpace.Size.About'), [FormatByteSize(ABytes)]);
end;

procedure ExportDiskSpaceWarningText(const AText: string);
var
  SaveDlg: TSaveDialog;
  SL: TStringList;
begin
  SaveDlg := TSaveDialog.Create(nil);
  try
    SaveDlg.Title := TrText('DiskSpace.Export.DialogTitle');
    SaveDlg.Filter := TrText('DiskSpace.Export.Filter');
    SaveDlg.DefaultExt := 'txt';
    SaveDlg.FileName := 'FastFile_DiskSpace_' + FormatDateTime('yyyymmdd_hhnnss', Now) + '.txt';
    if not SaveDlg.Execute then
      Exit;
    SL := TStringList.Create;
    try
      SL.Text := AText;
      SL.SaveToFile(SaveDlg.FileName);
      MessageDlg(Format(TrText('DiskSpace.Export.Success'), [SaveDlg.FileName]),
        mtInformation, [mbOK], 0);
    finally
      SL.Free;
    end;
  finally
    SaveDlg.Free;
  end;
end;

function ShowDiskSpaceWarningDialog(const AMessage: string): Integer;
var
  Dlg: TForm;
  Memo: TMemo;
  Pnl: TPanel;
  BtnContinue, BtnCancel, BtnExport: TButton;
  MaxW, W, H, BtnW, BtnH, Gap, TotalBtnW, StartX: Integer;
begin
  Dlg := TForm.Create(nil);
  try
    Dlg.BorderStyle := bsDialog;
    Dlg.Caption := TrText('DiskSpace.Warning.Title');
    Dlg.Position := poScreenCenter;
    Dlg.Font.Size := 9;

    Pnl := TPanel.Create(Dlg);
    Pnl.Parent := Dlg;
    Pnl.Align := alBottom;
    Pnl.Height := 48;
    Pnl.BevelOuter := bvNone;

    Memo := TMemo.Create(Dlg);
    Memo.Parent := Dlg;
    Memo.Align := alClient;
    Memo.ReadOnly := True;
    Memo.WordWrap := True;
    Memo.ScrollBars := ssVertical;
    Memo.BorderStyle := bsNone;
    Memo.Font.Assign(Dlg.Font);
    Memo.Lines.Text := AMessage;

    BtnContinue := TButton.Create(Dlg);
    BtnContinue.Parent := Pnl;
    BtnContinue.Caption := TrText('DiskSpace.Button.Continue');
    BtnContinue.ModalResult := mrYes;
    BtnContinue.Default := True;

    BtnCancel := TButton.Create(Dlg);
    BtnCancel.Parent := Pnl;
    BtnCancel.Caption := TrText('DiskSpace.Button.Cancel');
    BtnCancel.ModalResult := mrCancel;

    BtnExport := TButton.Create(Dlg);
    BtnExport.Parent := Pnl;
    BtnExport.Caption := TrText('DiskSpace.Button.Export');
    BtnExport.ModalResult := DISK_SPACE_DLG_EXPORT;

    Gap := 8;
    BtnH := 25;
    BtnW := BtnContinue.Width;
    if BtnCancel.Width > BtnW then BtnW := BtnCancel.Width;
    if BtnExport.Width > BtnW then BtnW := BtnExport.Width;
    BtnContinue.SetBounds(0, 10, BtnW, BtnH);
    BtnCancel.SetBounds(0, 10, BtnW, BtnH);
    BtnExport.SetBounds(0, 10, BtnW, BtnH);
    TotalBtnW := BtnW * 3 + Gap * 2;

    MaxW := Screen.Width * 9 div 10;
    if MaxW < 520 then MaxW := 520;
    if MaxW > 720 then MaxW := 720;
    W := MaxW;
    if W < TotalBtnW + 32 then W := TotalBtnW + 32;

    H := 340;
    if Screen.Height > 0 then
    begin
      if H > Screen.Height * 2 div 3 then
        H := Screen.Height * 2 div 3;
      if H < 260 then H := 260;
    end;

    Dlg.ClientWidth := W;
    Dlg.ClientHeight := H;
    StartX := (Pnl.ClientWidth - TotalBtnW) div 2;
    if StartX < 8 then StartX := 8;
    BtnExport.SetBounds(StartX, 10, BtnW, BtnH);
    BtnCancel.SetBounds(StartX + BtnW + Gap, 10, BtnW, BtnH);
    BtnContinue.SetBounds(StartX + (BtnW + Gap) * 2, 10, BtnW, BtnH);

    Result := Dlg.ShowModal;
  finally
    Dlg.Free;
  end;
end;

type
  TVolNeed = record
    Key: string;
    SamplePath: string;
    Required: Int64;
  end;

function VolumeKeyForPath(const APath: string): string;
var
  P, Rest: string;
  PPos: Integer;
begin
  P := ExpandFileName(APath);
  Result := UpperCase(ExtractFileDrive(P));
  if Result <> '' then Exit;
  if (Length(P) >= 2) and (P[1] = '\') and (P[2] = '\') then
  begin
    Rest := Copy(P, 3, MaxInt);
    PPos := Pos('\', Rest);
    if PPos > 0 then
      Result := '\\' + Copy(Rest, 1, PPos - 1) + '\' + Copy(Rest, PPos + 1, MaxInt)
    else
      Result := '\\' + Rest;
    PPos := Pos('\', Copy(Result, 3, MaxInt));
    if PPos > 0 then
      SetLength(Result, PPos + 1);
  end
  else
    Result := ExtractFilePath(P);
end;

function DiskSpaceRequiredForAtomicRewrite(const AFileSize: Int64): Int64;
begin
  Result := AFileSize + DISK_SPACE_SAFETY_MARGIN;
end;

function VolumeHasSpaceForAtomicRewrite(const APath: string; const AFileSize: Int64): Boolean;
begin
  Result := VolumeHasMinFreeBytes(APath, DiskSpaceRequiredForAtomicRewrite(AFileSize));
end;

function MergeFilesCanUseAppendAtEnd(const ADestSize, AInsertOffset, AFromLine, AToLine,
  ASrcStartOffset, ASrcRangeSize: Int64): Boolean;
begin
  { Apenas insercao no fim do destino, origem inteira (sem intervalo de linhas). }
  Result := (AFromLine = 0) and (AToLine = 0) and (ASrcRangeSize > 0) and
    (ASrcStartOffset = 0) and (ADestSize >= 0) and (AInsertOffset >= ADestSize);
end;

function EstimateMergeFilesPeakBytes(const ADestExists: Boolean;
  const ADestSize, ASrcRangeSize, AInsertOffset: Int64;
  const AFromLine, AToLine: Int64): Int64;
begin
  if MergeFilesCanUseAppendAtEnd(ADestSize, AInsertOffset, AFromLine, AToLine, 0, ASrcRangeSize) then
  begin
    Result := ASrcRangeSize;
    if ADestExists then
      Inc(Result, ADestSize);
  end
  else
  begin
    Result := ADestSize + ASrcRangeSize;
    if ADestExists then
      Inc(Result, ADestSize);
  end;
end;

function EstimateMergeFilesPeakBytes(const ADestExists: Boolean;
  const ADestSize, ASrcRangeSize: Int64): Int64;
begin
  Result := EstimateMergeFilesPeakBytes(ADestExists, ADestSize, ASrcRangeSize,
    ADestSize, 0, 0);
end;

function EstimateMergeDeltaPeakBytes(const AFileSize: Int64): Int64;
begin
  Result := AFileSize * 2;
end;

function EstimateSplitOutputPeakBytes(const ASrcSize: Int64): Int64;
begin
  Result := ASrcSize * 2;
end;

function EstimateSplitFractionPeakBytes(const ASrcSize: Int64;
  const APartFrom, APartTo, APartCount: Integer): Int64;
var
  Parts, Num, Den: Int64;
begin
  if APartCount < 1 then
    Parts := 1
  else
    Parts := APartTo - APartFrom + 1;
  if Parts < 1 then Parts := 1;
  Num := Parts;
  Den := APartCount;
  if Den < 1 then Den := 1;
  Result := ASrcSize + (ASrcSize * Num) div Den + ASrcSize div 4;
end;

function EstimateCompareMergeApplyPeakBytes(const ATargetFileSize: Int64): Int64;
begin
  Result := ATargetFileSize * 2;
end;

procedure AddVolNeed(var AVols: array of TVolNeed; var AVolCount: Integer;
  const APath: string; const AAddRequired: Int64);
var
  K: string;
  i: Integer;
begin
  if (APath = '') or (AAddRequired <= 0) then Exit;
  K := VolumeKeyForPath(APath);
  for i := 0 to AVolCount - 1 do
    if AVols[i].Key = K then
    begin
      Inc(AVols[i].Required, AAddRequired);
      Exit;
    end;
  if AVolCount >= Length(AVols) then Exit;
  AVols[AVolCount].Key := K;
  AVols[AVolCount].SamplePath := APath;
  Inc(AVols[AVolCount].Required, AAddRequired);
  Inc(AVolCount);
end;

function ConfirmDiskSpaceForPaths(const AOperationLabel: string;
  const APath1: string; const ARequired1: Int64;
  const APath2: string; const ARequired2: Int64): Boolean;
const
  MAX_VOLS = 4;
var
  Vols: array[0..MAX_VOLS - 1] of TVolNeed;
  VolCount, i: Integer;
  FreeB, NeedB, ShortB: Int64;
  WorstShort, WorstFree, WorstNeed: Int64;
  WorstVolLabel, Msg, TempDir: string;
  Dlg: Integer;
begin
  Result := True;
  VolCount := 0;
  AddVolNeed(Vols, VolCount, APath1, ARequired1 + DISK_SPACE_SAFETY_MARGIN);
  AddVolNeed(Vols, VolCount, APath2, ARequired2);
  if VolCount = 0 then Exit;

  WorstShort := 0;
  for i := 0 to VolCount - 1 do
  begin
    NeedB := Vols[i].Required;
    if not VolumeFreeBytes(Vols[i].SamplePath, FreeB) then
      Continue;
    if FreeB >= NeedB then
      Continue;
    ShortB := NeedB - FreeB;
    if ShortB > WorstShort then
    begin
      WorstShort := ShortB;
      WorstFree := FreeB;
      WorstNeed := NeedB;
      WorstVolLabel := VolumeKeyForPath(Vols[i].SamplePath);
      if WorstVolLabel = '' then
        WorstVolLabel := ExtractFilePath(Vols[i].SamplePath);
    end;
  end;

  if WorstShort <= 0 then Exit;

  TempDir := EnsureFastFileTempDir;
  Msg := Format(TrText('DiskSpace.Warning.Body'),
    [AOperationLabel,
     FormatByteSizeAbout(WorstNeed),
     WorstVolLabel,
     FormatByteSize(WorstFree),
     FormatByteSize(WorstShort),
     TempDir]);

  repeat
    Dlg := ShowDiskSpaceWarningDialog(Msg);
    if Dlg = DISK_SPACE_DLG_EXPORT then
      ExportDiskSpaceWarningText(Msg);
  until Dlg <> DISK_SPACE_DLG_EXPORT;
  Result := Dlg = mrYes;
end;

function ConfirmDiskSpaceForMergeFiles(const ADestPath, ASourcePath: string;
  const ADestSize, ASrcRangeSize, AInsertOffset: Int64;
  const AFromLine, AToLine: Int64): Boolean;
var
  Peak: Int64;
  TempPath: string;
begin
  Peak := EstimateMergeFilesPeakBytes(True, ADestSize, ASrcRangeSize,
    AInsertOffset, AFromLine, AToLine);
  if MergeFilesCanUseAppendAtEnd(ADestSize, AInsertOffset, AFromLine, AToLine, 0, ASrcRangeSize) then
    TempPath := ADestPath
  else
    TempPath := FastFileTempPath(FASTFILE_MERGE_TEMP_FILE);
  Result := ConfirmDiskSpaceForPaths(TrText('DiskSpace.Op.MergeFiles'),
    TempPath, Peak, ADestPath, 0);
end;

function ConfirmDiskSpaceForMergeLines(const AFilePath: string): Boolean;
var
  Sz: Int64;
  Peak: Int64;
begin
  Sz := GetFileSize(AFilePath);
  Peak := EstimateMergeDeltaPeakBytes(Sz);
  Result := ConfirmDiskSpaceForPaths(TrText('DiskSpace.Op.MergeLines'),
    AFilePath, Peak, FastFileTempPath(FASTFILE_MERGE_TEMP_FILE), Peak);
end;

function ConfirmDiskSpaceForSplitEqual(const ASourcePath: string): Boolean;
begin
  Result := ConfirmDiskSpaceForPaths(TrText('DiskSpace.Op.SplitEqual'),
    ASourcePath, EstimateSplitOutputPeakBytes(GetFileSize(ASourcePath)));
end;

function ConfirmDiskSpaceForSplitPattern(const ASourcePath: string): Boolean;
begin
  Result := ConfirmDiskSpaceForPaths(TrText('DiskSpace.Op.SplitPattern'),
    ASourcePath, EstimateSplitOutputPeakBytes(GetFileSize(ASourcePath)));
end;

function ConfirmDiskSpaceForSplitFraction(const ASourcePath: string;
  const APartFrom, APartTo, APartCount: Integer): Boolean;
begin
  Result := ConfirmDiskSpaceForPaths(TrText('DiskSpace.Op.SplitFraction'),
    ASourcePath, EstimateSplitFractionPeakBytes(GetFileSize(ASourcePath),
      APartFrom, APartTo, APartCount));
end;

function ConfirmDiskSpaceForCompareMergeApply(const ATargetPath: string): Boolean;
var
  Sz, Peak: Int64;
begin
  Sz := GetFileSize(ATargetPath);
  Peak := EstimateCompareMergeApplyPeakBytes(Sz);
  Result := ConfirmDiskSpaceForPaths(TrText('DiskSpace.Op.CompareMerge'),
    ATargetPath, Peak, FastFileTempPath(FASTFILE_MERGE_TEMP_FILE), Peak);
end;

function IsDiskOrMemoryStreamError(const E: Exception): Boolean;
var
  L: string;
begin
  Result := (E is EInOutError) or (E is EStreamError) or (E is EOutOfMemory);
  if Result then Exit;
  L := LowerCase(E.Message);
  Result := (Pos('disk', L) > 0) or (Pos('space', L) > 0) or
    (Pos('stream', L) > 0) or (Pos('espa', L) > 0) or (Pos('disco', L) > 0) or
    (Pos('memoria', L) > 0) or (Pos('memory', L) > 0);
end;

function DiskOperationFailureMessage(const E: Exception): string;
begin
  if IsDiskOrMemoryStreamError(E) then
    Result := TrText('DiskSpace.Error.OperationFailed')
  else
    Result := E.Message;
end;

end.
