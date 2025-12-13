{$mode fpc}{$H+}
program main;

uses
    SysUtils, Classes, fpjson, jsonparser, ConvertAFNtoAFD, AFN, AFD, CommonTypes, ConvertAFNEtoAFN, ConvertMultiToAFNE, MinimizeAFD;

type
  AFN_E = record
    alfabeto: array of char;
    estados: array of string;
    estadoInicial: array of string;
    estadosFinais: array of string;
    transicoes: array of TTransicao;
  end;

  AFN_multiestado_inicial = record
    alfabeto: array of char;
    estados: array of string;
    estadosIniciais: array of string;
    estadosFinais: array of string;
    transicoes: array of TTransicao;
  end;

    //Vetor de vetores... Matriz.
  IntMatriz = array of array of Integer;

var
  data: TJSONData;
  inputFileName: string;
  choice, subchoice: string;
  afd_result: TAFD;
  afn_obj: TAFN;
//   afn_e_obj: TAFN_E;
//   afn_multiestado_inicial_obj: TAFN_multiestado_inicial;
  alfabeto: array of char;
  estados: array of string;
  estadosIniciais: array of string;
  estadosFinais: array of string;
  transicoes: array of TTransicao;
  jsonObj: TJSONObject;
  jsonArr: TJSONArray;
  i, j, k, count: Integer;
  item: TJSONData;
  innerArr: TJSONArray;
  s: string;
  isAFD, isAFN, isAFN_E, isAFN_Multiestado_Inicial: Boolean;
  sl: TStringList;
  fname, w: string;

// ======================= 

function ExisteNaoDeterminismo(const T: array of TTransicao): boolean;
var
  i, j: integer;
