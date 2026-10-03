#!/usr/bin/env python3
"""Restore procedure/function signatures damaged by const migration."""
from pathlib import Path

MAIN = Path(__file__).resolve().parent.parent / "MainUnit.pas"

REPLACEMENTS = [
    # --- interface TfrmMain ---
    (
        "    function DrawCheckListFindHighlight(CLB: TCheckListBox; const R: TRect;\r\n"
        "    function AlignMatchColInLineText(const LineTxt, Needle: string;\r\n"
        "    function IsClickInFirstColumn(X: Integer): Boolean;",
        "    function DrawCheckListFindHighlight(CLB: TCheckListBox; const R: TRect;\r\n"
        "      const Vis: string; MatchStart, MatchLen: Integer): Boolean;\r\n"
        "    function AlignMatchColInLineText(const LineTxt, Needle: string;\r\n"
        "      HintByte0: Integer; CaseSens: Boolean): Integer;\r\n"
        "    function IsClickInFirstColumn(X: Integer): Boolean;",
    ),
    (
        "    procedure DrawCheckListLineAutofillPreview(CLB: TCheckListBox;\r\n"
        "    procedure CancelLineAutofillDrag;",
        "    procedure DrawCheckListLineAutofillPreview(CLB: TCheckListBox;\r\n"
        "      Index: Integer; const ItemRect: TRect);\r\n"
        "    procedure CancelLineAutofillDrag;",
    ),
    (
        "    function DoMergeFilesFromDialog(const DestFileName, SourceFileName: String;\r\n"
        "    function DoSplitByPatternFromDialog(const SourceFile, Pattern: String; const IsRegex: Boolean;\r\n"
        "    function DoSplitEqualPartsFromDialog(const SourceFile: String; const PartCount: Integer;\r\n"
        "    procedure InitializeLanguage;",
        "    function DoMergeFilesFromDialog(const DestFileName, SourceFileName: String;\r\n"
        "      const MergeMode: TMergeFilesMode; const InsertAfterLine: Int64;\r\n"
        "      const FromLine, ToLine: Int64): Boolean;\r\n"
        "    function DoSplitByPatternFromDialog(const SourceFile, Pattern: String; const IsRegex: Boolean;\r\n"
        "      const HeaderStr, FooterStr: String; const UseEqualParts: Boolean;\r\n"
        "      const EqualPartsCount: Integer; const RegexOp: TRegexOp; const Replacement: String): Boolean;\r\n"
        "    function DoSplitEqualPartsFromDialog(const SourceFile: String; const PartCount: Integer;\r\n"
        "      const HeaderStr, FooterStr: String): Boolean;\r\n"
        "    procedure InitializeLanguage;",
    ),
    (
        "    procedure StartAsyncUndoRedo(const AAction: TPendingUndoRedoAction;\r\n"
        "      const ADiskOp: TOperationType; const ALine: Int64; const AContent: String;\r\n"
        "    procedure PushUndo(const AOp: TOperationType; const ALine: Int64;\r\n"
        "    procedure DoUndo;",
        "    procedure StartAsyncUndoRedo(const AAction: TPendingUndoRedoAction;\r\n"
        "      const ADiskOp: TOperationType; const ALine: Int64; const AContent: String);\r\n"
        "    procedure PushUndo(const AOp: TOperationType; const ALine: Int64;\r\n"
        "      const AOldContent, ANewContent: String);\r\n"
        "    procedure DoUndo;",
    ),
    (
        "    procedure RecordForUndo(const AOp: TOperationType; const ALine: Int64;\r\n"
        "    procedure RecordBatchInsertForUndo(const AStartLine: Int64; ALines: TStringList);",
        "    procedure RecordForUndo(const AOp: TOperationType; const ALine: Int64;\r\n"
        "      const AOldContent, ANewContent: String);\r\n"
        "    procedure RecordBatchInsertForUndo(const AStartLine: Int64; ALines: TStringList);",
    ),
    (
        "    function ApplyEditWithUndo(const AOp: TOperationType; const ALine: Int64;\r\n"
        "    function ApplyBatchInsertWithUndo(const AStartLine: Int64; ALines: TStringList;",
        "    function ApplyEditWithUndo(const AOp: TOperationType; const ALine: Int64;\r\n"
        "      const AOldContent, ANewContent: String; AQuietFinish: Boolean = False): Boolean;\r\n"
        "    function ApplyBatchInsertWithUndo(const AStartLine: Int64; ALines: TStringList;\r\n"
        "      const ABatchKind: Integer = 0): Boolean;",
    ),
    (
        "    function WrapPlainTextToPixelWidth(const ACanvas: TCanvas; const AText: string;\r\n"
        "    function ListViewItemIndexIsSelected(const ALv: TCustomListView; const AIndex: Integer): Boolean;",
        "    function WrapPlainTextToPixelWidth(const ACanvas: TCanvas; const AText: string;\r\n"
        "      MaxWidth: Integer): string;\r\n"
        "    function ListViewItemIndexIsSelected(const ALv: TCustomListView; const AIndex: Integer): Boolean;",
    ),
    (
        "    procedure editFile(const AInitialOp: TOperationType = otEdit;\r\n"
        "    procedure ApplyMainFileListWheel(const WheelDelta: Integer);",
        "    procedure editFile(const AInitialOp: TOperationType = otEdit; AForceListRow: Integer = -1);\r\n"
        "    procedure ApplyMainFileListWheel(const WheelDelta: Integer);",
    ),
    (
        "    procedure ApplySingleLineIndexPatchDone(const AOp: TOperationType;\r\n"
        "    procedure ApplyMetadataOnlyPostEdit(const ADeltaLines: Int64);",
        "    procedure ApplySingleLineIndexPatchDone(const AOp: TOperationType; ASuccess: Boolean);\r\n"
        "    procedure ApplyMetadataOnlyPostEdit(const ADeltaLines: Int64);",
    ),
    (
        "    procedure CommitPendingMergeFilesUndoIfNeeded(const ASuccess: Boolean;\r\n"
        "    procedure ApplyStoredMergeDelta(const ADeltaText: string);",
        "    procedure CommitPendingMergeFilesUndoIfNeeded(const ASuccess: Boolean);\r\n"
        "    procedure ApplyStoredMergeDelta(const ADeltaText: string);",
    ),
    # --- implementation ---
    (
        "function RunSegmentedDeleteLinesWait(const AFileName, AIdxPath: string;\r\nvar",
        "function RunSegmentedDeleteLinesWait(const AFileName, AIdxPath: string;\r\n"
        "  const ALines: TInt64DynArray; out ASegOk: Boolean; out AErrorMsg: string): Boolean;\r\nvar",
    ),
    (
        "function PreviewPatternMatchesInFile(const AFileName, APattern: String; const AIsRegex: Boolean;\r\nvar",
        "function PreviewPatternMatchesInFile(const AFileName, APattern: String; const AIsRegex: Boolean;\r\n"
        "  const AMaxSamples: Integer; out AReport: String; out AErrorMsg: String): Boolean;\r\nvar",
    ),
    (
        "function TScriptEngineRunThread.TryReadIndexOffsetByLineNumber(\r\nvar",
        "function TScriptEngineRunThread.TryReadIndexOffsetByLineNumber(\r\n"
        "  const ALineNumber1Based: Int64; out AOffset: Int64): Boolean;\r\nvar",
    ),
    (
        "function TScriptEngineRunThread.ReadLineContentByOffsets(\r\nvar",
        "function TScriptEngineRunThread.ReadLineContentByOffsets(\r\n"
        "  const AStartOffset, AEndOffset: Int64): string;\r\nvar",
    ),
    (
        "function TScriptEngineRunThread.TryReadSparseLineStartOffset(\r\nvar",
        "function TScriptEngineRunThread.TryReadSparseLineStartOffset(\r\n"
        "  const ALineNumber1Based: Int64; out AOffset: Int64): Boolean;\r\nvar",
    ),
    (
        "function TScriptEngineRunThread.ReadLineContentByNumber(\r\nvar",
        "function TScriptEngineRunThread.ReadLineContentByNumber(\r\n"
        "  const ALineNumber1Based: Int64): string;\r\nvar",
    ),
    (
        "function TfrmMain.DoMergeFilesFromDialog(const DestFileName, SourceFileName: String;\r\nvar",
        "function TfrmMain.DoMergeFilesFromDialog(const DestFileName, SourceFileName: String;\r\n"
        "  const MergeMode: TMergeFilesMode; const InsertAfterLine: Int64;\r\n"
        "  const FromLine, ToLine: Int64): Boolean;\r\nvar",
    ),
    (
        "function TfrmMain.DoSplitEqualPartsFromDialog(const SourceFile: String; const PartCount: Integer;\r\nvar",
        "function TfrmMain.DoSplitEqualPartsFromDialog(const SourceFile: String; const PartCount: Integer;\r\n"
        "  const HeaderStr, FooterStr: String): Boolean;\r\nvar",
    ),
    (
        "function TfrmMain.DoSplitFileFractionFromDialog(const SourceFile: String;\r\nvar",
        "function TfrmMain.DoSplitFileFractionFromDialog(const SourceFile: String;\r\n"
        "  const TotalParts, PartFrom, PartTo: Integer; const HeaderStr, FooterStr: String): Boolean;\r\nvar",
    ),
    (
        "function TfrmMain.DoSplitByPatternFromDialog(const SourceFile, Pattern: String; const IsRegex: Boolean;\r\nvar",
        "function TfrmMain.DoSplitByPatternFromDialog(const SourceFile, Pattern: String; const IsRegex: Boolean;\r\n"
        "  const HeaderStr, FooterStr: String; const UseEqualParts: Boolean;\r\n"
        "  const EqualPartsCount: Integer; const RegexOp: TRegexOp; const Replacement: String): Boolean;\r\nvar",
    ),
    (
        "function TfrmMain.CheckListBoxWordWrapTextRect(CLB: TCheckListBox;\r\nvar",
        "function TfrmMain.CheckListBoxWordWrapTextRect(CLB: TCheckListBox;\r\n"
        "  const ItemRect: TRect): TRect;\r\nvar",
    ),
    (
        "procedure TfrmMain.addNewContentsFromPositionFileStream(fFileName: string;\r\nvar",
        "procedure TfrmMain.addNewContentsFromPositionFileStream(fFileName: string;\r\n"
        "  const position: Int64);\r\nvar",
    ),
    (
        "procedure TfrmMain.splitFirstFile(const fFileName: string;\r\nvar",
        "procedure TfrmMain.splitFirstFile(const fFileName: string; const position: Int64);\r\nvar",
    ),
    (
        "function TfrmMain.getNextCtrlLineFeedPositionFromOffSet(\r\nvar",
        "function TfrmMain.getNextCtrlLineFeedPositionFromOffSet(\r\n"
        "  const fFileName: string; const _offSet: Int64): Int64;\r\nvar",
    ),
    (
        "procedure TfrmMain.FindFileFolderChange(Sender: TObject;\r\nbegin",
        "procedure TfrmMain.FindFileFolderChange(Sender: TObject;\r\n"
        "  const Folder: String; var IgnoreFolder: TFolderIgnore);\r\nbegin",
    ),
    (
        "procedure TfrmMain.ReopenFileStreamsOnly(const AFileName: String;\r\nvar",
        "procedure TfrmMain.ReopenFileStreamsOnly(const AFileName: String;\r\n"
        "  const AOpenLineIndexFiles: Boolean = True);\r\nvar",
    ),
    (
        "procedure TfrmMain.OpenFileStreams(const AFileName: String;\r\nbegin",
        "procedure TfrmMain.OpenFileStreams(const AFileName: String;\r\n"
        "  const AOpenLineIndexFiles: Boolean = True);\r\nbegin",
    ),
    (
        "function TfrmMain.getLineContentsFromLineIndex(\r\nvar",
        "function TfrmMain.getLineContentsFromLineIndex(const iLine: int64): string;\r\nvar",
    ),
    (
        "function TfrmMain.AlignMatchColInLineText(const LineTxt, Needle: string;\r\nvar",
        "function TfrmMain.AlignMatchColInLineText(const LineTxt, Needle: string;\r\n"
        "  HintByte0: Integer; CaseSens: Boolean): Integer;\r\nvar",
    ),
    (
        "function TfrmMain.DrawCheckListFindHighlight(CLB: TCheckListBox; const R: TRect;\r\nvar",
        "function TfrmMain.DrawCheckListFindHighlight(CLB: TCheckListBox; const R: TRect;\r\n"
        "  const Vis: string; MatchStart, MatchLen: Integer): Boolean;\r\nvar",
    ),
    (
        "procedure TfrmMain.editFile(const AInitialOp: TOperationType;\r\nvar",
        "procedure TfrmMain.editFile(const AInitialOp: TOperationType = otEdit;\r\n"
        "  AForceListRow: Integer = -1);\r\nvar",
    ),
    (
        "procedure TfrmMain.DrawCheckListLineAutofillPreview(CLB: TCheckListBox;\r\nvar",
        "procedure TfrmMain.DrawCheckListLineAutofillPreview(CLB: TCheckListBox;\r\n"
        "  Index: Integer; const ItemRect: TRect);\r\nvar",
    ),
    (
        "procedure TfrmMain.ApplySingleLineIndexPatchDone(const AOp: TOperationType;\r\nbegin",
        "procedure TfrmMain.ApplySingleLineIndexPatchDone(const AOp: TOperationType;\r\n"
        "  ASuccess: Boolean);\r\nbegin",
    ),
    (
        "function TfrmMain.WrapPlainTextToPixelWidth(const ACanvas: TCanvas; const AText: string;\r\nvar",
        "function TfrmMain.WrapPlainTextToPixelWidth(const ACanvas: TCanvas; const AText: string;\r\n"
        "  MaxWidth: Integer): string;\r\nvar",
    ),
    (
        "procedure TfrmMain.PushUndo(const AOp: TOperationType; const ALine: Int64;\r\nvar",
        "procedure TfrmMain.PushUndo(const AOp: TOperationType; const ALine: Int64;\r\n"
        "  const AOldContent, ANewContent: String);\r\nvar",
    ),
    (
        "procedure TfrmMain.RecordForUndo(const AOp: TOperationType; const ALine: Int64;\r\nbegin",
        "procedure TfrmMain.RecordForUndo(const AOp: TOperationType; const ALine: Int64;\r\n"
        "  const AOldContent, ANewContent: String);\r\nbegin",
    ),
    (
        "procedure IdleLogoBlendBmpOnto(DstBmp: TBitmap; XDst, YDst: Integer;\r\nvar",
        "procedure IdleLogoBlendBmpOnto(DstBmp: TBitmap; XDst, YDst: Integer;\r\n"
        "  SrcBmp: TBitmap; SrcBlend: Integer);\r\nvar",
    ),
    (
        "procedure IdleLogoStretchSmooth(DstBmp: TBitmap; XDst, YDst, DstW, DstH: Integer;\r\nvar",
        "procedure IdleLogoStretchSmooth(DstBmp: TBitmap; XDst, YDst, DstW, DstH: Integer;\r\n"
        "  SrcBmp: TBitmap; SrcBlend: Integer);\r\nvar",
    ),
    (
        "function TfrmMain.ApplyEditWithUndo(const AOp: TOperationType; const ALine: Int64;\r\nbegin",
        "function TfrmMain.ApplyEditWithUndo(const AOp: TOperationType; const ALine: Int64;\r\n"
        "  const AOldContent, ANewContent: String; AQuietFinish: Boolean = False): Boolean;\r\nbegin",
    ),
    (
        "procedure TfrmMain.CommitPendingMergeFilesUndoIfNeeded(const ASuccess: Boolean;\r\nvar",
        "procedure TfrmMain.CommitPendingMergeFilesUndoIfNeeded(const ASuccess: Boolean);\r\nvar",
    ),
    # Fix body references for merge undo
    (
        "    if (ABackupPath <> '') and FileExists(ABackupPath) then\r\n"
        "      DeleteFile(ABackupPath);",
        "    if (FPendingMergeFilesBackup <> '') and FileExists(FPendingMergeFilesBackup) then\r\n"
        "      DeleteFile(FPendingMergeFilesBackup);",
    ),
    (
        "    FFHistoryAppendMergeFiles(ADest, ASource, FPendingMergeFilesDetail);\r\n"
        "    if (ABackupPath <> '') and FileExists(ABackupPath) then",
        "    FFHistoryAppendMergeFiles(FPendingMergeFilesDest, FPendingMergeFilesSource, FPendingMergeFilesDetail);\r\n"
        "    if (FPendingMergeFilesBackup <> '') and FileExists(FPendingMergeFilesBackup) then",
    ),
    (
        "      P^.OldContent := ABackupPath;\r\n"
        "      P^.NewContent := ADest;",
        "      P^.OldContent := FPendingMergeFilesBackup;\r\n"
        "      P^.NewContent := FPendingMergeFilesDest;",
    ),
]


def main():
    text = MAIN.read_text(encoding="utf-8", errors="replace")
    if "\r\n" not in text:
        text = text.replace("\n", "\r\n")
    applied = 0
    for old, new in REPLACEMENTS:
        if old in text:
            text = text.replace(old, new, 1)
            applied += 1
        else:
            old_lf = old.replace("\r\n", "\n")
            new_lf = new.replace("\r\n", "\n")
            if old_lf in text:
                text = text.replace(old_lf, new_lf, 1)
                applied += 1
            else:
                print("MISSING:", old[:70].replace("\r\n", " | "))
    MAIN.write_text(text.replace("\r\n", "\n"), encoding="utf-8", newline="\n")
    print(f"Applied {applied}/{len(REPLACEMENTS)} replacements")


if __name__ == "__main__":
    main()
