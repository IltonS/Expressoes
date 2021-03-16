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
  EmptyString = 'E01 - A Express�o n�o pode ser vazia.';
  OperatorAtTheEnd = 'E02 - A express�o n�o pode terminar com o operador %s.';
  InvalidToken = 'E03 - %s � um caracter inv�lido.';
  InvalidCommaPrecession = 'E04 - A v�rgula n�o pode iniciar um express�o ou ser precedida por ) ou %.';
  InvalidCommaSuccession = 'E05 - A v�rgula deve ser sucedida por um n�mero.';
  InvalidOperatorPrecession = 'E06 - O operador %s na posi��o %s deve ser precedido por um n�mero.';
  InvalidRightParentheses = 'E07 - O par�ntesis na posi��o %s foi fechado incorretamente.';
  LeftParenthesesMissingOperator = 'E08 - Operador n�o encontrado antes do par�ntesis ( na posi��o %s.';
  RightParenthesesMissingOperator = 'E09 - Operador n�o encontrado ap�s o par�ntesis ) na posi��o %s.';
  InvalidParenthesesNumber = 'E10 - O n�mero de par�ntesis na express�o est� incorreto.';

//------------------------------------------------------------------------------
// Fun��es Helpers
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
// Fun��es principais
//------------------------------------------------------------------------------
procedure ValidateExpression(const Ex : string);
var
  LeftParenthesesCount, RightParenthesesCount, I : Integer;
begin
  {$REGION 'Resumo da gram�tica aceita para express�es'}
  {
    #1 - Express�o n�o pode ser vazia
    #2 - Express�o n�o pode terminar em +, -, *, /
    #3 - Caracter precisa ser um s�mbolo ou n�mero:
         Symbols : TSymbols = ['+','-','*','/','%','(',')'];
         Numbers : TNumbers = ['0'..'9',','];
    #4 - V�rgula n�o pode ser precedida por ) or %
    #5 - V�rgula precisa ser sucedida por um n�mero
    #6 - Os caracteres +, *, /, % precisam ser precedidos por um n�mero, ')' or '%'
    #7 - Par�ntesis fechado incorretamente
    #8 - '(' n�o pode ser precedio por n�mero, '%' or ')'
    #9 - ')' n�o pode ser sucedido por um n�mero
    #10 - A contagem de par�ntesis precisa ser igual
  }
  {$ENDREGION}

  //Inicializa vari�veis locais
  LeftParenthesesCount := 0;
  RightParenthesesCount := 0;

  // #1 - Express�o n�o pode ser vazia
  if Ex.IsEmpty then
    raise Exception.Create(EmptyString);

  // #2 - Express�o n�o pode terminar em +, -, *, / )
  if Ex.Chars[Ex.Length-1] in ['+','-','*','/'] then
    raise Exception.CreateFmt(OperatorAtTheEnd,[Ex.Chars[Ex.Length-1]]);

  for I := 0 to (Ex.Length-1) do
  begin
    // #3 - Caracter precisa ser um s�mbolo ou n�mero
    if (not (Ex.Chars[I] in Symbols)) and (not (Ex.Chars[I] in Numbers)) then
      raise Exception.CreateFmt(InvalidToken,[Ex.Chars[I]]);

    if Ex.Chars[I] = ',' then
    begin
      // #4 - V�rgula n�o pode ser precedida por ) or %
      try
        if Ex.Chars[I-1] in [')','%'] then
          raise Exception.Create(InvalidCommaPrecession);
      except
        raise Exception.Create(InvalidCommaPrecession);
      end;

      // #5 - V�rgula precisa ser sucedida por um n�mero
      try
        if not (Ex.Chars[I+1] in ['0'..'9']) then
          raise Exception.Create(InvalidCommaSuccession);
      except
        raise Exception.Create(InvalidCommaSuccession);
      end;
    end;


    // #6 - Os caracteres +, *, /, % precisam ser precedidos por um n�mero, ')' or '%'
    try
      if (Ex.Chars[I] in ['+','*','/','%']) and (not (Ex.Chars[I-1] in ['0'..'9',',',')','%']) ) then
        raise Exception.CreateFmt(InvalidOperatorPrecession,[Ex.Chars[I],IntToStr(I+1)]);
    except
      raise Exception.CreateFmt(InvalidOperatorPrecession,[Ex.Chars[I],IntToStr(I+1)]);
    end;

    // Valida��o de par�ntesis
    if Ex.Chars[I] in ['(',')'] then
    begin
      case Ex.Chars[I] of //Contador de par�ntesis para validar a express�o
        '(' : Inc(LeftParenthesesCount);
        ')' : Inc(RightParenthesesCount);
      end;

      // #7 - Par�ntesis fechado incorretamente
      if RightParenthesesCount > LeftParenthesesCount then
        raise Exception.CreateFmt(InvalidRightParentheses,[IntToStr(I+1)]);

      // #8 - '(' n�o pode ser precedio por n�mero, '%' or ')'
      if (Ex.Chars[I] = '(') and (I>0) and (Ex.Chars[I-1] in ['0'..'9','%',')'] ) then
        raise Exception.CreateFmt(LeftParenthesesMissingOperator,[IntToStr(I+1)]);

      // #9 - ')' n�o pode ser sucedido por um n�mero
      if (Ex.Chars[I] = ')') and (I<=Ex.Length-2) and (Ex.Chars[I+1] in ['0'..'9'] ) then
        raise Exception.CreateFmt(RightParenthesesMissingOperator,[IntToStr(I+1)])
    end
  end; //for

  // #10 - A contagem de par�ntesis precisa ser igual
  if LeftParenthesesCount <> RightParenthesesCount then
    raise Exception.Create(InvalidParenthesesNumber)
