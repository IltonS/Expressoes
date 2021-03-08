library ExParser;

uses
  System.SysUtils,
  System.Classes,
  System.Character;

{$R *.res}

type
  TToken = record
    TokenType : String;
    TokenValue : String
  end;

var
  GExpression: String;

  /// <summary>Main DLL function.</summary>
  /// <param name="Ex">Receives a ShortString with a math expression. Eg.: '4+5*(6+1)'</param>
  /// <remarks>
  /// <para>
  /// From original DLL note:
  /// "To avoid using BORLNDMM.DLL, pass string information
  /// using PChar or ShortString parameters."
  /// </para>
  /// <para>
  /// To make use of String Helpers, the ShortString parameter is casted
  /// into String and stored in a global variable GExpression. Helpers Examples:
  /// <code>GExpression.Chars[0];</code>
  /// <code>GExpression.Chars[0].IsWhiteSpace;</code>
  /// <code>GExpression.Chars[0].IsLetter;</code>
  /// <code>GExpression.Chars[0].IsDigit;</code>
  /// </para>
  /// </remarks>
function Parse(Ex: ShortString): Double; stdcall;
begin
  GExpression := String(Ex);

  Result := 0;
end;

exports
  Parse;

end.
