library ExEval;

{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections;

type
  TOperators = set of Char;
  TNumbers = set of Char;

  TTokenType = (ttOperator,ttNumber,ttUndefined);

  TToken = record
    TokenType : TTokenType;
    TokenValue : string;
  end;

  EInvalidToken = class(Exception);

const
  Operators : TOperators = ['+','-','*','/','(',')'];
  Numbers : TNumbers = ['0'..'9',','];

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
    ttNumber : Result := 'Number';
    ttUndefined : Result := 'Undefined';
  end;
end;

//------------------------------------------------------------------------------
// Core Funtions
//------------------------------------------------------------------------------
function MakeLexicalAnalysis(const SourceString : string; TokenList : TList<TToken>) : Boolean;
var
  MyChar : Char;
  NumbersBuffer : string;
  IsScanningNumber : Boolean;
begin
  //Initialize Local Variables:
  NumbersBuffer := EmptyStr;
  IsScanningNumber :=  False;

  for MyChar in SourceString do
  begin
    if MyChar in Operators then //Scan for Operators:
    begin
      if IsScanningNumber then //Check if the previous char was a number
      begin
        TokenList.Add(MakeToken(ttNumber,NumbersBuffer)); //Make the number token
        NumbersBuffer := EmptyStr; //Clear the Numbers Buffer
      end;

      IsScanningNumber := False;

      TokenList.Add(MakeToken(ttOperator,MyChar)) //Make the operator token
    end
    else
      if MyChar in Numbers then //Scan for Operators:
      begin
        IsScanningNumber := True;
        NumbersBuffer := NumbersBuffer + MyChar //Update the Numbers Buffer
      end
      else
      begin
        {TODO -oIltonS -cTratamento de Erros : Tratar Token Inválido}
      end;
  end; //For

  if IsScanningNumber then //Check if the expression ended with a number
    TokenList.Add(MakeToken(ttNumber,NumbersBuffer)); //Make the number token

  Result := True;
end;

procedure Parse(const SourceString : string);
var
  TokenList : TList<TToken>;
  Token : TToken;
begin
  TokenList := TList<TToken>.Create;
  MakeLexicalAnalysis(SourceString,TokenList);

  for Token in TokenList do
  begin
    Writeln(Token.TokenValue + ' is ' + TokenTypeToStr(Token.TokenType));
  end;
  Writeln;

  TokenList.Free;
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