begin
  ExisteNaoDeterminismo := False;
  for i := 0 to High(T) do
  begin
    if (T[i].fromState = '') or (T[i].symbol = #0) then Continue;
    for j := i+1 to High(T) do
    begin
      if (T[j].fromState = '') or (T[j].symbol = #0) then Continue;
      if (T[i].fromState = T[j].fromState) and (T[i].symbol = T[j].symbol) then
      begin
        if (T[i].toState <> T[j].toState) then
        begin
          ExisteNaoDeterminismo := True;
          Exit;
        end;
      end;
    end;
  end;
end;

//Mapear nomes de estado p/ índices inteiros
function IndexOfStr(const arr: array of string; const s: string): Integer;
var i: Integer;
begin
  for i := 0 to High(arr) do
    if arr[i] = s then
    begin
      IndexOfStr := i;
      Exit;
    end;
  IndexOfStr := -1;
end;

//Mapear nomes de estado p/ índices inteiros
function IndexOfChar(const arr: array of char; const c: char): Integer;
var i: Integer;
begin
  for i := 0 to High(arr) do
    if arr[i] = c then
    begin
      IndexOfChar := i;
      Exit;
    end;
  IndexOfChar := -1;
end;

//Construindo a Matriz de transições
procedure BuildDelta(const estados: array of string; const alfabeto: array of char;
  const trans: array of TTransicao; var delta: IntMatriz);
var
  i, ns, na, f, a, t: Integer;
  //ns -> Número de estados, na -> Tamanho do Alfabeto
  //Esses dois definem o tamanho da matriz delta
begin
  ns := Length(estados);
  na := Length(alfabeto);
  SetLength(delta, ns);
  for i := 0 to ns-1 do
  begin
    SetLength(delta[i], na);
    FillChar(delta[i][0], SizeOf(Integer)*na, $FF); // -1 em todos
  end;

  for i := 0 to High(trans) do
  begin
    f := IndexOfStr(estados, trans[i].fromState); //Linha da Matriz
    a := IndexOfChar(alfabeto, trans[i].symbol);  //Coluna da Matriz
    t := IndexOfStr(estados, trans[i].toState);   //Valor Salvo na Matriz
    if (f >= 0) and (a >= 0) and (t >= 0) then
      delta[f][a] := t;
  end;
end;

function TestarPalavraAFD(const estados: array of string; const alfabeto: array of char;
  const estadoInicial: string; const estadosFinais: array of string;
  const trans: array of TTransicao; const palavra: string): Boolean;
var
  delta: IntMatriz;
  i, cur, symi, nxt: Integer;
  finalsMask: array of Boolean;
begin
  TestarPalavraAFD := False;

  BuildDelta(estados, alfabeto, trans, delta);

  SetLength(finalsMask, Length(estados));
  for i := 0 to High(finalsMask) do finalsMask[i] := False;
  for i := 0 to High(estadosFinais) do
  begin
    nxt := IndexOfStr(estados, estadosFinais[i]);
    if nxt >= 0 then finalsMask[nxt] := True;
  end;

  cur := IndexOfStr(estados, estadoInicial);
  if cur < 0 then
  begin
    TestarPalavraAFD := False; Exit;
  end;

  for i := 1 to Length(palavra) do
  begin
    symi := IndexOfChar(alfabeto, palavra[i]);
    if symi < 0 then
    begin
      TestarPalavraAFD := False; Exit; // símbolo fora do alfabeto
    end;

    //Pega a transição do estado atual com o símbolo atual e diz o próximo estado.
    nxt := delta[cur][symi];
    if nxt < 0 then
    begin
      TestarPalavraAFD := False; Exit; // transição não definida
    end;
    cur := nxt;
  end;

  TestarPalavraAFD := finalsMask[cur];
end;

// ========================== 

procedure ShowMenu;
begin
  Writeln;
  Writeln('=================================================');
  Writeln('|                      MENU                     |');
  Writeln('|0. Converter multiestado inicial em AFN-&      |');
  Writeln('|1. Converter AFN-& em AFN                      |');
  Writeln('|2. Converter AFN em AFD                        |');
  Writeln('|3. Minimizar AFD                               |');
  Writeln('|4. Testar palavras                             |');
  Writeln('|5. Sair                                        |');
  Writeln('=================================================');
  Writeln;
end;

begin
    // Checar argumentos de linha de comando para arquivo de entrada
    if ParamCount >= 1 then
        inputFileName := 'input/' + ParamStr(1)
    else
        inputFileName := 'input/automato.json';
      
    WriteLn('Using input file: ', inputFileName);

    isAFD := False;
    isAFN := False;
    isAFN_E := False;
    isAFN_Multiestado_Inicial := False;

    data := GetJSON(TFileStream.Create(inputFileName, fmOpenRead), True);
    {
    WriteLn('--- JSON Content ---');
    WriteLn(data.FormatJSON);
    WriteLn('--- End JSON ---');
    }
    if data.JSONType = jtObject then
    begin
        jsonObj := TJSONObject(data);

        // ---- Alfabeto ----
        if jsonObj.Find('alfabeto') <> nil then
        begin
            jsonArr := jsonObj.Arrays['alfabeto'];

            SetLength(alfabeto, jsonArr.Count);
            for i := 0 to jsonArr.Count - 1 do
                alfabeto[i] := jsonArr.Strings[i][1];
        end;

        // ---- Estados ----
        if jsonObj.Find('estados') <> nil then
        begin
            jsonArr := jsonObj.Arrays['estados'];

            SetLength(estados, jsonArr.Count);
            for i := 0 to jsonArr.Count - 1 do
                estados[i] := jsonArr.Strings[i];
        end;

        // ---- Estados Iniciais ----
        if jsonObj.Find('estados_iniciais') <> nil then
        begin
            jsonArr := jsonObj.Arrays['estados_iniciais'];
            SetLength(estadosIniciais, jsonArr.Count);

            if jsonArr.Count > 1 then
              isAFN_Multiestado_Inicial := True;

            for i := 0 to jsonArr.Count - 1 do
                estadosIniciais[i] := jsonArr.Strings[i];
        end;

        if Length(estadosIniciais) > 1 then
            Writeln('Estado inicial: ', estadosIniciais[0])
        else if Length(estadosIniciais) = 1 then
            Writeln('Estado inicial: ', estadosIniciais[0]);

        // ---- Estados Finais ----
        if jsonObj.Find('estados_finais') <> nil then
        begin
            jsonArr := jsonObj.Arrays['estados_finais'];
            SetLength(estadosFinais, jsonArr.Count);
            for i := 0 to jsonArr.Count - 1 do
                estadosFinais[i] := jsonArr.Strings[i];
        end;

        // ---- Transições ----
        if jsonObj.Find('transicoes') <> nil then
        begin
            jsonArr := jsonObj.Arrays['transicoes'];
            SetLength(transicoes, jsonArr.Count);
            for i := 0 to jsonArr.Count - 1 do
            begin
                item := jsonArr.Items[i];
                case item.JSONType of
                    jtArray:
                    begin
                    
                        innerArr := TJSONArray(item);
                        transicoes[i].fromState := innerArr.Strings[0];
                        transicoes[i].toState   := innerArr.Strings[1];
                        transicoes[i].symbol    := innerArr.Strings[2][1];
                        if (transicoes[i].symbol = '&') and (not isAFN_Multiestado_Inicial) then
                            isAFN_E := True;
                    end;
                else
                    begin
                        transicoes[i].fromState := '';
                        transicoes[i].toState := '';
                        transicoes[i].symbol := #0;
                    end;
                end;
            end;
        end;
    end;

    isAFN := False;
    if (not isAFN_Multiestado_Inicial) and (not isAFN_E) then
    begin
        if ExisteNaoDeterminismo(transicoes) then
          isAFN := True;
    end;

    if (not isAFN) and (not isAFN_E) and (not isAFN_Multiestado_Inicial) then
        isAFD := True
    else
        isAFD := False;

    if isAFN_Multiestado_Inicial then
        Writeln('O autômato é um AFN de multiestado inicial')
    else if isAFN_E then
        Writeln('O autômato é um AFN-&')
    else if isAFN then
        Writeln('O autômato é um AFN')
    else
        Writeln('O autômato é um AFD');

    // Loop do Menu
    while True do
    begin
        ShowMenu;
        Write('Escolha uma opção: ');
        Readln(choice);
        case choice of
            '0': 
            begin
                Writeln('Convertendo AFN multiestado inicial em AFN-&...');
                if isAFN_Multiestado_Inicial then
                begin
                    afn_obj.alfabeto := alfabeto;
                    afn_obj.estados := estados;
                    afn_obj.estadosIniciais := estadosIniciais;
                    afn_obj.estadosFinais := estadosFinais;
                    afn_obj.transicoes := transicoes;
                    afn_obj.isAFN := isAFN;
                    afn_obj.isAFN_E := isAFN_E;
                    afn_obj.isAFN_Multiestado_Inicial := isAFN_Multiestado_Inicial;

                    afn_obj := ConvertMultiToAFNE.ConvertMultiToAFNE(afn_obj);

                    alfabeto := afn_obj.alfabeto;
                    estados := afn_obj.estados;
                    estadosIniciais := afn_obj.estadosIniciais;
                    estadosFinais := afn_obj.estadosFinais;
                    transicoes := afn_obj.transicoes;

                    isAFN_Multiestado_Inicial := False;
                    isAFN_E := True;
                    isAFN := True;
                    
                    Writeln('Autômato convertido com sucesso!');
                    Writeln('{');
                    
                    // Alfabeto
                    Writeln('    "alfabeto": [');
                    for i := 0 to High(alfabeto) do
                    begin
                        Write('        "', alfabeto[i], '"');
                        if i < High(alfabeto) then Writeln(',') else Writeln;
                    end;
                    Writeln('    ],');

                    // Estados
                    Writeln('    "estados": [');
                    for i := 0 to High(estados) do
                    begin
                        Write('        "', estados[i], '"');
                        if i < High(estados) then Writeln(',') else Writeln;
                    end;
                    Writeln('    ],');

                    // Estados Iniciais
                    Writeln('    "estados_iniciais": [');
                    for i := 0 to High(estadosIniciais) do
                    begin
                        Write('        "', estadosIniciais[i], '"');
                        if i < High(estadosIniciais) then Writeln(',') else Writeln;
                    end;
                    Writeln('    ],');

                    // Estados Finais
                    Writeln('    "estados_finais": [');
                    for i := 0 to High(estadosFinais) do
                    begin
                        Write('        "', estadosFinais[i], '"');
                        if i < High(estadosFinais) then Writeln(',') else Writeln;
                    end;
                    Writeln('    ],');

                    // Transições
                    Writeln('    "transicoes": [');
                    for i := 0 to High(transicoes) do
                    begin
                        Writeln('        [');
                        Writeln('            "', transicoes[i].fromState, '",');
                        Writeln('            "', transicoes[i].toState, '",');
                        Writeln('            "', transicoes[i].symbol, '"');
                        Write('        ]');
                        if i < High(transicoes) then Writeln(',') else Writeln;
                    end;
                    Writeln('    ]');

                    Writeln('}');
                    
                end
                else
                    Writeln('O automato nao possui multiplos estados iniciais.');
            end;
            '1': 
            begin
                Writeln('Convertendo AFN-& em AFN...');
                if isAFN_E then
                begin
                    afn_obj.alfabeto := alfabeto;
                    afn_obj.estados := estados;
                    afn_obj.estadosIniciais := estadosIniciais;
                    afn_obj.estadosFinais := estadosFinais;
                    afn_obj.transicoes := transicoes;

                    afn_obj := ConvertAFNEtoAFN.ConvertAFNEtoAFN(afn_obj);

                    alfabeto := afn_obj.alfabeto;
                    estados := afn_obj.estados;
                    estadosIniciais := afn_obj.estadosIniciais;
                    estadosFinais := afn_obj.estadosFinais;
                    transicoes := afn_obj.transicoes;

                    isAFN_E := False;
                    isAFN := True;
                    if Length(estadosIniciais) > 1 then isAFN_Multiestado_Inicial := True;
                    Writeln('Autômato convertido com sucesso!');
                    Writeln('{');
                    
                    // Alfabeto
                    Writeln('    "alfabeto": [');
                    for i := 0 to High(alfabeto) do
                    begin
                        Write('        "', alfabeto[i], '"');
                        if i < High(alfabeto) then Writeln(',') else Writeln;
                    end;
                    Writeln('    ],');

                    // Estados
                    Writeln('    "estados": [');
                    for i := 0 to High(estados) do
                    begin
                        Write('        "', estados[i], '"');
                        if i < High(estados) then Writeln(',') else Writeln;
                    end;
                    Writeln('    ],');

                    // Estados Iniciais
                    Writeln('    "estados_iniciais": [');
                    for i := 0 to High(estadosIniciais) do
                    begin
                        Write('        "', estadosIniciais[i], '"');
                        if i < High(estadosIniciais) then Writeln(',') else Writeln;
                    end;
                    Writeln('    ],');

                    // Estados Finais
                    Writeln('    "estados_finais": [');
                    for i := 0 to High(estadosFinais) do
                    begin
                        Write('        "', estadosFinais[i], '"');
                        if i < High(estadosFinais) then Writeln(',') else Writeln;
                    end;
                    Writeln('    ],');

                    // Transições
                    Writeln('    "transicoes": [');
                    for i := 0 to High(transicoes) do
                    begin
                        Writeln('        [');
                        Writeln('            "', transicoes[i].fromState, '",');
                        Writeln('            "', transicoes[i].toState, '",');
                        Writeln('            "', transicoes[i].symbol, '"');
                        Write('        ]');
                        if i < High(transicoes) then Writeln(',') else Writeln;
                    end;
                    Writeln('    ]');

                    Writeln('}');
                    
                end
                else
                    Writeln('O automato nao e um AFN-&.');
            end;

            '2':
            begin
                Writeln('Função 2 selecionada');
                if isAFN then
                begin
                    Writeln('Convertendo AFN para AFD...');
                    afn_obj.alfabeto := alfabeto;
                    afn_obj.estados := estados;
                    afn_obj.estadosIniciais := estadosIniciais;
                    afn_obj.estadosFinais := estadosFinais;
                    afn_obj.transicoes := transicoes;
                    afn_obj.isAFN := isAFN;
                    afn_obj.isAFN_E := isAFN_E;
                    afn_obj.isAFN_Multiestado_Inicial := isAFN_Multiestado_Inicial;
                    Writeln('isAFN: ', BoolToStr(afn_obj.isAFN, True));

                    afd_result := ConvertAFNtoAFD.ConvertAFNtoAFD(afn_obj);
                    Writeln('Conversão concluída!');
                    estados := afd_result.estados;
                    alfabeto := afd_result.alfabeto;
                    estadosIniciais := [afd_result.estadoInicial];
                    estadosFinais := afd_result.estadosFinais;
                    transicoes := afd_result.transicoes;
                    isAFD := True;
                    isAFN := False;
                    isAFN_E := False;
                    isAFN_Multiestado_Inicial := False;
                end
                else
                    Writeln('O autômato já é um AFD, não é necessário converter.');
            end;
            '3':
            begin
              Writeln('Minimizar AFD');
              if not isAFD then
              begin
                Writeln('O autômato usado não é um AFD!');
                continue;
              end;

              if Length(estadosIniciais) <> 1 then
              begin
                Writeln('AFD inválido, há mais de um estado inicial. ');
                Continue;
              end;

              afd_result.alfabeto := alfabeto;
              afd_result.estados := estados;
              afd_result.estadoInicial := estadosIniciais[0];
              afd_result.estadosFinais := estadosFinais;
              afd_result.transicoes := transicoes;

              // garantir que o estado inicial existe na lista de estados
              if IndexOfStr(estados, estadosIniciais[0]) < 0 then
              begin
                Writeln('ERRO: Estado inicial "', estadosIniciais[0], '" nao existe na lista de estados.');
                Writeln('Dica: Isso geralmente ocorre apos renomear estados (q0,q1,...) sem atualizar o inicial.');
                Continue;
              end;

              MinimizarAFD(afd_result, afd_result);
              alfabeto := afd_result.alfabeto;
              estados := afd_result.estados;
              SetLength(estadosIniciais, 1);
              estadosIniciais[0] := afd_result.estadoInicial;
              estadosFinais := afd_result.estadosFinais;
              transicoes := afd_result.transicoes;

              isAFD := True;
              isAFN := False;
              isAFN_E := False;
              isAFN_Multiestado_Inicial := False;

              Writeln('AFD minimizado!');
            end;

            //=========== (4) ===========

            '4':
            begin
                Writeln('Teste de palavras (AFD)');
                if not isAFD then // Se não for um AFD...
                begin
                    Writeln('Esse autômato não é um AFD!!!');
                    Writeln('-> Carregue um AFD ou converta antes de testar!');
                    Continue;
                end;
                if Length(estadosIniciais) <> 1 then //Se a quantidade de estados for diferente de 1
                begin
                    if Length(estadosIniciais) > 1 then
                    begin
                        Writeln('Esse AFD está errado, possui mais de 1 estado inicial.');
                        Continue;
                    end;
                    if Length(estadosIniciais) = 0 then
                    begin
                        Writeln('AFD sem estado inicial.');
                        Continue;
                    end;
                end;

                Writeln('1 Via Arquivo');
                Writeln('2 Via Terminal');
                Write('Escolha uma opcao: ');
                Readln(subchoice);

                case subchoice of
                    '1':
                    begin
                        fname := 'input/palavras.txt';
                        if not FileExists(fname) then
                            Writeln('Arquivo ', fname, ' nao encontrado.')
                        else
                        begin
                            sl := TStringList.Create;
                            sl.LoadFromFile(fname);
                            Writeln;
                            Writeln('Testando ', sl.Count, ' palavra(s) de ', fname, ':');
                            Writeln;
                            for i := 0 to sl.Count-1 do
                            begin
                                w := Trim(sl[i]);

                                // Reconhecer palavra vazia (antes eu não tinha feito)
                                if (w = '') or (w = '&') or (w = 'ε') then
                                begin
                                    if TestarPalavraAFD(estados, alfabeto, estadosIniciais[0], estadosFinais, transicoes, '') then
                                        Writeln('PALAVRA VAZIA -> ACEITA')
                                    else
                                        Writeln('PALAVRA VAZIA -> REJEITA');
                                    Continue;
                                end;

                                // As outras palavras que não sao vazia
                                if TestarPalavraAFD(estados, alfabeto, estadosIniciais[0], estadosFinais, transicoes, w) then
                                    Writeln(w, ' -> ACEITA')
                                else 
                                    Writeln(w, ' -> REJEITA');
                            end;
                            sl.Free;
                        end;
                    end;

                    '2':
                    begin
                        Writeln('Digite palavras para testar.');
                        Writeln('- ENTER = palavra vazia (ε)');
                        Writeln('- Digite "sair" para encerrar.');
                        while True do
                        begin
                            Write('> ');
                            ReadLn(w);
                            w := Trim(w);

                            // Comando para sair
                            if LowerCase(w) = 'sair' then
                                Break;

                            // ENTER (string vazia) = palavra vazia
                            if w = '' then
                            begin
                                if TestarPalavraAFD(estados, alfabeto, estadosIniciais[0], estadosFinais, transicoes, '') then
                                    Writeln('ε -> ACEITA')
                                else
                                    Writeln('ε -> REJEITA');
                                Continue;
                            end;

                            // Qualquer outra palavra "normal"
                            if TestarPalavraAFD(estados, alfabeto, estadosIniciais[0], estadosFinais, transicoes, w) then
                                Writeln(w, ' -> ACEITA')
                            else
                                Writeln(w, ' -> REJEITA');
                        end;
                    end;
                else
                    Writeln('Opção inválida');
                end;
            end;

            //=========== (4) ===========

            '5':
            begin
                Writeln('Saindo...');
                Break;
            end;
        else
            Writeln('Opção inválida');
        end;
    end;

    data.Free;
end.
