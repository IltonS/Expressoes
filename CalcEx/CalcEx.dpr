program CalcEx;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils;

function Eval(const Ex: ShortString): Double; stdcall;
  external 'ExEval.dll' name 'Eval';

var
  ExResult : Double;
begin
    ExResult := Eval(ParamStr(1));
    Writeln(FloatToStr(ExResult));
    Write('Pressione ENTER para sair...');
    Readln;
end.
