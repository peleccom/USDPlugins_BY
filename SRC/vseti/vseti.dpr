library vseti;
uses
  SysUtils,
  SimUtils in '..\LIB\SimUtils.pas',
  RegExpr in '..\LIB\Regexpr.pas',
  js in '..\LIB\js.pas';

{$E .plg}
{$R *.res}

const
  PluginName = 'Vseti.by';
  PluginVer = '1.1a';
  Author='Peleccom';
  RealiseDate='2012';
  SW_HIDE = 0;


type
  TDArray = Array of Array of Byte;
  TPicToArr = procedure (const fn: PChar; var Arr: TDArray; const Width, Height: Integer); stdcall;
  TArrToPic = procedure (const fn: PChar; var Arr: TDArray; const Width, Height: Integer); stdcall;



  // �������� ������� (����� ��� �������� ��������� ���������� ������,
  // ���������� � GET � POST. ����� ����� �� ���� ������� � �������)
  TPlgCallBack = procedure(const AText: PChar); stdcall;
  TShowHAWindow = procedure (const fn: PChar; const DTicket: Integer; const CallBack: TPlgCallBack); stdcall;
  TGetClipboard = procedure (const CallBack: TPlgCallBack); stdcall;
  // ��������� ������ GET
  TURLGet = procedure(const URL: PChar; const CallBack: TPlgCallBack); stdcall;
  // ��������� ������ POST, ������ �������� - ������ ������������ � �������
  // � �������: ���_����1=��������_����1 #10 ���_����2=��������_����2 � ��
  TURLPost = procedure(const URL, Data: PChar; const CallBack: TPlgCallBack);
    stdcall;
  TSetRetResult = procedure(const AText: PChar); stdcall;
  // ��������� � ��� ���� �����
  TSaveToLog = procedure(const AText: PChar); stdcall;
  // ���������� ��������� (����� �� ���������� Dialogs)
  TShowMsg = function(const AText: PChar; const mode: Byte): Integer; stdcall;
  // 0 - info, 1 - confirmation, 2 - Error
  TWaitTime = procedure(const SecondsForWait: Longword); stdcall;
  // ��������� ����� ������ � ����. ��� ������� � ������
  TSaveToFile = procedure(const AName, AContent: PChar); stdcall;
  // ��������� �������� ����� ������ ��������. ������ ����� ���������� �� ���� ����������
  // ���� ���� 2 ������� - ShowMsg (TShowMsg) � WaitTime (TWaitTime = procedure (const SecondsForWait: Longword))
  // ���� ������� � ����� ������ ��� - ���������� nil
  TGetFuncAddr = function(const AFuncName: PChar): Pointer; stdcall;
  TSimpleOptions = procedure(const OptionScript: PChar;
    const CallBack: TPlgCallBack); stdcall;
  TGetOption = procedure(const Plugin, Option, DefVal: PChar;
    const CallBack: TPlgCallBack); stdcall;
  TSetOption = procedure(const Plugin, Option, Value: PChar); stdcall;
  TGetPicSize = procedure (const fn: PChar; const CallBack: TPlgCallBack); stdcall;

  // ������ ������ (mode=0 ����������, 1- ������) 
  TSetCookie = procedure (const AString: PChar; const mode: byte); stdcall;


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

  SetCookie : TSetCookie;
  // -----------------------------------------------------------------------------------------------
  // ������ ��������� ���� --------------------------------------------------------------------------
  // -----------------------------------------------------------------------------------------------

  // ������� ���������� �����������, � ���������� � 1 ������ ����������
  // ����� GET ��� POST ������
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

// ��������������� �������. �� ����� - �����, �� ������
// ���������� ��������. ����� Get
function Get(const URL: AnsiString): AnsiString;
begin
  RezFromMainApp := '';
  Result := '';
  URLGet(PChar(URL), @PlgCallBack);
  Result := RezFromMainApp;
end;

