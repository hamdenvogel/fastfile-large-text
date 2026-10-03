unit UntFields;
interface
uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, DB, Buttons;
type
  TProcedure = class
    procedure IncludeBtnClick(Sender: TObject);
    procedure ExcludeBtnClick(Sender: TObject);
    procedure IncAllBtnClick(Sender: TObject);
    procedure ExcAllBtnClick(Sender: TObject);
    procedure MoveSelected(List: TCustomListBox; Items: TStrings);
    procedure SetItem(List: TListBox; Index: Integer);
    function GetFirstSelection(List: TCustomListBox): Integer;
    procedure SetButtons;
  end;
var
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
  function CreateFormField(const pDataSet:TDataSet):TStringList;
implementation
function CreateFormField(const pDataSet:TDataSet):TStringList;
var
  Form:TForm;
  Proc:TProcedure;
  I:Integer;
begin
  Application.CreateForm(TForm, Form);
  Proc := TProcedure.Create;
  try
    with Form do
    begin
      Height := 282;
      Width  := 353;
      BorderStyle := bsDialog;
      Position := poScreenCenter;
      Visible  := False;
      FormStyle := fsNormal;
      OKBtn := TButton.Create(Form);
      with OKBtn do
      begin
        Parent := Form;
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
      CancelBtn :=  TButton.Create(Form);
      with CancelBtn do
      begin
        Parent := Form;
        Top := 220;
        Left := 261;
        Width := 75;
        Height := 25;
        Cancel := True;
        Caption := 'Cancela';
        ModalResult := 2;
        TabOrder := 2;
      end;
      DstList := TListBox.Create(Form);
      with DstList do
      begin
        Parent := Form;
        Left := 192;
        Top := 24 ;
        Width := 144 ;
        Height := 185 ;
        ItemHeight := 13;
        MultiSelect := True;
        TabOrder := 0;
      end;
      SrcLabel := TLabel.Create(Form);
      with SrcLabel do
      begin
        Parent := Form;
        Left := 8;
        Top := 8;
        Width := 145;
        Height := 16;
        AutoSize := False;
        Caption := 'Lista Original:';
      end;
      DstLabel := TLabel.Create(Form);
      with DstLabel do
      begin
        Parent := Form;
        Left := 192;
        Top := 8;
        Width := 145;
        Height := 16;
        AutoSize := False;
        Caption := 'Lista Destino:';
      end;
      IncludeBtn :=  TSpeedButton.Create(Form);
      with IncludeBtn do
      begin
        Parent := Form;
        Left := 160;
        Top := 32;
        Width := 24;
        Height := 24;
        Caption := '>';
        Enabled := False;
        OnClick := Proc.IncludeBtnClick;
      end;
      IncAllBtn := TSpeedButton.Create(Form);
      with IncAllBtn do
      begin
        Parent := Form;
        Left := 160 ;
        Top := 64;
        Width := 24;
        Height := 24;
        Caption := '>>';
        Enabled := False;
        OnClick := Proc.IncAllBtnClick;
      end;
      ExcludeBtn := TSpeedButton.Create(Form);
      with ExcludeBtn do
      begin
        Parent := Form;
        Left := 160;
        Top := 96;
        Width := 24;
        Height := 24;
        Caption := '<';
        Enabled := False;
        OnClick := Proc.ExcludeBtnClick;
      end;
      ExAllBtn := TSpeedButton.Create(Form);
      with ExAllBtn do
      begin
        Parent := Form;
        Left := 160;
        Top := 128;
        Width := 24;
        Height := 24;
        Caption := '<<';
        Enabled := False;
        OnClick := Proc.ExcAllBtnClick;
      end;
      SrcList := TListBox.Create(Form);
      with SrcList do
      begin
        Parent := Form;
        Left := 8;
        Top := 24;
        Width := 144 ;
        Height := 185 ;
        ItemHeight := 13;
        MultiSelect := True;
        TabOrder := 3;
      end;
      SrcList.Clear;
      for I := 0 to pDataSet.Fields.Count -1 do
        SrcList.Items.AddObject(pDataSet.Fields[I].FieldName, pDataSet.Fields[I]);
      IncludeBtn.Enabled := SrcList.Items.Count > 0;
      IncAllBtn.Enabled  := SrcList.Items.Count > 0;
      OKBtn.Enabled      := SrcList.Items.Count > 0;
      ShowModal;
      if ModalResult = MrOk then
      begin
        Result := TStringList.Create;
        Result.Assign (DstList.Items);
      end else
        Result := nil;
    end;
  finally
    Proc.Free;
    Form.Free;
  end;
end;

procedure TProcedure.IncludeBtnClick(Sender: TObject);
var
  Index: Integer;
begin
  Index := GetFirstSelection(SrcList);
  MoveSelected(SrcList, DstList.Items);
  SetItem(SrcList, Index);
end;
procedure TProcedure.ExcludeBtnClick(Sender: TObject);
var
  Index: Integer;
begin
  Index := GetFirstSelection(DstList);
  MoveSelected(DstList, SrcList.Items);
  SetItem(DstList, Index);
end;
procedure TProcedure.IncAllBtnClick(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to SrcList.Items.Count - 1 do
    DstList.Items.AddObject(SrcList.Items[I],
      SrcList.Items.Objects[I]);
  SrcList.Items.Clear;
  SetItem(SrcList, 0);
end;
procedure TProcedure.ExcAllBtnClick(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to DstList.Items.Count - 1 do
    SrcList.Items.AddObject(DstList.Items[I], DstList.Items.Objects[I]);
  DstList.Items.Clear;
  SetItem(DstList, 0);
end;
procedure TProcedure.MoveSelected(List: TCustomListBox; Items: TStrings);
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
procedure TProcedure.SetItem(List: TListBox; Index: Integer);
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
function TProcedure.GetFirstSelection(List: TCustomListBox): Integer;
begin
  for Result := 0 to List.Items.Count - 1 do
    if List.Selected[Result] then Exit;
  Result := LB_ERR;
end;
procedure TProcedure.SetButtons;
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
end.

