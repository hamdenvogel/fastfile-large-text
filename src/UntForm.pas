unit UntForm;
interface
uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, DB, Buttons;
type
  TFrmFields = class(TForm)
  private
    FDataSetItems: TDataSet;
    { Private declarations }
    procedure IncludeBtnClick(Sender: TObject);
    procedure ExcludeBtnClick(Sender: TObject);
    procedure IncAllBtnClick(Sender: TObject);
    procedure ExcAllBtnClick(Sender: TObject);
    procedure MoveSelected(List: TCustomListBox; Items: TStrings);
    procedure SetItem(List: TListBox; Index: Integer);
    function GetFirstSelection(List: TCustomListBox): Integer;
    procedure SetButtons;
    procedure SetDataSetItems(const Value: TDataSet);
  public
    OKBtn: TButton;
    CancelBtn: TButton;
    SrcLabel: TLabel;
    DstLabel: TLabel;
    IncludeBtn: TSpeedButton;
    IncAllBtn: TSpeedButton;
    ExcludeBtn: TSpeedButton;
    ExAllBtn: TSpeedButton;
    SrcList: TListBox;
    DstList: TListBox;
    constructor Create(AOwner: TComponent; pDataSet:TDataSet=nil);//;reintroduce;
    procedure IniForm;
    property DataSetItems:TDataSet read FDataSetItems write SetDataSetItems;
  end;
var
  FrmFields:TFrmFields;
implementation
{ TFrmField }
procedure TFrmFields.IncludeBtnClick(Sender: TObject);
var
  Index: Integer;
begin
  Index := GetFirstSelection(SrcList);
  MoveSelected(SrcList, DstList.Items);
  SetItem(SrcList, Index);
end;
procedure TFrmFields.ExcludeBtnClick(Sender: TObject);
var
  Index: Integer;
begin
  Index := GetFirstSelection(DstList);
  MoveSelected(DstList, SrcList.Items);
  SetItem(DstList, Index);
