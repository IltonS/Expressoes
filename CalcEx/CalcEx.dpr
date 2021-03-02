program CalcEx;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils;

function Parse(Ex : ShortString): Double; stdcall;
  external 'ExParser.dll' name 'Parse';

var
  ExResult : Double;
begin
    ExResult := Parse(ParamStr(1));
    Writeln(FloatToStr(ExResult));
end.
