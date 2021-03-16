library ExEval;

{$R *.res}

uses
  System.SysUtils,
  System.StrUtils,
  System.Classes,
  System.Generics.Collections;

type
  TSymbols = set of Char;
  TNumbers = set of Char;

  TTokenType = (ttOperator,ttLeftParentheses,ttRightParentheses,ttNumber,ttPercentageNumber);

  TToken = record
    TokenType : TTokenType;
    TokenValue : string;
  end;

const
  Symbols : TSymbols = ['+','-','*','/','%','(',')'];
  Numbers : TNumbers = ['0'..'9',','];

resourcestring
  //----------------------------------------------------------------------------
  // Error Resources Strings
  //----------------------------------------------------------------------------
  EmptyString = 'E01 - A Expressão não pode ser vazia.';
  OperatorAtTheEnd = 'E02 - A expressão não pode terminar com o operador %s.';
  InvalidToken = 'E03 - %s é um caracter inválido.';
  InvalidCommaPrecession = 'E04 - A vírgula não pode iniciar um expressão ou ser precedida por ) ou %.';
  InvalidCommaSuccession = 'E05 - A vírgula deve ser sucedida por um número.';
  InvalidOperatorPrecession = 'E06 - O operador %s na posição %s deve ser precedido por um número.';
  InvalidRightParentheses = 'E07 - O parêntesis na posição %s foi fechado incorretamente.';
  LeftParenthesesMissingOperator = 'E08 - Operador não encontrado antes do parêntesis ( na posição %s.';
  RightParenthesesMissingOperator = 'E09 - Operador não encontrado após o parêntesis ) na posição %s.';
  InvalidParenthesesNumber = 'E10 - O número de parêntesis na expressão está incorreto.';

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
procedure ValidateExpression(const Ex : string);
var
  LeftParenthesesCount, RightParenthesesCount, I : Integer;
begin
  //Initialize local variables:
  LeftParenthesesCount := 0;
  RightParenthesesCount := 0;

  // #1 - Expression can't be empty
  if Ex.IsEmpty then
    raise Exception.Create(EmptyString);

  // #2 - Last character can't be +, -, *, /
  if Ex.Chars[Ex.Length-1] in ['+','-','*','/'] then
    raise Exception.CreateFmt(OperatorAtTheEnd,[Ex.Chars[Ex.Length-1]]);

  for I := 0 to (Ex.Length-1) do
  begin
    // #3 - Character must be a Symbol or a number
    if (not (Ex.Chars[I] in Symbols)) and (not (Ex.Chars[I] in Numbers)) then
      raise Exception.CreateFmt(InvalidToken,[Ex.Chars[I]]);

    if Ex.Chars[I] = ',' then
    begin
      // #4 - ',' Can't be preceded by ) or %
      try
        if Ex.Chars[I-1] in [')','%'] then
          raise Exception.Create(InvalidCommaPrecession);
      except
        raise Exception.Create(InvalidCommaPrecession);
      end;

      // #5 - ',' Must be suceded by a number
      try
        if not (Ex.Chars[I+1] in ['0'..'9']) then
          raise Exception.Create(InvalidCommaSuccession);
      except
        raise Exception.Create(InvalidCommaSuccession);
      end;
    end;


    // #6 - Characters +, *, /, % must be preceded by a number, ')' or %
    try
      if (Ex.Chars[I] in ['+','*','/','%']) and (not (Ex.Chars[I-1] in ['0'..'9',',',')','%']) ) then
        raise Exception.CreateFmt(InvalidOperatorPrecession,[Ex.Chars[I],IntToStr(I+1)]);
    except
      raise Exception.CreateFmt(InvalidOperatorPrecession,[Ex.Chars[I],IntToStr(I+1)]);
    end;

    // Validates parentheses
    if Ex.Chars[I] in ['(',')'] then
    begin
      case Ex.Chars[I] of //Count Parentheses to validate if the expression is valid
        '(' : Inc(LeftParenthesesCount);
        ')' : Inc(RightParenthesesCount);
      end;

      // #7 - Right parentheses used without a Left parentheses
      if RightParenthesesCount > LeftParenthesesCount then
        raise Exception.CreateFmt(InvalidRightParentheses,[IntToStr(I+1)]);

      // #8 - '(' can't be preceded by number, '%' or ')'
      if (Ex.Chars[I] = '(') and (I>0) and (Ex.Chars[I-1] in ['0'..'9','%',')'] ) then
        raise Exception.CreateFmt(LeftParenthesesMissingOperator,[IntToStr(I+1)]);

      // #9 - ')' can't be suceded by number
      if (Ex.Chars[I] = ')') and (I<=Ex.Length-2) and (Ex.Chars[I+1] in ['0'..'9'] ) then
        raise Exception.CreateFmt(RightParenthesesMissingOperator,[IntToStr(I+1)])
    end
  end; //for

  // #10 - The number of '(' and ')' must be the same
  if LeftParenthesesCount <> RightParenthesesCount then
    raise Exception.Create(InvalidParenthesesNumber)
end;

function MakeLexicalAnalysis(SourceString : string; TokenList : TList<TToken>) : Boolean;
var
  MyChar : Char;
  NumbersBuffer : string;
  IsScanningNumber : Boolean;
begin
  //Initialize Local Variables:
  Result := False;
  NumbersBuffer := EmptyStr;
  IsScanningNumber :=  False;

  {$REGION 'Notes on percentage calculation'}
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
  {$ENDREGION}

  for MyChar in SourceString do
  begin
    if MyChar in Symbols then //Scan for Operators and Parentheses:
    begin
      if IsScanningNumber and (MyChar = '%') then //Check for x% numbers
      begin
        NumbersBuffer := NumbersBuffer + MyChar; //Update the Numbers Buffer
        Continue
      end;

      if IsScanningNumber then //Check if the previous char was a number
      begin
        TokenList.Add(MakeToken(ttNumber,NumbersBuffer)); //Make the number token
        NumbersBuffer := EmptyStr //Clear the Numbers Buffer
      end;

      IsScanningNumber := False;

      case MyChar of
        '(' : TokenList.Add(MakeToken(ttLeftParentheses,MyChar)); //Make the ( token
        ')' : TokenList.Add(MakeToken(ttRightParentheses,MyChar)) //Make the ) token
      else
        TokenList.Add(MakeToken(ttOperator,MyChar)) //Make the operator token
      end;
    end
    else //Scan for numbers
    begin
      IsScanningNumber := True;
      NumbersBuffer := NumbersBuffer + MyChar //Update the Numbers Buffer
    end
  end; //For

  if IsScanningNumber then //Check if the expression ended with a number
    TokenList.Add(MakeToken(ttNumber,NumbersBuffer)); //Make the number token

  Result := True
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

  TokenList.Free
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

  ValidateExpression(Expression);

  Parse(Expression);

  Result := -1
end;

exports
  Eval;

end.
