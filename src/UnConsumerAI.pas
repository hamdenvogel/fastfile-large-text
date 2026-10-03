unit UnConsumerAI;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, UnConsts, clipbrd;

type
  // ---------------------------------------------------------------------------
  // TConsumerAI Class
  // Encapsula a l˜gica de prepara˜˜o de par˜metros e execu˜˜o da ferramenta
  // ---------------------------------------------------------------------------
  TConsumerAI = class
  private
    FFileNamePath: String;
    FPathToDeploy: String;
    procedure SetFileNamePath(const Value: String);
    procedure SetPathToDeploy(const Value: String);
    function ExecuteWithoutFreezing(const Command: string): Boolean;
  public
    property FileNamePath: String read FFileNamePath write SetFileNamePath;
    property PathToDeploy: String read FPathToDeploy write SetPathToDeploy;
    
    // M˜todo principal que monta a string: ConsumerAI.exe -file "ARQUIVO" -rp -prompt
    function Process: Boolean;
  end;

implementation

uses
  uI18n, uFastFileMsgDlg;

procedure ShowAppMessage(const Msg: string);
begin
  FastFileMsgInfo(TrText(Msg));
end;

{ TConsumerAI }

procedure TConsumerAI.SetFileNamePath(const Value: String);
begin
  if FFileNamePath <> Value then
    FFileNamePath := Value;
end;

procedure TConsumerAI.SetPathToDeploy(const Value: String);
begin
  if FPathToDeploy <> Value then
    FPathToDeploy := System.SysUtils.ExcludeTrailingBackslash(Value);
end;

function TConsumerAI.ExecuteWithoutFreezing(const Command: string): Boolean;
var
  SI: TStartupInfo;
  PI: TProcessInformation;
  CommandPChar: array[0..4096] of Char; 
  ExitCode: Cardinal; 
begin
  Result := False;
  FillChar(SI, SizeOf(SI), 0);
  SI.cb := SizeOf(SI);
  SI.dwFlags := STARTF_USESHOWWINDOW;
  SI.wShowWindow := SW_HIDE; 

  StrPLCopy(CommandPChar, Command, SizeOf(CommandPChar) - 1);

  if CreateProcess(nil, CommandPChar, nil, nil, False, 0, nil, nil, SI, PI) then
  begin
    try
      repeat
        Application.ProcessMessages;
        Sleep(50);
        GetExitCodeProcess(PI.hProcess, ExitCode);
      until ExitCode <> STILL_ACTIVE;
      Result := True;
    finally
      CloseHandle(PI.hProcess);
      CloseHandle(PI.hThread);
    end;
  end
  else
    ShowAppMessage('Error: ' + SysErrorMessage(GetLastError));
end;

function TConsumerAI.Process: Boolean;
var
  ExePath, Parameters, FullCommand: String;
begin
  Result := False;  
  // Localiza o execut˜vel na mesma pasta da aplica˜˜o Delphi
  ExePath := ExtractFilePath(Application.ExeName) + CONSUMERAI;

  if not FileExists(ExePath) then
  begin
    ShowAppMessage('Executable not found: ' + ExePath);
    Exit;
  end;
  
  // Montagem da string conforme solicitado: -file "ARQUIVO" -rp -prompt
  Parameters := Format('-file "%s" -rp -prompt', [FFileNamePath]);

  FullCommand := Format('"%s" %s', [ExePath, Parameters]);
  
  // Copia para o clipboard para confer˜ncia do comando gerado
  Clipboard.AsText := FullCommand;
  
  Result := ExecuteWithoutFreezing(FullCommand);
end;

end.
