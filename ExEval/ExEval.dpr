library ExEval;

uses
  System.SysUtils,
  System.Classes;

{$R *.res}
var
  GExpression : String;

function Eval(const Ex: ShortString): Double; stdcall;
begin
  GExpression := Ex;

  Writeln(GExpression);
  Writeln;

  Result := -1;
end;

exports
  Eval;

end.
