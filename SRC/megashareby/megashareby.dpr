library megashareby;
uses
  SysUtils,
  SimUtils in '..\LIB\SimUtils.pas',
  RegExpr in '..\LIB\Regexpr.pas';

{$E .plg}
{$R *.res}

const
  PluginName = 'Megashare.by';
  PluginVer = '1.0';
  SW_HIDE = 0;
type
  TDArray = Array of Array of Byte;
  TPicToArr = procedure (const fn: PChar; var Arr: TDArray; const Width, Height: Integer); stdcall;
  TArrToPic = procedure (const fn: PChar; var Arr: TDArray; const Width, Height: Integer); stdcall;



  // Обратная функция (через нее основная программа возвращает строки,
  // полученные в GET и POST. Чтобы точно не было проблем с памятью)
  TPlgCallBack = procedure(const AText: PChar); stdcall;
  TShowHAWindow = procedure (const fn: PChar; const DTicket: Integer; const CallBack: TPlgCallBack); stdcall;
  TGetClipboard = procedure (const CallBack: TPlgCallBack); stdcall;
  // Выполняет запрос GET
  TURLGet = procedure(const URL: PChar; const CallBack: TPlgCallBack); stdcall;
  // Выполняет запрос POST, Второй параметр - данные передаваемые в запросе
  // В формате: имя_поля1=значения_поля1 #10 имя_поля2=значения_поля2 и тд
  TURLPost = procedure(const URL, Data: PChar; const CallBack: TPlgCallBack);
    stdcall;
  TSetRetResult = procedure(const AText: PChar); stdcall;
  // Сохраняет в лог файл текст
  TSaveToLog = procedure(const AText: PChar); stdcall;
  // Показывает сообщение (чтобы не подключать Dialogs)
  TShowMsg = function(const AText: PChar; const mode: Byte): Integer; stdcall;
  // 0 - info, 1 - confirmation, 2 - Error
  TWaitTime = procedure(const SecondsForWait: Longword); stdcall;
  // Сохраняет любые данные в файл. Для отладки и дебага
  TSaveToFile = procedure(const AName, AContent: PChar); stdcall;
  // Позволяет получить адрес других процедур. Список будет пополнятся по мере надобности
  // Пока есть 2 функции - ShowMsg (TShowMsg) и WaitTime (TWaitTime = procedure (const SecondsForWait: Longword))
  // Если функции с таким именем нет - возвращает nil
  TGetFuncAddr = function(const AFuncName: PChar): Pointer; stdcall;
  TSimpleOptions = procedure(const OptionScript: PChar;
    const CallBack: TPlgCallBack); stdcall;
  TGetOption = procedure(const Plugin, Option, DefVal: PChar;
    const CallBack: TPlgCallBack); stdcall;
  TSetOption = procedure(const Plugin, Option, Value: PChar); stdcall;
  TGetPicSize = procedure (const fn: PChar; const CallBack: TPlgCallBack); stdcall;


var
  URLGet: TURLGet;
  URLPost: TURLPost;
  FDebug: Boolean;
  WorkDir: AnsiString;
  SaveToLog: TSaveToLog;
  SaveToFile: TSaveToFile;
  ShowMsg: TShowMsg;
  WaitTime: TWaitTime;
  SetRetResult: TSetRetResult;
  RezFromMainApp: AnsiString;
  SimpleOptions: TSimpleOptions;
  GetFuncAddr: TGetFuncAddr;
  GetOptionInPRG: TGetOption;
  SetOptionInPRG: TSetOption;
  GetPicSize: TGetPicSize;
  PicToArr: TPicToArr;
  ArrToPic: TArrToPic;
  GetProgClipboard: TGetClipboard;
  ShowHAWindow: TShowHAWindow;
  // -----------------------------------------------------------------------------------------------
  // Начало основного кода --------------------------------------------------------------------------
  // -----------------------------------------------------------------------------------------------

  // Функиця вызывается приложением, и возвращает в 1 строке полученный
  // через GET или POST данные

procedure PlgCallBack(const AText: PChar); stdcall;
begin
  RezFromMainApp := StrPas(AText);
end;

procedure SetOption(const Name, Value: AnsiString);
begin
  if @SetOptionInPRG = nil then
    exit;
  SetOptionInPRG(PluginName, PChar(Name), PChar(Value));
end;

// Вспомогательная функция. На входе - адрес, на выходе
// содержимое страницы. Метод Get
function Get(const URL: AnsiString): AnsiString;
begin
  RezFromMainApp := '';
  Result := '';
  URLGet(PChar(URL), @PlgCallBack);
  Result := RezFromMainApp;
end;

// Вспомогательная функция. На входе - адрес, данные для POST,
// на выходе содержимое страницы. Метод Post
function Post(const URL, Data: AnsiString): AnsiString;
begin
  RezFromMainApp := '';
  Result := '';
  URLPost(PChar(URL), PChar(Data), @PlgCallBack);
  Result := RezFromMainApp;
