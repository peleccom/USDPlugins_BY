//------------------------------------------------------------------------------------
// Модуль для выполнения JavaScript
// Написан Peleccom
// version 0.1,  11.08.2011
//------------------------------------------------------------------------------------

unit js;

interface

uses  MSScriptControl_TLB;

function Run(s:String):String;
implementation

{Text}
function Run(s:String):String;
var
 ScriptControl1: TScriptControl;
begin
 try
 ScriptControl1:=TScriptControl.Create(nil);
 ScriptControl1.Language:='JScript';
 result:=ScriptControl1.Eval(s);

 finally
 ScriptControl1.Free();
 end;
end;

end.