// ��������������� �������. �� ����� - �����, ������ ��� POST,
// �� ������ ���������� ��������. ����� Post
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
  //������ �������
  SetLength(a, x);
  for i:=high(a) downto 0 do
    SetLength(a[i], y); //������ ������ �������
end;

function RecogniseFile(const fn: AnsiString): AnsiString;
const TXTFile='Uvaga.txt';
var    Arr: TDArray;
    ResArr: Array [0..1] of String;
      w, h: Integer;
        ss: AnsiString;
begin
  Result:='';
  if FDebug then Savetolog(Pchar('Try to recognize picture '+fn));
  if not FileExists(fn) then exit;
  //������ �������� � ��������� bmp
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
                    RunAndWait(ss, SW_Hide, 5*60*1000); //5 �����
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


// ������� ���������� ��� �������� �������.
procedure PlgInit(const funcGet, funcPost, funcSaveToLog, funcGetFuncAddr,
  funcSaveToFile, funcRetResult: Pointer; const Debug: Byte;
  const AWorkDir: PChar); stdcall;
begin
  @URLGet := funcGet; // ������ �� ������� GET
  @URLPost := funcPost; // ������ �� ������� POST
  @SaveToLog := funcSaveToLog; // ������ �� ������� SaveToLog
  @SaveToFile := funcSaveToFile; // ������ �� ������� SaveToFile
  @SetRetResult := funcRetResult; // ������ �� ������ SetRetResult

  @GetFuncAddr := funcGetFuncAddr; // ������� ��� ��������� ������� ������ �������
  @ShowMsg := GetFuncAddr('ShowMsg'); // � ��� ������ ��������� ������ �� ������� ShowMsg
  @WaitTime := GetFuncAddr('WaitTime');
  @GetOptionInPRG := GetFuncAddr('GetOption');
   @ShowHAWindow:=GetFuncAddr('ShowHAWindow');
  @GetProgClipboard:=GetFuncAddr('GetClipboard');
  @GetPicSize:=GetFuncAddr('GetPicSize');
  @PicToArr:=GetFuncAddr('PicToArr');
  @ArrToPic:=GetFuncAddr('ArrToPic');
  @SetOptionInPRG := GetFuncAddr('SetOption');
  @SimpleOptions := GetFuncAddr('SimpleOptions');
  @SetCookie := GetFuncAddr('SetCookie');
  FDebug := Debug = 1; // ����� ������� ��/���
  WorkDir := StrPas(AWorkDir); // ������� ������� (�������� ��� ���������� ������ ��� �������)


  SetRetResult('vseti.by/video|1036'); // � ������ ������� �����. ���������.
  // ����� ������������ ����� - �����������
  // ������ ������ ��� ������.
  // ���� � URL ���� ��� ��������� - �� ����
  // ����� ����� ����� �������. ������� �� �����
end;



//********************MAIN*********************************************
function GetValue(html:String;Param:String):String;
Var
  regexpr:TregExpr;
  s1:string;
begin
s1:='';
 regexpr:=tregexpr.create();
  regexpr.Expression:='var '+Param+' = '+#39+'(.*?)'+#39;
      if  regexpr.Exec(html) then
             begin
             s1:=regexpr.match[1];
             end;
  regexpr.Free();
 result:=s1;
end;

