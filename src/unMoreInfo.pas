unit unMoreInfo;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, sSkinProvider, acPNG, ExtCtrls, acImage, sPanel, StdCtrls,
  sMemo, sGroupBox, sLabel, Buttons, sBitBtn, ClipBrd, sButton;

type
  TfrmMoreInfo = class(TForm)
    sSkinProvider1: TsSkinProvider;
    pnlLogo: TsPanel;
    pnlInfo: TsPanel;
    gbxInfo: TsGroupBox;
    memoInfo: TsMemo;
    sLabelFX1: TsLabelFX;
    pnlContactAuthor: TsPanel;
    btnContactAuthor: TsBitBtn;
    lblLicense: TsLabel;
    sGroupBox3: TsGroupBox;
    memoLicense: TsMemo;
    sImage1: TsImage;
    sLabel1: TsLabel;
    btnClose: TsButton;
    procedure FormCreate(Sender: TObject);
    procedure btnContactAuthorClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmMoreInfo: TfrmMoreInfo;

implementation

uses UnDM, UnUtils;

{$R *.dfm}

procedure TfrmMoreInfo.FormCreate(Sender: TObject);
begin
  memoInfo.Clear;
  with memoInfo.Lines do
  begin
    Add('Support');
    Add('Please send an email to the developer software ');
    Add('(below - just select and copythe following line below):');
    Add('');
    Add('hamdenvogel@gmail.com');
  end;
end;

procedure TfrmMoreInfo.btnContactAuthorClick(Sender: TObject);
begin
  Clipboard.AsText := 'hamdenvogel@gmail.com';
  UnUtils.MessageBox('Information','Email of the author was copied to the clipboard, please paste it from CRLT + V command and send an email from it');
end;

procedure TfrmMoreInfo.btnCloseClick(Sender: TObject);
begin
  Self.Close;
end;

end.
