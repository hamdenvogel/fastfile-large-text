unit MruHelper;

interface

uses
  uPosBMH,
  Windows, Messages, SysUtils, Classes, Controls, StdCtrls, Forms, ExtCtrls,
  Graphics, IniFiles, Math;

type
  TMruHelper = class
  private
    FEdit: TEdit;
    FPopup: TForm;
    FList: TListBox;
    FAllItems: TStringList;
    FMaxItems: Integer;
    FIniFileName: string;
    FDebounce: TTimer;
    FDebounceInterval: Integer;
    FOldOnEnter: TNotifyEvent;
    FOldOnExit: TNotifyEvent;
    FOldOnChange: TNotifyEvent;
    FOldOnKeyDown: TKeyEvent;
    FIgnoreChange: Boolean;

    procedure EditEnter(Sender: TObject);
    procedure EditExit(Sender: TObject);
    procedure EditChange(Sender: TObject);
    procedure EditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure DebounceTimer(Sender: TObject);

    procedure CreatePopup;
    procedure ShowPopup;
    procedure HidePopup;
    procedure ApplyFilter(const FilterText: string);

    procedure ListClick(Sender: TObject);
    procedure ListDblClick(Sender: TObject);
    procedure ListDrawItem(Control: TWinControl; Index: Integer; Rect: TRect; State: TOwnerDrawState);

    procedure LoadFromIni;
    procedure SaveToIni;

  public
    constructor Create(AEdit: TEdit; const AIniFileName: string; AMaxItems: Integer = 20);
    destructor Destroy; override;

    procedure AddItem(const S: string);
    procedure Clear;

    property MaxItems: Integer read FMaxItems write FMaxItems;
    property DebounceInterval: Integer read FDebounceInterval write FDebounceInterval;
  end;

implementation

{ TMruHelper }

constructor TMruHelper.Create(AEdit: TEdit; const AIniFileName: string; AMaxItems: Integer);
begin
  inherited Create;

  FEdit := AEdit;
  FIniFileName := AIniFileName;
  FMaxItems := AMaxItems;

  FAllItems := TStringList.Create;
  FAllItems.Sorted := False;
  FAllItems.Duplicates := dupIgnore;

  FOldOnEnter := FEdit.OnEnter;
  FOldOnExit := FEdit.OnExit;
  FOldOnChange := FEdit.OnChange;
  FOldOnKeyDown := FEdit.OnKeyDown;

  FEdit.OnEnter := EditEnter;
  FEdit.OnExit := EditExit;
  FEdit.OnChange := EditChange;
  FEdit.OnKeyDown := EditKeyDown;

  FDebounce := TTimer.Create(nil);
  FDebounce.Enabled := False;
  FDebounceInterval := 150;
  FDebounce.Interval := FDebounceInterval;
  FDebounce.OnTimer := DebounceTimer;

  CreatePopup;
  LoadFromIni;
end;

destructor TMruHelper.Destroy;
begin
  FEdit.OnEnter := FOldOnEnter;
  FEdit.OnExit := FOldOnExit;
  FEdit.OnChange := FOldOnChange;
  FEdit.OnKeyDown := FOldOnKeyDown;

  SaveToIni;

  FPopup.Free;
  FDebounce.Free;
  FAllItems.Free;

  inherited;
end;

procedure TMruHelper.CreatePopup;
begin
  FPopup := TForm.Create(nil);
  FPopup.BorderStyle := bsNone;
  FPopup.FormStyle := fsStayOnTop;
  FPopup.Color := clWindow;
  FPopup.Visible := False;

  FList := TListBox.Create(FPopup);
  FList.Parent := FPopup;
  FList.Align := alClient;
  FList.Style := lbOwnerDrawFixed;
  FList.ItemHeight := 18;
  FList.OnClick := ListClick;
  FList.OnDblClick := ListDblClick;
  FList.OnDrawItem := ListDrawItem;
end;

procedure TMruHelper.EditEnter(Sender: TObject);
begin
  if Assigned(FOldOnEnter) then FOldOnEnter(Sender);
  ApplyFilter('');
  if FList.Items.Count > 0 then
    ShowPopup;
end;

procedure TMruHelper.EditExit(Sender: TObject);
begin
  if Assigned(FOldOnExit) then FOldOnExit(Sender);

  if Trim(FEdit.Text) <> '' then
    AddItem(FEdit.Text);

  SaveToIni;
  HidePopup;
end;

procedure TMruHelper.EditChange(Sender: TObject);
begin
  if Assigned(FOldOnChange) then FOldOnChange(Sender);
  if FIgnoreChange then Exit;

  FDebounce.Enabled := False;
  FDebounce.Interval := FDebounceInterval;
  FDebounce.Enabled := True;