end;
function GetClipboard: AnsiString;
begin
  RezFromMainApp:='';
  Result:='';
  GetProgClipboard(@PlgCallBack);
  Result:=RezFromMainApp;
end;


function GetOption(const Name, DefVal: AnsiString): AnsiString;
begin
  if @GetOptionInPRG = nil then
  begin
    Result := DefVal;
    exit;
  end;
  RezFromMainApp := '';
  Result := '';
  GetOptionInPRG(PluginName, PChar(Name), PChar(DefVal), @PlgCallBack);
  Result := RezFromMainApp;
end;
procedure SetArrLen(var a: TDArray; const x, y: Integer); stdcall;
var i: Integer;
begin
  //Строка колонок
  SetLength(a, x);
  for i:=high(a) downto 0 do
    SetLength(a[i], y); //Высота каждой колонки
end;


function RecogniseFile(const fn: AnsiString): AnsiString;
const TXTFile='megashareby.txt';
var    Arr: TDArray;
    ResArr: Array [0..1] of String;
      w, h: Integer;
        ss: AnsiString;
begin
  Result:='';
  if FDebug then Savetolog(Pchar('Try to recognize picture '+fn));
  if not FileExists(fn) then exit;
  //Грузим картинку и сохраняем bmp
  GetPicSize(PChar(fn), @PlgCallBack);
  Split(RezFromMainApp, ResArr, '|');
  w:=StrToIntDef(ResArr[0], 0);
  h:=StrToIntDef(ResArr[1], 0);
  SetArrLen(Arr, w*3, h);
  PicToArr(PChar(fn), Arr, w, h);
  ArrToPic(PChar(ChangeFileExt(fn, '.bmp')), Arr, w, h);
  SetArrLen(Arr, 0, 0);


  ss:=GetOption('RecogniseCMD', '');

  if (ss<>'') then begin
                    SaveToLog(PChar('Recognise by OCR program'));
                    SaveToLog(PChar('Run <'+ss+'>'));
                    DeleteFile(WorkDir+TXTFile);
                    ChDir(WorkDir);
                    RunAndWait(ss, SW_Hide, 5*60*1000); //5 минут
                    if FileExists(WorkDir+TXTFile) then begin
                                                      SaveToLog('File '+TXTFile+' found, loading OCR result');
                                                      Result:=Trim(LoadString(WorkDir+TXTFile))
                                                        end
                                                 else
                                    begin
                                        if (@GetProgClipboard<>nil) then begin
                                                           SaveToLog('File '+TXTFile+' NOT found, paste OCR result from clipboard');
                                                            Result:=GetClipboard;
                                                                      end
                                                                    else
                                                                          SaveToLog('File '+TXTFile+' NOT found, cant paste OCR result from clipboard (need Beta 9.3 or better)');
                                    end;
                    end
              else
  begin
    SaveToLog(PChar('Recognise by User'));
    RezFromMainApp:='';
    Result:='';
    ShowHAWindow(PChar(fn), 0, @PlgCallBack);
    Result:=Trim(RezFromMainApp);
    Split(RezFromMainApp, ResArr, '|');
    Result:=ResArr[0];
  end;
end;


// Функция вызывается при загрузке плагина.
procedure PlgInit(const funcGet, funcPost, funcSaveToLog, funcGetFuncAddr,
  funcSaveToFile, funcRetResult: Pointer; const Debug: Byte;
  const AWorkDir: PChar); stdcall;
begin
  @URLGet := funcGet; // Ссылка на функцию GET
  @URLPost := funcPost; // Ссылка на функцию POST
  @SaveToLog := funcSaveToLog; // Ссылка на функцию SaveToLog
  @SaveToFile := funcSaveToFile; // Ссылка на функцию SaveToFile
  @SetRetResult := funcRetResult; // Ссылка на фунцию SetRetResult

  @GetFuncAddr := funcGetFuncAddr; // Функция для получения адресов других функций
  @ShowMsg := GetFuncAddr('ShowMsg'); // И как пример получение Адреса на функцию ShowMsg
  @WaitTime := GetFuncAddr('WaitTime');
  @GetOptionInPRG := GetFuncAddr('GetOption');
   @ShowHAWindow:=GetFuncAddr('ShowHAWindow');
  @GetProgClipboard:=GetFuncAddr('GetClipboard');
  @GetPicSize:=GetFuncAddr('GetPicSize');
  @PicToArr:=GetFuncAddr('PicToArr');
  @ArrToPic:=GetFuncAddr('ArrToPic');
  @SetOptionInPRG := GetFuncAddr('SetOption');
  @SimpleOptions := GetFuncAddr('SimpleOptions');
  FDebug := Debug = 1; // Режим отладки да/нет
  WorkDir := StrPas(AWorkDir); // Рабочий каталог (например для сохранения файлов при отладке)


  SetRetResult('megashare.by|1036'); // С какого сервака умеет. Подстрока.
  // Через вертикальную черту - минимальная
  // Версия нужная для работы.
  // Если в URL есть эта подстрока - то линк
  // будет отдан этому плагину. Регистр не важен
