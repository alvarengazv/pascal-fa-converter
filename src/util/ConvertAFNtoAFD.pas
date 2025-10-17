unit ConvertAFNtoAFD;
interface

uses
    AFN, AFD, CommonTypes;

function ConvertAFNtoAFD(const AFNrec: TAFN): TAFD;

// Função para encontrar ou adicionar um estado do AFD baseado na combinação de estados do AFN
function GetOrAddAfdState(const afnStates: array of string): string;

function BuildStateName(const afnStates: array of string): string;

implementation

type
    TAFDStateMap = record
        afdState: string;
        afnStates: array of string;
    end;

var
    afdStateMap: array of TAFDStateMap;

function GetOrAddAfdState(const afnStates: array of string): string;
var
    stateName: string;
    i: Integer;
begin
    // Criar nome do estado do AFD baseado na combinação de estados do AFN
    stateName := BuildStateName(afnStates);
    // Verificar se o estado já existe
    for i := 0 to High(afdStateMap) do
    begin
        if afdStateMap[i].afdState = stateName then
        exit(stateName);
    end;
    // Se não existir, adicionar novo estado
    SetLength(afdStateMap, Length(afdStateMap) + 1);
    afdStateMap[High(afdStateMap)].afdState := stateName;
    SetLength(afdStateMap[High(afdStateMap)].afnStates, Length(afnStates));
    for i := 0 to High(afnStates) do
        afdStateMap[High(afdStateMap)].afnStates[i] := afnStates[i];
        
    GetOrAddAfdState := stateName;

end;

function BuildStateName(const afnStates: array of string): string;
var
    idx: Integer;
    name: string;
begin
    name := '{';
    for idx := 0 to High(afnStates) do
    begin
        name := name + afnStates[idx];
        if idx < High(afnStates) then
        name := name + ',';
    end;
    name := name + '}';
    BuildStateName := name;
end;

function ConvertAFNtoAFD(const AFNrec: TAFN): TAFD;
var
    AFDrec: TAFD;
    i, j, k, m, fromStateIndex, tableLines: Integer;
    trans: TTransicao;
    reachable: Boolean;
    tempEstados, currentStates: array of string;
    afdStateName: string;
    
    // Tabela de transições do AFN
    afnTransitionTable: array of record
        fromState: string;
        toStates: array of string; // Pode ser um conjunto de estados
        symbol: char;
    end;

    // Tabela de transições do AFD
    afdTransitionTable: array of record
        fromState: string;
        toState: array of string;
        symbol: char;
    end;
        

