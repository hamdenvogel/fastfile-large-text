unit UnitPopupScaling;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, Dialogs, StdCtrls, sRadioButton,
  ComCtrls, sTrackBar, sLabel, sSkinProvider, Buttons, sSpeedButton,
  sPanel, ImgList, acAlphaImageList, sBevel, ExtCtrls, sCommonData, acAlphaHints;


type
  TFormPopupScaling = class(TForm)
    sSkinProvider1: TsSkinProvider;
    sPanel1: TsPanel;
    sTrackBar1: TsTrackBar;
    sLabel1: TsLabel;
    sLabel2: TsLabel;
    sSpeedButton1: TsSpeedButton;
    sSpeedButton3: TsSpeedButton;
    sCharImageList1: TsCharImageList;
    sBevel1: TsBevel;
    sBevel2: TsBevel;
    sSpeedButton4: TsSpeedButton;
    procedure sTrackBar1UserChanged(Sender: TObject);
    procedure sSpeedButton4Click(Sender: TObject);
    procedure sSpeedButton1Click(Sender: TObject);
    procedure sTrackBar1UserChange(Sender: TObject);
    procedure MakeSelected(Btn: TsSpeedButton; Selected: boolean);
    procedure ClosePopup(AnimationAllowed: boolean = False);
    procedure FormShow(Sender: TObject);
    procedure sTrackBar1SkinPaint(Sender: TObject; Canvas: TCanvas);
  public
  end;

var
  FormPopupScaling: TFormPopupScaling;
  { Definido em TfrmMain.FormCreate — sem uses MainUnit (evita ciclo D7). }
  PopupScalingSkinData: TsCommonData;
  PopupScalingAlphaHints: TsAlphaHints;
  PopupScalingSpeedBtnPPI: TsSpeedButton;
  PopupScalingAppAnimated: Boolean;
  PopupScalingCaptionChanged: TNotifyEvent;
  PopupScalingRestoreDefault: TNotifyEvent;
  { Caption for sSpeedButton4, set by the main form before showing the popup. }
  PopupScalingRestoreCaption: string;

implementation

{$R *.dfm}

uses acntUtils, sGraphUtils, sSkinManager, sConst, sVclUtils, acntTypes, UnDM, uI18n;

const
  ArrowArray: array [0..3] of integer = (96, 120, 144, 192);


procedure TFormPopupScaling.ClosePopup(AnimationAllowed: boolean = False);
begin
  if not AnimationAllowed then begin
    sSkinProvider1.AllowAnimation := False; // Quick hiding
    Close;
    sSkinProvider1.AllowAnimation := True;
    Application.ProcessMessages;
  end
  else
    Close;
end;


procedure TFormPopupScaling.FormShow(Sender: TObject);
begin
  sTrackBar1.Position := GetPPI(PopupScalingSkinData);
  sSpeedButton1.Caption := TrText('Auto scaling');
  sSpeedButton3.Caption := TrText('Custom PixelsPerInch value') + ': ' + IntToStr(sTrackBar1.Position);
  if PopupScalingRestoreCaption <> '' then
    sSpeedButton4.Caption := PopupScalingRestoreCaption
  else
    sSpeedButton4.Caption := TrText('Scale.RestoreDefault');
end;

procedure TFormPopupScaling.sSpeedButton4Click(Sender: TObject);
begin
  ClosePopup;
  MakeSelected(sSpeedButton1, False);
  MakeSelected(sSpeedButton3, True);
  if Assigned(PopupScalingRestoreDefault) then
    PopupScalingRestoreDefault(Self);
end;


procedure TFormPopupScaling.MakeSelected(Btn: TsSpeedButton; Selected: boolean);
begin
  if Selected then begin
    Btn.Font.Style := [fsBold];
    Btn.ImageIndex := 0;
  end
  else begin
    Btn.Font.Style := [];
    Btn.ImageIndex := 1;
  end;
end;


procedure TFormPopupScaling.sSpeedButton1Click(Sender: TObject);
var
  Mode: integer;
