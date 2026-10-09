unit uAgentPatch;

{
  Proposed changes from the agent and how they reach the disk.

  Nothing here talks to a form. Line edits, inserts and deletes go through the
  Compare/merge engine (uMergeApply): one pass per file, only the changed region
  is rebuilt, in place when it fits, journal written to the session history.
  Anonymize goes through uAnonymize: same byte length, written in place.

  Every line number in a batch refers to the file as it was when the agent read
  it. Proposals in one batch do not shift each other.
}

interface

uses
  Windows, SysUtils, Classes, Generics.Collections, uAnonymize, uFastFileAssistantHost;

type
  { aekAction: a FastFile core action (Action.ActionId), run through the Assistant dispatcher on Accept. }
  TAgentEditKind = (aekReplace, aekInsert, aekDelete, aekAnonymize, aekAction);

  TAgentEdit = class
  public
    Kind: TAgentEditKind;
    Path: string;
    { Replace/Delete/Anonymize: LineStart..LineEnd. Insert: before LineStart.
      Anonymize with LineEnd = 0: from LineStart to the end of the file. }
    LineStart: Int64;
    LineEnd: Int64;
    NewText: string;
    Anon: TAnonOptions;
    AnonInfo: string;
    Action: TAssistantChainStep;
    { Preview rows built off the UI thread; PreviewKey ties them to the lines and the file version. Not cloned. }
    PreviewText: string;
    PreviewKey: string;
    { Records selected by the criterion of an export action; -1 when it has no criterion. }
    MatchCount: Int64;
    constructor Create;
    function Clone: TAgentEdit;
    function NewLineCount: Integer;
    { Lines added minus lines removed once applied. }
    function LineDelta: Int64;
  end;

  TAgentApplyResult = record
    Applied: Integer;
    Missing: Integer;
    SameLayout: Boolean;
    Cancelled: Boolean;
    Err: string;
    Mode: string;
  end;

{ Applies every edit in AEdits (all on APath). AWnd/AMsg receive the merge
  engine messages (cMaMsgRelease is sent synchronously before a file swap).
  Must run on a worker thread: it waits for the merge thread. }
function AgentApplyFileEdits(const APath, AIndexPath: string; AEdits: TList<TAgentEdit>;
  AWnd: HWND; AMsg: UINT; const ACancel: TFunc<Boolean>; out AResult: TAgentApplyResult): Boolean;

function AgentSplitLines(const S: string): TStringList;
function AgentReadLineWindow(const APath: string; AStart, AEnd: Int64;
  AMaxLines: Integer; const AIndexPath: string = ''; ACancelFlag: PInteger = nil): string;
{ Before/after of the first AMaxLines lines of an anonymize proposal. }
function AgentAnonPreview(AEdit: TAgentEdit; const AIndexPath: string; AMaxLines: Integer;
  ACancelFlag: PInteger = nil): string;

implementation

uses
  Math, uMergeApply, uAgentTools, uFastFilePaths, uTextEncoding, uEolPolicy,
  uFileSessionHistory;

function AgentSplitLines(const S: string): TStringList;
var
  I, StartAt: Integer;
  Ch: Char;
