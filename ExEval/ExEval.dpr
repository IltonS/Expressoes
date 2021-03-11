library ExEval;

{$R *.res}

uses
  System.SysUtils,
  System.StrUtils,
  System.Classes,
  System.Generics.Collections;

type
  TOperators = set of Char;
  TNumbers = set of Char;

  TTokenType = (ttOperator,ttLeftParentheses,ttRightParentheses,ttNumber,ttPercentageNumber);

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
function MakeToken(TokenType : TTokenType; const TokenValue : string) : TToken;
begin
  if (TokenType = ttNumber) and ( PosEx('%',TokenValue) <> 0 ) then //Check if is a number and if it is a percentage number
    TokenType := ttPercentageNumber;

  Result.TokenType := TokenType;
  Result.TokenValue := TokenValue;
end;

function TokenTypeToStr(TokenType : TTokenType) : string;
begin
  case TokenType of
    ttOperator : Result := 'Operator';
    ttLeftParentheses : Result := 'Left Parentheses';
    ttRightParentheses : Result := 'Right Parentheses';
    ttNumber : Result := 'Number';
    ttPercentageNumber : Result := 'Percentage Number';
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

  //----------------------------------------------------------------------------
  // Notes on percentage calculation
  //----------------------------------------------------------------------------
  {
    Scenarios:

    Right Percentage
    [1] x op y% => x * (1 op (y/100)) -> https://stackoverflow.com/questions/18938863/parsing-percent-expressions-with-antlr4
    [2] x% op y% => (x/100) * (1 op (y/100))

    Left Percentage
    [3] y% op x => (y/100) op x

    * % is part of the number
      4 + 3% => 4 3% + => scenario [1]

    * % is operator
      (2+2)+(3+3)% => 2 2 + 3 3 + % + => 4 3 3 + % + => 4 6 % + => 4 6% + => scenario [1]

      (2+2)%+(3+3)% => 2 2 + % 3 3 + % + => 4 % 3 3 + % + => 4% 3 3 + % + => 4% 6 % + => 4% 6% + => scenario [2]

      (2+2)+(3+3%%)% => 2 2 + 3 3%% + % + => 4 3 3%% + % + => 4 0,0309 % + => 4 0,0309% + => 4,001236 => scenario [1]

      (2+2)%+(3+3) => 2 2 + % 3 3 + + => 4 % 3 3 + + => 4% 3 3 + + => 4% 6 + => scenario [3]

      (2+2)%%+(3+3) => 2 2 + %% 3 3 + + => 4 %% 3 3 + + => 4%% 3 3 + + => 4%% 6 + => scenario [3]
                    => 2 2 + % % 3 3 + + => 4 % % 3 3 + + => 4% % 3 3 + + => 4%% 3 3 + + => 4%% 6 + => scenario [3]

  }

  for MyChar in SourceString do
  begin
    if (MyChar in Operators) or (MyChar = '(') or (MyChar = ')') then //Scan for Operators and Parentheses:
    begin
      if IsScanningNumber and (MyChar = '%') then //Check for x% numbers
      begin
        NumbersBuffer := NumbersBuffer + MyChar; //Update the Numbers Buffer
        Continue
      end;

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

  {TODO -oIltonS -cTratamento de Exceções : Tratar ex do tipo )3+3(}
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

  {TODO -oIltonS -cTratamento de Exceções : A expressão deve começãr com 0 ou (}
  Expression := '0' + Expression; //Force an expression to begin with 0

  Parse(Expression);

  Result := -1;
end;

exports
  Eval;

end.
