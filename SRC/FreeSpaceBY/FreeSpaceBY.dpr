library FreeSpaceBY;

uses
  SysUtils,
  SimUtils in '..\LIB\SimUtils.pas',
  RegExpr in '..\LIB\Regexpr.pas';

{$E .plg}
{$R *.res}

const
  PluginName = 'FreeSpace.by';
  PluginVer = '1.3';

type
  // �������� ������� (����� ��� �������� ��������� ���������� ������,
  // ���������� � GET � POST. ����� ����� �� ���� ������� � �������)
  TPlgCallBack = procedure(const AText: PChar); stdcall;
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
  @SetOptionInPRG := GetFuncAddr('SetOption');
  @SimpleOptions := GetFuncAddr('SimpleOptions');
  FDebug := Debug = 1; // ����� ������� ��/���
  WorkDir := StrPas(AWorkDir); // ������� ������� (�������� ��� ���������� ������ ��� �������)

  SetRetResult('freespace.by|1036'); // � ������ ������� �����. ���������.
  // ����� ������������ ����� - �����������
  // ������ ������ ��� ������.
  // ���� � URL ���� ��� ��������� - �� ����
  // ����� ����� ����� �������. ������� �� �����
end;

// �������� ������� - ���������� ����� �� "������������" ����� ���� �������� �������� �� ����
// � �������� ��������� ���������� ����������� ���� - �������� "http://sr1.mytempdir.com/116387"
// ���������� ������ ����, ���� ���� �� ���� �������:
// %deleted% - ���� ��� ������ � �������
// %notfound% - ���� �� ������ �� ������� (������ ����?)
// ���� ������������ ������ ������ - ��������� ��� ���� �� ������� � ������� �������� �����
// ��������� ����� 5 ����� (�� �� ��������� �� ��� ������ 30 ������ ����� �������
// ��� ��������� � ����� �����, ����� ����� "�������" �������� � ����� ����� �������� ����)
procedure PlgGetDirectLink(const FreeSpaceByLnk: PChar); stdcall;
var
  s: AnsiString;
  n: Integer;
  s1: string;
  login, passw: AnsiString;
  PostStr: AnsiString;
  Loginned: Boolean;
  regexpr:TregExpr;
begin
  SaveToLog(PChar('Plugin '+PluginName+' ver. '+PluginVer));
  DeleteFile(WorkDir+'FreeSpaceBy1.html');
  DeleteFile(WorkDir+'FreeSpaceBy2.html');
  DeleteFile(WorkDir+'FreeSpaceBy3.html');
  login := trim(GetOption('Login', ''));
  passw := trim(GetOption('Password', ''));

  begin
    // ��� ��� �����
    
    PostStr :='format=ajax'+#10+'lang=ru'+#10+'action[0]=AuthExt.logon'+#10+ 'username[0]=' + login + #10 + 'auth_provider_key=local' + #10 +
      'password[0]=' + passw + #10 + 'remember[0]=1';
    s := Post('http://freespace.by/api.php', PostStr);

    if FDebug then
      SaveToLog(PChar('Freespace.by Post: FreeSpace.by ' +  PostStr));
    //
    if FDebug then
      SaveToFile(PChar('FreeSpaceBy1.html'), PChar(s));


  s := Get(FreeSpaceByLnk); // ���������
   if FDebug then
    SaveToFile(PChar(WorkDir + 'FreeSpaceBy2.html'), PChar(s));
      if pos(AnsiToUtf8('�����</'), s) > 0 then
    begin
      SaveToLog(PChar('Freespace.by Loginned' + #13#10));
      Loginned := true;
    end

    else
    begin
      SaveToLog(PChar('Freespace.by Not Loggined' + #13#10));
      Loginned := false;
    end;
  end;


  if pos('file was removed', s) > 0 then
  begin
    SetRetResult('%deleted%');
    exit;
  end;
  if s = '' then
    exit;
  s := Utf8ToAnsi(s);
  // ������ �� �������
  if pos('404 Not Found', s) > 0 then
  begin // ������
    SetRetResult('%notfound%'); // � �������� ����� ���������� ����� �������
    exit;
  end;
  if pos('��� �� ������', s) > 0 then
  begin // ���� �� ������ (������ ����)
    SetRetResult('%notfound%');
    exit;
  end; // !!!! � ������ �� ����� ������
  if pos('�������� ������ ��� ����������� �����', s) > 0 then
  begin
    SaveToLog(PChar('This file can download only from Belorussia.'));
    SetRetResult('%deleted%');
    exit;
  end;
  if pos('temporary blocked', s) > 0 then
    exit;

  n := pos('id="remaining_time"', s);
  if n > 0 then
  begin
    n := pos('.remainingTime', s);
    if n > 0 then
      s := OnlyNums(copy(s, length('.remainingTime') + n, 10))
    else
      s := '';

    n := StrToIntDef(s, 150);

    SaveToLog(PChar('Need wait ' + IntToStr(n) + ' seconds'));
    WaitTime(n);
   end;
    s := Get(FreeSpaceByLnk + '?1');
     if pos('404 Not Found', s) > 0 then
      begin // ������
      SetRetResult('%notfound%'); // � �������� ����� ���������� ����� �������
      exit;
      end;
    if FDebug then
    SaveToFile(PChar(WorkDir + 'FreeSpaceBy3.html'), PChar(s));
    regexpr:=TregExpr.Create();
    regexpr.Expression:='<a.href="(http://93.*?)"';
    if  regexpr.Exec(s) then
    begin
      s:=regexpr.match[1];
      SaveToLog(PChar('Freespace.by ' + #13#10));
      if FDebug then
        SaveToFile(PChar(WorkDir + 'Freespaceby.html'), PChar(s));
    end;
    randomize;
    SetRetResult(PChar(s + '|' + (IntToStr(random(5)))));
  end;

  procedure PlgGetAbout; stdcall;
  begin
    ShowMsg(PChar(PluginName + ' plugin'#10'Version ' + PluginVer +
          #10'(c) Peleccom 2010 �'), 0);
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

  exports PlgInit, PlgGetDirectLink, PlgDestroy, PlgGetOptions, PlgGetAbout;

  begin

end.
