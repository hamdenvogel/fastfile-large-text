unit uLineEditor;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Clipbrd, CheckLst, Generics.Collections;

type
  TOperationType = (otInsert, otReplace, otEdit, otDelete, otDuplicate);

  TLineEditorGetLineEvent = function(ALine1Based: Int64): string of object;
  TLineEditorGetCountEvent = function: Int64 of object;

  TLineEditorState = record
    Text: string;
    SelStart, SelLen: Integer;
  end;

  TfrmLineEditor = class(TForm)
    Label1: TLabel;
    cbOperation: TComboBox;
    Label2: TLabel;
    edtLineNumber: TEdit;
    Label3: TLabel;
    pnlMemoTools: TPanel;
    btnSelectAll: TButton;
    btnCopy: TButton;
    btnPaste: TButton;
    btnClear: TButton;
    btnAskAI: TButton;
    mmContent: TMemo;
    pnlFooter: TPanel;
    btnConfirm: TButton;
    btnCancel: TButton;
    Bevel1: TBevel;
    chkMergeLines: TCheckBox;
    pnlMerge: TPanel;
    lblMergeHint: TLabel;
    clbMerge: TCheckListBox;
    procedure cbOperationChange(Sender: TObject);
    procedure btnConfirmClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormResize(Sender: TObject);
    procedure mmContentKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnSelectAllClick(Sender: TObject);
    procedure btnCopyClick(Sender: TObject);
    procedure btnPasteClick(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
    procedure btnAskAIClick(Sender: TObject);
    procedure chkMergeLinesClick(Sender: TObject);
    procedure clbMergeClickCheck(Sender: TObject);
  private
    FGetLine: TLineEditorGetLineEvent;
    FGetCount: TLineEditorGetCountEvent;
    FMergeDeleteLines: TList;
    FUpdatingMergePreview: Boolean;
    FpnlFind: TPanel;
    FlblFind: TLabel;
    FedtFind: TEdit;
    FbtnFindPrev: TButton;
    FbtnFindNext: TButton;
    FlblFindCount: TLabel;
    FchkFindCase: TCheckBox;
    FchkFindWord: TCheckBox;
    FchkFindAccents: TCheckBox;
    FchkFindRegex: TCheckBox;
    FFindTimer: TTimer;
    FFindHits: TArray<TPoint>;
    FFindText: string;
    FFindCur: Integer;
    FFindAnchor: Integer;
    FFindError: string;
    FOldMemoWndProc: TWndMethod;
    FOldFindEditWndProc: TWndMethod;
    FlblRepl: TLabel;
    FedtRepl: TEdit;
    FbtnReplOne: TButton;
    FbtnReplAll: TButton;
    FOldReplEditWndProc: TWndMethod;
    FSuppressCtrlChar: Boolean;
    FEmptyReplOk: Boolean;
    FbtnUndo: TButton;
    FbtnRedo: TButton;
    FUndoList: TList<TLineEditorState>;
    FRedoList: TList<TLineEditorState>;
    FLastState: TLineEditorState;
    FPendingState: TLineEditorState;
    FTypingGroup: Boolean;
    FUndoTimer: TTimer;
    FUndoDepth: Integer;
    FAIThread: TThread;
    FAskAIInProgress: Boolean;
    FAskAICaption: string;
    FAskAIOldConfirmEnabled: Boolean;
    FAskAIOldCancelEnabled: Boolean;
    FAskAIOldMemoEnabled: Boolean;
    FAskAIOldAskEnabled: Boolean;
    procedure CreateUndo;
    function CurState: TLineEditorState;
    procedure PushUndo(const AState: TLineEditorState);
    procedure UndoBegin;
    procedure UndoEnd;
    procedure UndoReset;
    procedure ApplyState(const AState: TLineEditorState);
    procedure DoUndo;
    procedure DoRedo;
    procedure UpdateUndoButtons;
    procedure UndoTimerTick(Sender: TObject);
    procedure btnUndoClick(Sender: TObject);
    procedure btnRedoClick(Sender: TObject);
    procedure LayoutMemoTools;
    function MemoToolsWantedWidth: Integer;
    function FindTextMissing: Boolean;
    function FindFailed(const AErr: string; AHits: Integer): Boolean;
    function ConfirmEmptyReplace(ACount: Integer; AOnce: Boolean): Boolean;
    procedure edtReplChange(Sender: TObject);
  private
    FbtnPrevLine: TButton;
    FbtnNextLine: TButton;
    FOrigText: string;
    FOrigLineNo: Int64;
    FLineCount: Int64;
    procedure CreateAdjacentButtons;
    procedure LayoutAdjacentButtons;
    procedure UpdateAdjacentButtons;
    function AdjacentLineNo(ADir: Integer): Int64;
    function AdjacentLineText(ALine: Int64; out AText: string): Boolean;
    procedure btnPrevLineClick(Sender: TObject);
    procedure btnNextLineClick(Sender: TObject);
    procedure edtLineNumberChange(Sender: TObject);
    function IsInsertOp: Boolean;
    procedure CreateFindBar;
    procedure LayoutFindBar;
    procedure ApplyFindCaptions;
    function ScanMatches(const AText: string; out AHits: TArray<TPoint>;
      AReps: TStringList; out AErr: string): Integer;
    procedure RecomputeFind(ASelect: Boolean);
    procedure ReplaceCurrent;
    procedure ReplaceAll;
    procedure FocusReplace;
    procedure ReplEditWndProc(var Msg: TMessage);
    procedure edtReplKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure edtReplKeyPress(Sender: TObject; var Key: Char);
    procedure btnReplOneClick(Sender: TObject);
    procedure btnReplAllClick(Sender: TObject);
    procedure FormKeyPressFind(Sender: TObject; var Key: Char);
    procedure SelectFindHit(AIndex: Integer);
    procedure FindStep(ADir: Integer);
    procedure UpdateFindCount;
    procedure FocusFind;
    procedure MemoWndProc(var Msg: TMessage);
    procedure FindEditWndProc(var Msg: TMessage);
    procedure PaintFindHits;
    procedure edtFindChange(Sender: TObject);
    procedure edtFindEnter(Sender: TObject);
    procedure edtFindKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure edtFindKeyPress(Sender: TObject; var Key: Char);
    procedure btnFindPrevClick(Sender: TObject);
    procedure btnFindNextClick(Sender: TObject);
    procedure chkFindOptionClick(Sender: TObject);
    procedure mmContentChange(Sender: TObject);
    procedure FindTimerTick(Sender: TObject);
    procedure MemoSelectAll;
    procedure MemoCopy;
    procedure MemoPaste;
    procedure UpdateMemoToolButtons;
    procedure ApplyUiLanguage;
    procedure LayoutMergePanel(AShow: Boolean; AAdjustHeight: Boolean = True);
    procedure PopulateMergeList;
    procedure RefreshMergePreview;
    function CollectMergeSelection(out ATargetLine: Int64;
      ADeleteLines: TList; out AJoined: string;
      const ASilent: Boolean = False): Boolean;
    function PromptAskAiGoal(out AGoal: string): Boolean;
    procedure AskAIResult(AOk: Boolean; const AAnswer: WideString; const AError: string);
  public
    destructor Destroy; override;
    { AMergeDeleteLines: optional list of Int64 line numbers to delete after editing
      the kept (lowest) line with the joined TextContent.
      AInsertAfter: when Op=otInsert, insert after LineNum (target becomes LineNum+1). }
    class function Execute(var Op: TOperationType; var LineNum: Int64;
      var TextContent: String; const ALockOperation: Boolean = False;
      AGetLine: TLineEditorGetLineEvent = nil;
      AGetCount: TLineEditorGetCountEvent = nil;
      AMergeDeleteLines: TList = nil;
      const AInsertAfter: Boolean = False): Boolean;
  end;

var
  frmLineEditor: TfrmLineEditor;

implementation

uses
  Math, StrUtils, Character, RegularExpressions, Menus,
  uTextEncoding, uI18n, uFastFileMsgDlg, uFastFileAIClient, uFastFileScale;

{$R *.dfm}

const
  cFindMaxHits = 200000;
  cFindHitColor = $0066E6FF;
  cFindCurColor = $003399FF;

  cKeySelectAll = 'Ctrl+A';
  cKeyCopy = 'Ctrl+C';
  cKeyPaste = 'Ctrl+V';
  cKeyClear = 'Ctrl+Shift+Del';
  cKeyAskAI = 'Ctrl+Shift+A';
  cKeyPrevLine = 'Alt+' + #$2191;
  cKeyNextLine = 'Alt+' + #$2193;
  cKeyReplOne = 'F4';
  cKeyReplAll = 'Shift+F4';
  cKeyUndo = 'Ctrl+Z';
  cKeyRedo = 'Ctrl+Y';
  cKeyConfirm = 'Ctrl+Enter';
  cKeyCancel = 'Esc';

type
  TLineEditorAIThread = class(TThread)
  private
    FOwner: TfrmLineEditor;
    FPrompt: WideString;
    FAnswer: WideString;
    FError: string;
    FOk: Boolean;
    procedure ApplyResult;
  protected
    procedure Execute; override;
  public
    constructor Create(AOwner: TfrmLineEditor; const APrompt: WideString);
  end;

constructor TLineEditorAIThread.Create(AOwner: TfrmLineEditor;
  const APrompt: WideString);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FOwner := AOwner;
  FPrompt := APrompt;
end;

procedure TLineEditorAIThread.Execute;
begin
  try
    FOk := FastFileAIInvokePrompt(FPrompt, FAnswer, FError);
  except
    on E: Exception do
    begin
      FOk := False;
      FError := E.Message;
    end;
  end;
  Synchronize(ApplyResult);
end;

procedure TLineEditorAIThread.ApplyResult;
begin
  if Assigned(FOwner) then
    FOwner.AskAIResult(FOk, FAnswer, FError);
end;

function KeyText(const AKeys: string): string;
var
  Parts: TStringList;
  i: Integer;
  P: string;
begin
  Result := '';
  Parts := TStringList.Create;
  try
    Parts.Delimiter := '+';
    Parts.StrictDelimiter := True;
    Parts.DelimitedText := AKeys;
    for i := 0 to Parts.Count - 1 do
    begin
      P := Parts[i];
      if P = 'Ctrl' then P := TrText('LineEditor.KeyCtrl')
      else if P = 'Shift' then P := TrText('LineEditor.KeyShift')
      else if P = 'Alt' then P := TrText('LineEditor.KeyAlt')
      else if P = 'Del' then P := TrText('LineEditor.KeyDel')
      else if P = 'Enter' then P := TrText('LineEditor.KeyEnter')
      else if P = 'Esc' then P := TrText('LineEditor.KeyEsc');
      if i > 0 then
        Result := Result + '+';
      Result := Result + P;
    end;
  finally
    Parts.Free;
  end;
end;

function WithKey(const ACaption, AKeys: string): string;
begin
  Result := ACaption + ' (' + KeyText(AKeys) + ')';
end;

function FitButtonWidth(ABtn: TButton; AMin: Integer = 0): Integer;
var
  Bmp: TBitmap;
begin
  Bmp := TBitmap.Create;
  try
    Bmp.Canvas.Font.Assign(ABtn.Font);
    Result := Bmp.Canvas.TextWidth(StripHotkey(ABtn.Caption)) + FfPx(32);
  finally
    Bmp.Free;
  end;
  if Result < AMin then
    Result := AMin;
end;

var
  GFindCase: Boolean = False;
  GFindWord: Boolean = False;
  GFindAccents: Boolean = True;
  GFindRegex: Boolean = False;

{ Remove acentos mantendo o comprimento (indices do resultado = indices do memo). }
function FindFoldAccents(const S: string): string;
const
  cExtA = 'AaAaAa' + 'CcCcCcCc' + 'DdDd' + 'EeEeEeEeEe' + 'GgGgGgGg' + 'HhHh' +
    'IiIiIiIiIiIi' + 'Jj' + 'Kkk' + 'LlLlLlLlLl' + 'NnNnNnn' + 'Nn' + 'OoOoOoOo' +
    'RrRrRr' + 'SsSsSsSs' + 'TtTtTt' + 'UuUuUuUuUuUu' + 'Ww' + 'YyY' + 'ZzZzZz' + 's';
var
  i, o: Integer;
  c: Char;
begin
  Result := S;
  UniqueString(Result);
  for i := 1 to Length(Result) do
  begin
    o := Ord(Result[i]);
    if o < $C0 then Continue;
    case o of
      $C0..$C5: c := 'A';
      $C7: c := 'C';
      $C8..$CB: c := 'E';
      $CC..$CF: c := 'I';
      $D1: c := 'N';
      $D2..$D6, $D8: c := 'O';
      $D9..$DC: c := 'U';
      $DD: c := 'Y';
      $E0..$E5: c := 'a';
      $E7: c := 'c';
      $E8..$EB: c := 'e';
      $EC..$EF: c := 'i';
      $F1: c := 'n';
      $F2..$F6, $F8: c := 'o';
      $F9..$FC: c := 'u';
      $FD, $FF: c := 'y';
      $100..$17F: c := cExtA[o - $100 + 1];
      $218: c := 'S';
      $219: c := 's';
      $21A: c := 'T';
      $21B: c := 't';
    else
      Continue;
    end;
    Result[i] := c;
  end;
end;

function FindIsWordChar(C: Char): Boolean;
begin
  Result := C.IsLetterOrDigit or (C = '_');
end;

procedure ShowAppMessage(const Msg: string);
begin
  FastFileMsgInfo(TrText(Msg));
end;

procedure TfrmLineEditor.CreateFindBar;

  function NewChk(AChecked: Boolean): TCheckBox;
  begin
    Result := TCheckBox.Create(Self);
    Result.Parent := FpnlFind;
    Result.Checked := AChecked;
    Result.OnClick := chkFindOptionClick;
    Result.ShowHint := True;
  end;

begin
  if Assigned(FpnlFind) then Exit;
  FpnlFind := TPanel.Create(Self);
  FpnlFind.Parent := Self;
  FpnlFind.BevelOuter := bvNone;
  FpnlFind.ParentBackground := False;
  FpnlFind.Color := clBtnFace;
  FpnlFind.Caption := '';
  FpnlFind.TabOrder := pnlMemoTools.TabOrder + 1;

  FlblFind := TLabel.Create(Self);
  FlblFind.Parent := FpnlFind;
  FlblFind.Font.Style := [fsBold];

  FedtFind := TEdit.Create(Self);
  FedtFind.Parent := FpnlFind;
  FedtFind.OnChange := edtFindChange;
  FedtFind.OnEnter := edtFindEnter;
  FedtFind.OnKeyDown := edtFindKeyDown;
  FedtFind.OnKeyPress := edtFindKeyPress;
  FedtFind.ShowHint := True;
  FOldFindEditWndProc := FedtFind.WindowProc;
  FedtFind.WindowProc := FindEditWndProc;

  FbtnFindPrev := TButton.Create(Self);
  FbtnFindPrev.Parent := FpnlFind;
  FbtnFindPrev.Caption := #$25B2;
  FbtnFindPrev.OnClick := btnFindPrevClick;
  FbtnFindPrev.ShowHint := True;

  FbtnFindNext := TButton.Create(Self);
  FbtnFindNext.Parent := FpnlFind;
  FbtnFindNext.Caption := #$25BC;
  FbtnFindNext.OnClick := btnFindNextClick;
  FbtnFindNext.ShowHint := True;

  FlblFindCount := TLabel.Create(Self);
  FlblFindCount.Parent := FpnlFind;
  FlblFindCount.AutoSize := False;
  FlblFindCount.Layout := tlCenter;
  FlblFindCount.EllipsisPosition := epEndEllipsis;
  FlblFindCount.ShowHint := True;

  FlblRepl := TLabel.Create(Self);
  FlblRepl.Parent := FpnlFind;
  FlblRepl.Font.Style := [fsBold];

  FedtRepl := TEdit.Create(Self);
  FedtRepl.Parent := FpnlFind;
  FedtRepl.OnKeyDown := edtReplKeyDown;
  FedtRepl.OnChange := edtReplChange;
  FedtRepl.OnKeyPress := edtReplKeyPress;
  FedtRepl.ShowHint := True;
  FOldReplEditWndProc := FedtRepl.WindowProc;
  FedtRepl.WindowProc := ReplEditWndProc;

  FbtnReplOne := TButton.Create(Self);
  FbtnReplOne.Parent := FpnlFind;
  FbtnReplOne.OnClick := btnReplOneClick;
  FbtnReplOne.ShowHint := True;

  FbtnReplAll := TButton.Create(Self);
  FbtnReplAll.Parent := FpnlFind;
  FbtnReplAll.OnClick := btnReplAllClick;
  FbtnReplAll.ShowHint := True;

  FchkFindCase := NewChk(GFindCase);
  FchkFindWord := NewChk(GFindWord);
  FchkFindAccents := NewChk(GFindAccents);
  FchkFindRegex := NewChk(GFindRegex);

  FFindTimer := TTimer.Create(Self);
  FFindTimer.Enabled := False;
  FFindTimer.Interval := 250;
  FFindTimer.OnTimer := FindTimerTick;

  OnKeyPress := FormKeyPressFind;
  FFindCur := -1;
  FFindAnchor := 0;
  mmContent.HideSelection := False;
  mmContent.OnChange := mmContentChange;
  FOldMemoWndProc := mmContent.WindowProc;
  mmContent.WindowProc := MemoWndProc;

  { Barra de procura entre as ferramentas do memo e o memo. }
  FpnlFind.SetBounds(mmContent.Left, pnlMemoTools.Top + pnlMemoTools.Height + FfPx(2),
    mmContent.Width, FfPx(76));
  mmContent.Top := FpnlFind.Top + FpnlFind.Height + FfPx(2);
  ApplyFindCaptions;
end;

procedure TfrmLineEditor.ApplyFindCaptions;
begin
  if not Assigned(FpnlFind) then Exit;
  FlblFind.Caption := TrText('LineEditor.Find');
  FedtFind.TextHint := TrText('LineEditor.FindCue');
  FedtFind.Hint := TrText('LineEditor.FindHint');
  FbtnFindPrev.Hint := TrText('LineEditor.FindPrevHint');
  FbtnFindNext.Hint := TrText('LineEditor.FindNextHint');
  FchkFindCase.Caption := TrText('LineEditor.FindCase');
  FchkFindWord.Caption := TrText('LineEditor.FindWord');
  FchkFindAccents.Caption := TrText('LineEditor.FindAccents');
  FchkFindRegex.Caption := TrText('LineEditor.FindRegex');
  FchkFindRegex.Hint := TrText('LineEditor.FindRegexHint');
  FlblRepl.Caption := TrText('LineEditor.Replace');
  FedtRepl.TextHint := TrText('LineEditor.ReplaceCue');
  FedtRepl.Hint := TrText('LineEditor.ReplaceHint');
  FbtnReplOne.Caption := WithKey(TrText('LineEditor.ReplaceOne'), cKeyReplOne);
  FbtnReplOne.Hint := TrText('LineEditor.ReplaceHint');
  FbtnReplAll.Caption := WithKey(TrText('LineEditor.ReplaceAll'), cKeyReplAll);
  FbtnReplAll.Hint := TrText('LineEditor.ReplaceHint');
  LayoutFindBar;
  UpdateFindCount;
end;

procedure TfrmLineEditor.LayoutFindBar;
var
  W, x, y, bw, cntW, rowH: Integer;

  function TextW(const S: string): Integer;
  begin
    Canvas.Font := Font;
    Result := Canvas.TextWidth(S);
  end;

  procedure PlaceChk(AChk: TCheckBox);
  var
    cw: Integer;
    Bmp: TBitmap;
  begin
    Bmp := TBitmap.Create;
    try
      Bmp.Canvas.Font.Assign(AChk.Font);
      cw := Bmp.Canvas.TextWidth(AChk.Caption);
    finally
      Bmp.Free;
    end;
    cw := Max(cw, TextW(AChk.Caption));
    Inc(cw, Max(GetSystemMetrics(SM_CXMENUCHECK), FfPx(13)) + FfPx(16));
    AChk.SetBounds(x, y, cw, FfPx(17));
    Inc(x, cw + FfPx(10));
  end;

var
  lblW, y2, rw1, rw2: Integer;
begin
  if not Assigned(FpnlFind) then Exit;
  FpnlFind.SetBounds(pnlMemoTools.Left, pnlMemoTools.Top + pnlMemoTools.Height + FfPx(2),
    pnlMemoTools.Width, FpnlFind.Height);
  W := FpnlFind.ClientWidth;
  rowH := FedtFind.Height;
  Canvas.Font := FlblFind.Font;
  lblW := Max(Canvas.TextWidth(FlblFind.Caption), Canvas.TextWidth(FlblRepl.Caption));
  FlblFind.SetBounds(0, (rowH - FlblFind.Height) div 2 + 1, lblW, FlblFind.Height);
  bw := FfPx(26);
  cntW := TextW(Format(TrText('LineEditor.FindCount: %d %d'), [99999, 99999]));
  cntW := Max(FfPx(60), Min(cntW + FfPx(8), W div 3));
  x := lblW + FfPx(6);
  FedtFind.SetBounds(x, 0, Max(FfPx(80), W - x - 2 * (bw + FfPx(3)) - cntW - FfPx(6)), rowH);
  x := FedtFind.Left + FedtFind.Width + FfPx(3);
  FbtnFindPrev.SetBounds(x, 0, bw, rowH);
  Inc(x, bw + FfPx(3));
  FbtnFindNext.SetBounds(x, 0, bw, rowH);
  Inc(x, bw + FfPx(6));
  FlblFindCount.SetBounds(x, 0, Max(FfPx(40), W - x), rowH);

  y2 := rowH + FfPx(4);
  FlblRepl.SetBounds(0, y2 + (rowH - FlblRepl.Height) div 2 + 1, lblW, FlblRepl.Height);
  rw1 := FitButtonWidth(FbtnReplOne);
  rw2 := FitButtonWidth(FbtnReplAll);
  x := lblW + FfPx(6);
  FedtRepl.SetBounds(x, y2, Max(FfPx(80), W - x - rw1 - rw2 - FfPx(9)), rowH);
  x := FedtRepl.Left + FedtRepl.Width + FfPx(3);
  FbtnReplOne.SetBounds(x, y2 - 1, rw1, rowH + 2);
  Inc(x, rw1 + FfPx(6));
  FbtnReplAll.SetBounds(x, y2 - 1, rw2, rowH + 2);

  x := 0;
  y := y2 + rowH + FfPx(6);
  PlaceChk(FchkFindCase);
  PlaceChk(FchkFindWord);
  PlaceChk(FchkFindAccents);
  PlaceChk(FchkFindRegex);
  FpnlFind.Height := y + FfPx(19);
  mmContent.Top := FpnlFind.Top + FpnlFind.Height + FfPx(2);
end;

// Expande $0..$9, ${n}, $$, \n, \t e \\ usando o texto original (sem dobrar acentos).
function FindExpandReplacement(const M: TMatch; const AOrig, ARepl: string): string;
var
  i, g, j: Integer;
  c: Char;

  procedure AddGroup(AIdx: Integer);
  begin
    if (AIdx >= 0) and (AIdx < M.Groups.Count) and M.Groups[AIdx].Success then
      Result := Result + Copy(AOrig, M.Groups[AIdx].Index, M.Groups[AIdx].Length);
  end;

begin
  Result := '';
  i := 1;
  while i <= Length(ARepl) do
  begin
    c := ARepl[i];
    if (c = '$') and (i < Length(ARepl)) then
    begin
      if ARepl[i + 1] = '$' then
      begin
        Result := Result + '$';
        Inc(i, 2);
        Continue;
      end;
      if CharInSet(ARepl[i + 1], ['0'..'9']) then
      begin
        AddGroup(Ord(ARepl[i + 1]) - Ord('0'));
        Inc(i, 2);
        Continue;
      end;
      if ARepl[i + 1] = '{' then
      begin
        j := i + 2;
        g := 0;
        while (j <= Length(ARepl)) and CharInSet(ARepl[j], ['0'..'9']) do
        begin
          g := g * 10 + Ord(ARepl[j]) - Ord('0');
          Inc(j);
        end;
        if (j > i + 2) and (j <= Length(ARepl)) and (ARepl[j] = '}') then
        begin
          AddGroup(g);
          i := j + 1;
          Continue;
        end;
      end;
    end
    else if (c = '\') and (i < Length(ARepl)) then
    begin
      case ARepl[i + 1] of
        'n': begin Result := Result + #13#10; Inc(i, 2); Continue; end;
        't': begin Result := Result + #9; Inc(i, 2); Continue; end;
        '\': begin Result := Result + '\'; Inc(i, 2); Continue; end;
      end;
    end;
    Result := Result + c;
    Inc(i);
  end;
end;

function TfrmLineEditor.ScanMatches(const AText: string; out AHits: TArray<TPoint>;
  AReps: TStringList; out AErr: string): Integer;
var
  Pat, T, P, Repl: string;
  i, n, L: Integer;
  Opts: TRegExOptions;
  M: TMatch;

  procedure AddHit(AStart0, ALen: Integer);
  begin
    if n >= Length(AHits) then
      SetLength(AHits, Max(64, n * 2));
    AHits[n] := Point(AStart0, ALen);
    Inc(n);
  end;

begin
  n := 0;
  AHits := nil;
  AErr := '';
  if Assigned(AReps) then
    AReps.Clear;
  Repl := '';
  if Assigned(FedtRepl) then
    Repl := FedtRepl.Text;
  Pat := FedtFind.Text;
  if Pat <> '' then
  begin
    T := AText;
    P := Pat;
    if FchkFindAccents.Checked then
    begin
      T := FindFoldAccents(T);
      P := FindFoldAccents(P);
    end;
    if FchkFindRegex.Checked then
    begin
      Opts := [roMultiLine];
      if not FchkFindCase.Checked then
        Include(Opts, roIgnoreCase);
      if FchkFindWord.Checked then
        P := '\b(?:' + P + ')\b';
      try
        M := TRegEx.Match(T, P, Opts);
        while M.Success and (n < cFindMaxHits) do
        begin
          if M.Length > 0 then
          begin
            AddHit(M.Index - 1, M.Length);
            if Assigned(AReps) then
              AReps.Add(FindExpandReplacement(M, AText, Repl));
          end;
          M := M.NextMatch;
        end;
      except
        on E: Exception do
        begin
          n := 0;
          if Assigned(AReps) then
            AReps.Clear;
          AErr := TrText('LineEditor.FindBadRegex');
        end;
      end;
    end
    else
    begin
      if not FchkFindCase.Checked then
      begin
        T := AnsiLowerCase(T);
        P := AnsiLowerCase(P);
      end;
      L := Length(P);
      i := PosEx(P, T, 1);
      while (i > 0) and (n < cFindMaxHits) do
      begin
        if FchkFindWord.Checked and
           (((i > 1) and FindIsWordChar(T[i - 1])) or
            ((i + L <= Length(T)) and FindIsWordChar(T[i + L]))) then
        begin
          i := PosEx(P, T, i + 1);
          Continue;
        end;
        AddHit(i - 1, L);
        if Assigned(AReps) then
          AReps.Add(Repl);
        i := PosEx(P, T, i + L);
      end;
    end;
  end;
  SetLength(AHits, n);
  Result := n;
end;

procedure TfrmLineEditor.RecomputeFind(ASelect: Boolean);
var
  i, n, SelS: Integer;
begin
  if not Assigned(FedtFind) then Exit;
  FFindText := mmContent.Text;
  n := ScanMatches(FFindText, FFindHits, nil, FFindError);

  FFindCur := -1;
  if n > 0 then
  begin
    if ASelect then
    begin
      FFindCur := 0;
      for i := 0 to n - 1 do
        if FFindHits[i].X >= FFindAnchor then
        begin
          FFindCur := i;
          Break;
        end;
      SelectFindHit(FFindCur);
    end
    else
    begin
      SelS := mmContent.SelStart;
      for i := 0 to n - 1 do
        if FFindHits[i].X >= SelS then
        begin
          FFindCur := i;
          Break;
        end;
    end;
  end;
  UpdateFindCount;
  if mmContent.HandleAllocated then
    mmContent.Invalidate;
end;

procedure TfrmLineEditor.SelectFindHit(AIndex: Integer);
begin
  if (AIndex < 0) or (AIndex > High(FFindHits)) then Exit;
  FFindCur := AIndex;
  mmContent.SelStart := FFindHits[AIndex].X;
  mmContent.SelLength := FFindHits[AIndex].Y;
  if mmContent.HandleAllocated then
  begin
    SendMessage(mmContent.Handle, EM_SCROLLCARET, 0, 0);
    mmContent.Invalidate;
  end;
  UpdateFindCount;
end;

procedure TfrmLineEditor.FindStep(ADir: Integer);
var
  i, S, SL, Target: Integer;
begin
  if not Assigned(FedtFind) then Exit;
  if FindTextMissing then Exit;
  if FFindTimer.Enabled or (FFindText <> mmContent.Text) then
  begin
    FFindTimer.Enabled := False;
    RecomputeFind(False);
  end;
  if FindFailed(FFindError, Length(FFindHits)) then Exit;
  S := mmContent.SelStart;
  SL := mmContent.SelLength;
  Target := -1;
  if ADir > 0 then
  begin
    for i := 0 to High(FFindHits) do
      if (FFindHits[i].X > S) or ((FFindHits[i].X = S) and (SL = 0)) then
      begin
        Target := i;
        Break;
      end;
    if Target < 0 then
      Target := 0;
  end
  else
  begin
    for i := High(FFindHits) downto 0 do
      if FFindHits[i].X < S then
      begin
        Target := i;
        Break;
      end;
    if Target < 0 then
      Target := High(FFindHits);
  end;
  SelectFindHit(Target);
end;

procedure TfrmLineEditor.UpdateFindCount;
begin
  if not Assigned(FlblFindCount) then Exit;
  FlblFindCount.Font.Color := clWindowText;
  if (FFindError <> '') or (FedtFind.Text = '') or (Length(FFindHits) = 0) then
    FlblFindCount.Caption := ''
  else
    FlblFindCount.Caption := Format(TrText('LineEditor.FindCount: %d %d'),
      [FFindCur + 1, Length(FFindHits)]);
  FlblFindCount.Hint := FlblFindCount.Caption;
  if FFindError <> '' then
    FedtFind.Color := $00DDDDFF
  else if (FedtFind.Text <> '') and (Length(FFindHits) = 0) then
    FedtFind.Color := $00E6E6FF
  else
    FedtFind.Color := clWindow;
end;

procedure TfrmLineEditor.FocusFind;
var
  S: string;
begin
  if not Assigned(FedtFind) then Exit;
  if mmContent.SelLength > 0 then
  begin
    S := mmContent.SelText;
    if (Pos(#13, S) = 0) and (Pos(#10, S) = 0) and (Length(S) <= 500) then
      FedtFind.Text := S;
  end;
  if FedtFind.CanFocus then
    FedtFind.SetFocus;
  FedtFind.SelectAll;
end;

procedure TfrmLineEditor.MemoWndProc(var Msg: TMessage);
begin
  FOldMemoWndProc(Msg);
  if (Msg.Msg = WM_PAINT) and (Length(FFindHits) > 0) then
    PaintFindHits;
end;

procedure TfrmLineEditor.FindEditWndProc(var Msg: TMessage);
begin
  FOldFindEditWndProc(Msg);
  { Enter/Esc chegam ao OnKeyDown do edit em vez do botao Default / Cancel. }
  if Msg.Msg = WM_GETDLGCODE then
    Msg.Result := Msg.Result or DLGC_WANTALLKEYS;
end;

procedure TfrmLineEditor.PaintFindHits;
var
  H: HWND;
  C: TControlCanvas;
  lh, firstLn, nVis, cStart, cEnd, lo, hi, mid, k, j, jEnd, x, y, x2, w, p, p2: Integer;
  SelS, SelL: Integer;
  R: TRect;
  ch: Char;
  Col: TColor;
begin
  if not mmContent.HandleAllocated then Exit;
  H := mmContent.Handle;
  C := TControlCanvas.Create;
  try
    C.Control := mmContent;
    C.Font.Assign(mmContent.Font);
    C.Font.Color := clBlack;
    lh := C.TextHeight('Wg');
    if lh < 1 then Exit;
    firstLn := SendMessage(H, EM_GETFIRSTVISIBLELINE, 0, 0);
    nVis := mmContent.ClientHeight div lh + 2;
    cStart := SendMessage(H, EM_LINEINDEX, firstLn, 0);
    if cStart < 0 then cStart := 0;
    cEnd := SendMessage(H, EM_LINEINDEX, firstLn + nVis, 0);
    if cEnd < 0 then
      cEnd := Length(FFindText);
    lo := 0;
    hi := High(FFindHits);
    while lo < hi do
    begin
      mid := (lo + hi) div 2;
      if FFindHits[mid].X + FFindHits[mid].Y <= cStart then
        lo := mid + 1
      else
        hi := mid;
    end;
    SelS := mmContent.SelStart;
    SelL := mmContent.SelLength;
    HideCaret(H);
    try
      for k := lo to High(FFindHits) do
      begin
        if FFindHits[k].X >= cEnd then Break;
        if (FFindHits[k].X = SelS) and (FFindHits[k].Y = SelL) then Continue;
        if k = FFindCur then
          Col := cFindCurColor
        else
          Col := cFindHitColor;
        C.Brush.Color := Col;
        C.Brush.Style := bsSolid;
        j := Max(FFindHits[k].X, cStart);
        jEnd := Min(FFindHits[k].X + FFindHits[k].Y, Min(cEnd, Length(FFindText)));
        if j >= jEnd then Continue;
        p := SendMessage(H, EM_POSFROMCHAR, j, 0);
        while j < jEnd do
        begin
          p2 := SendMessage(H, EM_POSFROMCHAR, j + 1, 0);
          ch := FFindText[j + 1];
          if (p <> -1) and (ch <> #13) and (ch <> #10) then
          begin
            x := SmallInt(LoWord(p));
            y := SmallInt(HiWord(p));
            if (p2 <> -1) and (SmallInt(HiWord(p2)) = y) and (SmallInt(LoWord(p2)) > x) then
              x2 := SmallInt(LoWord(p2))
            else
            begin
              if ch = #9 then
                w := C.TextWidth(' ')
              else
                w := C.TextWidth(ch);
              x2 := x + w;
            end;
            R := Rect(x, y, x2, y + lh);
            if (R.Bottom > 0) and (R.Top < mmContent.ClientHeight) then
            begin
              if ch = #9 then
                C.FillRect(R)
              else
                C.TextRect(R, x, y, ch);
            end;
          end;
          p := p2;
          Inc(j);
        end;
      end;
    finally
      ShowCaret(H);
    end;
  finally
    C.Free;
  end;
end;

procedure TfrmLineEditor.edtFindChange(Sender: TObject);
begin
  FEmptyReplOk := False;
  FFindTimer.Enabled := False;
  RecomputeFind(True);
end;

procedure TfrmLineEditor.edtFindEnter(Sender: TObject);
begin
  FFindAnchor := mmContent.SelStart;
end;

procedure TfrmLineEditor.edtFindKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    VK_RETURN:
      begin
        if ssShift in Shift then FindStep(-1) else FindStep(1);
        Key := 0;
      end;
    VK_DOWN:
      begin
        FindStep(1);
        Key := 0;
      end;
    VK_UP:
      begin
        FindStep(-1);
        Key := 0;
      end;
  end;
end;

procedure TfrmLineEditor.edtFindKeyPress(Sender: TObject; var Key: Char);
begin
  if (Key = #13) or (Key = #27) then
    Key := #0;
end;

procedure TfrmLineEditor.btnFindPrevClick(Sender: TObject);
begin
  FindStep(-1);
end;

procedure TfrmLineEditor.btnFindNextClick(Sender: TObject);
begin
  FindStep(1);
end;

procedure TfrmLineEditor.chkFindOptionClick(Sender: TObject);
begin
  GFindCase := FchkFindCase.Checked;
  GFindWord := FchkFindWord.Checked;
  GFindAccents := FchkFindAccents.Checked;
  GFindRegex := FchkFindRegex.Checked;
  FFindAnchor := mmContent.SelStart;
  RecomputeFind(FedtFind.Text <> '');
end;

procedure TfrmLineEditor.mmContentChange(Sender: TObject);
begin
  { Digitação: um passo de desfazer por rajada (pausa de 1 s encerra o grupo). }
  if Assigned(FUndoList) and (FUndoDepth = 0) then
  begin
    if not FTypingGroup then
    begin
      PushUndo(FLastState);
      FTypingGroup := True;
    end;
    FUndoTimer.Enabled := False;
    FUndoTimer.Enabled := True;
    FLastState := CurState;
    UpdateUndoButtons;
  end;
  if not Assigned(FedtFind) or (FedtFind.Text = '') then Exit;
  FFindTimer.Enabled := False;
  FFindTimer.Enabled := True;
end;

procedure TfrmLineEditor.FindTimerTick(Sender: TObject);
begin
  FFindTimer.Enabled := False;
  RecomputeFind(False);
end;

procedure TfrmLineEditor.ReplaceCurrent;
var
  Hits: TArray<TPoint>;
  Reps: TStringList;
  Err: string;
  i, k, S: Integer;
begin
  if not Assigned(FedtFind) or not mmContent.Enabled then Exit;
  if FindTextMissing then Exit;
  Reps := TStringList.Create;
  try
    ScanMatches(mmContent.Text, Hits, Reps, Err);
    if Err <> '' then
    begin
      RecomputeFind(False);
      FindFailed(Err, 0);
      Exit;
    end;
    k := -1;
    for i := 0 to High(Hits) do
      if (Hits[i].X = mmContent.SelStart) and (Hits[i].Y = mmContent.SelLength) then
      begin
        k := i;
        Break;
      end;
    if k < 0 then
    begin
      { Seleção não é uma ocorrência: apenas posiciona na próxima. }
      FindStep(1);
      Exit;
    end;
    if not ConfirmEmptyReplace(1, True) then Exit;
    UndoBegin;
    try
      mmContent.SelText := Reps[k];
    finally
      UndoEnd;
    end;
    S := Hits[k].X + Length(Reps[k]);
  finally
    Reps.Free;
  end;
  FFindTimer.Enabled := False;
  mmContent.SelStart := S;
  mmContent.SelLength := 0;
  FFindAnchor := S;
  RecomputeFind(True);
  if Length(FFindHits) = 0 then
    mmContent.SelStart := S;
end;

procedure TfrmLineEditor.ReplaceAll;
var
  Hits: TArray<TPoint>;
  Reps: TStringList;
  Err, Src: string;
  SB: TStringBuilder;
  i, Last: Integer;
begin
  if not Assigned(FedtFind) or not mmContent.Enabled then Exit;
  if FindTextMissing then Exit;
  Src := mmContent.Text;
  Reps := TStringList.Create;
  try
    ScanMatches(Src, Hits, Reps, Err);
    if (Err <> '') or (Length(Hits) = 0) then
    begin
      RecomputeFind(False);
      FindFailed(Err, Length(Hits));
      Exit;
    end;
    if not ConfirmEmptyReplace(Length(Hits), False) then Exit;
    SB := TStringBuilder.Create(Length(Src));
    try
      Last := 1;
      for i := 0 to High(Hits) do
      begin
        SB.Append(Copy(Src, Last, Hits[i].X + 1 - Last));
        SB.Append(Reps[i]);
        Last := Hits[i].X + Hits[i].Y + 1;
      end;
      SB.Append(Copy(Src, Last, MaxInt));
      UndoBegin;
      try
        mmContent.Text := SB.ToString;
      finally
        UndoEnd;
      end;
    finally
      SB.Free;
    end;
  finally
    Reps.Free;
  end;
  FFindTimer.Enabled := False;
  mmContent.SelStart := 0;
  mmContent.SelLength := 0;
  RecomputeFind(False);
  FedtFind.Color := clWindow;
  FastFileMsgSuccess(Format(TrText('LineEditor.ReplacedMsg: %d'), [Length(Hits)]));
end;

procedure TfrmLineEditor.FocusReplace;
begin
  if not Assigned(FedtRepl) then Exit;
  if (FedtFind.Text = '') and (mmContent.SelLength > 0) then
    FocusFind;
  if FedtRepl.CanFocus then
    FedtRepl.SetFocus;
  FedtRepl.SelectAll;
end;

procedure TfrmLineEditor.ReplEditWndProc(var Msg: TMessage);
begin
  FOldReplEditWndProc(Msg);
  if Msg.Msg = WM_GETDLGCODE then
    Msg.Result := Msg.Result or DLGC_WANTALLKEYS;
end;

procedure TfrmLineEditor.edtReplKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    if ssShift in Shift then ReplaceAll else ReplaceCurrent;
    Key := 0;
  end;
end;

procedure TfrmLineEditor.edtReplKeyPress(Sender: TObject; var Key: Char);
begin
  if (Key = #13) or (Key = #10) or (Key = #27) then
    Key := #0;
end;

procedure TfrmLineEditor.btnReplOneClick(Sender: TObject);
begin
  ReplaceCurrent;
end;

procedure TfrmLineEditor.btnReplAllClick(Sender: TObject);
begin
  ReplaceAll;
end;

procedure TfrmLineEditor.FormKeyPressFind(Sender: TObject; var Key: Char);
begin
  { Atalhos Ctrl+tecla geram um caractere de controle (ex.: Ctrl+H = backspace). }
  if FSuppressCtrlChar then
  begin
    FSuppressCtrlChar := False;
    if Key < #32 then
      Key := #0;
  end;
end;

procedure TfrmLineEditor.MemoSelectAll;
begin
  if not mmContent.Enabled then Exit;
  mmContent.SelectAll;
  mmContent.SetFocus;
end;

procedure TfrmLineEditor.MemoCopy;
begin
  if not mmContent.Enabled then Exit;
  if mmContent.SelLength > 0 then
    mmContent.CopyToClipboard
  else
  begin
    mmContent.SelectAll;
    mmContent.CopyToClipboard;
  end;
end;

procedure TfrmLineEditor.MemoPaste;
begin
  if not mmContent.Enabled then Exit;
  if Clipboard.HasFormat(CF_TEXT) then
  begin
    UndoBegin;
    try
      mmContent.PasteFromClipboard;
    finally
      UndoEnd;
    end;
  end;
end;

procedure TfrmLineEditor.UpdateMemoToolButtons;
var
  En: Boolean;
begin
  En := mmContent.Enabled;
  btnSelectAll.Enabled := En;
  btnCopy.Enabled := En;
  btnPaste.Enabled := En and Clipboard.HasFormat(CF_TEXT);
  btnClear.Enabled := En;
  btnAskAI.Enabled := not FAskAIInProgress;
  if Assigned(FedtRepl) then
  begin
    FedtRepl.Enabled := En;
    FbtnReplOne.Enabled := En;
    FbtnReplAll.Enabled := En;
  end;
  UpdateUndoButtons;
end;

procedure TfrmLineEditor.btnClearClick(Sender: TObject);
begin
  if not mmContent.Enabled then Exit;
  UndoBegin;
  try
    mmContent.Clear;
  finally
    UndoEnd;
  end;
  mmContent.SetFocus;
end;

destructor TfrmLineEditor.Destroy;
begin
  if Assigned(FAIThread) then
  begin
    FAIThread.WaitFor;
    FreeAndNil(FAIThread);
  end;
  FreeAndNil(FUndoList);
  FreeAndNil(FRedoList);
  inherited;
end;

procedure TfrmLineEditor.CreateUndo;

  function NewBtn(AClick: TNotifyEvent): TButton;
  begin
    Result := TButton.Create(Self);
    Result.Parent := pnlMemoTools;
    Result.OnClick := AClick;
    Result.ShowHint := True;
    Result.Height := btnSelectAll.Height;
  end;

begin
  if Assigned(FUndoList) then Exit;
  FUndoList := TList<TLineEditorState>.Create;
  FRedoList := TList<TLineEditorState>.Create;
  FUndoTimer := TTimer.Create(Self);
  FUndoTimer.Enabled := False;
  FUndoTimer.Interval := 1000;
  FUndoTimer.OnTimer := UndoTimerTick;
  FbtnUndo := NewBtn(btnUndoClick);
  FbtnRedo := NewBtn(btnRedoClick);
  FbtnUndo.TabOrder := btnClear.TabOrder + 1;
  FbtnRedo.TabOrder := FbtnUndo.TabOrder + 1;
end;

function TfrmLineEditor.CurState: TLineEditorState;
begin
  Result.Text := mmContent.Text;
  Result.SelStart := mmContent.SelStart;
  Result.SelLen := mmContent.SelLength;
end;

procedure TfrmLineEditor.PushUndo(const AState: TLineEditorState);
const
  cMaxUndo = 200;
begin
  FUndoList.Add(AState);
  while FUndoList.Count > cMaxUndo do
    FUndoList.Delete(0);
  FRedoList.Clear;
end;

{ Alterações feitas por código (colar, limpar, substituir...) viram um passo de desfazer. }
procedure TfrmLineEditor.UndoBegin;
begin
  if not Assigned(FUndoList) then Exit;
  if FUndoDepth = 0 then
  begin
    FTypingGroup := False;
    FUndoTimer.Enabled := False;
    FPendingState := CurState;
  end;
  Inc(FUndoDepth);
end;

procedure TfrmLineEditor.UndoEnd;
begin
  if not Assigned(FUndoList) then Exit;
  Dec(FUndoDepth);
  if FUndoDepth > 0 then Exit;
  if mmContent.Text <> FPendingState.Text then
    PushUndo(FPendingState);
  FLastState := CurState;
  UpdateUndoButtons;
end;

procedure TfrmLineEditor.UndoReset;
begin
  if not Assigned(FUndoList) then Exit;
  FUndoList.Clear;
  FRedoList.Clear;
  FTypingGroup := False;
  FUndoTimer.Enabled := False;
  FLastState := CurState;
  UpdateUndoButtons;
end;

procedure TfrmLineEditor.ApplyState(const AState: TLineEditorState);
begin
  Inc(FUndoDepth);
  try
    mmContent.Text := AState.Text;
    mmContent.SelStart := AState.SelStart;
    mmContent.SelLength := AState.SelLen;
  finally
    Dec(FUndoDepth);
  end;
  FLastState := CurState;
  if mmContent.CanFocus then
    mmContent.SetFocus;
  if mmContent.HandleAllocated then
    SendMessage(mmContent.Handle, EM_SCROLLCARET, 0, 0);
  UpdateUndoButtons;
end;

procedure TfrmLineEditor.DoUndo;
var
  S: TLineEditorState;
begin
  if not Assigned(FUndoList) or not mmContent.Enabled or (FUndoList.Count = 0) then
  begin
    MessageBeep(MB_OK);
    Exit;
  end;
  FTypingGroup := False;
  FUndoTimer.Enabled := False;
  FRedoList.Add(CurState);
  S := FUndoList.Last;
  FUndoList.Delete(FUndoList.Count - 1);
  ApplyState(S);
end;

procedure TfrmLineEditor.DoRedo;
var
  S: TLineEditorState;
begin
  if not Assigned(FRedoList) or not mmContent.Enabled or (FRedoList.Count = 0) then
  begin
    MessageBeep(MB_OK);
    Exit;
  end;
  FTypingGroup := False;
  FUndoTimer.Enabled := False;
  FUndoList.Add(CurState);
  S := FRedoList.Last;
  FRedoList.Delete(FRedoList.Count - 1);
  ApplyState(S);
end;

procedure TfrmLineEditor.UpdateUndoButtons;
begin
  if not Assigned(FbtnUndo) then Exit;
  FbtnUndo.Enabled := mmContent.Enabled and (FUndoList.Count > 0);
  FbtnRedo.Enabled := mmContent.Enabled and (FRedoList.Count > 0);
end;

procedure TfrmLineEditor.UndoTimerTick(Sender: TObject);
begin
  FUndoTimer.Enabled := False;
  FTypingGroup := False;
end;

procedure TfrmLineEditor.btnUndoClick(Sender: TObject);
begin
  DoUndo;
end;

procedure TfrmLineEditor.btnRedoClick(Sender: TObject);
begin
  DoRedo;
end;

function TfrmLineEditor.FindTextMissing: Boolean;
begin
  Result := FedtFind.Text = '';
  if not Result then Exit;
  FFindHits := nil;
  UpdateFindCount;
  FastFileMsgWarn(TrText('LineEditor.FindEmpty'));
  FocusFind;
end;

function TfrmLineEditor.FindFailed(const AErr: string; AHits: Integer): Boolean;
begin
  Result := (AErr <> '') or (AHits = 0);
  if not Result then Exit;
  if AErr <> '' then
    FastFileMsgWarn(Format(TrText('LineEditor.FindBadRegexMsg: %s'), [FedtFind.Text]))
  else
    FastFileMsgInfo(Format(TrText('LineEditor.FindNoneMsg: %s'), [FedtFind.Text]));
  FocusFind;
end;

function TfrmLineEditor.ConfirmEmptyReplace(ACount: Integer; AOnce: Boolean): Boolean;
begin
  Result := (FedtRepl.Text <> '') or (AOnce and FEmptyReplOk);
  if Result then Exit;
  Result := FastFileMessageDlg(
    Format(TrText('LineEditor.ReplaceEmptyConfirm: %d %s'), [ACount, FedtFind.Text]),
    mtConfirmation, [mbYes, mbNo], 0) = mrYes;
  if Result and AOnce then
    FEmptyReplOk := True;
end;

procedure TfrmLineEditor.edtReplChange(Sender: TObject);
begin
  FEmptyReplOk := False;
end;

procedure TfrmLineEditor.btnSelectAllClick(Sender: TObject);
begin
  MemoSelectAll;
end;

procedure TfrmLineEditor.btnCopyClick(Sender: TObject);
begin
  MemoCopy;
end;

procedure TfrmLineEditor.btnPasteClick(Sender: TObject);
begin
  MemoPaste;
  UpdateMemoToolButtons;
end;

procedure TfrmLineEditor.mmContentKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if not mmContent.Enabled then Exit;
  if ssCtrl in Shift then
  begin
    case Key of
      Ord('A'), Ord('a'):
        begin
          MemoSelectAll;
          Key := 0;
        end;
      Ord('C'), Ord('c'):
        begin
          MemoCopy;
          Key := 0;
        end;
      Ord('V'), Ord('v'):
        begin
          MemoPaste;
          UpdateMemoToolButtons;
          Key := 0;
        end;
    end;
  end;
end;

procedure TfrmLineEditor.ApplyUiLanguage;
var
  W, MaxWidth: Integer;
  WorkArea: TRect;
begin
  Caption := TrText('File Line Editor');
  Label1.Caption := TrText('Operation:');
  Label2.Caption := TrText('Line Number:');
  Label3.Caption := TrText('Content:');
  btnSelectAll.Caption := WithKey(TrText('Select All'), cKeySelectAll);
  btnCopy.Caption := WithKey(TrText('Copy'), cKeyCopy);
  btnPaste.Caption := WithKey(TrText('Paste'), cKeyPaste);
  btnClear.Caption := WithKey(TrText('LineEditor.Clear'), cKeyClear);
  btnClear.Hint := TrText('LineEditor.ClearHint');
  btnClear.ShowHint := True;
  btnAskAI.Caption := WithKey(TrText('ListView.AskAI'), cKeyAskAI);
  btnAskAI.Hint := TrText('LineEditor.AskAIHint');
  btnAskAI.ShowHint := True;
  chkMergeLines.Caption := TrText('LineEditor.MergeLines');
  chkMergeLines.Hint := TrText('LineEditor.MergeLinesHint');
  chkMergeLines.ShowHint := True;
  lblMergeHint.Caption := TrText('LineEditor.MergeListHint');
  btnConfirm.Caption := WithKey(TrText('Confirm'), cKeyConfirm);
  btnCancel.Caption := WithKey(TrText('Cancel'), cKeyCancel);

  if Assigned(FbtnUndo) then
  begin
    FbtnUndo.Caption := WithKey(TrText('LineEditor.Undo'), cKeyUndo);
    FbtnUndo.Hint := TrText('LineEditor.UndoHint');
    FbtnRedo.Caption := WithKey(TrText('LineEditor.Redo'), cKeyRedo);
    FbtnRedo.Hint := TrText('LineEditor.RedoHint');
  end;

  btnConfirm.Width := FitButtonWidth(btnConfirm, FfPx(90));
  btnCancel.Width := FitButtonWidth(btnCancel, FfPx(90));
  ApplyFindCaptions;
  LayoutAdjacentButtons;

  { Legendas com atalhos alargam as barras: o formulário cresce até o limite da tela;
    acima disso a barra de ferramentas quebra em mais linhas. }
  W := MemoToolsWantedWidth + 2 * pnlMemoTools.Left;
  if Assigned(FbtnNextLine) then
    W := Max(W, FbtnNextLine.Left + FbtnNextLine.Width + pnlMemoTools.Left);
  FfWorkAreaOf(Self, WorkArea);
  MaxWidth := Min(FfPx(1100), WorkArea.Right - WorkArea.Left - FfPx(40));
  if MaxWidth < FfPx(320) then
    MaxWidth := FfPx(320);
  W := Min(W, MaxWidth);
  if ClientWidth < W then
    ClientWidth := W;
end;

procedure TfrmLineEditor.LayoutMemoTools;
var
  Btns: array[0..6] of TButton;
  i, x, y, w, h, gap: Integer;
begin
  Btns[0] := btnSelectAll;
  Btns[1] := btnCopy;
  Btns[2] := btnPaste;
  Btns[3] := btnClear;
  Btns[4] := FbtnUndo;
  Btns[5] := FbtnRedo;
  Btns[6] := btnAskAI;
  h := btnSelectAll.Height;
  gap := FfPx(6);
  x := 0;
  y := FfPx(2);
  for i := Low(Btns) to High(Btns) do
  begin
    if not Assigned(Btns[i]) then Continue;
    w := FitButtonWidth(Btns[i], FfPx(80));
    if (x > 0) and (x + w > pnlMemoTools.ClientWidth) then
    begin
      x := 0;
      Inc(y, h + FfPx(4));
    end;
    Btns[i].SetBounds(x, y, w, h);
    Inc(x, w + gap);
  end;
  pnlMemoTools.Height := y + h + FfPx(2);
end;

function TfrmLineEditor.MemoToolsWantedWidth: Integer;
var
  Btns: array[0..6] of TButton;
  i: Integer;
begin
  Btns[0] := btnSelectAll;
  Btns[1] := btnCopy;
  Btns[2] := btnPaste;
  Btns[3] := btnClear;
  Btns[4] := FbtnUndo;
  Btns[5] := FbtnRedo;
  Btns[6] := btnAskAI;
  Result := 0;
  for i := Low(Btns) to High(Btns) do
    if Assigned(Btns[i]) then
      Inc(Result, FitButtonWidth(Btns[i], FfPx(80)) + FfPx(6));
end;

procedure TfrmLineEditor.CreateAdjacentButtons;

  function NewBtn(AClick: TNotifyEvent): TButton;
  begin
    Result := TButton.Create(Self);
    Result.Parent := Self;
    Result.OnClick := AClick;
    Result.ShowHint := True;
    Result.Visible := False;
  end;

begin
  if Assigned(FbtnPrevLine) then Exit;
  FbtnPrevLine := NewBtn(btnPrevLineClick);
  FbtnNextLine := NewBtn(btnNextLineClick);
  FbtnPrevLine.TabOrder := edtLineNumber.TabOrder + 1;
  FbtnNextLine.TabOrder := FbtnPrevLine.TabOrder + 1;
  FLineCount := -1;
  edtLineNumber.OnChange := edtLineNumberChange;
end;

procedure TfrmLineEditor.LayoutAdjacentButtons;
var
  H, T: Integer;
begin
  if not Assigned(FbtnPrevLine) then Exit;
  FbtnPrevLine.Caption := WithKey(TrText('LineEditor.CopyPrevLine'), cKeyPrevLine);
  FbtnNextLine.Caption := WithKey(TrText('LineEditor.CopyNextLine'), cKeyNextLine);
  H := btnSelectAll.Height;
  T := edtLineNumber.Top + (edtLineNumber.Height - H) div 2;
  FbtnPrevLine.SetBounds(chkMergeLines.Left, T, FitButtonWidth(FbtnPrevLine), H);
  FbtnNextLine.SetBounds(FbtnPrevLine.Left + FbtnPrevLine.Width + FfPx(6), T,
    FitButtonWidth(FbtnNextLine), H);
end;

function TfrmLineEditor.IsInsertOp: Boolean;
begin
  Result := (cbOperation.ItemIndex in [3, 4]) and not chkMergeLines.Checked;
end;

function TfrmLineEditor.AdjacentLineNo(ADir: Integer): Int64;
var
  Base: Int64;
begin
  Base := StrToInt64Def(Trim(edtLineNumber.Text), 0);
  if Base < 1 then Exit(0);
  { Antes de N: vizinhas N-1 e N. Depois de N: vizinhas N e N+1. }
  if cbOperation.ItemIndex = 4 then
  begin
    if ADir < 0 then Result := Base else Result := Base + 1;
  end
  else
  begin
    if ADir < 0 then Result := Base - 1 else Result := Base;
  end;
end;

function TfrmLineEditor.AdjacentLineText(ALine: Int64; out AText: string): Boolean;
begin
  AText := '';
  Result := False;
  if ALine < 1 then Exit;
  if Assigned(FGetCount) then
  begin
    if FLineCount < 0 then
      FLineCount := FGetCount();
    if ALine > FLineCount then Exit;
  end;
  if Assigned(FGetLine) then
    AText := FGetLine(ALine)
  else if ALine = FOrigLineNo then
    AText := FOrigText
  else
    Exit;
  Result := Trim(AText) <> '';
end;

procedure TfrmLineEditor.UpdateAdjacentButtons;

  procedure UpdBtn(ABtn: TButton; ADir: Integer);
  var
    Ln: Int64;
    S: string;
  begin
    Ln := AdjacentLineNo(ADir);
    ABtn.Enabled := AdjacentLineText(Ln, S);
    if ABtn.Enabled then
      ABtn.Hint := Format(TrText('LineEditor.CopyLineHint: %d'), [Ln])
    else
      ABtn.Hint := TrText('LineEditor.AdjLineUnavailable');
  end;

var
  Show: Boolean;
begin
  if not Assigned(FbtnPrevLine) then Exit;
  Show := IsInsertOp;
  FbtnPrevLine.Visible := Show;
  FbtnNextLine.Visible := Show;
  chkMergeLines.Visible := not Show;
  if not Show then Exit;
  UpdBtn(FbtnPrevLine, -1);
  UpdBtn(FbtnNextLine, 1);
end;

procedure TfrmLineEditor.btnPrevLineClick(Sender: TObject);
var
  S: string;
begin
  if AdjacentLineText(AdjacentLineNo(-1), S) then
  begin
    UndoBegin;
    try
      mmContent.Text := S;
    finally
      UndoEnd;
    end;
    mmContent.SetFocus;
  end;
end;

procedure TfrmLineEditor.btnNextLineClick(Sender: TObject);
var
  S: string;
begin
  if AdjacentLineText(AdjacentLineNo(1), S) then
  begin
    UndoBegin;
    try
      mmContent.Text := S;
    finally
      UndoEnd;
    end;
    mmContent.SetFocus;
  end;
end;

procedure TfrmLineEditor.edtLineNumberChange(Sender: TObject);
begin
  UpdateAdjacentButtons;
end;

procedure TfrmLineEditor.LayoutMergePanel(AShow: Boolean;
  AAdjustHeight: Boolean);
var
  ContentBottom, MemoH, NeedH, MergeH, Gap, Margin, MinMemo: Integer;
  MaxClientH, ChromeH: Integer;
  WorkArea: TRect;
begin
  MergeH := FfPx(168);
  Gap := FfPx(8);
  Margin := FfPx(16);
  MinMemo := FfPx(110);
  { Opaque panels — avoid AlphaControls/ParentBackground see-through. }
  Color := clBtnFace;
  if Assigned(pnlFooter) then
  begin
    pnlFooter.ParentBackground := False;
    pnlFooter.Color := clBtnFace;
  end;
  if Assigned(pnlMerge) then
  begin
    pnlMerge.ParentBackground := False;
    pnlMerge.Color := clBtnFace;
  end;
  if Assigned(pnlMemoTools) then
  begin
    pnlMemoTools.ParentBackground := False;
    pnlMemoTools.Color := clBtnFace;
  end;

  pnlMemoTools.Width := ClientWidth - 2 * Margin;
  LayoutMemoTools;
  LayoutFindBar;

  pnlMerge.Visible := AShow;
  if AShow then
    NeedH := mmContent.Top + MinMemo + Gap + MergeH + Gap + pnlFooter.Height
  else
    NeedH := mmContent.Top + FfPx(180) + Gap + pnlFooter.Height;
  if NeedH < FfPx(400) then NeedH := FfPx(400);
  if AShow and (NeedH < FfPx(540)) then NeedH := FfPx(540);
  if AAdjustHeight then
  begin
    FfWorkAreaOf(Self, WorkArea);
    ChromeH := Height - ClientHeight;
    MaxClientH := WorkArea.Bottom - WorkArea.Top - ChromeH - FfPx(16);
    if MaxClientH < FfPx(160) then
      MaxClientH := FfPx(160);
    if NeedH > MaxClientH then
      NeedH := MaxClientH;
    ClientHeight := NeedH;
  end;

  if Assigned(pnlFooter) then
  begin
    btnCancel.Left := pnlFooter.ClientWidth - Margin - btnCancel.Width;
    btnConfirm.Left := btnCancel.Left - Gap - btnConfirm.Width;
    btnConfirm.Top := FfPx(14);
    btnCancel.Top := FfPx(14);
    if Assigned(Bevel1) then
    begin
      if pnlFooter.ClientWidth - 2 * Margin > FfPx(100) then
        Bevel1.Width := pnlFooter.ClientWidth - 2 * Margin
      else
        Bevel1.Width := FfPx(100);
    end;
  end;

  ContentBottom := ClientHeight - pnlFooter.Height - Gap;
  if AShow then
  begin
    MergeH := Min(MergeH, Max(0, ContentBottom - mmContent.Top - FfPx(48) - Gap));
    pnlMerge.SetBounds(Margin, ContentBottom - MergeH,
      ClientWidth - 2 * Margin, MergeH);
    lblMergeHint.SetBounds(0, 0, pnlMerge.ClientWidth, FfPx(28));
    clbMerge.SetBounds(0, FfPx(30), pnlMerge.ClientWidth,
      Max(0, pnlMerge.ClientHeight - FfPx(30)));
    MemoH := pnlMerge.Top - mmContent.Top - Gap;
  end
  else
    MemoH := ContentBottom - mmContent.Top;

  if not AAdjustHeight and (MemoH < FfPx(48)) then
    MemoH := Max(0, MemoH);
  mmContent.SetBounds(Margin, mmContent.Top, ClientWidth - 2 * Margin, MemoH);
  mmContent.Color := clWindow;
  pnlMemoTools.Width := mmContent.Width;
  cbOperation.Width := mmContent.Width;
  LayoutFindBar;
end;

procedure TfrmLineEditor.PopulateMergeList;
var
  Base, Lo, Hi, I, Total: Int64;
  Cap, Txt: string;
  Idx: Integer;
begin
  clbMerge.Items.Clear;
  if not Assigned(FGetLine) or not Assigned(FGetCount) then Exit;
  Total := FGetCount();
  if Total < 1 then Exit;
  Base := StrToInt64Def(Trim(edtLineNumber.Text), 1);
  if Base < 1 then Base := 1;
  if Base > Total then Base := Total;
  Lo := Max(Int64(1), Base - 40);
  Hi := Min(Total, Base + 40);
  clbMerge.Items.BeginUpdate;
  try
    I := Lo;
    while I <= Hi do
    begin
      Txt := FGetLine(I);
      if Length(Txt) > 72 then
        Txt := Copy(Txt, 1, 69) + '...';
      Cap := Format('%d: %s', [I, Txt]);
      Idx := clbMerge.Items.AddObject(Cap, TObject(NativeInt(I)));
      if I = Base then
        clbMerge.Checked[Idx] := True;
      Inc(I);
    end;
  finally
    clbMerge.Items.EndUpdate;
  end;
end;

procedure TfrmLineEditor.RefreshMergePreview;
var
  Target: Int64;
  Del: TList;
  Joined: string;
begin
  if FUpdatingMergePreview then Exit;
  if not chkMergeLines.Checked then Exit;
  Del := TList.Create;
  try
    if CollectMergeSelection(Target, Del, Joined, True) then
    begin
      FUpdatingMergePreview := True;
      UndoBegin;
      try
        mmContent.Text := Joined;
        edtLineNumber.Text := IntToStr(Target);
      finally
        UndoEnd;
        FUpdatingMergePreview := False;
      end;
    end;
  finally
    Del.Free;
  end;
end;

function TfrmLineEditor.CollectMergeSelection(out ATargetLine: Int64;
  ADeleteLines: TList; out AJoined: string;
  const ASilent: Boolean): Boolean;
var
  I: Integer;
  Ln: Int64;
  Parts: TStringList;
  First: Boolean;
begin
  Result := False;
  ATargetLine := 0;
  AJoined := '';
  if Assigned(ADeleteLines) then
    ADeleteLines.Clear;
  if not Assigned(FGetLine) then Exit;

  Parts := TStringList.Create;
  try
    First := True;
    for I := 0 to clbMerge.Items.Count - 1 do
      if clbMerge.Checked[I] then
      begin
        Ln := NativeInt(clbMerge.Items.Objects[I]);
        if Ln < 1 then Continue;
        if First then
        begin
          ATargetLine := Ln;
          First := False;
        end
        else if Assigned(ADeleteLines) then
          ADeleteLines.Add(Pointer(NativeInt(Ln)));
        Parts.Add(FGetLine(Ln));
      end;
    if Parts.Count < 2 then
    begin
      if not ASilent then
        ShowAppMessage(TrText('LineEditor.MergeNeedTwo'));
      Exit;
    end;
    { Join into one physical line (no separators) — user can edit before confirm. }
    AJoined := '';
    for I := 0 to Parts.Count - 1 do
      AJoined := AJoined + Parts[I];
    Result := True;
  finally
    Parts.Free;
  end;
end;

procedure TfrmLineEditor.chkMergeLinesClick(Sender: TObject);
begin
  if chkMergeLines.Checked then
  begin
    if (not Assigned(FGetLine)) or (not Assigned(FGetCount)) then
    begin
      chkMergeLines.Checked := False;
      ShowAppMessage(TrText('LineEditor.MergeUnavailable'));
      Exit;
    end;
    { Force edit mode for merge. }
    cbOperation.ItemIndex := 2;
    cbOperationChange(nil);
    cbOperation.Enabled := False;
    PopulateMergeList;
    LayoutMergePanel(True);
    RefreshMergePreview;
  end
  else
  begin
    if not (Tag = 1) then { Tag=1 means ALockOperation }
      cbOperation.Enabled := True;
    LayoutMergePanel(False);
  end;
end;

procedure TfrmLineEditor.clbMergeClickCheck(Sender: TObject);
begin
  RefreshMergePreview;
end;

function TfrmLineEditor.PromptAskAiGoal(out AGoal: string): Boolean;
var
  Frm: TForm;
  Lbl: TLabel;
  Memo: TMemo;
  Footer: TPanel;
  BtnOk, BtnCancel: TButton;
  LineHint, Cap: string;
  R: TRect;
  LabelH, MemoTop, MemoH: Integer;
begin
  Result := False;
  AGoal := '';
  LineHint := Trim(edtLineNumber.Text);
  Frm := TForm.CreateNew(nil);
  try
    Frm.BorderStyle := bsDialog;
    Frm.Position := poOwnerFormCenter;
    Frm.Caption := TrText('ListView.AskAI');
    Frm.Font.Name := 'Segoe UI';
    Frm.Font.Size := 9;
    Frm.Color := clBtnFace;
    FfPrepareDialog(Frm, 480, 280);

    Footer := TPanel.Create(Frm);
    Footer.Parent := Frm;
    Footer.Align := alBottom;
    Footer.Height := 48;
    Footer.BevelOuter := bvNone;
    Footer.ParentBackground := False;
    Footer.Color := clBtnFace;

    BtnCancel := TButton.Create(Frm);
    BtnCancel.Parent := Footer;
    BtnCancel.Caption := TrText('Cancel');
    BtnCancel.ModalResult := mrCancel;
    BtnCancel.Cancel := True;
    BtnCancel.SetBounds(Footer.ClientWidth - 12 - 88, 12, 88, 28);
    BtnCancel.Anchors := [akTop, akRight];

    BtnOk := TButton.Create(Frm);
    BtnOk.Parent := Footer;
    BtnOk.Caption := TrText('OK');
    BtnOk.ModalResult := mrOk;
    BtnOk.Default := True;
    BtnOk.SetBounds(BtnCancel.Left - 8 - 88, 12, 88, 28);
    BtnOk.Anchors := [akTop, akRight];

    if chkMergeLines.Checked then
      Cap := TrText('LineEditor.AskAI.MergePrompt')
    else
      Cap := Format(TrText('LineEditor.AskAI.PromptLabel: %s'), [LineHint]);

    Lbl := TLabel.Create(Frm);
    Lbl.Parent := Frm;
    Lbl.AutoSize := False;
    Lbl.WordWrap := True;
    Lbl.Transparent := True;
    Lbl.Layout := tlTop;
    Lbl.Caption := Cap;
    Lbl.SetBounds(12, 12, Frm.ClientWidth - 24, 40);
    Frm.Canvas.Font.Assign(Lbl.Font);
    R := Rect(0, 0, Lbl.Width, 0);
    DrawText(Frm.Canvas.Handle, PChar(Cap), Length(Cap), R,
      DT_LEFT or DT_WORDBREAK or DT_CALCRECT or DT_NOPREFIX);
    LabelH := R.Bottom - R.Top + 4;
    if LabelH < 20 then LabelH := 20;
    if LabelH > 72 then LabelH := 72;
    Lbl.Height := LabelH;

    MemoTop := Lbl.Top + Lbl.Height + 8;
    MemoH := Frm.ClientHeight - Footer.Height - MemoTop - 8;
    if MemoH < 80 then MemoH := 80;
    Memo := TMemo.Create(Frm);
    Memo.Parent := Frm;
    Memo.ScrollBars := ssVertical;
    Memo.WantReturns := True;
    Memo.SetBounds(12, MemoTop, Frm.ClientWidth - 24, MemoH);

    if Frm.ShowModal = mrOk then
    begin
      AGoal := Trim(Memo.Text);
      Result := AGoal <> '';
      if not Result then
        ShowAppMessage(TrText('ListView.AskAI.NeedGoal'));
    end;
  finally
    Frm.Free;
  end;
end;

procedure TfrmLineEditor.btnAskAIClick(Sender: TObject);
var
  Goal, Prompt, Excerpt, LineNums: string;
  Target: Int64;
  Del: TList;
  Joined: string;
  I: Integer;
  Ln: Int64;
begin
  if FAskAIInProgress then Exit;
  if not PromptAskAiGoal(Goal) then Exit;

  LineNums := Trim(edtLineNumber.Text);
  Excerpt := mmContent.Text;

  if chkMergeLines.Checked then
  begin
    Del := TList.Create;
    try
      if CollectMergeSelection(Target, Del, Joined) then
      begin
        LineNums := IntToStr(Target);
        for I := 0 to Del.Count - 1 do
          LineNums := LineNums + ',' + IntToStr(NativeInt(Del[I]));
        Excerpt := Joined;
      end;
    finally
      Del.Free;
    end;
  end;

  Prompt :=
    'Apply the user instruction to the complete input text from line(s) ' +
    LineNums + '.' + #13#10 +
    'Preserve every character, field, delimiter, spacing, and line break that ' +
    'the instruction does not ask to change. Return only the complete ' +
    'transformed text, with no explanation, quotation marks, or Markdown.' + #13#10 +
    'If the instruction is ambiguous or cannot be applied, return the input ' +
    'text unchanged.' + #13#10#13#10 +
    'USER INSTRUCTION:' + #13#10 + Goal + #13#10#13#10 +
    'INPUT TEXT:' + #13#10 + Excerpt;

  if Assigned(FAIThread) then
  begin
    FAIThread.WaitFor;
    FreeAndNil(FAIThread);
  end;
  FAskAICaption := btnAskAI.Caption;
  FAskAIOldConfirmEnabled := btnConfirm.Enabled;
  FAskAIOldCancelEnabled := btnCancel.Enabled;
  FAskAIOldMemoEnabled := mmContent.Enabled;
  FAskAIOldAskEnabled := btnAskAI.Enabled;
  FAskAIInProgress := True;
  btnAskAI.Caption := TrText('Assistant.Thinking');
  btnAskAI.Enabled := False;
  btnConfirm.Enabled := False;
  btnCancel.Enabled := False;
  mmContent.Enabled := False;
  LayoutMemoTools;
  try
    FAIThread := TLineEditorAIThread.Create(Self, WideString(Prompt));
    FAIThread.Start;
  except
    on E: Exception do
      AskAIResult(False, '', E.Message);
  end;
end;

procedure TfrmLineEditor.AskAIResult(AOk: Boolean; const AAnswer: WideString;
  const AError: string);
begin
  FAskAIInProgress := False;
  btnAskAI.Caption := FAskAICaption;
  btnAskAI.Enabled := FAskAIOldAskEnabled;
  btnConfirm.Enabled := FAskAIOldConfirmEnabled;
  btnCancel.Enabled := FAskAIOldCancelEnabled;
  mmContent.Enabled := FAskAIOldMemoEnabled;
  LayoutMemoTools;
  if not AOk then
  begin
    ShowAppMessage(Format(TrText('LineEditor.AskAI.RequestFailed: %s'), [AError]));
    Exit;
  end;
  if Trim(AAnswer) = '' then
  begin
    ShowAppMessage(TrText('LineEditor.AskAI.EmptyResponse'));
    Exit;
  end;
  UndoBegin;
  try
    mmContent.Text := string(AAnswer);
  finally
    UndoEnd;
  end;
  if mmContent.Enabled then
    mmContent.SetFocus;
end;

procedure TfrmLineEditor.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if FAskAIInProgress then
    CanClose := False;
end;

class function TfrmLineEditor.Execute(var Op: TOperationType;
  var LineNum: Int64; var TextContent: String;
  const ALockOperation: Boolean = False;
  AGetLine: TLineEditorGetLineEvent = nil;
  AGetCount: TLineEditorGetCountEvent = nil;
  AMergeDeleteLines: TList = nil;
  const AInsertAfter: Boolean = False): Boolean;
var
  InitialOp: TOperationType;
  InitialText, TempText: String;
  Target: Int64;
  Joined: string;
  WantInsertAfter: Boolean;

  function NormalizeEditorNewlines(const S: string): string;
  begin
    Result := StringReplace(S, #13#10, #10, [rfReplaceAll]);
    Result := StringReplace(Result, #13, #10, [rfReplaceAll]);
  end;
begin
  Result := False;
  if Assigned(AMergeDeleteLines) then
    AMergeDeleteLines.Clear;
  frmLineEditor := TfrmLineEditor.Create(nil);
  try
    frmLineEditor.Color := clBtnFace;
    frmLineEditor.DoubleBuffered := True;
    frmLineEditor.AlphaBlend := False;
    ApplyTranslationsToForm(frmLineEditor);
    frmLineEditor.FGetLine := AGetLine;
    frmLineEditor.FGetCount := AGetCount;
    frmLineEditor.FMergeDeleteLines := AMergeDeleteLines;
    frmLineEditor.CreateUndo;
    frmLineEditor.CreateFindBar;
    frmLineEditor.CreateAdjacentButtons;
    FfPrepareDialog(frmLineEditor, 600, 420);
    frmLineEditor.ApplyUiLanguage;
    InitialOp := Op;
    InitialText := NormalizeEditorNewlines(TextContent);
    frmLineEditor.FOrigText := TextContent;
    frmLineEditor.FOrigLineNo := LineNum;

    frmLineEditor.cbOperation.Items.Clear;
    frmLineEditor.cbOperation.Items.Add(TrText('Delete Line'));
    frmLineEditor.cbOperation.Items.Add(TrText('Duplicate Line'));
    frmLineEditor.cbOperation.Items.Add(TrText('Edit Line'));
    frmLineEditor.cbOperation.Items.Add(TrText('Insert line before'));
    frmLineEditor.cbOperation.Items.Add(TrText('Insert line after'));

    case Op of
      otDelete:    frmLineEditor.cbOperation.ItemIndex := 0;
      otDuplicate: frmLineEditor.cbOperation.ItemIndex := 1;
      otEdit:      frmLineEditor.cbOperation.ItemIndex := 2;
      otInsert:
        if AInsertAfter then
          frmLineEditor.cbOperation.ItemIndex := 4
        else
          frmLineEditor.cbOperation.ItemIndex := 3;
    else
      frmLineEditor.cbOperation.ItemIndex := 2;
    end;

    if ALockOperation then
    begin
      frmLineEditor.Tag := 1;
      frmLineEditor.cbOperation.Enabled := False;
      frmLineEditor.edtLineNumber.ReadOnly := True;
      frmLineEditor.edtLineNumber.Color := clBtnFace;
    end
    else
      frmLineEditor.Tag := 0;

    frmLineEditor.chkMergeLines.Enabled :=
      Assigned(AGetLine) and Assigned(AGetCount) and Assigned(AMergeDeleteLines);
    frmLineEditor.LayoutMergePanel(False);

    frmLineEditor.cbOperationChange(nil);

    if LineNum > 0 then
      frmLineEditor.edtLineNumber.Text := IntToStr(LineNum)
    else
      frmLineEditor.edtLineNumber.Text := '';

    if Op = otInsert then
      frmLineEditor.mmContent.Text := ''
    else
      frmLineEditor.mmContent.Text := TextContent;
    frmLineEditor.UndoReset;
    frmLineEditor.UpdateMemoToolButtons;
    frmLineEditor.UpdateAdjacentButtons;

    if frmLineEditor.ShowModal = mrOk then
    begin
      if frmLineEditor.chkMergeLines.Checked then
      begin
        if not frmLineEditor.CollectMergeSelection(Target,
          AMergeDeleteLines, Joined) then
        begin
          Result := False;
          Exit;
        end;
        Op := otEdit;
        LineNum := Target;
        TextContent := NormalizeEditorNewlines(frmLineEditor.mmContent.Text);
        if (Length(TextContent) > 0) and (TextContent[Length(TextContent)] = #10) then
          SetLength(TextContent, Length(TextContent) - 1);
        Result := True;
        Exit;
      end;

      WantInsertAfter := False;
      if ALockOperation then
      begin
        Op := InitialOp;
        WantInsertAfter := AInsertAfter and (Op = otInsert);
      end
      else
        case frmLineEditor.cbOperation.ItemIndex of
          0: Op := otDelete;
          1: Op := otDuplicate;
          2: Op := otEdit;
          3: Op := otInsert;
          4: begin Op := otInsert; WantInsertAfter := True; end;
        end;

      LineNum := StrToInt64Def(frmLineEditor.edtLineNumber.Text, 0);

      TempText := NormalizeEditorNewlines(frmLineEditor.mmContent.Text);
      if (Length(TempText) > 0) and (TempText[Length(TempText)] = #10) then
        SetLength(TempText, Length(TempText) - 1);
      TextContent := TempText;

      if Op = otDuplicate then
      begin
        Op := otInsert;
        Inc(LineNum);
      end
      else if WantInsertAfter then
        Inc(LineNum);

      if (InitialOp = otEdit) and (Op = otEdit) and
         (NormalizeEditorNewlines(TextContent) = InitialText) then
      begin
        Result := False;
        Exit;
      end;
      Result := True;
    end;
  finally
    FreeAndNil(frmLineEditor);
  end;
end;

procedure TfrmLineEditor.cbOperationChange(Sender: TObject);
begin
  if chkMergeLines.Checked then
  begin
    mmContent.Enabled := True;
    mmContent.Color := clWindow;
    UpdateMemoToolButtons;
    UpdateAdjacentButtons;
    Exit;
  end;
  mmContent.Enabled := (cbOperation.ItemIndex in [2, 3, 4]);
  if not mmContent.Enabled then
    mmContent.Color := clBtnFace
  else
    mmContent.Color := clWindow;
  if Sender <> nil then
  begin
    UndoBegin;
    try
      if IsInsertOp then
      begin
        if mmContent.Text = FOrigText then
          mmContent.Text := '';
      end
      else if mmContent.Text = '' then
        mmContent.Text := FOrigText;
    finally
      UndoEnd;
    end;
  end;
  UpdateMemoToolButtons;
  UpdateAdjacentButtons;
end;

procedure TfrmLineEditor.btnConfirmClick(Sender: TObject);
var
  OpText, MsgText: string;
  Target: Int64;
  Del: TList;
  Joined: string;
  Extra: string;
begin
  if Trim(edtLineNumber.Text) = '' then
  begin
    ShowAppMessage('Line Number is required.');
    Exit;
  end;

  if chkMergeLines.Checked then
  begin
    Del := TList.Create;
    try
      if not CollectMergeSelection(Target, Del, Joined) then Exit;
      MsgText := TrText('LineEditor.MergeConfirm') + #13#10#13#10 +
        Format(TrText('LineEditor.MergeConfirmDetail: %d %d'),
          [Target, Del.Count + 1]) + #13#10#13#10 +
        TrText('Do you want to continue?');
      if FastFileMessageDlg(MsgText, mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
        Exit;
      ModalResult := mrOk;
    finally
      Del.Free;
    end;
    Exit;
  end;

  case cbOperation.ItemIndex of
    0: OpText := TrText('Delete Line');
    1: OpText := TrText('Duplicate Line');
    2: OpText := TrText('Edit Line');
    3: OpText := TrText('Insert line before');
    4: OpText := TrText('Insert line after');
  else
    OpText := TrText('Operation');
  end;
  Extra := '';
  MsgText := TrText('Confirm the operation?') + #13#10#13#10 +
             OpText + #13#10 +
             TrText('Line: ') + Trim(edtLineNumber.Text) + Extra + #13#10#13#10 +
             TrText('Do you want to continue?');
  if FastFileMessageDlg(MsgText, mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;
  ModalResult := mrOk;
end;

procedure TfrmLineEditor.btnCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TfrmLineEditor.FormResize(Sender: TObject);
begin
  if not Assigned(mmContent) or not Assigned(pnlMerge) then
    Exit;
  LayoutMergePanel(pnlMerge.Visible, False);
end;

procedure TfrmLineEditor.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  Mods: TShiftState;
  InCombo, InEdit: Boolean;
  K: Word;

  procedure Handled(ACtrlChar: Boolean = False);
  begin
    Key := 0;
    FSuppressCtrlChar := ACtrlChar;
  end;

begin
  K := Key;
  Mods := Shift * [ssCtrl, ssShift, ssAlt];
  InCombo := ActiveControl = cbOperation;
  InEdit := (ActiveControl is TCustomEdit) or InCombo;

  if (Key = VK_RETURN) and (Mods = [ssCtrl]) then
  begin
    Handled(True);
    if btnConfirm.Enabled then
      btnConfirm.Click;
    Exit;
  end;
  if (Key = VK_DELETE) and (Mods = [ssCtrl, ssShift]) then
  begin
    Handled;
    if btnClear.Enabled then
      btnClearClick(btnClear);
    Exit;
  end;
  if (Key = Ord('A')) and (Mods = [ssCtrl, ssShift]) then
  begin
    Handled(True);
    if btnAskAI.Enabled then
      btnAskAIClick(btnAskAI);
    Exit;
  end;
  { Ctrl+Z / Ctrl+Y usam a pilha própria do memo; nos campos Procurar/Substituir fica o padrão. }
  if ((ActiveControl = mmContent) or not InEdit) and
     (((K = Ord('Z')) and (Mods = [ssCtrl])) or
      ((K = Ord('Y')) and (Mods = [ssCtrl])) or
      ((K = Ord('Z')) and (Mods = [ssCtrl, ssShift]))) then
  begin
    Handled(True);
    if (K = Ord('Z')) and (Mods = [ssCtrl]) then DoUndo else DoRedo;
    Exit;
  end;
  { Fora dos campos de texto, Ctrl+A/C/V agem sobre o memo. }
  if (Mods = [ssCtrl]) and not InEdit and
     ((Key = Ord('A')) or (Key = Ord('C')) or (Key = Ord('V'))) then
  begin
    Handled(True);
    case K of
      Ord('A'): MemoSelectAll;
      Ord('C'): MemoCopy;
    else
      MemoPaste;
      UpdateMemoToolButtons;
    end;
    Exit;
  end;
  if ((Key = VK_UP) or (Key = VK_DOWN)) and (Mods = [ssAlt]) and not InCombo and
     Assigned(FbtnPrevLine) and FbtnPrevLine.Visible then
  begin
    Handled;
    if (K = VK_UP) and FbtnPrevLine.Enabled then
      btnPrevLineClick(FbtnPrevLine)
    else if (K = VK_DOWN) and FbtnNextLine.Enabled then
      btnNextLineClick(FbtnNextLine);
    Exit;
  end;
  if (Key = VK_F4) and Assigned(FedtRepl) and not InCombo and
     ((Mods = []) or (Mods = [ssShift])) then
  begin
    Handled;
    if ssShift in Mods then ReplaceAll else ReplaceCurrent;
    Exit;
  end;

  if Assigned(FedtFind) then
  begin
    if ((Key = Ord('F')) and (ssCtrl in Shift)) then
    begin
      Handled(True);
      FocusFind;
      Exit;
    end;
    if ((Key = Ord('H')) and (ssCtrl in Shift)) then
    begin
      Handled(True);
      FocusReplace;
      Exit;
    end;
    if Key = VK_F3 then
    begin
      Key := 0;
      if ssShift in Shift then FindStep(-1) else FindStep(1);
      Exit;
    end;
    if (Key = VK_ESCAPE) and (ActiveControl = FedtFind) and (FedtFind.Text <> '') then
    begin
      Key := 0;
      FedtFind.Text := '';
      Exit;
    end;
  end;
  if Key = VK_ESCAPE then
  begin
    Key := 0;
    ModalResult := mrCancel;
  end;
end;

end.
