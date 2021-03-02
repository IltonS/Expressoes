program CalcEx;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils;

function GetHelloMsg(): ShortString; stdcall;
  external 'ExParser.dll' name 'GetHelloMsg';

begin
  Writeln('Vc digitou: ', ParamStr(1));
  //Writeln('Pressione ENTER para sair...');
  //Readln;
end.