begin
WriteLn('Convertendo AFN para AFD...');
    // Inicializar o AFD
    SetLength(AFDrec.alfabeto, Length(AFNrec.alfabeto));
    for i := 0 to High(AFNrec.alfabeto) do
        AFDrec.alfabeto[i] := AFNrec.alfabeto[i];
    
    SetLength(AFDrec.estados, 0);
    SetLength(AFDrec.estadosFinais, 0);
    SetLength(AFDrec.transicoes, 0);

    // Tabela de transição do AFN, com fromState, toState (pode ser conjunto) e symbol
    // Começar com uma tabela vazia
    SetLength(afnTransitionTable, 0);

    // Preencher a tabela de transições do AFN
    for i := 0 to High(AFNrec.transicoes) do
    begin
        WriteLn('Processando transição ', i);
        WriteLn('DEBUG: ', AFNrec.transicoes[i].fromState, ' ',
                        AFNrec.transicoes[i].toState, ' ',
                        Ord(AFNrec.transicoes[i].symbol));
        // Processar cada transição do AFN
        trans := AFNrec.transicoes[i];
        
        // Procurar se já existe entrada para o fromState e symbol
        fromStateIndex := -1;
        for j := 0 to High(afnTransitionTable) do
        begin
            if (afnTransitionTable[j].fromState = trans.fromState) and
                (afnTransitionTable[j].symbol = trans.symbol) then
            begin
                fromStateIndex := j;
                Break;
            end;
        end;

        // Se o estado fromState+symbol não foi encontrado, adicioná-lo
        if fromStateIndex = -1 then
        begin
            SetLength(afnTransitionTable, Length(afnTransitionTable) + 1);
            fromStateIndex := High(afnTransitionTable);
            afnTransitionTable[fromStateIndex].fromState := trans.fromState;
            afnTransitionTable[fromStateIndex].symbol := trans.symbol;
            SetLength(afnTransitionTable[fromStateIndex].toStates, 0);
        end;

        // Adicionar o estado de destino à lista de estados de destino
        with afnTransitionTable[fromStateIndex] do
        begin
            SetLength(toStates, Length(toStates) + 1);
            toStates[High(toStates)] := trans.toState;
        end;
    end;

    // Debug: imprimir tabela de transições do AFN
    for i := 0 to High(afnTransitionTable) do
    begin
        WriteLn('From State: ', afnTransitionTable[i].fromState,
                ' Symbol: ', afnTransitionTable[i].symbol,
                ' To States: ');
        for j := 0 to High(afnTransitionTable[i].toStates) do
            Write(afnTransitionTable[i].toStates[j], ' ');
        WriteLn;
    end;

    // Tabela de transição do AFD - Terão 2^(estados do AFN) estados possíveis
    // Cada estado do AFD será uma combinação de estados do AFN
    
    tableLines := 1 shl Length(AFNrec.estados); // 2^n combinações
    SetLength(currentStates, 0);

    // Encontrar os Estados do AFD:
    // Exemplo: Se o AFN tem estados {q0, q1}, o AFD terá estados { {}, {q0}, {q1}, {q0,q1} }

    for i := 0 to tableLines - 1 do
    begin
        SetLength(currentStates, 0);
        for j := 0 to High(AFNrec.estados) do
        begin
            if (i and (1 shl j)) <> 0 then
            begin
                SetLength(currentStates, Length(currentStates) + 1);
                currentStates[High(currentStates)] := AFNrec.estados[j];
            end;
        end;
        // Obter ou adicionar o estado do AFD baseado na combinação de estados do AFN
        afdStateName := GetOrAddAfdState(currentStates);
        // Adicionar ao conjunto de estados do AFD
        SetLength(AFDrec.estados, Length(AFDrec.estados) + 1);
        AFDrec.estados[High(AFDrec.estados)] := afdStateName;
    end;

    // Debug: imprimir estados do AFD
    WriteLn('Estados do AFD:');
    for i := 0 to High(AFDrec.estados) do
        WriteLn(AFDrec.estados[i]);

    // Montar a tabela de transições do AFD
    SetLength(afdTransitionTable, 0);
    for i := 0 to High(AFDrec.estados) do
    begin
        for j := 0 to High(AFDrec.estados[i]) do
        begin
            for k := 0 to High(afnTransitionTable) do
            begin
                if (afnTransitionTable[k].fromState = AFDrec.estados[i][j]) then
                begin
                    // Se o estado de origem do AFN está na combinação do estado do AFD
                    // Adicionar transições para cada símbolo
                    // ... completar lógica para preencher a tabela de transições do AFD
                    // Exemplo:
                    WriteLn('Adicionando transição do AFD para estado ', AFDrec.estados[i], ' com símbolo ', afnTransitionTable[k].symbol);
                    SetLength(afdTransitionTable, Length(afdTransitionTable) + 1);
                    with afdTransitionTable[High(afdTransitionTable)] do
                    begin
                        fromState := AFDrec.estados[i][j];
                        symbol := afnTransitionTable[k].symbol;
                        // Combinar os estados de destino do AFN
                        for m := 0 to High(afnTransitionTable[k].toStates) do
                        begin
                            SetLength(afdTransitionTable[High(afdTransitionTable)].toState, Length(afdTransitionTable[High(afdTransitionTable)].toState) + 1);
                            afdTransitionTable[High(afdTransitionTable)].toState[High(afdTransitionTable[High(afdTransitionTable)].toState)] := afnTransitionTable[k].toStates[m];
                        end;
                    end;
                end;
            end;
        end;
    end;

    // Debug: imprimir tabela de transições do AFD
    WriteLn('Tabela de Transições do AFD:');
    for i := 0 to High(afdTransitionTable) do
    begin
        WriteLn('From State: ', afdTransitionTable[i].fromState,
                ' Symbol: ', afdTransitionTable[i].symbol,
                ' To States: ');
        for j := 0 to High(afdTransitionTable[i].toState) do
            Write(afdTransitionTable[i].toState[j], ' ');
        WriteLn;
    end;

    // Encontrar os estados finais do AFD, que são aqueles que contêm pelo menos um estado final do AFN

    // Eliminar estados inalcançáveis
    for i := 0 to High(AFDrec.estados) do
    begin
        reachable := False;
        for j := 0 to High(AFDrec.transicoes) do
        begin
            if AFDrec.transicoes[j].fromState = AFDrec.estados[i] then
            begin
                reachable := True;
                Break;
            end;
        end;
        if not reachable then
        begin
            // Remover estado inalcançável
            AFDrec.estados[i] := '';
        end;
    end;

    // Remover entradas vazias
    tempEstados := [];
    for i := 0 to High(AFDrec.estados) do
    begin
        if AFDrec.estados[i] <> '' then
        begin
            SetLength(tempEstados, Length(tempEstados) + 1);
            tempEstados[High(tempEstados)] := AFDrec.estados[i];
        end;
    end;

    AFDrec.estados := Copy(tempEstados, 0, Length(tempEstados));
    ConvertAFNtoAFD := AFDrec;
end;
end.