end;

procedure TMruHelper.EditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Assigned(FOldOnKeyDown) then FOldOnKeyDown(Sender, Key, Shift);

  case Key of
    VK_DOWN, VK_RETURN, VK_TAB, VK_SPACE:
      begin
        ApplyFilter(FEdit.Text);
        if FList.Items.Count > 0 then
          ShowPopup;
        Key := 0;
      end;

    VK_ESCAPE:
      begin
        HidePopup;
        Key := 0;
      end;
  end;
end;

procedure TMruHelper.DebounceTimer(Sender: TObject);
begin
  FDebounce.Enabled := False;
  ApplyFilter(FEdit.Text);
  if FList.Items.Count > 0 then
    ShowPopup
  else
    HidePopup;
end;

procedure TMruHelper.ShowPopup;
var
  P: TPoint;
  H, Count: Integer;
begin
  if FList.Items.Count = 0 then Exit;

  P := FEdit.ClientToScreen(Point(0, FEdit.Height));
  FPopup.Left := P.X;
  FPopup.Top := P.Y;

  // FIX: largura correta j� na primeira vez
  FPopup.Width := FEdit.ClientWidth;

  Count := Min(FList.Items.Count, 8);
  H := Count * FList.ItemHeight + 4;
  FPopup.ClientHeight := H;

  FPopup.Show;
  // Garantir alinhamento perfeito
  FPopup.Width := FEdit.ClientWidth;
end;

procedure TMruHelper.HidePopup;
begin
  FPopup.Hide;
end;

procedure TMruHelper.ApplyFilter(const FilterText: string);
var
  i: Integer;
  s: string;
begin
  FList.Items.BeginUpdate;
  try
    FList.Items.Clear;

    for i := 0 to FAllItems.Count - 1 do
    begin
      s := FAllItems[i];
      if (Trim(FilterText) = '') or (PosBMH(AnsiLowerCase(Trim(FilterText)), AnsiLowerCase(s)) > 0) then
        FList.Items.Add(s);
    end;

  finally
    FList.Items.EndUpdate;
  end;
end;

procedure TMruHelper.ListClick(Sender: TObject);
begin
  if FList.ItemIndex >= 0 then
  begin
    FIgnoreChange := True;
    try
      FEdit.Text := FList.Items[FList.ItemIndex];
      FEdit.SelStart := Length(FEdit.Text);
    finally
      FIgnoreChange := False;
    end;
  end;
  HidePopup;
end;

procedure TMruHelper.ListDblClick(Sender: TObject);
begin
  ListClick(Sender);
end;

procedure TMruHelper.ListDrawItem(Control: TWinControl; Index: Integer; Rect: TRect; State: TOwnerDrawState);
var
  LB: TListBox;
  Txt: string;
begin
  LB := Control as TListBox;
  Txt := LB.Items[Index];

  if odSelected in State then
  begin
    LB.Canvas.Brush.Color := clHighlight;
    LB.Canvas.Font.Color := clHighlightText;
  end
  else
  begin
    LB.Canvas.Brush.Color := LB.Color;
    LB.Canvas.Font.Color := clWindowText;
  end;

  LB.Canvas.FillRect(Rect);
  LB.Canvas.TextOut(Rect.Left + 4, Rect.Top + 2, Txt);
end;

procedure TMruHelper.AddItem(const S: string);
var
  idx: Integer;
begin
  if Trim(S) = '' then Exit;

  idx := FAllItems.IndexOf(S);
  if idx >= 0 then
    FAllItems.Delete(idx);

  FAllItems.Insert(0, S);

  while FAllItems.Count > FMaxItems do
    FAllItems.Delete(FAllItems.Count - 1);
end;

procedure TMruHelper.Clear;
begin
  FAllItems.Clear;
end;

procedure TMruHelper.LoadFromIni;
var
  Ini: TIniFile;
  i: Integer;
  s: string;
begin
  if not FileExists(FIniFileName) then Exit;

  Ini := TIniFile.Create(FIniFileName);
  try
    FAllItems.Clear;
    i := 0;
    repeat
      s := Ini.ReadString('MRU', 'Item' + IntToStr(i), '');
      if s <> '' then
      begin
        FAllItems.Add(s);
        Inc(i);
      end
      else
        Break;
    until False;
  finally
    Ini.Free;
  end;
end;

procedure TMruHelper.SaveToIni;
var
  Ini: TIniFile;
  i: Integer;
begin
  Ini := TIniFile.Create(FIniFileName);
  try
    Ini.EraseSection('MRU');
    for i := 0 to FAllItems.Count - 1 do
      Ini.WriteString('MRU', 'Item' + IntToStr(i), FAllItems[i]);
  finally
    Ini.Free;
  end;
end;

end.

