unit UnConsumerDialog;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, UnConsumerAI, uI18n;

type
  // ---------------------------------------------------------------------------
  // TFormConsumerInput
  // Formulário Modal simplificado (apenas confirmação do caminho)
  // ---------------------------------------------------------------------------
  TFormConsumerInput = class(TForm)
  private
    LblPath: TLabel;
    EdtPath: TEdit;
    BtnOk: TBitBtn;
    BtnCancel: TBitBtn;
  public
    constructor Create(AOwner: TComponent); override;
    procedure SetupData(AConsumer: TConsumerAI);
    procedure GetData(AConsumer: TConsumerAI);
  end;

  // ---------------------------------------------------------------------------
  // TConsumerUIHelper
  // Gerencia a criação do objeto e exibição da interface
  // ---------------------------------------------------------------------------
  TConsumerUIHelper = class
  public
    class function RequestInputAndExecute(const AFileName: string; const HiddenDeployPath: String): Boolean;
  end;

implementation

{ TConsumerUIHelper }

class function TConsumerUIHelper.RequestInputAndExecute(const AFileName: string; const HiddenDeployPath: String): Boolean;
var
  inputForm: TFormConsumerInput;
  consumer: TConsumerAI;
begin
  Result := False;
  inputForm := TFormConsumerInput.Create(nil);
  consumer := TConsumerAI.Create;
  try
    consumer.FileNamePath := AFileName;
    consumer.PathToDeploy := HiddenDeployPath;
    
    inputForm.SetupData(consumer);
    
    if inputForm.ShowModal = mrOk then
    begin
      inputForm.GetData(consumer);
      Result := consumer.Process;
    end;
  finally
    FreeAndNil(inputForm);
    FreeAndNil(consumer);
  end;
end;

{ TFormConsumerInput }

constructor TFormConsumerInput.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  
  self.Caption := TrText('Confirm AI processing');
  self.Position := poScreenCenter;
  self.BorderStyle := bsDialog;
  self.ClientWidth := 400;
  self.ClientHeight := 120; // Reduzido pois removemos campos

  LblPath := TLabel.Create(self);
  LblPath.Parent := self;
  LblPath.Left := 20; LblPath.Top := 15;
  LblPath.Caption := TrText('File path:');

  EdtPath := TEdit.Create(self);
  EdtPath.Parent := self;
  EdtPath.Left := 20; EdtPath.Top := 30;
  EdtPath.Width := 360;

  BtnOk := TBitBtn.Create(self);
  BtnOk.Parent := self;
  BtnOk.Left := 210; BtnOk.Top := 75;
  BtnOk.Kind := bkOK;
  BtnOk.Caption := TrText('Run');

  BtnCancel := TBitBtn.Create(self);
  BtnCancel.Parent := self;
  BtnCancel.Left := 300; BtnCancel.Top := 75;
  BtnCancel.Kind := bkCancel;
  BtnCancel.Caption := TrText('Cancel');
end;

procedure TFormConsumerInput.SetupData(AConsumer: TConsumerAI);
begin
  EdtPath.Text := AConsumer.FileNamePath;
end;

procedure TFormConsumerInput.GetData(AConsumer: TConsumerAI);
begin
  AConsumer.FileNamePath := EdtPath.Text;
end;

end.