end;
procedure TFrmFields.IncAllBtnClick(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to SrcList.Items.Count - 1 do
    DstList.Items.AddObject(SrcList.Items[I],
      SrcList.Items.Objects[I]);
  SrcList.Items.Clear;
  SetItem(SrcList, 0);
end;
procedure TFrmFields.ExcAllBtnClick(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to DstList.Items.Count - 1 do
    SrcList.Items.AddObject(DstList.Items[I], DstList.Items.Objects[I]);
  DstList.Items.Clear;
  SetItem(DstList, 0);
end;
procedure TFrmFields.MoveSelected(List: TCustomListBox; Items: TStrings);
var
  I: Integer;
begin
  for I := List.Items.Count - 1 downto 0 do
    if List.Selected[I] then
    begin
      Items.AddObject(List.Items[I], List.Items.Objects[I]);
      List.Items.Delete(I);
    end;
end;
procedure TFrmFields.SetButtons;
var
  SrcEmpty, DstEmpty: Boolean;
begin
  SrcEmpty := SrcList.Items.Count = 0;
  DstEmpty := DstList.Items.Count = 0;
  IncludeBtn.Enabled := not SrcEmpty;
  IncAllBtn.Enabled := not SrcEmpty;
  ExcludeBtn.Enabled := not DstEmpty;
  ExAllBtn.Enabled := not DstEmpty;
end;
function TFrmFields.GetFirstSelection(List: TCustomListBox): Integer;
begin
  for Result := 0 to List.Items.Count - 1 do
    if List.Selected[Result] then Exit;
  Result := LB_ERR;
end;
procedure TFrmFields.SetItem(List: TListBox; Index: Integer);
var
  MaxIndex: Integer;
begin
  with List do
  begin
    SetFocus;
    MaxIndex := List.Items.Count - 1;
    if Index = LB_ERR then Index := 0
    else if Index > MaxIndex then Index := MaxIndex;
    Selected[Index] := True;
  end;
  SetButtons;
end;
procedure TFrmFields.SetDataSetItems(const Value: TDataSet);
var
  I:Integer;
begin
  SrcList.Clear;
  FDataSetItems := Value;
  for I := 0 to FDataSetItems.Fields.Count -1 do
    SrcList.Items.AddObject(FDataSetItems.Fields[I].FieldName, FDataSetItems.Fields[I]);
  IncludeBtn.Enabled := SrcList.Items.Count > 0;
  IncAllBtn.Enabled  := SrcList.Items.Count > 0;
  OKBtn.Enabled      := SrcList.Items.Count > 0;
end;
constructor TFrmFields.Create(AOwner: TComponent; pDataSet: TDataSet);
begin
  inherited Create(AOwner);
  Self.Height := 282;
  Self.Width  := 353;
  Self.BorderStyle := bsDialog;
  Self.Position := poScreenCenter;
  Self.Visible  := False;
  Self.FormStyle := fsNormal;
{  OKBtn := TButton.Create(Self);
  OKBtn.Parent := Self;
  with OKBtn do
  begin
    Left := 181;
    Top := 220;
    Width := 75;
    Height := 25;
    Caption := 'OK';
    Default := True;
    Enabled := False;
    ModalResult := 1;
    TabOrder := 1;
  end;
  CancelBtn :=  TButton.Create(Self);
  with CancelBtn do
  begin
    Top := 220;
    Left := 261;
    Width := 75;
    Height := 25;
    Cancel := True;
    Caption := 'Cancela';
    ModalResult := 2;
    TabOrder := 2;
  end;
  DstList := TListBox.Create(Self);
  with DstList do
  begin
    Left := 192;
    Top := 24 ;
    Width := 144 ;
    Height := 185 ;
    ItemHeight := 13;
    MultiSelect := True;
    TabOrder := 0;
  end;
  SrcLabel := TLabel.Create(Self);
  with SrcLabel do
  begin
    Left := 8;
    Top := 8;
    Width := 145;
    Height := 16;
    AutoSize := False;
    Caption := 'Lista Original:';
  end;
  DstLabel := TLabel.Create(Self);
  with DstLabel do
  begin
    Left := 192;
    Top := 8;
    Width := 145;
    Height := 16;
    AutoSize := False;
    Caption := 'Destination List:';
  end;
  IncludeBtn :=  TSpeedButton.Create(Self);
  with IncludeBtn do
  begin
    Left := 160;
    Top := 32;
    Width := 24;
    Height := 24;
    Caption := '>';
    Enabled := False;
    OnClick := IncludeBtnClick;
  end;
  IncAllBtn := TSpeedButton.Create(Self);
  with IncAllBtn do
  begin
    Left := 160 ;
    Top := 64;
    Width := 24;
    Height := 24;
    Caption := '>>';
    Enabled := False;
    OnClick := IncAllBtnClick;
  end;
  ExcludeBtn := TSpeedButton.Create(Self);
  with ExcludeBtn do
  begin
    Left := 160;
    Top := 96;
    Width := 24;
    Height := 24;
    Caption := '<';
    Enabled := False;
    OnClick := ExcludeBtnClick;
  end;
  ExAllBtn := TSpeedButton.Create(Self);
  with ExAllBtn do
  begin
    Left := 160;
    Top := 128;
    Width := 24;
    Height := 24;
    Caption := '<<';
    Enabled := False;
    OnClick := ExcAllBtnClick;
  end;
  SrcList := TListBox.Create(Self);
  with SrcList do
  begin
    Left := 8;
    Top := 24;
    Width := 144 ;
    Height := 185 ;
    ItemHeight := 13;
    MultiSelect := True;
    TabOrder := 3;
  end;}
 // if (not Assigned(DataSetItems)) and  Assigned(pDataSet) then
 //   DataSetItems := pDataSet;
end;
procedure TFrmFields.IniForm;
begin
end;
end.

