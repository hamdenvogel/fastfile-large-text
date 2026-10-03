unit UnSplash;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  sLabel, StdCtrls, sGroupBox, ExtCtrls, sPanel, sSkinProvider, ComCtrls,
  acProgressBar, Buttons, sBitBtn, acPNG, acImage, sMemo, sSpeedButton,
  sButton;

type
  TfrmSplash = class(TForm)
    sSkinProvider1: TsSkinProvider;
    grdpnlMain: TsGradientPanel;
    sImage2: TsImage;
    img: TsImage;
    sLabelFX1: TsLabelFX;
    sLabelFX2: TsLabelFX;
    pnlInfo: TsPanel;
    sGroupBox1: TsGroupBox;
    sWebLabel2: TsLabel;
    sLabel5: TsLabel;
    sLabelFX3: TsLabelFX;
    memoLicense: TsMemo;
    grdpnlBottom: TsGradientPanel;
    btnMoreInfo: TsSpeedButton;
    grdpnlButtonsBottom: TsGradientPanel;
    btnClose: TsButton;
    procedure WMSysCommand(var Msg: TWMSysCommand); message WM_SYSCOMMAND;
    procedure btnMoreInfoClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  public
    constructor Create(AOwner: TComponent); override;
  end;

var
  frmSplash: TfrmSplash;

implementation

uses UnUtils, unMoreInfo, uI18n;

{$R *.DFM}

{ TfrmSplash }

constructor TfrmSplash.Create(AOwner: TComponent);
var
  BtnCopy, BtnExport: TButton;
  TotalW, StartX, BtnTop: Integer;
begin
  inherited Create(AOwner);
  btnClose.Caption := TrText('Close');
  KeyPreview := True;
  OnKeyDown  := FormKeyDown;
  { Add Copy and Export buttons alongside the existing Close button }
  TotalW := 90 * 2 + 8;
  StartX := (grdpnlButtonsBottom.ClientWidth - TotalW - 8) div 2;
  BtnTop := (grdpnlButtonsBottom.ClientHeight - 26) div 2;
  if BtnTop < 2 then BtnTop := 2;

  BtnCopy := TButton.Create(Self);
  BtnCopy.Parent := grdpnlButtonsBottom;
  BtnCopy.Caption := TrText('&Copy');
  BtnCopy.Width := 90;
  BtnCopy.Height := 26;
  BtnCopy.Left := StartX;
  BtnCopy.Top  := BtnTop;
  BtnCopy.ModalResult := mrYes;

  BtnExport := TButton.Create(Self);
  BtnExport.Parent := grdpnlButtonsBottom;
  BtnExport.Caption := TrText('&Export...');
  BtnExport.Width := 90;
  BtnExport.Height := 26;
  BtnExport.Left := StartX + 98;
  BtnExport.Top  := BtnTop;
  BtnExport.ModalResult := mrRetry;
end;

procedure TfrmSplash.WMSysCommand(var Msg: TWMSysCommand);
begin
  if ((Msg.CmdType and $FFF0) = SC_MOVE) or 
    ((Msg.CmdType and $FFF0) = SC_SIZE) then 
  begin
    Msg.Result := 0;
    Exit;
  end; 
  inherited;
end;

procedure TfrmSplash.btnMoreInfoClick(Sender: TObject);
begin
  frmMoreInfo := TfrmMoreInfo.Create(nil);
  try
    frmMoreInfo.BorderStyle := bsDialog;
    frmMoreInfo.ShowModal;
  finally
    FreeAndNil(frmMoreInfo);
  end;
end;

procedure TfrmSplash.btnCloseClick(Sender: TObject);
begin
  ModalResult := mrOk;
end;

procedure TfrmSplash.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_ESCAPE then ModalResult := mrCancel;
end;

end.
