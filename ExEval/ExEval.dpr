library ExEval;

{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections;

type
  TOperators = set of Char;

  TTokenType = (ttOperator,ttUndefined);

  TToken = record
    TokenType : TTokenType;
    TokenValue : string;
  end;

const
  Operators : TOperators = ['+','-','*','/','(',')'];

//------------------------------------------------------------------------------
// Helpers Functions
//------------------------------------------------------------------------------
function MakeToken(const TokenType : TTokenType; const TokenValue : string) : TToken;
begin
  Result.TokenType := TokenType;
  Result.TokenValue := TokenValue;
end;

function TokenTypeToStr(TokenType : TTokenType) : string;
begin
  case TokenType of
    ttOperator : Result := 'Operator';
    ttUndefined : Result := 'Undefined';
  end;
end;

//------------------------------------------------------------------------------
// Core Funtions
//------------------------------------------------------------------------------
function MakeLexicalAnalysis(const SourceString : string) : TList<TToken>;
var
  MyChar : Char;
begin
  Result := TList<TToken>.Create;

  for MyChar in SourceString do
  begin
    //Scan for Operators:
    if MyChar in Operators then
      Result.Add(MakeToken(ttOperator,MyChar));
  end;

end;

procedure Parse(const SourceString : string);
var
  TokenList : TList<TToken>;
  Token : TToken;
begin
  TokenList := TList<TToken>.Create;
  TokenList := MakeLexicalAnalysis(SourceString);

  for Token in TokenList do
  begin
    Writeln(Token.TokenValue + ' is ' + TokenTypeToStr(Token.TokenType));
  end;
  Writeln;
end;

/// <summary>
///   Main DLL function
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
///     into a String and stored in a variable named Expression.
///   </para>
/// </remarks>
function Eval(const Ex: ShortString): Double; stdcall;
var
  Expression : string;
begin
  Expression := string(Ex);

  Writeln(Expression);
  Writeln;

  Parse(Expression);

  Result := -1;
end;

exports
  Eval;

end.
