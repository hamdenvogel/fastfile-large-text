unit uFindReplace;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls;

type
  TFindReplaceAction = (fraFindNext, fraReplace, fraReplaceAll, fraClosed);

  TfrmFindReplace = class(TForm)
    lblFind: TLabel;
    lblReplace: TLabel;
    edtFind: TEdit;
    edtReplace: TEdit;
    chkCaseSensitive: TCheckBox;
    chkWholeWord: TCheckBox;
    btnFindNext: TButton;
    btnReplace: TButton;
    btnReplaceAll: TButton;
    btnClose: TButton;
    Bevel1: TBevel;
    lblStatus: TLabel;
    procedure btnFindNextClick(Sender: TObject);
    procedure btnReplaceClick(Sender: TObject);
    procedure btnReplaceAllClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    FAction: TFindReplaceAction;
  public
    property Action: TFindReplaceAction read FAction;

    function GetFindText: string;
    function GetReplaceText: string;
    function GetCaseSensitive: boolean;
    function GetWholeWord: boolean;

    procedure SetStatus(const S: string);
    procedure SetReplaceEnabled(const AEnabled: Boolean);
  end;

var
  frmFindReplace: TfrmFindReplace;

implementation

uses
  uI18n;

{$R *.dfm}

function TfrmFindReplace.GetFindText: string;
begin
  Result := edtFind.Text;
end;

function TfrmFindReplace.GetReplaceText: string;
begin
  Result := edtReplace.Text;
end;

function TfrmFindReplace.GetCaseSensitive: boolean;
begin
  Result := chkCaseSensitive.Checked;
end;

function TfrmFindReplace.GetWholeWord: boolean;
begin
  Result := chkWholeWord.Checked;
end;

procedure TfrmFindReplace.SetStatus(const S: string);
begin
  lblStatus.Caption := TrText(S);
end;

procedure TfrmFindReplace.SetReplaceEnabled(const AEnabled: Boolean);
begin
  btnReplace.Enabled := AEnabled;
  btnReplaceAll.Enabled := AEnabled;
  if not AEnabled then
    edtReplace.Color := clBtnFace
  else
    edtReplace.Color := clWindow;
end;

procedure TfrmFindReplace.btnFindNextClick(Sender: TObject);
begin
  if Trim(edtFind.Text) = '' then
  begin
    SetStatus('Enter search text.');
    Exit;
  end;
  FAction := fraFindNext;
  ModalResult := mrOk;
end;

procedure TfrmFindReplace.btnReplaceClick(Sender: TObject);
begin
  if not btnReplace.Enabled then
  begin
    SetStatus('Read-only session is enabled. Turn it off in Options to edit or save the file.');
    Exit;
  end;
  if Trim(edtFind.Text) = '' then
  begin
    SetStatus('Enter search text.');
    Exit;
  end;
  FAction := fraReplace;
  ModalResult := mrOk;
end;

procedure TfrmFindReplace.btnReplaceAllClick(Sender: TObject);
begin
  if not btnReplaceAll.Enabled then
  begin
    SetStatus('Read-only session is enabled. Turn it off in Options to edit or save the file.');
    Exit;
  end;
  if Trim(edtFind.Text) = '' then
  begin
    SetStatus('Enter search text.');
    Exit;
  end;
  FAction := fraReplaceAll;
  ModalResult := mrOk;
end;

procedure TfrmFindReplace.btnCloseClick(Sender: TObject);
begin
  FAction := fraClosed;
  ModalResult := mrCancel;
end;

procedure TfrmFindReplace.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
  begin
    FAction := fraClosed;
    ModalResult := mrCancel;
  end;
end;

end.