function Login(mail,pass:String):Boolean;
var
s, newcookie:Ansistring;
regexpr:TregExpr;
begin
result:=False;
s:=Get('http://vseti.by/');
s := Post('http://login.vseti.by/?act=login','email='+mail+#10+'password='+pass+#10+'jsc=') ;
SaveToFile(Pchar(WorkDir+PluginName+'1.html'), Pchar(s));
regexpr:=tregexpr.create();
regexpr.Expression:='setCookieEx\('+#39+'(.+?)'+#39+',.?'+#39+'(.*?)'+#39+',.?(\d+)\)';
if FDebug then SaveToLog(Pchar('Trying regexpr :'+regexpr.Expression+#13));
newcookie := '';
if regexpr.Exec(s) then
  begin
    repeat
    if FDebug then SaveToLog(Pchar('Found regexpr'));
    newcookie := newcookie + 'vs'+regexpr.Match[1]+'='
          + regexpr.Match[2] + '; ';
    until not regexpr.ExecNext();
    if FDebug then SaveToLog(Pchar(newcookie));
    SetCookie(Pchar(newcookie),1);
  end
else
    Exit;

s := Get('http://vseti.by/start.php');
s := UTF8Decode(s);
SaveToFile(Pchar(WorkDir+PluginName+'2.html'), Pchar(s));
if Pos('�������', s) > 0 then
  result:=True;
end;

// �������� ������� - ���������� ����� �� "������������" ����� ���� �������� �������� �� ����
// � �������� ��������� ���������� ����������� ���� - �������� "http://sr1.mytempdir.com/116387"
// ���������� ������ ����, ���� ���� �� ���� �������:
// %deleted% - ���� ��� ������ � �������
// %notfound% - ���� �� ������ �� ������� (������ ����?)
// ���� ������������ ������ ������ - ��������� ��� ���� �� ������� � ������� �������� �����
// ��������� ����� 5 ����� (�� �� ��������� �� ��� ������ 30 ������ ����� �������
// ��� ��������� � ����� �����, ����� ����� "�������" �������� � ����� ����� �������� ����)
procedure PlgGetDirectLink(const Lnk: PChar); stdcall;

function AnErrorOnPage(text:string):boolean;
	begin
	result:=true;
	// ���� ������
	if pos('��������� ���� �� ������', text) > 0 then
		begin
		SetRetResult('%notfound%');
		exit;
		end;
	// ���� �� ������
	if pos('404 Not Found', text) > 0 then
		begin // ������
		SetRetResult('%notfound%');
		exit;
		end;
    if pos('HTTP 500. HTTP ERROR 500', text) > 0 then
		begin // ������
		SetRetResult('%notfound%');
		exit;
		end;
	result:=false;
	end;
var
  s,s1: AnsiString;
  L,P:string;
  regexpr:TregExpr;
begin
  SaveToLog(PChar('Plugin '+PluginName+' ver. '+PluginVer));
  DeleteFile(WorkDir+PluginName+'1.html');
  DeleteFile(WorkDir+PluginName+'2.html');
  L:=GetOption('Login','');
  P:=GetOption('Password','');
  if not Login(L,P) then
            begin
            SetRetResult('%LoginFailed');
            SaveToLog(Pchar('Incorrect login or password'));
            exit;
            end;
  s:=Get(Lnk);
  SaveToFile(Pchar(WorkDir+PluginName+'1.html'),Pchar(s));
  regexpr:=tregexpr.create();
  regexpr.Expression:='url:.'+#39+'(.*?)'+#39;
  if  regexpr.Exec(s) then
    begin
    s1:=regexpr.match[1];
    if Pos('video.php',s1)>0 then
    begin
    SaveToLog(Pchar('Link found: '+s1));
    s1:=SimUtils.UrlDecode(s1);
    end
    else
    s1:=''
    end
  else
    s1:='';
  regexpr.Free();
	randomize;
  if s1<>'' then
    SetRetResult(PChar(s1 + '|' + (IntToStr(random(5)))))
  else
    SetRetResult('%notfound%');
  end;

 //********************MAIN*********************************************


 
  procedure PlgGetAbout; stdcall;
  begin
    ShowMsg(PChar(PluginName + ' plugin'#10'Version ' + PluginVer +
          #10'(c) '+Author+' '+RealiseDate+' �'), 0);
  end;

  
  
  // ���������� ����� ��������� �������
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
      'type=label|left=5|top=8|width=26|height=13|value=Account setting "Vseti.by":'#10
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

 Exports PlgInit, PlgGetDirectLink, PlgDestroy, PlgGetAbout,PlgGetOptions;

 begin

end.

