unit unSplitView;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, sBitBtn, acPNG, ExtCtrls, acImage, sLabel,
  sMemo, sGroupBox, sPanel;

type
  TfrmSplitView = class(TForm)
    About: TsSplitView;
    sPanel4: TsGradientPanel;
    sPanel7: TsPanel;
    lblAboutTopLeft: TsLabel;
    lblUsefulLinksName: TsLabel;
    sWebLabel3: TsWebLabel;
    sWebLabel4: TsWebLabel;
    sGroupBox3: TsGroupBox;
    memoLicense: TsMemo;
    sGroupBox1: TsGroupBox;
    sWebLabel2: TsLabel;
    sLabel1: TsLabel;
    sPanel9: TsPanel;
    pnlAboutTop: TsPanel;
    sLabel33: TsLabel;
    sLabelFX1: TsLabelFX;
    sLabel32: TsLabel;
    sWebLabel1: TsWebLabel;
    pnlLogo: TsPanel;
    sImage2: TsImage;
    pnlLogoLeft: TsPanel;
    sPanel11: TsPanel;
    sBitBtn1: TsBitBtn;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmSplitView: TfrmSplitView;

implementation

{$R *.dfm}

end.
