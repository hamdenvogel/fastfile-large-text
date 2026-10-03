unit uTailExportDialog;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls;

type
  TfrmTailExportDialog = class(TForm)
    lblTitle: TLabel;
    lblAvailable: TLabel;
    grpScope: TRadioGroup;
    lblFrom: TLabel;
    lblTo: TLabel;
    edtFromLine: TEdit;
    edtToLine: TEdit;
    lblPath: TLabel;
    edtPath: TEdit;
    btnBrowse: TButton;
    Bevel1: TBevel;
    btnExport: TButton;
    btnCancel: TButton;
    procedure btnExportClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure btnBrowseClick(Sender: TObject);
    procedure grpScopeClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    FFirstLine1: Int64;
    FLastLine1: Int64;
    procedure UpdateRangeEditsEnabled;
  public
    class function Execute(const AFirstLine1Based, ALastLine1Based: Int64;
      var AOutPath: string; var AExportAll: Boolean;
      var AFrom1Based, ATo1Based: Int64): Boolean;
  end;

implementation

uses
  uI18n, uFastFileMsgDlg;

{$R *.dfm}

procedure TfrmTailExportDialog.UpdateRangeEditsEnabled;
var
  UseRange: Boolean;
begin
  UseRange := (grpScope.ItemIndex = 1);
  lblFrom.Enabled := UseRange;
  lblTo.Enabled := UseRange;
  edtFromLine.Enabled := UseRange;
  edtToLine.Enabled := UseRange;
end;

procedure TfrmTailExportDialog.FormShow(Sender: TObject);
begin
  UpdateRangeEditsEnabled;
end;

procedure TfrmTailExportDialog.grpScopeClick(Sender: TObject);
begin
  UpdateRangeEditsEnabled;
end;

procedure TfrmTailExportDialog.btnBrowseClick(Sender: TObject);
var
  Dlg: TSaveDialog;
begin
  Dlg := TSaveDialog.Create(nil);
  try
    Dlg.Title := TrText('Tail export file');
    Dlg.FileName := edtPath.Text;
    Dlg.Filter := TrText('Text files (*.txt)|*.txt|All files (*.*)|*.*');
    Dlg.DefaultExt := 'txt';
    if Dlg.Execute then
      edtPath.Text := Dlg.FileName;
  finally
    Dlg.Free;
  end;
end;

procedure TfrmTailExportDialog.btnExportClick(Sender: TObject);
var
  VFrom, VTo: Int64;
begin
  if Trim(edtPath.Text) = '' then
  begin
    FastFileMessageBox(PChar(TrText('Export path is required.')),
      PChar(TrText('Export tail lines')), MB_OK or MB_ICONWARNING);
    edtPath.SetFocus;
    Exit;
  end;
  if grpScope.ItemIndex = 1 then
  begin
    VFrom := StrToInt64Def(Trim(edtFromLine.Text), -1);
    VTo := StrToInt64Def(Trim(edtToLine.Text), -1);
    if (VFrom < FFirstLine1) or (VTo > FLastLine1) or (VFrom > VTo) then
    begin
      FastFileMessageBox(PChar(Format(TrText('Line range must be between %d and %d.'),
        [FFirstLine1, FLastLine1])), PChar(TrText('Export tail lines')),
        MB_OK or MB_ICONWARNING);
      edtFromLine.SetFocus;
      Exit;
    end;
  end;
  ModalResult := mrOk;
end;

procedure TfrmTailExportDialog.btnCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

class function TfrmTailExportDialog.Execute(const AFirstLine1Based,
  ALastLine1Based: Int64; var AOutPath: string; var AExportAll: Boolean;
  var AFrom1Based, ATo1Based: Int64): Boolean;
var
  Frm: TfrmTailExportDialog;
  VFrom, VTo: Int64;
begin
  Result := False;
  if ALastLine1Based < AFirstLine1Based then
    Exit;
  Frm := TfrmTailExportDialog.Create(nil);
  try
    Frm.FFirstLine1 := AFirstLine1Based;
    Frm.FLastLine1 := ALastLine1Based;
    ApplyTranslationsToForm(Frm);
    Frm.Caption := TrText('Export tail lines');
    Frm.grpScope.Caption := TrText('What to export');
    Frm.lblTitle.Caption := TrText('Export lines appended while Tail / Follow mode was active (Ctrl+T).');
    Frm.lblFrom.Caption := TrText('From line:');
    Frm.lblTo.Caption := TrText('To line:');
    Frm.lblPath.Caption := TrText('Save to file:');
    Frm.btnBrowse.Caption := TrText('Browse...');
    Frm.btnExport.Caption := TrText('Export');
    Frm.btnCancel.Caption := TrText('Cancel');
    Frm.lblAvailable.Caption := Format(TrText('Tail captured %d line(s), from line %d to %d.'),
      [ALastLine1Based - AFirstLine1Based + 1, AFirstLine1Based, ALastLine1Based]);
    Frm.grpScope.Items.Clear;
    Frm.grpScope.Items.Add(TrText('All lines captured in this Tail session'));
    Frm.grpScope.Items.Add(TrText('Line range (from line ... to line ...)'));
    Frm.grpScope.ItemIndex := 0;
    Frm.edtFromLine.Text := Format('%d', [AFirstLine1Based]);
    Frm.edtToLine.Text := Format('%d', [ALastLine1Based]);
    Frm.edtPath.Text := AOutPath;
    if Frm.ShowModal = mrOk then
    begin
      AOutPath := Trim(Frm.edtPath.Text);
      AExportAll := (Frm.grpScope.ItemIndex = 0);
      if AExportAll then
      begin
        AFrom1Based := AFirstLine1Based;
        ATo1Based := ALastLine1Based;
      end
      else
      begin
        VFrom := StrToInt64Def(Trim(Frm.edtFromLine.Text), AFirstLine1Based);
        VTo := StrToInt64Def(Trim(Frm.edtToLine.Text), ALastLine1Based);
        if VFrom < AFirstLine1Based then VFrom := AFirstLine1Based;
        if VTo > ALastLine1Based then VTo := ALastLine1Based;
        if VFrom > VTo then
        begin
          AFrom1Based := VTo;
          ATo1Based := VFrom;
        end
        else
        begin
          AFrom1Based := VFrom;
          ATo1Based := VTo;
        end;
      end;
      Result := True;
    end;
  finally
    Frm.Free;
  end;
end;

end.
