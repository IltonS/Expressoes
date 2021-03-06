library ExParser;

uses
  System.SysUtils,
  System.Classes,
  System.Character;

{$R *.res}

function Parse(Ex : ShortString): Double; stdcall;
var
  Expression : String;
begin
  {
    From original note:
      "To avoid using BORLNDMM.DLL, pass string information
      using PChar or ShortString parameters."

    To make use of String Helpers, the ShortString parameter is casted
    into String

    Helpers Examples:
      * Expression.Chars[0]               : Char
      * Expression.Chars[0].IsWhiteSpace  :Boolean
  }
  Expression := String(Ex);

  Result := 0;
end;

exports
  Parse;

end.
