//------------------------------------------------------------------------------------
// Модуль часто используемых функций.
// Написано SimBa aka Dimonius http://www.dimonius.ru/
// Разрешается свободное использование и распространение с сохранением копирайтов
// ver. 2.2,  27.07.2007
//------------------------------------------------------------------------------------

unit SimUtils;

interface

uses Windows, SysUtils, Classes;

//Text functions
//Кол-во вхождений подстроки в строку
function PosNum(const SubStr, S: AnsiString; seFr: LongInt=0; seTo: LongInt = MaxInt): LongInt;
//Поиск с любой позиции
function PosEx(const SubStr, S: AnsiString; Offset: LongInt = 1): LongInt;
//Поиск в обратном направлении
function PosBack(const SubStr, S: AnsiString; const Offset: LongInt = MaxInt): LongInt;
//Замена текста (НЕрегистрозависимая)
function repl(const str: AnsiString; find: AnsiString; const replace: AnsiString): AnsiString;
//LastDelimiter только вперед
function FindChars(const chars, s: AnsiString): Integer;
//Делит строку, разбивая ее по разделителю и записывает в ResArr. если ResArr меньше нужного - все записывается в последний элемент
procedure Split(const s: AnsiString; var ResArr: array of AnsiString; const separator: Char);
//Сохранение строки
procedure SaveString(const fn, s: AnsiString);
//Загрузка строки
function LoadString(const fn: AnsiString): AnsiString;
//Перевод из 7ми битных кодировок в Windows (%FA%DD и тд)
function SevBit2Win(const mm: AnsiString): AnsiString;
//Выясняет текст в кодировке UTF или нет
function isUTF(const s: AnsiString): Boolean;
//Перевод из UTF в Win
function UTF2Win(const mm: AnsiString): AnsiString;
//Декодирует Base64
function DecodeBase64(const CinLine: AnsiString): AnsiString;
//Оставляет в строке только цифры
function OnlyNums(const s: AnsiString): AnsiString;
//Оставляет в строке только разрешенные символы
function OnlyNeedChars(const s, chars: AnsiString): AnsiString;
//Удалят из строки указанные символы
function DeleteChars(const s, chars: AnsiString): AnsiString;
//Делает строку из символов
function Sim(const c: Char; const n: Integer): AnsiString;
//Убирает с начала и с конца строки кавычки, если они есть
function StripQuote(const s: AnsiString; const quote: Char='"'): AnsiString;
//Выводит число с апострафами
function FormatNum(const s: AnsiString; const apos: AnsiString=''''): AnsiString;
//Удаляет теги из строки
function StripTags(const s: AnsiString; const ReplTag: String=''): AnsiString;
//Удаляет двойные пробелы
function StripDoubleSpaces(const s: AnsiString): AnsiString;

//Misc
//Неблокирующий Sleep
procedure SleepH(const MSec: Cardinal);
//Запуск с ожиданием завершения проги
function RunAndWait(const cmd: AnsiString; const ShowWin: Word=STARTF_USESHOWWINDOW; const Timeout: Cardinal=INFINITE): Integer;
//Получения размера файла в байтах
function GetFileSize(const FileName: string): Int64;
//Преобразования Hex строки в число
function Hex2Dec(const S: string): Longint;
//Копия преобразования в Rect
function Rect(ALeft, ATop, ARight, ABottom: Integer): TRect;
//Проверяет имя на совпадение, и если что добавляет цифру в конце
function GetUniName(const name: AnsiString): AnsiString;
//Проверяет имя файла на правильность, удаляет запрещенные символы
function NormalName(const FileName: AnsiString): AnsiString;
//Проверяет путь к файлу на правильность, удаляет запрещенные символы и пробелы
function NormalPathName(const Path: AnsiString): AnsiString;
//Проверяет есть ли слеш в конце директории и если нет - доавбляет
function SlashDir(const Path: AnsiString): AnsiString;

//Inet
//Парсинг полей для отправки через POST
function parceForm(s: AnsiString; var url: AnsiString; const ReplaceParams: Boolean=True): AnsiString;
//удаляет параметр из POST запроса
function DelPostParam(const s, Name: AnsiString): AnsiString;
//Выясняет адрес сервера из текущего адреса
function GetServerName(const url: AnsiString): AnsiString;
//Выделяет нужный параметр из строки
function GetUrlParam(const s, name: AnsiString; const delim: Char = '&'): AnsiString;

//Math
function Min(const a, b: Integer): Integer; overload;
function Min(const a, b: Int64): Int64; overload;
function Max(const a, b: Integer): Integer; overload;
function Max(const a, b: Int64): Int64; overload;
function CheckMinMax(const val, min, max: Integer): Integer;


// added 11.08.11
function UrlEncode(Str: string): string;
function UrlDecode(Str: string): string;

implementation

{Text}
function PosNum(const SubStr, S: AnsiString; seFr: LongInt=0; seTo: LongInt = MaxInt): LongInt;
var c1,c2: Char;
    i,n: Integer;
begin
  Result:=0;
  if (seFr>seTo) then begin
    i:=seFr;
    seFr:=seTo;
    seTo:=i;
  end;

  i:=SeTo;
  n:=length(SubStr);
  if (length(s)=0) or (n=0) or (n>length(s)) then exit;
  if (i>length(s)) then i:=length(s);
  dec(i, n-1);
  if i<1 then exit;

  c1:=AnsiLowerCase(SubStr[1])[1];
  c2:=AnsiUpperCase(c1)[1];
  dec(n);

  while (i>0) and (i>=seFr) do begin
    if ((c1=s[i]) or (c2=s[i])) and ((n=0) or (StrLIComp(@SubStr[2], @s[i+1], n)=0)) then begin
      inc(Result);
      dec(i, n);
    end;
    dec(i);
  end;
end;

function PosBack(const SubStr, S: AnsiString;const Offset: LongInt = MaxInt): LongInt;
var c1,c2: Char;
    i,n: Integer;
begin
  Result:=0;
  i:=Offset;
  n:=length(SubStr);
  if (length(s)=0) or (n=0) or (n>length(s)) then exit;
  if (i>length(s)) then i:=length(s);
  dec(i,length(SubStr));
  if i<1 then exit;

  c1:=AnsiLowerCase(SubStr[1])[1];
  c2:=AnsiUpperCase(c1)[1];
  dec(n);

  while i>0 do begin
    if ((c1=s[i]) or (c2=s[i])) and (StrLIComp(@SubStr[2],@s[i+1],n)=0) then begin
      Result:=i;
      exit;
    end;
    dec(i);
  end;
end;

function PosEx(const SubStr, S: AnsiString; Offset: LongInt = 1): LongInt;
asm
  PUSH    ESI
  PUSH    EDI
  PUSH    EBX
  TEST    &SubStr, &SubStr
  JE      @Exit
  TEST    &S, &S
  JE      @Exit0
  TEST    &Offset, &Offset
  JG      @POff
  MOV     &Offset, 1
  @POff:
  MOV     ESI, &SubStr
  MOV     EDI, &S
  PUSH    EDI
  MOV     EAX, &Offset
  DEC     EAX
  MOV     ECX, [EDI - 4]
  MOV     EDX, [ESI - 4]
  DEC     EDX
  JS      @Fail
  SUB     ECX, EAX
  ADD     EDI, EAX
  MOV     AL, [ESI]
  INC     ESI
  SUB     ECX, EDX
  JLE     @Fail

  @Loop:
  REPNE   SCASB
  JNE     @Fail
  MOV     EBX, ECX
  PUSH    ESI
  PUSH    EDI
  MOV     ECX, EDX
  REPE    CMPSB
  POP     EDI
  POP     ESI
  JE      @Found
  MOV     ECX, EBX
  JMP     @Loop

  @Fail:
  POP     EDX

  @Exit0:
  XOR     EAX, EAX
  JMP     @Exit

  @Found:
  POP     EDX
  MOV     EAX, EDI
  SUB     EAX, EDX

  @Exit:
  POP     EBX
  POP     EDI
  POP     ESI
end;

function repl(const str: AnsiString; find: AnsiString; const replace: AnsiString): AnsiString;
var i,i2: Integer;
    n,n2: Integer;
    o   : Boolean;
    c3  : AnsiString;

  function eq(const n: Integer): Boolean;
  var i: Integer;
  begin
    Result:=True;
    if length(find)=1 then exit;
    //Чтобы не вылететь за пределы строки
    //Если мы дошли до конца строки, и не
    //влезает поисковая строка, то выходим
    if length(find)>length(str)-n then begin
      Result:=False;
      exit;
    end;
    for i:=1 to length(find) do begin
      if (find[i]<>str[i+n]) and (c3[i]<>str[i+n]) then begin
        Result:=False;
        break;
      end;
    end;
  end;

begin
  o:=length(replace)>length(find);
  if not o then
    SetLength(Result, length(str))
  else
    SetLength(Result, length(str)*2);

  i2:=1;
  i:=1;
  n2:=length(Result);
  c3:=AnsiUpperCase(find);
  while i<=length(str) do begin
    if not (((str[i]=find[1]) or (str[i]=c3[1])) and eq(i-1)) then begin //Ищем
      Result[i2]:=str[i];          //Если не нашли копируем символ
      inc(i2);
      if o and (i2>n2) then begin
        n2:=n2*2;
        SetLength(Result, n2);
      end;
    end else begin//Если нашли
      //Проверяем длину. Если не хватает - увеличиваем
      if o and ((n2-i2)<length(replace)) then begin
        n2:=(n2+length(replace))*2;
        SetLength(Result, n2);//минимально нужная длина * 2
      end;
      inc(i,length(find)-1); //пропускаем то, ЧТО заменяем
      //Копируем НА ЧТО заменяем
      for n:=1 to length(replace) do begin
        Result[i2]:=replace[n];
        inc(i2);
      end;
    end;
    inc(i);
  end;
  Result:=copy(Result,1,i2-1);
end;

{Misc}
procedure SleepH(const MSec: Cardinal);
var h: THandle;
begin
  if MSec=0 then exit;

  h:=CreateEvent(nil,true,false,nil);
  WaitForSingleObject(h, MSec);
  CloseHandle(h);
end;

procedure SaveString(const fn, s: AnsiString);
var f: TFileStream;
begin
  if FileExists(fn) then DeleteFile(fn);
  f:=TFileStream.Create(fn, fmOpenWrite or fmCreate or fmShareDenyWrite);
  try
    f.Write(Pointer(s)^,length(s));
  finally
    f.Free;
  end;
end;

function LoadString(const fn: AnsiString): AnsiString;
var f: TFileStream;
begin
  Result:='';
  if not FileExists(fn) then exit;
  f:=TFileStream.Create(fn, fmOpenRead or fmShareDenyNone);
  try
    SetLength(Result, f.Size);
    f.Read(Pointer(Result)^,f.Size);
  finally
    f.Free;
  end;
end;

function RunAndWait(const cmd: AnsiString; const ShowWin: Word=STARTF_USESHOWWINDOW; const Timeout: Cardinal=INFINITE): Integer;
var
  proc_info: TProcessInformation;
  startinfo: TStartupInfo;
  ExitCode: longword;
begin
  // Initialize the structures
  FillChar(proc_info, sizeof(TProcessInformation), 0);
  FillChar(startinfo, sizeof(TStartupInfo), 0);
  startinfo.cb := sizeof(TStartupInfo);

//SW_SHOWMINIMIZED;
//SW_MAXIMIZE;
//SW_HIDE;
//SW_SHOWNORMAL;
  startinfo.dwFlags:=STARTF_USESHOWWINDOW;
  startinfo.wShowWindow:=ShowWin;

  // Attempts to create the process
  if CreateProcess(nil, PChar(cmd), nil,
      nil, false, NORMAL_PRIORITY_CLASS, nil, nil,
       startinfo, proc_info) <> False then begin
    WaitForSingleObject(proc_info.hProcess, Timeout);
    GetExitCodeProcess(proc_info.hProcess, ExitCode);  // Optional
    CloseHandle(proc_info.hThread);
    CloseHandle(proc_info.hProcess);
    Result:=0;
  end else begin
    Result:=-1;
  end;
end;

function FindChars(const chars, s: AnsiString): Integer;
var i: Integer;
begin
  Result:=0;
  for i:=1 to length(s) do
    if pos(s[i], chars)>0 then begin
      Result:=i;
      exit;
    end;
end;

function parceForm(s: AnsiString; var url: AnsiString; const ReplaceParams: Boolean=True): AnsiString;
var i: Integer;
    nam,val: AnsiString;
    del: Char;
begin
  //Замена регистронезависимая.
  //Чтобы и <FORM и <form обрабатывались
  s:=repl(s, '<form', '<form');
  s:=repl(s, '</form', '</form');
  s:=repl(s, '<input', '<input');
  s:=repl(s, 'action=', 'action=');
  s:=repl(s, 'name=', 'name=');
  s:=repl(s, 'value=', 'value=');

  Result:='';
  i:=pos('<form', s);
  if i=0 then exit;
  s:=copy(s, i, MaxInt);

  i:=pos('</form', s);
  if i>0 then s:=copy(s,1,i-1);
  url:='';

  i:=Pos('action=', s);
  if i>0 then begin
    del:=copy(s,i+7,1)[1];
    if del in ['"',''''] then begin
      inc(i,8);
      url:=copy(s,i,MaxInt);
      i:=pos(del,url);
      url:=copy(url,1,i-1);
    end else begin
      inc(i,7);
      url:=copy(s,i,MaxInt);
      i:=FindChars(' >',url);
      url:=copy(url,1,i-1);
    end;
  end;

  nam:='';
  val:='';

  i:=pos('<input', s);
  while i>0 do begin
    s:=copy(s,i+6,MaxInt);

    i:=pos('name=',s);
    if i>0 then begin
      del:=copy(s,i+5,1)[1];
      if del in ['"',''''] then begin
        inc(i,6);
        nam:=copy(s,i,MaxInt);
        i:=pos(del,nam);
        nam:=copy(nam,1,i-1);
      end else begin
        inc(i,5);
        nam:=copy(s,i,MaxInt);
        i:=FindChars(' >',nam);
        nam:=copy(nam,1,i-1);
      end;
    end;

    i:=pos('value=',s);
    if pos('>',s)>i then begin
      if i>0 then begin
        del:=copy(s,i+6,1)[1];
        if del in ['"',''''] then begin
          inc(i,7);//Чтобы выбраться за пределы параметра
          val:=copy(s,i,MaxInt);
          i:=pos(del,val);
          val:=copy(val,1,i-1);
        end else begin
          inc(i,6);//Чтобы выбраться за пределы параметра
          val:=copy(s,i,MaxInt);
          i:=FindChars(' >',val);
          val:=copy(val,1,i-1);
        end;
      end;
    end else val:='';

    if nam<>'' then begin
      if ReplaceParams and (pos(nam+'=', Result)>0) then Result:=DelPostParam(Result, nam+'=');
      Result:=Result+nam+'='+val+#10;
    end;
    nam:='';
    val:='';
    i:=pos('<input',s);
  end;
  Result:=trim(Result);
end;

function DelPostParam(const s, Name: AnsiString): AnsiString;
var n,l: Integer;
begin
  Result:=#10+s+#10;
  n:=pos(AnsiLowerCase(Name), AnsiLowerCase(Result));
  if n=0 then exit;
  n:=PosBack(#10, Result, n)+1;
  l:=PosEx(#10,Result,n);
  Delete(Result,n,l-n+1);
  Result:=copy(Result,2,length(Result)-2);
end;

function Rect(ALeft, ATop, ARight, ABottom: Integer): TRect;
begin
  with Result do
  begin
    Left := ALeft;
    Top := ATop;
    Right := ARight;
    Bottom := ABottom;
  end;
end;

procedure Split(const s: AnsiString; var ResArr: array of AnsiString; const separator: Char);
var i, n, lp, k: Integer;
begin
  for i:=low(ResArr) to high(ResArr) do
    resarr[i]:='';

  n:=low(ResArr);
  lp:=1;
  k:=length(s);
  i:=1;
  while i<=k do begin
    if (s[i]=separator) or (i=k) then begin
      if (i=k) and (s[i]<>separator) then inc(i); //Чтобы не терять последний символ
      ResArr[n]:=copy(s, lp, i-lp);
      lp:=i+1;
      inc(n);
      //Если последний пункт, то выходим
      if (n>high(ResArr)) then
        exit;
    end;
    inc(i);
  end;
end;

function Min(const a, b: Integer): Integer;
begin
  if a<b then Result:=a else Result:=b;
end;

function Min(const a, b: Int64): Int64;
begin
  if a<b then Result:=a else Result:=b;
end;

function Max(const a, b: Integer): Integer;
begin
  if a>=b then Result:=a else Result:=b;
end;

function Max(const a, b: Int64): Int64;
begin
  if a>=b then Result:=a else Result:=b;
end;

function CheckMinMax(const val, min, max: Integer): Integer;
begin
  Result:=val;
  if Result>max then Result:=max;
  if Result<min then Result:=min;
end;

function Hex2Dec(const S: string): Longint;
var
  HexStr: string;
begin
  if Pos('$', S) = 0 then HexStr := '$' + S
  else HexStr := S;
  Result := StrToIntDef(HexStr, 0);
end;

function SevBit2Win(const mm: AnsiString): AnsiString;
const  HexArr = ['0'..'9','A'..'F','a'..'f'];
var i,n: Integer;
begin
  Result:='';
  if mm='' then exit;
  SetLength(Result,length(mm));
  i:=1;
  n:=1;
  repeat
    if ((mm[i]='=') or (mm[i]='%') or
       ((i>1) and (mm[i-1]='\') and (mm[i]=''''))) and
       (mm[i+1] in HexArr) and (mm[i+2] in HexArr) then begin
          if mm[i]='''' then dec(n);
          Result[n]:=chr(Hex2Dec(copy(mm,i+1,2)));
          inc(i,2);
          inc(n);
    end else begin
      //Убивает =#13 или =#10 - перенос строк закодированного текста
      if (mm[i]='=') and (i<length(mm)) and ((mm[i+1]=#10) or (mm[i+1]=#13)) then
        inc(i,2)//Перепрыгиваем пернос строки
      else begin
        if mm[i]<>'+' then
          Result[n]:=mm[i]
        else
          Result[n]:=' ';
        inc(n);
      end;
    end;
    inc(i);
  until i>length(mm);
  Result:=copy(Result,1,n-1);
end;

function isUTF(const s: AnsiString): Boolean;
const UTFchar= ['Р','С'];
var i: Integer;
begin
  Result:=False;
  if length(s)<10 then exit;

  for i:=1 to length(s)-8 do
    if (s[i] in UTFchar) and
       (s[i+2] in UTFchar) and
       (s[i+4] in UTFchar) and
       (s[i+6] in UTFchar) and
       (s[i+8] in UTFchar) then begin
         Result:=True;
         break;
      end;
end;

function UTF2WIN(const mm: AnsiString): AnsiString;
var i,n: Integer;
begin
  Result:='';
  if mm='' then exit;
  SetLength(Result,length(mm));
  i:=0;
  n:=0;
  repeat
    inc(i);
    inc(n);
    if (mm[i]=#208) then begin
      if mm[i+1]<>#129 then
        Result[n]:=chr(ord(mm[i+1])+48)
      else Result[n]:='Ё';
      inc(i);
    end else
    if (mm[i]=#209) then begin
      if mm[i+1]<>#145 then
        Result[n]:=chr(ord(mm[i+1])+112)
      else Result[n]:='ё';
      inc(i);
    end else
    if mm[i]<>#0 then Result[n]:=mm[i];
  until i>=length(mm);
  Result:=copy(Result,1,n);
end;

function DecodeBase64(const CinLine: AnsiString): AnsiString;
const
  RESULT_ERROR = -2;
var
  inLineIndex: Integer;
  c: Char;
  x: SmallInt;
  c4: Word;
  StoredC4: array[0..3] of SmallInt;
  InLineLength: Integer;
begin
  Result := '';
  inLineIndex := 1;
  c4 := 0;
  InLineLength := Length(CinLine);

  while inLineIndex <=InLineLength do
  begin
    while (inLineIndex <=InLineLength) and (c4 <4) do
    begin
      c := CinLine[inLineIndex];
      case c of
        '+'     : x := 62;
        '/'     : x := 63;
        '0'..'9': x := Ord(c) - (Ord('0')-52);
        '='     : x := -1;
        'A'..'Z': x := Ord(c) - Ord('A');
        'a'..'z': x := Ord(c) - (Ord('a')-26);
      else
        x := RESULT_ERROR;
      end;
      if x <>RESULT_ERROR then
      begin
        StoredC4[c4] := x;
        Inc(c4);
      end;
      Inc(inLineIndex);
    end;

    if c4 = 4 then
    begin
      c4 := 0;
      Result := Result + Char((StoredC4[0] shl 2) or (StoredC4[1] shr 4));
      if StoredC4[2] = -1 then Exit;
      Result := Result + Char((StoredC4[1] shl 4) or (StoredC4[2] shr 2));
      if StoredC4[3] = -1 then Exit;
      Result := Result + Char((StoredC4[2] shl 6) or (StoredC4[3]));
    end;
  end;
end;

function GetFileSize(const FileName: string): Int64;
var
  Handle: THandle;
  FindData: TWin32FindData;
begin
  Handle := FindFirstFile(PChar(FileName), FindData);
  if Handle <> INVALID_HANDLE_VALUE then begin
    Windows.FindClose(Handle);
    if (FindData.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY) = 0 then
    begin
      Int64Rec(Result).Lo := FindData.nFileSizeLow;
      Int64Rec(Result).Hi := FindData.nFileSizeHigh;
      Exit;
    end;
  end;
  Result := -1;
end;

function GetUniName(const name: AnsiString): AnsiString;
var nam, ext: AnsiString;
    n: Integer;
begin
  Result:=Name;
  if not FileExists(name) then exit;
  ext:=ExtractFileExt(name);
  nam:=copy(Name, 1, length(name)-length(ext));
  n:=1;
  while FileExists(nam+IntToStr(n)+ext) do inc(n);
  Result:=nam+IntToStr(n)+ext;
end;

function NormalName(const FileName: AnsiString): AnsiString;
var i: Integer;
    ext: AnsiString;
begin
  Result:=FileName;
  for i:=length(Result) downto 1 do begin
    if Result[i] in ['/','\',':','*','?','"','<','>','|',';','+',#0..#31] then
      delete(Result,i,1);
  end;
  if (Trim(Result)='') or (Trim(Result)='.') then Result:='NoName'+IntToStr(GetTickCount);
  ext:=ExtractFileExt(Result);
  Result:=copy(copy(Result, 1, length(Result)-length(ext)), 1, 200)+ext; //Имя файла не больше 200 символов
end;

function NormalPathName(const Path: AnsiString): AnsiString;
var i: Integer;
    Arr: Array of AnsiString;
begin
  Result:=Trim(Path);
  //Сносим запрещеные символы
  for i:=length(Result) downto 1 do begin
    if Result[i] in ['*','?','"','<','>','|',';',#0..#31] then
      delete(Result,i,1);
    if (Result[i]=':') and (i<>2) then //Если двоеточие - то только после диска может быть
      delete(Result,i,1);
    if (Result[i]='/') then Result[i]:='\';
  end;

  //Сносим пробелы на концах директорий
  i:=PosNum('\', Result);
  SetLength(Arr, i);
  Split(Result, Arr, '\');
  Result:='';
  for i:=high(Arr) downto low(Arr) do
    if (Arr[i]<>'') then Result:=trim(Arr[i])+'\'+Result;
  SetLength(Arr, 0);
end;

function SlashDir(const Path: AnsiString): AnsiString;
begin
  Result:=Trim(Path);
  if (Length(Result)>0) and (Result[length(Result)]<>'\') then Result:=Result+'\';
end;

function GetServerName(const url: AnsiString): AnsiString;
begin
  Result:=copy(url, 1, PosEx('/', url, 8)-1);
end;

function DeleteChars(const s, chars: AnsiString): AnsiString;
var i: Integer;
begin
  Result:=s;
  for i:=length(Result) downto 1 do
    if pos(Result[i], chars)>0 then delete(Result,i,1);
end;

function OnlyNeedChars(const s, chars: AnsiString): AnsiString;
var i: Integer;
begin
  Result:=s;
  for i:=length(Result) downto 1 do
    if pos(Result[i], chars)=0 then delete(Result,i,1);
end;

function OnlyNums(const s: AnsiString): AnsiString;
begin
  Result:=OnlyNeedChars(s, '0123456789');
end;

function Sim(const c: Char; const n: Integer): AnsiString;
var i: Integer;
begin
  Result:='';
  if (n<1) then exit;
  SetLength(Result, n);
  for i:=1 to length(Result) do Result[i]:=c;
end;

function StripQuote(const s: AnsiString; const quote: Char='"'): AnsiString;
begin
  Result:=s;
  if length(Result)<2 then exit;
  if (Result[1]=quote) and (Result[length(Result)]=quote) then Result:=copy(Result, 2, length(Result)-2);
end;

function GetUrlParam(const s, name: AnsiString; const delim: Char = '&'): AnsiString;
var n: Integer;
begin
  if name='' then begin
    Result:='';
    exit;
  end;
  Result:=delim+s+delim;
  n:=pos(AnsiLowerCase(delim+name+'='), AnsiLowerCase(Result));
  if n=0 then begin
    Result:='';
    exit;
  end;
  Result:=copy(Result, n+length(Name)+2, MaxInt);
  n:=pos(AnsiLowerCase(delim), AnsiLowerCase(Result));
  Result:=copy(Result, 1, n-1);
end;

function FormatNum(const s: AnsiString; const apos: AnsiString=''''): AnsiString;
var dr, int: AnsiString;
    delim  : String; 
    i: Integer;
begin
  Result:=trim(s);
  i:=FindChars('.,', Result);
  if i>0 then begin
    delim:=copy(Result, i, 1);
    dr:=trim(copy(Result, i+1, MaxInt));
    int:=trim(copy(Result, 1, i-1));
  end else begin
    delim:='';
    dr:='';
    int:=Result;
  end;

  i:=length(int)-2;
  while i>1 do begin
    Insert(apos, int, i);
    dec(i, 3);
  end;

  Result:=int+delim+dr;
end;

function StripTags(const s: AnsiString; const ReplTag: String=''): AnsiString;
var i, n, k: Integer;
    inTag: Boolean;
begin
  SetLength(Result, length(s));
  inTag:=False;
  n:=1;
  for i:=1 to length(s) do begin
    if (not inTag) and (s[i]='<') then inTag:=True;
    if (not inTag) then begin
      Result[n]:=s[i];
      inc(n);
    end;
    if (inTag) and (s[i]='>') then begin
      inTag:=False;
      for k:=1 to length(ReplTag) do begin
        Result[n]:=ReplTag[k];
        inc(n);
      end;
    end;
  end;
  Result:=copy(Result, 1, n-1);
end;

function StripDoubleSpaces(const s: AnsiString): AnsiString;
const SpaceChars=[' '];
var i, n: Integer;
    prevSpace: Boolean;
begin
  SetLength(Result, length(s));
  prevSpace:=False;
  n:=1;
  for i:=1 to length(s) do begin
    if not ((s[i] in SpaceChars) and (prevSpace)) then begin
      Result[n]:=s[i];
      inc(n);
    end;
    prevSpace:=s[i] in SpaceChars;
  end;
  Result:=copy(Result, 1, n-1);
end;


function UrlDecode(Str: string): string;
function HexToChar(W: word): Char;
asm
  cmp ah, 030h
  jl @@error
  cmp ah, 039h
  jg @@10
  sub ah, 30h
  jmp @@30
@@10:
  cmp ah, 041h
  jl @@error
  cmp ah, 046h
  jg @@20
  sub ah, 041h
  add ah, 00Ah
  jmp @@30
@@20:
  cmp ah, 061h
  jl @@error
  cmp al, 066h
  jg @@error
  sub ah, 061h
  add ah, 00Ah
@@30:
  cmp al, 030h
  jl @@error
  cmp al, 039h
  jg @@40
  sub al, 030h
  jmp @@60
@@40:
  cmp al, 041h
  jl @@error
  cmp al, 046h
  jg @@50
  sub al, 041h
  add al, 00Ah
  jmp @@60
@@50:
  cmp al, 061h
  jl @@error
  cmp al, 066h
  jg @@error
  sub al, 061h
  add al, 00Ah
@@60:
  shl al, 4
  or al, ah
  ret
@@error:
  xor al, al
end;
function GetCh(P: PChar; var Ch: Char): Char;
begin
 Ch:=P^;
 Result:=Ch;
end;
var
 P: PChar;
 Ch: Char;
begin
 Result:='';
 P:=@Str[1];
 while GetCh(P, Ch) <> #0 do begin
 case Ch of
  '+': Result:=Result+' ';
  '%': begin
  Inc(P);
  Result:=Result+HexToChar(PWord(P)^);
  Inc(P);
  end;
  else Result:=Result+Ch;
 end;
 Inc(P);
 end;
end;
function UrlEncode(Str: string): string;

function CharToHex(Ch: Char): Integer;
  asm
    and eax, 0FFh
    mov ah, al
    shr al, 4
    and ah, 00fh
    cmp al, 00ah
    jl @@10
    sub al, 00ah
    add al, 041h
    jmp @@20
@@10:
    add al, 030h
@@20:
    cmp ah, 00ah
    jl @@30
    sub ah, 00ah
    add ah, 041h
    jmp @@40
@@30:
    add ah, 030h
@@40:
    shl eax, 8
    mov al, '%'
  end;

var
  i, Len: Integer;
  Ch: Char;
  N: Integer;
  P: PChar;
begin
  Result := '';
  Len := Length(Str);
  P := PChar(@N);
  for i := 1 to Len do
  begin
    Ch := Str[i];
    if Ch in ['0'..'9', 'A'..'Z', 'a'..'z', '_'] then
      Result := Result + Ch
    else
    begin
      if Ch = ' ' then
        Result := Result + '+'
      else
      begin
        N := CharToHex(Ch);
        Result := Result + P;
      end;
    end;
  end;
end;


end.

