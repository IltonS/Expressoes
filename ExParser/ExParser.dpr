library ExParser;

uses
  System.SysUtils,
  System.Classes,
  System.Character;

{$R *.res}

type
  TOperators = set of Char;

  TTokenType = (ttOperator,ttUndefined);

  TToken = record
    TokenType : TTokenType;
    TokenValue : Char
  end;

var
  GExpression: String;

const
  OPERATORS : TOperators = ['+','-','*','/','(',')'];
  NULL_CHAR : Char = #0;

/// <summary>
///   Evaluates a given char to check if it's a operator or not.
/// </summary>
/// <param name="Input">
///   The Char to be evaluated.
/// </param>
/// <returns>
///   A TToken with a 'ttOperator' type if Input is an operator or
///   a 'ttUndefined' type otherwise;
/// </returns>
function ScanOperator(const Input : Char) : TToken;
begin
  if (Input in OPERATORS) then
  begin
    Result.TokenType := ttOperator;
    Result.TokenValue := Input;
  end
  else
  begin
    Result.TokenType := ttUndefined;
    Result.TokenValue := NULL_CHAR;
  end;
end;

/// <summary>
///   Main DLL function.
/// </summary>
/// <param name="Ex">
///   Receives a ShortString with a math expression. Eg.: '4+5*(6+1)'
/// </param>
/// <returns>
///   A Double value with the result of the expression
/// </returns>
/// <remarks>
///   <para>
///     From original DLL note:
///     "To avoid using BORLNDMM.DLL, pass string information
///     using PChar or ShortString parameters."
///   </para>
///   <para>
///     To make use of String Helpers, the ShortString parameter is casted
///     into String and stored in a global variable GExpression. Helpers Examples:
///     <code>GExpression.Chars[0];</code>
///     <code>GExpression.Chars[0].IsWhiteSpace;</code>
///     <code>GExpression.Chars[0].IsLetter;</code>
///     <code>GExpression.Chars[0].IsDigit;</code>
///   </para>
/// </remarks>
function Parse(const Ex: ShortString): Double; stdcall;
var
  I : Integer;
  MyChar : Char;
  Token : TToken;
begin
  GExpression := String(Ex);

  Writeln(GExpression);
  Writeln;

  Write('Operadores: [');
  for I := 0 to (GExpression.Length-1) do
  begin
    Token := ScanOperator(GExpression.Chars[I]);

    if Token.TokenType = ttOperator then
    begin
      Write(Token.TokenValue);

      if I <> (GExpression.Length-1) then
        Write(', ');
    end;
  end;
  Writeln(']');
  Writeln;

  {for MyChar in GExpression do
  begin
    Token := ScanOperator(MyChar);
    if Token.TokenType = ttOperator then
      Writeln(Token.TokenValue + ': Operator')
    else
      Writeln(Token.TokenValue + ': Undefined');
    Writeln;
  end;
  Writeln;}

  Result := 0;
end;

exports
  Parse;

end.
