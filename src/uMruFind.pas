unit uMruFind;
{ Shared MRU dropdown helpers: partial find + special combo tags (More / Find). }

interface

uses
  SysUtils, uI18n;

const
  MRU_OBJ_MORE = -1;
  MRU_OBJ_FIND = -2;
  MRU_OBJ_NONE = -3;
  MRU_OBJ_CLEAR_ALL = -4;
  MRU_FIND_BTN_W = 24;
  MRU_FIND_EDIT_MIN_W = 88;

function MruTextMatches(const AItem, ANeedle: string): Boolean;
function MruFindItemCaption: string;
function MruFindNoMatchCaption: string;
function MruMoreCaption(const AKey: string): string;
function MruClearAllCaption: string;

implementation

function MruTextMatches(const AItem, ANeedle: string): Boolean;
var
  Needle, Hay: string;
begin
  Needle := AnsiLowerCase(Trim(ANeedle));
  if Needle = '' then
  begin
    Result := True;
    Exit;
  end;
  Hay := AnsiLowerCase(AItem);
  Result := Pos(Needle, Hay) > 0;
end;

function MruFindItemCaption: string;
begin
  Result := Trim(TrText('MRU.Find'));
  if Result = '' then
    Result := 'Find...';
end;

function MruFindNoMatchCaption: string;
begin
  Result := Trim(TrText('MRU.FindNoMatch'));
  if Result = '' then
    Result := '(no matches)';
end;

function MruMoreCaption(const AKey: string): string;
begin
  Result := Trim(TrText(AKey));
  if Result = '' then
    Result := '...';
end;

function MruClearAllCaption: string;
begin
  Result := Trim(TrText('MRU.ClearAll'));
  if Result = '' then
    Result := 'Delete all entries';
end;

end.