end;

// Основная функция - вызывается когда по "виртуальному" линку надо получить реальный на файл
// В качестве параметра передается виртуальный линк - например "http://sr1.mytempdir.com/116387"
// Возвращает прямой линк, либо один из спец ответов:
// %deleted% - файл был удален с сервера
// %notfound% - файл не найден на сервере (кривой линк?)
// Если возвращается пустая строка - считается что линк не получен и попытка получить будет
// повторена через 5 минут (ну на рапидшаре за час только 30 метров можно скачать
// вот программа и будет ждать, когда время "бойкота" кончится и можно будет получить линк)
procedure PlgGetDirectLink(const Lnk: PChar); stdcall;

function AnErrorOnPage(text:string):boolean;
begin
if isUtf(text) then
text:=Utf2Win(text);
result:=true;
 if pos('Запрашиваемый вами файл не найден', text) > 0 then
  begin
    SetRetResult('%notfound%');
    exit;
  end;
  if text = '' then
    exit;
  // Ошибка от сервера
  if pos('404 Not Found', text) > 0 then
  begin // сервак
    SetRetResult('%notfound%'); // В основную прогу возвращаем через функцию
    exit;
  end;
     if pos('Защитный номер не верный', text) > 0 then
  begin // сервак
    SetRetResult('%Error recognise code'); // В основную прогу возвращаем через функцию
    exit;
  end;
    if pos('дален с сервера', text) > 0 then
  begin // сервак
    SetRetResult('%deleted%'); // В основную прогу возвращаем через функцию
    exit;
  end;
  result:=false;
end;
const
  kapchaUrl='http://megashare.by/captcha.php';
  kapchaFile='Megashareby.png';
var
  s,s1: AnsiString;
  regexpr:TregExpr;

begin
  SaveToLog(PChar('Plugin '+PluginName+' ver. '+PluginVer));
  DeleteFile(WorkDir+'Megashare1.html');
    s:=Get(Lnk);
    //
    if FDebug then
      SaveToFile(PChar(WorkDir + 'Megashare1.html'), PChar(s));
  if AnErrorOnPage(s) then exit;
    Get(kapchaurl+'|'+WorkDir+kapchaFile);
    s1:=RecogniseFile(WorkDir+kapchaFile);
    if s1='' then begin
    SetRetResult('%Error recognise code');
    exit;
  end;
  s:=Post(Lnk,'captchacode='+s1);
  if AnErrorOnPage(s) then exit;
  regexpr:=tregexpr.create();
   try
   regexpr.Expression:='document\.location="(.*?)";';
   if  regexpr.Exec(s) then
        s1:=regexpr.match[1]
      else
        begin
        SetRetResult('%notfound%');
        exit;
       end;
   if FDebug then
    SaveToLog(PChar('filename='+s1));
   finally
   regexpr.Free;
   end;
    randomize;
    SetRetResult(PChar(s1 + '|' + (IntToStr(random(5)))));
  end;

  procedure PlgGetAbout; stdcall;
  begin
    ShowMsg(PChar(PluginName + ' plugin'#10'Version ' + PluginVer +
          #10'(c) Peleccom 2011 ©'), 0);
  end;

  // Вызывается перед выгрузкой плагина
  procedure PlgDestroy; stdcall;
  begin
    @URLGet := nil;
    @URLPost := nil;
  end;

  procedure PlgGetOptions; stdcall;
  var
    s: AnsiString;
    n, i: Integer;

    Values: Array of String;
    Arr: Array [0 .. 1] of String;

  begin
    if @SimpleOptions = nil then
    begin
      ShowMsg('This feature work only into 1.3.4 final or better', 0);
      exit;
    end;

    s := 'type=form|width=224|height=147|caption=' + PluginName +
      ' options'#10 +
      'type=label|left=5|top=8|width=26|height=13|value=Free Registration:'#10
      + 'type=label|left=5|top=35|width=26|height=13|value=Login'#10 +
      'type=edit|left=58|top=31|width=150|height=21|name=Login|value=' +
      GetOption('Login', '') + #10 +
      'type=label|left=5|top=62|width=46|height=13|value=Password'#10 +
      'type=password|left=58|top=58|width=150|height=21|name=Password|value=' +
      GetOption('Password', '');

    RezFromMainApp := '';
    SimpleOptions(PChar(s), @PlgCallBack);
    if (RezFromMainApp <> '') then
    begin
      n := PosNum(#10, RezFromMainApp);
      SetLength(Values, n);

      Split(RezFromMainApp, Values, #10);

      for i := low(Values) to high(Values) do
      begin
        if Values[i] = '' then
          continue;

        Split(Values[i], Arr, '=');
        SetOption(Arr[0], trim(Arr[1]));
      end;

      SetLength(Values, 0);
    end;
  end;

  exports PlgInit, PlgGetDirectLink, PlgDestroy, PlgGetAbout;

  begin

end.