begin
  Mode := TsSpeedButton(Sender).Tag;
  case Mode of
    0: begin // Use Delphi VCL auto scaling
      // Hiding of popup window
      ClosePopup;
      DataModule1.sSkinManager1.Options.ScaleMode := smVCL;
      if Assigned(PopupScalingSpeedBtnPPI) then
        PopupScalingSpeedBtnPPI.Caption := TrText('Auto PPI: ') + IntToStr(GetPPI(PopupScalingSkinData));
    end;
    2: begin // Custom
      sTrackBar1.Position := GetPPI(PopupScalingSkinData);
      DataModule1.sSkinManager1.Options.PixelsPerInch := sTrackBar1.Position;
      if Assigned(PopupScalingSpeedBtnPPI) then
        PopupScalingSpeedBtnPPI.Caption := TrText('Custom PPI: ') + IntToStr(sTrackBar1.Position);
{      if Win32MajorVersion >= 10 then begin
//        ClosePopup;
//        Application.ProcessMessages;
        DataModule1.sSkinManager1.Options.ScaleMode := smCustomPPI;
//        Visible := True;
      end
      else}
        DataModule1.sSkinManager1.Options.ScaleMode := smCustomPPI;
    end;
  end;
//  if Win32MajorVersion >= 10 then
//    sTrackBar1.Enabled := (Mode <> 0);

  MakeSelected(sSpeedButton1, Mode = 0);
  MakeSelected(sSpeedButton3, Mode = 2);
  if Assigned(PopupScalingCaptionChanged) then
    PopupScalingCaptionChanged(Self);
end;


procedure TFormPopupScaling.sTrackBar1SkinPaint(Sender: TObject; Canvas: TCanvas);
var
  R, chR: TRect;
  i, aSize: integer;
  TickSize: TSize;
  C: TColor;

  procedure PaintArrow(Value: integer);
  var
    x: integer;
  begin
    x := chR.Left + WidthOf(chR) * (Value - sTrackBar1.Min) div (sTrackBar1.Max - sTrackBar1.Min + 3) + 3;
    R.Right := x + aSize;
    R.Left := x - aSize;
    DrawArrow(Canvas.Handle, C, C, R, asTop, 0, 0, aSize, arsSolid1);
  end;

begin
  chR := sTrackBar1.ChannelRect;
  TickSize := MkSize(ScaleInt(1, sTrackBar1.SkinData), ScaleInt(4, sTrackBar1.SkinData));
  aSize := sTrackBar1.SkinData.CommonSkinData.ArrowSize;
  R.Top := chR.Bottom + sTrackBar1.SkinData.CommonSkinData.Spacing;
  R.Bottom := R.Top + aSize * 2;
  C := GetFontColor(sPanel1, sPanel1.SkinData.SkinIndex, sPanel1.SkinData.SkinManager);
  for i := 0 to Length(ArrowArray) - 1 do
    PaintArrow(ArrowArray[i]);
end;


procedure TFormPopupScaling.sTrackBar1UserChange(Sender: TObject);
var
  i: integer;
begin
  // Hint showing
  if Visible then begin
    for i := 0 to Length(ArrowArray) - 1 do
      if (sTrackBar1.Position <> ArrowArray[i]) and (abs(sTrackBar1.Position - ArrowArray[i]) < 3) then begin
        sTrackBar1.Position := ArrowArray[i];
        Break
      end;

    if Assigned(PopupScalingAlphaHints) then
    begin
      PopupScalingAlphaHints.Animated := False;
      PopupScalingAlphaHints.DefaultMousePos := mpLeftBottom;
    end;
  end;
end;


procedure TFormPopupScaling.sTrackBar1UserChanged(Sender: TObject);
begin
  // Hiding of popup window
  ClosePopup;
  if DataModule1.sSkinManager1.Options.ScaleMode <> smCustomPPI then begin
    DataModule1.sSkinManager1.Options.PixelsPerInch := GetPPI(PopupScalingSkinData);
    DataModule1.sSkinManager1.Options.ScaleMode := smCustomPPI;
    Application.ProcessMessages;
  end;
  MakeSelected(sSpeedButton1, False);
  MakeSelected(sSpeedButton3, True);
  if Assigned(PopupScalingSpeedBtnPPI) then
    PopupScalingSpeedBtnPPI.Caption := TrText('Custom PPI: ') + IntToStr(sTrackBar1.Position);
  sSpeedButton3.Caption := TrText('Custom PixelsPerInch value') + ': ' + IntToStr(sTrackBar1.Position);
  if PopupScalingAppAnimated then
    SetPPIAnimated(sTrackBar1.Position)
  else
    DataModule1.sSkinManager1.Options.PixelsPerInch := sTrackBar1.Position;
  if Assigned(PopupScalingCaptionChanged) then
    PopupScalingCaptionChanged(Self);
end;

end.
