library ExEval;

{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections;

type
  TOperators = set of Char;
  TNumbers = set of Char;

  TTokenType = (ttOperator,ttLeftParentheses,ttRightParentheses,ttNumber);

  TToken = record
    TokenType : TTokenType;
    TokenValue : string;
  end;

const
  Operators : TOperators = ['+','-','*','/','%'];
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
    ttLeftParentheses : Result := 'Left Parentheses';
    ttRightParentheses : Result := 'Right Parentheses';
    ttNumber : Result := 'Number'
  end
end;

//------------------------------------------------------------------------------
// Core Funtions
//------------------------------------------------------------------------------
function MakeLexicalAnalysis(SourceString : string; TokenList : TList<TToken>) : Boolean;
var
  MyChar : Char;
  NumbersBuffer : string;
  IsScanningNumber : Boolean;
  LeftParenthesesCount, RightParenthesesCount : Integer;
begin
  //Initialize Local Variables:
  NumbersBuffer := EmptyStr;
  IsScanningNumber :=  False;
  LeftParenthesesCount := 0;
  RightParenthesesCount := 0;

  {TODO -oIltonS -cFeature : Validar funcionamento do operador %}
  //SourceString := StringReplace(SourceString,'%','/100',[rfReplaceAll]); //Replace % token for the actual calculation: /100

  for MyChar in SourceString do
  begin
    if (MyChar in Operators) or (MyChar = '(') or (MyChar = ')') then //Scan for Operators and Parentheses:
    begin
      if IsScanningNumber then //Check if the previous char was a number
      begin
        TokenList.Add(MakeToken(ttNumber,NumbersBuffer)); //Make the number token
        NumbersBuffer := EmptyStr; //Clear the Numbers Buffer
      end;

      IsScanningNumber := False;

      case MyChar of
        '(' : TokenList.Add(MakeToken(ttLeftParentheses,MyChar)); //Make the ( token
        ')' : TokenList.Add(MakeToken(ttRightParentheses,MyChar)); //Make the ) token
      else
        TokenList.Add(MakeToken(ttOperator,MyChar)) //Make the operator token
      end;

      case MyChar of //Count Parentheses to validate if the expression is valid
        '(' : Inc(LeftParenthesesCount);
        ')' : Inc(RightParenthesesCount);
      end;
    end
    else
      if MyChar in Numbers then //Scan for Numbers:
      begin
        IsScanningNumber := True;
        NumbersBuffer := NumbersBuffer + MyChar //Update the Numbers Buffer
      end
      else
        raise Exception.Create('Token Inválido: ' + QuotedStr(MyChar) + '.');
  end; //For

  if IsScanningNumber then //Check if the expression ended with a number
    TokenList.Add(MakeToken(ttNumber,NumbersBuffer)); //Make the number token

  if not (LeftParenthesesCount = RightParenthesesCount) then //validate ´parentheses
    raise Exception.Create('Uso incorreto de parêntesis');

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

  if Expression.IsEmpty then
    raise Exception.Create('Nenhuma expressão foi informada.');

  Parse(Expression);

  Result := -1;
end;

exports
  Eval;

end.
