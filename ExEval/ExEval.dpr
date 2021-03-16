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
  // Resources Strings para mensagens de erro
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
// Funções Helpers
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
// Funções principais
//------------------------------------------------------------------------------
procedure ValidateExpression(const Ex : string);
var
  LeftParenthesesCount, RightParenthesesCount, I : Integer;
begin
  {$REGION 'Resumo da gramática aceita para expressões'}
  {
    #1 - Expressão não pode ser vazia
    #2 - Expressão não pode terminar em +, -, *, /
    #3 - Caracter precisa ser um símbolo ou número:
         Symbols : TSymbols = ['+','-','*','/','%','(',')'];
         Numbers : TNumbers = ['0'..'9',','];
    #4 - Vírgula não pode ser precedida por ) or %
    #5 - Vírgula precisa ser sucedida por um número
    #6 - Os caracteres +, *, /, % precisam ser precedidos por um número, ')' or '%'
    #7 - Parêntesis fechado incorretamente
    #8 - '(' não pode ser precedio por número, '%' or ')'
    #9 - ')' não pode ser sucedido por um número
    #10 - A contagem de parêntesis precisa ser igual
  }
  {$ENDREGION}

  //Inicializa variáveis locais
  LeftParenthesesCount := 0;
  RightParenthesesCount := 0;

  // #1 - Expressão não pode ser vazia
  if Ex.IsEmpty then
    raise Exception.Create(EmptyString);

  // #2 - Expressão não pode terminar em +, -, *, / )
  if Ex.Chars[Ex.Length-1] in ['+','-','*','/'] then
    raise Exception.CreateFmt(OperatorAtTheEnd,[Ex.Chars[Ex.Length-1]]);

  for I := 0 to (Ex.Length-1) do
  begin
    // #3 - Caracter precisa ser um símbolo ou número
    if (not (Ex.Chars[I] in Symbols)) and (not (Ex.Chars[I] in Numbers)) then
      raise Exception.CreateFmt(InvalidToken,[Ex.Chars[I]]);

    if Ex.Chars[I] = ',' then
    begin
      // #4 - Vírgula não pode ser precedida por ) or %
      try
        if Ex.Chars[I-1] in [')','%'] then
          raise Exception.Create(InvalidCommaPrecession);
      except
        raise Exception.Create(InvalidCommaPrecession);
      end;

      // #5 - Vírgula precisa ser sucedida por um número
      try
        if not (Ex.Chars[I+1] in ['0'..'9']) then
          raise Exception.Create(InvalidCommaSuccession);
      except
        raise Exception.Create(InvalidCommaSuccession);
      end;
    end;


    // #6 - Os caracteres +, *, /, % precisam ser precedidos por um número, ')' or '%'
    try
      if (Ex.Chars[I] in ['+','*','/','%']) and (not (Ex.Chars[I-1] in ['0'..'9',',',')','%']) ) then
        raise Exception.CreateFmt(InvalidOperatorPrecession,[Ex.Chars[I],IntToStr(I+1)]);
    except
      raise Exception.CreateFmt(InvalidOperatorPrecession,[Ex.Chars[I],IntToStr(I+1)]);
    end;

    // Validação de parêntesis
    if Ex.Chars[I] in ['(',')'] then
    begin
      case Ex.Chars[I] of //Contador de parêntesis para validar a expressão
        '(' : Inc(LeftParenthesesCount);
        ')' : Inc(RightParenthesesCount);
      end;

      // #7 - Parêntesis fechado incorretamente
      if RightParenthesesCount > LeftParenthesesCount then
        raise Exception.CreateFmt(InvalidRightParentheses,[IntToStr(I+1)]);

      // #8 - '(' não pode ser precedio por número, '%' or ')'
      if (Ex.Chars[I] = '(') and (I>0) and (Ex.Chars[I-1] in ['0'..'9','%',')'] ) then
        raise Exception.CreateFmt(LeftParenthesesMissingOperator,[IntToStr(I+1)]);

      // #9 - ')' não pode ser sucedido por um número
      if (Ex.Chars[I] = ')') and (I<=Ex.Length-2) and (Ex.Chars[I+1] in ['0'..'9'] ) then
        raise Exception.CreateFmt(RightParenthesesMissingOperator,[IntToStr(I+1)])
    end
  end; //for

  // #10 - A contagem de parêntesis precisa ser igual
  if LeftParenthesesCount <> RightParenthesesCount then
    raise Exception.Create(InvalidParenthesesNumber)
