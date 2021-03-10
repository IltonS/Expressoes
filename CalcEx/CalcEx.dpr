program CalcEx;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils;

function Eval(const Ex: ShortString): Double; stdcall;
  external 'ExEval.dll' name 'Eval';

var
  ExResult: Double;

begin
  Writeln('Parâmetro informado: ' + ParamStr(1));
  Writeln;

  try
    ExResult := Eval(ParamStr(1));
    Writeln(FloatToStr(ExResult));
  except
   on E : Exception do
   begin
      Writeln('ERRO: ' + E.Message);
      Writeln
   end
  end;

  Write('Pressione ENTER para sair...');
  Readln
end.
