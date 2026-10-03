procedure TMainForm.exportToFile;
var
  textFileStream: TTextFileStream;
  indx: integer;
  iLine: int64;
  fullPathFile: string;
  Param: String;
  objLineIndexes: TInt64List;
  strCurrentLine: string;
  fileSize: Int64;
  CheckVar: Boolean;
  strLst: TStringList;
begin
  objLineIndexes := getDataFromListViewToExport;
  //if not existsCheckedRows(objLineIndexes) then Exit;
  if not existsCheckedRows(objLineIndexes) then
  begin
    if not isChecked then ActionCheckBoxesListView.Execute;
    Exit;
  end;
  fileSize := UnUtils.GetFileSize(sFileName.Text);
  if (fileSize > 52428800) and (isAllChecked) then //more than 50MB
    if MessageDlgCustom('The file contains more than 50MB. It may crash the application. Confirm?', mtConfirmation,
      [mbYes,mbNo],
      ['&Yes, Confirmed.',
      '&No, Abort this operation.'],
      CheckVar, False, nil)//nil = no custom font
      = mrNo then Exit;

  strCurrentLine := '';
  fullPathFile := Format('%s\%s', [GetTmpDir, 'export.txt']); { see EXPORT_DEFAULT_FILENAME in UnConsts.pas }
  if isAllChecked then
  begin
    strLst := TStringList.Create;
    try
      try
        strLst.LoadFromFile(sFileName.Text);
        UnUtils.SaveTextToFile(fullPathFile, strLst.Text);
        UnUtils.MessageBox('Information', Format('Exported to %s', [fullPathFile]));
        Param := Format('/n,/select,"%s"', [fullPathFile]);
        ShellExecute(0, 'Open', 'explorer.exe', PChar(Param), nil, SW_NORMAL);
      except on E: Exception do
        UnUtils.MessageBox('Error', E.Message);
      end;  
    finally
      FreeAndNil(strLst);
    end;
  end
  else
  begin
    textFileStream := TTextFileStream.Create(fullPathFile, fmOpenWrite or fmCreate);
    try
      try
       for indx := 0 to objLineIndexes.Count - 1 do
        begin
          iLine := objLineIndexes.items[indx];
          if LineExists(iLine) then
          begin
            if (iLine > 1) then
            begin
              strCurrentLine := getLineFromOffSet(StrToInt64Def(textFile.GetLineContent(iLine),1));
              if not AnsiEndsStr(#13#10, strCurrentLine) then
                strCurrentLine := strCurrentLine + #13#10;
              textFileStream.WriteLn(strCurrentLine, False);
            end;
          end;
        end;
      except on E: Exception do
        UnUtils.MessageBox('Error', E.Message);
      end;
      UnUtils.MessageBox('Information', Format('Exported to %s', [fullPathFile]));
      try
        Param := Format('/n,/select,"%s"', [fullPathFile]);
        ShellExecute(0, 'Open', 'explorer.exe', PChar(Param), nil, SW_NORMAL);
      except on E: Exception do
        UnUtils.MessageBox('Error', E.Message);
      end;
    finally
      FreeAndNil(textFileStream);
    end;
  end;
end;