end;

function MakeLexicalAnalysis(SourceString : string; TokenList : TList<TToken>) : Boolean;
var
  MyChar : Char;
  NumbersBuffer : string;
  IsScanningNumber : Boolean;
begin
  //Inicializa variáveis locais
  Result := False;
  NumbersBuffer := EmptyStr;
  IsScanningNumber :=  False;

  {$REGION 'Notas sobre calculo de porcentagem'}
  //----------------------------------------------------------------------------
  // Notas sobre calculo de porcentagem
  //----------------------------------------------------------------------------
  {
    Cenários:

    Número percentual a direita
    [1] x op y% => x * (1 op (y/100)) -> https://stackoverflow.com/questions/18938863/parsing-percent-expressions-with-antlr4
    [2] x% op y% => (x/100) * (1 op (y/100))

    Número percentual a esquerda
    [3] y% op x => (y/100) op x

    * % é parte do número
      4 + 3% => 4 3% + => scenario [1]

    * % é um operador
      (2+2)+(3+3)% => 2 2 + 3 3 + % + => 4 3 3 + % + => 4 6 % + => 4 6% + => cenário [1]

      (2+2)%+(3+3)% => 2 2 + % 3 3 + % + => 4 % 3 3 + % + => 4% 3 3 + % + => 4% 6 % + => 4% 6% + => cenário [2]

      (2+2)+(3+3%%)% => 2 2 + 3 3%% + % + => 4 3 3%% + % + => 4 0,0309 % + => 4 0,0309% + => 4,001236 => cenário [1]

      (2+2)%+(3+3) => 2 2 + % 3 3 + + => 4 % 3 3 + + => 4% 3 3 + + => 4% 6 + => cenário [3]

      (2+2)%%+(3+3) => 2 2 + %% 3 3 + + => 4 %% 3 3 + + => 4%% 3 3 + + => 4%% 6 + => cenário [3]
                    => 2 2 + % % 3 3 + + => 4 % % 3 3 + + => 4% % 3 3 + + => 4%% 3 3 + + => 4%% 6 + => cenário [3]

  }
  {$ENDREGION}

  for MyChar in SourceString do
  begin
    if MyChar in Symbols then //Lê um operador ou parêntesis
    begin
      if IsScanningNumber and (MyChar = '%') then //Busca por números percentuais
      begin
        NumbersBuffer := NumbersBuffer + MyChar; //Atualiza o buffer de números
        Continue
      end;

      if IsScanningNumber then //Verifica se o caracter anterior era um número
      begin
        TokenList.Add(MakeToken(ttNumber,NumbersBuffer)); //Cria um token de número
        NumbersBuffer := EmptyStr //Limpa o buffer de números.
      end;

      IsScanningNumber := False;

      case MyChar of
        '(' : TokenList.Add(MakeToken(ttLeftParentheses,MyChar)); //Cria o token (
        ')' : TokenList.Add(MakeToken(ttRightParentheses,MyChar)) //Cria o token )
      else
        TokenList.Add(MakeToken(ttOperator,MyChar)) //Cria um token de operador
      end;
    end
    else //Lê um número
    begin
      IsScanningNumber := True;
      NumbersBuffer := NumbersBuffer + MyChar //Atualiza o buffer de números
    end
  end; //For

  if IsScanningNumber then //Verifica se a expressão terminou com um número
    TokenList.Add(MakeToken(ttNumber,NumbersBuffer)); //Cria um token de número

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

{$REGION 'Documentação da função Eval'}
/// <summary>
///   Função principal da DLL.
/// </summary>
/// <param name="Ex">
///   Recebe uma ShortString contendo uma expressão matemática. Ex: '4+5*(6+1)'.
/// </param>
/// <returns>
///   Um Double com o resultado da expressão.
/// </returns>
/// <remarks>
///   <para>
///     From original DLL note:
///     "To avoid using BORLNDMM.DLL, pass string information
///     using PChar or ShortString parameters."
///   </para>
///   <para>
///     Para fazer uso dos String Helpers, O parâmetro do tipo ShortString é convertido
///     para uma String e armazenado numa variável chamada Expression.
///   </para>
/// </remarks>

{$ENDREGION}
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
