{$mode fpc}
program main;

uses
    SysUtils, Classes, fpjson, jsonparser, ConvertAFNtoAFD, AFN, AFD, CommonTypes;

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
  i: Integer;
  j: Integer;
  k: Integer;
  count: Integer;
  
  item: TJSONData;
  innerObj: TJSONObject;
  innerArr: TJSONArray;
  s: string;
  isAFD: Boolean;
  isAFN: Boolean;
  isAFN_E: Boolean;
  isAFN_Multiestado_Inicial: Boolean;

procedure ShowMenu;
begin
    Writeln('Menu:');
    Writeln('0. Converter multiestado inicial em AFN-&');
    Writeln('1. Converter AFN-& em AFN');
    Writeln('2. Converter AFN em AFD');
    Writeln('3. Minimizar AFD');
    Writeln('4. Testar palavras');
    Writeln('5. Sair');
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
                alfabeto[i] := jsonArr.Strings[i][1]; // pega primeiro caractere
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
                        // Expecting [fromState, toState, symbol]
                        innerArr := TJSONArray(item);
                        begin
                            transicoes[i].fromState := innerArr.Strings[0];
                            transicoes[i].toState   := innerArr.Strings[1];
                            transicoes[i].symbol    := innerArr.Strings[2][1];

                            // Se a transição for com símbolo '&' e o autômato não for AFN de multiestado inicial, marcar como AFN-E
                            if (transicoes[i].symbol = '&') and (not isAFN_Multiestado_Inicial) then
                                isAFN_E := True;

                            // Se existe mais de uma transição para o mesmo estado de origem e símbolo, é um AFN
                            if not isAFN_Multiestado_Inicial and not isAFN_E and (not isAFN) then
                            begin
                              count := 0;
                              for j := 0 to jsonArr.Count - 1 do
                              begin
                                if (transicoes[j].fromState = transicoes[i].fromState) and (transicoes[j].symbol = transicoes[i].symbol) then
                                      Inc(count);
                                if (count > 1) and (not isAFN) then
                                begin
                                    isAFN := True;
                                    Break;
                                end;
                              end;
                              
                            end;
                        end
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

    WriteLn('Quantidade de Transições: ', Length(transicoes));
    for i := 0 to High(transicoes) do
        WriteLn('De ', transicoes[i].fromState, ' para ', transicoes[i].toState, ' com símbolo ', transicoes[i].symbol); 


    if (not isAFN) and (not isAFN_E) and (not isAFN_Multiestado_Inicial) then
        isAFD := True;

    if isAFN_Multiestado_Inicial then
        Writeln('O autômato é um AFN de multiestado inicial')
    else if isAFN_E then
        Writeln('O autômato é um AFN-&')
    else if isAFN then
        Writeln('O autômato é um AFN')
    else
        Writeln('O autômato é um AFD');

    // Loop do menu
    while True do
    begin
        ShowMenu;
        Write('Escolha uma opção: ');
        Readln(choice);
        case choice of
            '0': Writeln('Função 0 selecionada');
            '1': Writeln('Função 1 selecionada');
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
                    // Writeln('AFD Resultante:');
                    // Writeln('Estados: ', Length(afd_result.estados));
                    // Writeln('Estado Inicial: ', afd_result.estadoInicial);
                    // Writeln('Estados Finais: ');
                    // for i := 0 to High(afd_result.estadosFinais) do
                    //     Write(afd_result.estadosFinais[i], ' ');
                    // Writeln;
                    // Writeln('Transições: ', Length(afd_result.transicoes));
                    // for i := 0 to High(afd_result.transicoes) do
                    //     Writeln('De ', afd_result.transicoes[i].fromState, ' para ', afd_result.transicoes[i].toState, ' com símbolo ', afd_result.transicoes[i].symbol);
                end
                else
                    Writeln('O autômato já é um AFD, não é necessário converter.');
            end;
            '3': Writeln('Função 3 selecionada');
            '4':
            begin
                Writeln('Função 4 selecionada');
                Writeln('1 Via Arquivo');
                Writeln('2 Via Terminal');
                Write('Escolha uma opcao: ');
                Readln(subchoice);
                case subchoice of
                    '1': Writeln('Função 1 selecionada');
                    '2': Writeln('Função 2 selecionada');
                else
                    Writeln('Opção inválida');
                end;
            end;
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
