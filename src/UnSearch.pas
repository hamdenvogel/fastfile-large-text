unit UnSearch;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, 
  Dialogs, StdCtrls, Mask, sMaskEdit, sCustomComboEdit, sComboEdit,
  sListBox, sLabel, sGroupBox, sFrameAdapter;

type
  TfrmSearch = class(TFrame)
    sGroupBox2: TsGroupBox;
    sLabel3: TsLabel;
    sListBox1: TsListBox;
    edtGoToLine: TsComboEdit;
    edtSearch: TsComboEdit;
    sFrameAdapter1: TsFrameAdapter;
    procedure sListBox1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

uses MainUnit, uI18n, uFastFileMsgDlg;

procedure ShowAppMessage(const Msg: string);
begin
  FastFileMsgInfo(TrText(Msg));
end;

{$R *.dfm}

procedure TfrmSearch.sListBox1Click(Sender: TObject);
var
  numberLine: int64;
begin
  numberLine := integer(sListBox1.Items.Objects[sListBox1.ItemIndex]);
  ShowAppMessage(IntToStr(numberLine));
end;

end.