end;

function MakeLexicalAnalysis(SourceString : string; TokenList : TList<TToken>) : Boolean;
var
  MyChar : Char;
  NumbersBuffer : string;
  IsScanningNumber : Boolean;
begin
  //Inicializa vari�veis locais
  Result := False;
  NumbersBuffer := EmptyStr;
  IsScanningNumber :=  False;

  {$REGION 'Notas sobre calculo de porcentagem'}
  //----------------------------------------------------------------------------
  // Notas sobre calculo de porcentagem
  //----------------------------------------------------------------------------
  {
    Cen�rios:

    N�mero percentual a direita
    [1] x op y% => x * (1 op (y/100)) -> https://stackoverflow.com/questions/18938863/parsing-percent-expressions-with-antlr4
    [2] x% op y% => (x/100) * (1 op (y/100))

    N�mero percentual a esquerda
    [3] y% op x => (y/100) op x

    * % � parte do n�mero
      4 + 3% => 4 3% + => scenario [1]

    * % � um operador
      (2+2)+(3+3)% => 2 2 + 3 3 + % + => 4 3 3 + % + => 4 6 % + => 4 6% + => cen�rio [1]

      (2+2)%+(3+3)% => 2 2 + % 3 3 + % + => 4 % 3 3 + % + => 4% 3 3 + % + => 4% 6 % + => 4% 6% + => cen�rio [2]

      (2+2)+(3+3%%)% => 2 2 + 3 3%% + % + => 4 3 3%% + % + => 4 0,0309 % + => 4 0,0309% + => 4,001236 => cen�rio [1]

      (2+2)%+(3+3) => 2 2 + % 3 3 + + => 4 % 3 3 + + => 4% 3 3 + + => 4% 6 + => cen�rio [3]

      (2+2)%%+(3+3) => 2 2 + %% 3 3 + + => 4 %% 3 3 + + => 4%% 3 3 + + => 4%% 6 + => cen�rio [3]
                    => 2 2 + % % 3 3 + + => 4 % % 3 3 + + => 4% % 3 3 + + => 4%% 3 3 + + => 4%% 6 + => cen�rio [3]

  }
  {$ENDREGION}

  for MyChar in SourceString do
  begin
    if MyChar in Symbols then //L� um operador ou par�ntesis
    begin
      if IsScanningNumber and (MyChar = '%') then //Busca por n�meros percentuais
      begin
        NumbersBuffer := NumbersBuffer + MyChar; //Atualiza o buffer de n�meros
        Continue
      end;

      if IsScanningNumber then //Verifica se o caracter anterior era um n�mero
      begin
        TokenList.Add(MakeToken(ttNumber,NumbersBuffer)); //Cria um token de n�mero
        NumbersBuffer := EmptyStr //Limpa o buffer de n�meros.
      end;

      IsScanningNumber := False;

      case MyChar of
        '(' : TokenList.Add(MakeToken(ttLeftParentheses,MyChar)); //Cria o token (
        ')' : TokenList.Add(MakeToken(ttRightParentheses,MyChar)) //Cria o token )
      else
        TokenList.Add(MakeToken(ttOperator,MyChar)) //Cria um token de operador
      end;
    end
    else //L� um n�mero
    begin
      IsScanningNumber := True;
      NumbersBuffer := NumbersBuffer + MyChar //Atualiza o buffer de n�meros
    end
  end; //For

  if IsScanningNumber then //Verifica se a express�o terminou com um n�mero
    TokenList.Add(MakeToken(ttNumber,NumbersBuffer)); //Cria um token de n�mero

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

{$REGION 'Documenta��o da fun��o Eval'}
/// <summary>
///   Fun��o principal da DLL.
/// </summary>
/// <param name="Ex">
///   Recebe uma ShortString contendo uma express�o matem�tica. Ex: '4+5*(6+1)'.
/// </param>
/// <returns>
///   Um Double com o resultado da express�o.
/// </returns>
/// <remarks>
///   <para>
///     From original DLL note:
///     "To avoid using BORLNDMM.DLL, pass string information
///     using PChar or ShortString parameters."
///   </para>
///   <para>
///     Para fazer uso dos String Helpers, O par�metro do tipo ShortString � convertido
///     para uma String e armazenado numa vari�vel chamada Expression.
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