begin
  Result := TStringList.Create;
  if S = '' then Exit;
  StartAt := 1;
  I := 1;
  while I <= Length(S) do
  begin
    Ch := S[I];
    if (Ch = #10) or (Ch = #13) then
    begin
      Result.Add(Copy(S, StartAt, I - StartAt));
      if (Ch = #13) and (I < Length(S)) and (S[I + 1] = #10) then
        Inc(I);
      StartAt := I + 1;
    end;
    Inc(I);
  end;
  if StartAt <= Length(S) then
    Result.Add(Copy(S, StartAt, MaxInt));
end;

{ TAgentEdit }

constructor TAgentEdit.Create;
begin
  inherited Create;
  MatchCount := -1;
end;

function TAgentEdit.Clone: TAgentEdit;
begin
  Result := TAgentEdit.Create;
  Result.Kind := Kind;
  Result.Path := Path;
  Result.LineStart := LineStart;
  Result.LineEnd := LineEnd;
  Result.NewText := NewText;
  Result.Anon := Anon;
  Result.AnonInfo := AnonInfo;
  Result.Action := Action;
  Result.MatchCount := MatchCount;
end;

function TAgentEdit.NewLineCount: Integer;
var
  SL: TStringList;
begin
  if Kind in [aekDelete, aekAnonymize, aekAction] then
    Exit(0);
  SL := AgentSplitLines(NewText);
  try
    Result := Max(1, SL.Count);
  finally
    SL.Free;
  end;
end;

function TAgentEdit.LineDelta: Int64;
begin
  case Kind of
    aekReplace: Result := NewLineCount - (LineEnd - LineStart + 1);
    aekInsert: Result := NewLineCount;
    aekDelete: Result := -(LineEnd - LineStart + 1);
  else
    Result := 0;
  end;
end;

{ --- anonymize ------------------------------------------------------------------ }

type
  TAnonCancelProbe = class
  public
    Fn: TFunc<Boolean>;
    function Query: Boolean;
  end;

function TAnonCancelProbe.Query: Boolean;
begin
  Result := Assigned(Fn) and Fn();
end;

function FileSize64(const APath: string): Int64;
var
  F: TFileStream;
begin
  F := TFileStream.Create(APath, fmOpenRead or fmShareDenyNone);
  try
    Result := F.Size;
  finally
    F.Free;
  end;
end;

function AnonymizeOne(AEdit: TAgentEdit; const AIndexPath: string;
  const ACancel: TFunc<Boolean>; out AErr: string; out ACancelled: Boolean): Boolean;
var
  Ranges: TAnonRanges;
  StartOfs, EndOfs: Int64;
  R: TAnonJobResult;
  Hist: TStringList;
  Count: Int64;
  Probe: TAnonCancelProbe;
begin
  Result := False;
  AErr := '';
  ACancelled := False;
  SetLength(Ranges, 0);
  if (AEdit.LineStart > 1) or (AEdit.LineEnd > 0) then
  begin
    if not AgentLineOffset(AEdit.Path, AEdit.LineStart, AIndexPath, nil, StartOfs) then
    begin
      AErr := 'line ' + IntToStr(AEdit.LineStart) + ' is past the end of the file';
      Exit;
    end;
    if (AEdit.LineEnd <= 0) or not AgentLineOffset(AEdit.Path, AEdit.LineEnd + 1, AIndexPath, nil, EndOfs) then
      EndOfs := FileSize64(AEdit.Path);
    SetLength(Ranges, 1);
    Ranges[0].Start := StartOfs;
    Ranges[0].Len := EndOfs - StartOfs;
    if Ranges[0].Len <= 0 then
    begin
      AErr := 'empty range';
      Exit;
    end;
  end;
  Probe := TAnonCancelProbe.Create;
  try
    Probe.Fn := ACancel;
    R := AnonApplyToFile(AEdit.Path, '', AEdit.Anon, DetectTextFileEncoding(AEdit.Path),
      Ranges, nil, Probe.Query);
  finally
    Probe.Free;
  end;
  if R.Cancelled then
  begin
    ACancelled := True;
    Exit;
  end;
  if not R.Success then
  begin
    AErr := R.ErrorMsg;
    if AErr = '' then
      AErr := 'anonymize failed';
    Exit;
  end;
  if AEdit.LineEnd > 0 then
    Count := AEdit.LineEnd - AEdit.LineStart + 1
  else
    Count := 0;
  Hist := TStringList.Create;
  try
    Hist.Add('ANON|' + IntToStr(AEdit.LineStart) + '|' + IntToStr(Count) + '|' +
      FFHistorySanitizeField(AEdit.AnonInfo, 200));
    FFHistoryAppendOpLines(AEdit.Path, Hist);
  finally
    Hist.Free;
  end;
  Result := True;
end;

{ --- line edits through uMergeApply ------------------------------------------------ }

type
  TOpBuilder = class
  public
    Ops: TList<TMaOp>;
    Spill: TFileStream;
    SpillLine: Int64;
    Enc: string;
    Seq: Integer;
    constructor Create(const ASpillPath, AEnc: string);
    destructor Destroy; override;
    function AddText(const S: string): Int64;
    procedure Add(AKind: TMaKind; ATgt, ASrc: Int64);
    procedure AddEdit(E: TAgentEdit);
  end;

constructor TOpBuilder.Create(const ASpillPath, AEnc: string);
begin
  inherited Create;
  Ops := TList<TMaOp>.Create;
  Spill := TFileStream.Create(ASpillPath, fmCreate);
  Enc := AEnc;
end;

destructor TOpBuilder.Destroy;
begin
  Spill.Free;
  Ops.Free;
  inherited;
end;

function TOpBuilder.AddText(const S: string): Int64;
var
  B: AnsiString;
  Lf: AnsiChar;
begin
  B := UnicodeTextToFileBytes(S, Enc);
  { The spill separates lines with one LF byte and the reader trims a trailing CR byte. }
  if (Pos(AnsiString(#10), B) > 0) or (Pos(AnsiString(#13), B) > 0) then
    raise Exception.Create('line edits are not supported for this file encoding (' + Enc + ')');
  if B <> '' then
    Spill.WriteBuffer(B[1], Length(B));
  Lf := #10;
  Spill.WriteBuffer(Lf, 1);
  Inc(SpillLine);
  Result := SpillLine;
end;

procedure TOpBuilder.Add(AKind: TMaKind; ATgt, ASrc: Int64);
var
  Op: TMaOp;
begin
  Op.Kind := AKind;
  Op.TgtLine := ATgt;
  Op.SrcLine := ASrc;
  Op.Seq := Seq;
  Inc(Seq);
  Ops.Add(Op);
end;

procedure TOpBuilder.AddEdit(E: TAgentEdit);
var
  Lines: TStringList;
  I, OldCount, Common: Int64;
begin
  if E.Kind = aekDelete then
  begin
    I := E.LineStart;
    while I <= E.LineEnd do
    begin
      Add(makDelete, I, 0);
      Inc(I);
    end;
    Exit;
  end;
  Lines := AgentSplitLines(E.NewText);
  try
    if Lines.Count = 0 then
      Lines.Add('');
    if E.Kind = aekInsert then
    begin
      for I := 0 to Lines.Count - 1 do
        Add(makInsert, E.LineStart, AddText(Lines[I]));
      Exit;
    end;
    OldCount := E.LineEnd - E.LineStart + 1;
    Common := Min(OldCount, Int64(Lines.Count));
    for I := 0 to Common - 1 do
      Add(makEdit, E.LineStart + I, AddText(Lines[I]));
    for I := Common to Lines.Count - 1 do
      Add(makInsert, E.LineEnd + 1, AddText(Lines[I]));
    I := E.LineStart + Common;
    while I <= E.LineEnd do
    begin
      Add(makDelete, I, 0);
      Inc(I);
    end;
  finally
    Lines.Free;
  end;
end;

function ApplyLineEdits(const APath: string; AEdits: TList<TAgentEdit>; AWnd: HWND; AMsg: UINT;
  const ACancel: TFunc<Boolean>; var AResult: TAgentApplyResult): Boolean;
var
  B: TOpBuilder;
  SpillPath, Enc: string;
  I: Integer;
  T: TMergeApplyThread;
  Parts: TArray<string>;
begin
  Result := True;
  Enc := DetectTextFileEncoding(APath);
  SpillPath := FastFileScratchTempPath('agentspill');
  B := TOpBuilder.Create(SpillPath, Enc);
  try
    for I := 0 to AEdits.Count - 1 do
      if AEdits[I].Kind in [aekReplace, aekInsert, aekDelete] then
        B.AddEdit(AEdits[I]);
    FreeAndNil(B.Spill);
    if B.Ops.Count = 0 then Exit;
    { Spill holds new lines already in the target encoding: raw copy, no conversion. }
    T := TMergeApplyThread.Create(SpillPath, APath, EnsureFastFileTempSubDir('merge'),
      '', Enc, 10, Byte(LineTermCharForFile(APath)),
      RawByteString(OutputEolForFile(APath)), B.Ops.ToArray, AWnd, AMsg);
    try
      T.CancelPoll := ACancel;
      T.Start;
      T.WaitFor;
      Inc(AResult.Applied, T.AppliedCount);
      Inc(AResult.Missing, T.MissingLines);
      AResult.SameLayout := AResult.SameLayout and T.SameLayout;
      AResult.Mode := T.TimingText;
      if T.Cancelled then
      begin
        AResult.Cancelled := True;
        Result := False;
      end
      else if not T.Succeeded then
      begin
        Result := False;
        if T.ErrorMsg = '*changed*' then
          AResult.Err := 'changed'
        else if Copy(T.ErrorMsg, 1, 8) = '*space*|' then
        begin
          Parts := T.ErrorMsg.Split(['|']);
          AResult.Err := Format('space|%s|%s', [Parts[1], Parts[2]]);
        end
        else
          AResult.Err := T.ErrorMsg;
      end;
    finally
      T.Free;
    end;
  finally
    B.Free;
    if FileExists(SpillPath) then
      DeleteFile(SpillPath);
  end;
end;

function AgentApplyFileEdits(const APath, AIndexPath: string; AEdits: TList<TAgentEdit>;
  AWnd: HWND; AMsg: UINT; const ACancel: TFunc<Boolean>; out AResult: TAgentApplyResult): Boolean;
var
  I: Integer;
  Err: string;
  Stop: Boolean;
begin
  AResult.Applied := 0;
  AResult.Missing := 0;
  AResult.SameLayout := True;
  AResult.Cancelled := False;
  AResult.Err := '';
  AResult.Mode := '';
  Result := False;
  if not FileExists(APath) then
  begin
    AResult.Err := 'file not found';
    Exit;
  end;
  try
    { Anonymize first: same byte length, so the line numbers of the other edits still hold. }
    for I := 0 to AEdits.Count - 1 do
      if AEdits[I].Kind = aekAnonymize then
      begin
        if Assigned(ACancel) and ACancel() then
        begin
          AResult.Cancelled := True;
          Exit;
        end;
        if not AnonymizeOne(AEdits[I], AIndexPath, ACancel, Err, Stop) then
        begin
          AResult.Cancelled := Stop;
          AResult.Err := Err;
          Exit;
        end;
        Inc(AResult.Applied);
      end;
    Result := ApplyLineEdits(APath, AEdits, AWnd, AMsg, ACancel, AResult);
  except
    on E: Exception do
    begin
      AResult.Err := E.Message;
      Result := False;
    end;
  end;
end;

function AgentReadLineWindow(const APath: string; AStart, AEnd: Int64;
  AMaxLines: Integer; const AIndexPath: string; ACancelFlag: PInteger): string;
var
  Count: Integer;
begin
  if AEnd < AStart then
    AEnd := AStart;
  Count := Integer(Min(AEnd - AStart + 1, Int64(AMaxLines)));
  Result := AgentToolReadLines(APath, AStart, Count, ACancelFlag, AIndexPath);
end;

function AgentAnonPreview(AEdit: TAgentEdit; const AIndexPath: string; AMaxLines: Integer;
  ACancelFlag: PInteger): string;
var
  Lines: TAgentRawLines;
  Engine: TAnonEngine;
  Enc: string;
  SL: TStringList;
  I, Count: Integer;
  NewRaw: AnsiString;
  Changed: Boolean;
begin
  Result := '';
  Count := AMaxLines;
  if (AEdit.LineEnd > 0) and (AEdit.LineEnd - AEdit.LineStart + 1 < Count) then
    Count := Integer(AEdit.LineEnd - AEdit.LineStart + 1);
  Lines := AgentReadRawLines(AEdit.Path, AEdit.LineStart, Count, AIndexPath, ACancelFlag);
  if Length(Lines) = 0 then Exit;
  Enc := DetectTextFileEncoding(AEdit.Path);
  Engine := TAnonEngine.Create(AEdit.Anon, Enc);
  SL := TStringList.Create;
  try
    for I := 0 to High(Lines) do
    begin
      NewRaw := AnonPreviewBytes(Engine, Lines[I].Raw, Lines[I].Ofs, Changed);
      if Changed then
      begin
        SL.Add(Format('- %d| %s', [Lines[I].LineNo, FileBytesToUnicodeText(Lines[I].Raw, Enc)]));
        SL.Add(Format('+ %d| %s', [Lines[I].LineNo, FileBytesToUnicodeText(NewRaw, Enc)]));
      end
      else
        SL.Add(Format('  %d| %s', [Lines[I].LineNo, FileBytesToUnicodeText(Lines[I].Raw, Enc)]));
    end;
    Result := SL.Text;
  finally
    SL.Free;
    Engine.Free;
  end;
end;

end.
