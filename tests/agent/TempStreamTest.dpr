program TempStreamTest;

{$APPTYPE CONSOLE}

uses
  Windows, SysUtils, Classes, uTemporaryFileStream, UnBufferedTextWriter;

var
  T: TTemporaryFileStream;
  Wr: TBufferedTextWriter;
  TempPath, Target: string;
  Fails: Integer;

procedure Check(const ACond: Boolean; const AName: string);
begin
  if ACond then Writeln('ok   ', AName)
  else begin Writeln('FAIL ', AName); Inc(Fails); end;
end;

begin
  Fails := 0;
  Target := ExtractFilePath(ParamStr(0)) + 'tempstream_target.txt';
  DeleteFile(Target);

  T := TTemporaryFileStream.CreateForIndex('tstcommit');
  TempPath := T.FilePath;
  Wr := TBufferedTextWriter.CreateFromHandle(T.Handle, 4096);
  Wr.WriteOffsetDirect(1);
  Wr.WriteOffsetDirect(42);
  Wr.Free;
  T.DeleteFileOnDestroy := False;
  T.Free;
  Check(FileExists(TempPath), 'kept after Free');
  Check(RenameFile(TempPath, Target), 'rename after Free');
  Check(FileExists(Target) and not FileExists(TempPath), 'moved');
  with TFileStream.Create(Target, fmOpenRead) do
  try
    Check(Size = 40, 'two 20-byte records');
  finally
    Free;
  end;
  DeleteFile(Target);

  T := TTemporaryFileStream.CreateForIndex('tstdiscard');
  TempPath := T.FilePath;
  T.Free;
  Check(not FileExists(TempPath), 'deleted on Free');

  Writeln('fails=', Fails);
  ExitCode := Fails;
end.
