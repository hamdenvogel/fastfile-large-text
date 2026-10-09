unit UnFormAboutFF;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, ShellAPI,
  sSkinProvider, sPanel, sLabel, sButton, sMemo, acImage, acPNG;

type
  TfrmAboutFF = class(TForm)
    sSkinProvider1: TsSkinProvider;
    pnlTop: TsPanel;
    imgLogo: TsImage;
    pnlLogoText: TsPanel;
    lblAppName: TsLabel;
    lblVersion: TsLabel;
    lblBuildTime: TsLabel;
    lblDevelopedBy: TsLabel;
    lblHome: TsLabel;
    lblHomeURL: TsLabel;
    pnlGNU: TsPanel;
    lblGNUTitle: TsLabel;
    memoLicense: TsMemo;
    pnlBottom: TsPanel;
    btnOK: TsButton;
    procedure FormCreate(Sender: TObject);
    procedure lblHomeURLClick(Sender: TObject);
    procedure lblHomeURLMouseEnter(Sender: TObject);
    procedure lblHomeURLMouseLeave(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    procedure LoadLogo;
  public
  end;

implementation

uses UnUtils, uI18n, UnConsts;

{$R *.dfm}

procedure TfrmAboutFF.LoadLogo;
var
  PNGPath: string;
begin
  { acPNG in uses already registers PNG in Delphi's picture registry,
    so Picture.LoadFromFile works for .png files without a separate class. }
  PNGPath := ExtractFilePath(Application.ExeName) + ICON_HELP_PNG;
  if not FileExists(PNGPath) then
    PNGPath := ExtractFilePath(ParamStr(0)) + ICON_HELP_PNG;
  if FileExists(PNGPath) then
    imgLogo.Picture.LoadFromFile(PNGPath);
end;

procedure TfrmAboutFF.FormCreate(Sender: TObject);
var
  BtnCopy, BtnExport: TButton;
  TotalW, StartX, BtnTop: Integer;
begin
  { TsSkinProvider picks up the active skin automatically from TsSkinManager in DataModule1. }
  Caption := Tr('toolbar.about_fastfile', 'About FastFile');
  lblAppName.Caption  := APPLICATION_DISPLAY_NAME;
  lblVersion.Caption  := UnUtils.GetDisplayVersion(True);
  lblBuildTime.Caption := TrText('Build time: ') + FormatDateTime('dd/mm/yyyy - hh:nn:ss', Now);
  lblDevelopedBy.Caption := TrText('Developed by: ') + 'Hamden Vogel';
  lblHome.Caption := TrText('Contact email:');
  lblHomeURL.Caption := 'hamdenvogel@gmail.com';
  lblBuildTime.AutoSize := True;
  lblDevelopedBy.AutoSize := True;
  lblHome.AutoSize := True;
  lblHomeURL.Left := lblHome.Left + lblHome.Width + 8;

  memoLicense.Lines.Clear;
  memoLicense.Lines.Add(APPLICATION_DEVELOPER);
  memoLicense.Lines.Add('');
  memoLicense.Lines.Add('This program is free software; you can redistribute it and/or');
  memoLicense.Lines.Add('modify it under the terms of the GNU General Public License as');
  memoLicense.Lines.Add('published by the Free Software Foundation; either version 3 of');
  memoLicense.Lines.Add('the License, or at your option any later version.');
  memoLicense.Lines.Add('');
  memoLicense.Lines.Add('This program is distributed in the hope that it will be useful,');
  memoLicense.Lines.Add('but WITHOUT ANY WARRANTY; without even the implied warranty of');
  memoLicense.Lines.Add('MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the');
  memoLicense.Lines.Add('GNU General Public License for more details.');
  memoLicense.Lines.Add('');
  memoLicense.Lines.Add('You should have received a copy of the GNU General Public License');
  memoLicense.Lines.Add('along with this program. If not, see <https://www.gnu.org/licenses/>.');

  LoadLogo;

  { Add Copy and Export buttons to pnlBottom alongside the existing OK/Close button }
  btnOK.Caption := TrText('Close');
  TotalW  := 90 * 3 + 16;
  StartX  := (pnlBottom.ClientWidth - TotalW) div 2;
  BtnTop  := (pnlBottom.ClientHeight - 26) div 2;
  if BtnTop < 4 then BtnTop := 4;

  KeyPreview := True;
  OnKeyDown  := FormKeyDown;

  BtnCopy := TButton.Create(Self);
  BtnCopy.Parent := pnlBottom;
  BtnCopy.Caption := TrText('&Copy');
  BtnCopy.Width := 90;
  BtnCopy.Height := 26;
  BtnCopy.Left := StartX;
  BtnCopy.Top  := BtnTop;
  BtnCopy.ModalResult := mrYes;

  BtnExport := TButton.Create(Self);
  BtnExport.Parent := pnlBottom;
  BtnExport.Caption := TrText('&Export...');
  BtnExport.Width := 90;
  BtnExport.Height := 26;
  BtnExport.Left := StartX + 98;
  BtnExport.Top  := BtnTop;
  BtnExport.ModalResult := mrRetry;

  btnOK.Width := 90;
  btnOK.Left  := StartX + 196;
  btnOK.Top   := BtnTop;
end;

procedure TfrmAboutFF.lblHomeURLClick(Sender: TObject);
begin
  ShellExecute(Handle, 'open', 'mailto:hamdenvogel@gmail.com', nil, nil, SW_SHOWNORMAL);
end;

procedure TfrmAboutFF.lblHomeURLMouseEnter(Sender: TObject);
begin
  lblHomeURL.Font.Style := lblHomeURL.Font.Style + [fsUnderline];
end;

procedure TfrmAboutFF.lblHomeURLMouseLeave(Sender: TObject);
begin
  lblHomeURL.Font.Style := lblHomeURL.Font.Style - [fsUnderline];
end;

procedure TfrmAboutFF.btnOKClick(Sender: TObject);
begin
  ModalResult := mrOk;
end;

procedure TfrmAboutFF.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_ESCAPE then ModalResult := mrCancel;
end;

end.
