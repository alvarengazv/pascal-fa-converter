unit ConvertAFNtoAFD;

{$mode fpc}{$H+}

interface

uses
    AFN, AFD, CommonTypes;

function ConvertAFNtoAFD(const AFNrec: TAFN): TAFD;

// Função para encontrar ou adicionar um estado do AFD baseado na combinação de estados do AFN
function GetOrAddAfdState(const afnStates: array of string): string;

function BuildStateName(const afnStates: array of string): string;

implementation

uses
    SysUtils;

type
    // Fallback se sua versão do FPC não tiver TStringArray disponível
    TStringDynArray = array of string;

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
    // canon: TStringDynArray;
begin
    // Sempre arruma o nome do conjunto (ordenação canônica desejada) para evitar que
    // subconjuntos iguais com ordens diferentes sejam tratados como distintos
    // (ex.: {p2,p0} vs {p0,p2}). A função BuildStateName cria a representação textual.

    stateName := BuildStateName(afnStates);

    // Verificar se o estado já existe
    for i := 0 to High(afdStateMap) do
    begin
        if afdStateMap[i].afdState = stateName then
          Exit(stateName);
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
    i, j, k, m, n, z, fromStateIndex, tableLines, desiredIdx, insertPos, idx: Integer;
    trans: TTransicao;
    reachable: Boolean;
    currentStates: array of string;
    afdStateName, removedState: string;

    // Tabela de transições do AFN
    afnTransitionTable: array of record
        fromState: string;
        toStates: array of string; // Pode ser um conjunto de estados
        symbol: char;
    end;

    // Tabela de transições do AFD
    afdTransitionTable: array of record
        fromState: string;
        toStates: array of string;
        symbol: char;
    end;

    var stateRenameMap: array of record
        oldName: string;
        newName: string;
    end;

begin
    WriteLn('Convertendo AFN para AFD...');

    // Algoritmo geral (construção de subconjuntos / subset construction):
    // 1) Montar uma tabela mais conveniente das transições do AFN (afnTransitionTable),
    //    onde cada linha combina um estado de origem e um símbolo, e lista todos os
    //    estados de destino possíveis (facilita iterações).
    // 2) Gerar todos os subconjuntos possíveis dos estados do AFN (2^n combinações)
    //    e criar estados correspondentes no AFD com nomes do tipo '{q0,q1}'.
    // 3) Para cada estado do AFD e cada símbolo do alfabeto, calcular o conjunto de
    //    estados destino (união das imagens das transições do AFN) e inserir a
    //    transição correspondente no AFD.
    // 4) Eliminar estados inalcançáveis, determinar estados finais do AFD e renomear
    //    os estados para uma forma mais compacta (q0, q1, ...).

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

    // Observação: usamos `afnTransitionTable` para agrupar transições por (fromState, symbol)
    // e manter para cada par a lista de `toStates`. Isso simplifica a montagem das
    // transições do AFD ao calcular a imagem de um subconjunto por um símbolo.

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

    // Observação: neste ponto `afdStateMap` contém a correspondência entre nomes do AFD
    // e os subconjuntos de estados do AFN que representam.

    // Montar a tabela de transições do AFD
    SetLength(afdTransitionTable, 0);
    // WriteLn('Montando tabela de transições do AFD...');

    // Para cada estado do AFD
    for i := 0 to High(AFDrec.estados) do
    begin
        // Para cada símbolo do alfabeto
        for j := 0 to High(AFNrec.alfabeto) do
        begin
            // Construir conjunto de estados destino do AFD
            SetLength(currentStates, 0);

            // Para cada transição do AFN
            for k := 0 to High(afnTransitionTable) do
            begin
                // Se o símbolo coincide e o estado de origem do AFN está contido no estado do AFD
                if (afnTransitionTable[k].symbol = AFNrec.alfabeto[j]) and
                   (Pos(afnTransitionTable[k].fromState, AFDrec.estados[i]) > 0) then
                begin
                    // Adicionar todos os estados de destino do AFN ao conjunto, na ordem em que aparecem, para evitar duplicados, como {q0, q1} e {q1, q0}
                    for m := 0 to High(afnTransitionTable[k].toStates) do
                    begin
                        // Verificar se o estado já está no conjunto (evitar duplicados)
                        reachable := False;
                        for n := 0 to High(currentStates) do
                        begin
                            if currentStates[n] = afnTransitionTable[k].toStates[m] then
                            begin
                                reachable := True;
                                Break;
                            end;
                        end;

                        if not reachable then
                        begin
                            // Inserir na ordem definida por AFNrec.estados (assim a ordenação {q0,q1,q2} é preservada)
                            // Encontrar o índice do estado atual em AFNrec.estados
                            
                            desiredIdx := -1;
                            for z := 0 to High(AFNrec.estados) do
                            begin
                                if AFNrec.estados[z] = afnTransitionTable[k].toStates[m] then
                                begin
                                    desiredIdx := z;
                                    Break;
                                end;
                            end;
                            if desiredIdx = -1 then
                                desiredIdx := High(AFNrec.estados) + 1; // Se não encontrado, colocar no final

                            // Determine insertion position in currentStates by comparing AFN indices
                            // Determinar a posição de inserção em currentStates comparando os índices do AFN
                            insertPos := 0;
                            while insertPos < Length(currentStates) do
                            begin
                                // find index of currentStates[insertPos] in AFNrec.estados
                                idx := -1;
                                for n := 0 to High(AFNrec.estados) do
                                begin
                                    if AFNrec.estados[n] = currentStates[insertPos] then
                                    begin
                                        idx := n;
                                        Break;
                                    end;
                                end;
                                if idx = -1 then
                                    idx := High(AFNrec.estados) + 1; // Se não encontrado, colocar no final

                                // Parar quando encontramos um índice AFN maior
                                if idx > desiredIdx then
                                    Break;

                                insertPos := insertPos + 1;
                            end;

                            // Inserrir em 'insertPos'
                            SetLength(currentStates, Length(currentStates) + 1);
                            for n := High(currentStates) downto insertPos + 1 do
                                currentStates[n] := currentStates[n - 1];
                            currentStates[insertPos] := afnTransitionTable[k].toStates[m];

                        end;
                    end;
                end;
            end;

            // Se há estados de destino, criar a transição do AFD
            if Length(currentStates) > 0 then
            begin
                SetLength(afdTransitionTable, Length(afdTransitionTable) + 1);
                afdTransitionTable[High(afdTransitionTable)].fromState := AFDrec.estados[i];
                afdTransitionTable[High(afdTransitionTable)].symbol := AFNrec.alfabeto[j];

                // Construir o nome do estado de destino do AFD
                afdStateName := GetOrAddAfdState(currentStates);
                SetLength(afdTransitionTable[High(afdTransitionTable)].toStates, 1);
                afdTransitionTable[High(afdTransitionTable)].toStates[0] := afdStateName;
            end;
        end;
    end;

    // Após construir `afdTransitionTable`, transformamos em TAFD.transicoes e seguimos
    // com a limpeza (remoção de estados inalcançáveis) e marcação dos finais.

    // Preencher as transições do AFD
    SetLength(AFDrec.transicoes, 0);
    for i := 0 to High(afdTransitionTable) do
    begin
        for j := 0 to High(afdTransitionTable[i].toStates) do
        begin
            SetLength(AFDrec.transicoes, Length(AFDrec.transicoes) + 1);
            AFDrec.transicoes[High(AFDrec.transicoes)].fromState := afdTransitionTable[i].fromState;
            AFDrec.transicoes[High(AFDrec.transicoes)].toState := afdTransitionTable[i].toStates[j];
            AFDrec.transicoes[High(AFDrec.transicoes)].symbol := afdTransitionTable[i].symbol;
        end;
    end;

    // Finalizar o AFD
    AFDrec.estadoInicial := GetOrAddAfdState(AFNrec.estadosIniciais);

    // Eliminar estados inalcançáveis
    i := 0;
    while i <= High(AFDrec.estados) do
    begin
        reachable := (AFDrec.estados[i] = AFDrec.estadoInicial);
        if not reachable then
        begin
            for j := 0 to High(AFDrec.transicoes) do
            begin
                if ((AFDrec.transicoes[j].toState = AFDrec.estados[i]) and
                    (AFDrec.transicoes[j].fromState <> AFDrec.transicoes[j].toState)) then
                begin
                    reachable := True;
                    Break;
                end;
            end;
        end;

        if reachable then
        begin
            Inc(i);
            Continue;
        end;

        removedState := AFDrec.estados[i];
        for j := i to High(AFDrec.estados) - 1 do
            AFDrec.estados[j] := AFDrec.estados[j + 1];
        SetLength(AFDrec.estados, Length(AFDrec.estados) - 1);

        j := 0;
        while j <= High(AFDrec.transicoes) do
        begin
            if (AFDrec.transicoes[j].fromState = removedState) or
               (AFDrec.transicoes[j].toState = removedState) then
            begin
                for k := j to High(AFDrec.transicoes) - 1 do
                    AFDrec.transicoes[k] := AFDrec.transicoes[k + 1];
                SetLength(AFDrec.transicoes, Length(AFDrec.transicoes) - 1);
            end
            else
                Inc(j);
        end;
        i := 0;
    end;

    // Encontrar estados finais
    for i := 0 to High(AFDrec.estados) do
    begin
        for j := 0 to High(AFNrec.estadosFinais) do
        begin
            // Verificar se o estado final do AFN está contido no conjunto de estados do AFD
            if Pos(AFNrec.estadosFinais[j], AFDrec.estados[i]) > 0 then
            begin
                // Adicionar ao conjunto de estados finais do AFD
                SetLength(AFDrec.estadosFinais, Length(AFDrec.estadosFinais) + 1);
                AFDrec.estadosFinais[High(AFDrec.estadosFinais)] := AFDrec.estados[i];
                Break;
            end;
        end;
    end;

    // Finalmente renomeamos os estados para índices sequenciais (q0, q1, ...), o que
    // torna a saída mais legível e compatível com as outras rotinas do projeto.

    // Renomear estados do AFD, para q0, q1, q2, na ordem em que aparecem

    SetLength(stateRenameMap, Length(AFDrec.estados));
    for i := 0 to High(AFDrec.estados) do
    begin
        stateRenameMap[i].oldName := AFDrec.estados[i];
        stateRenameMap[i].newName := 'q' + IntToStr(i);;
    end;

    // Aplicar renomeação nas transições
    for i := 0 to High(AFDrec.transicoes) do
    begin
        for j := 0 to High(stateRenameMap) do
        begin
            if AFDrec.transicoes[i].fromState = stateRenameMap[j].oldName then
            begin
                AFDrec.transicoes[i].fromState := stateRenameMap[j].newName;
            end;
            if AFDrec.transicoes[i].toState = stateRenameMap[j].oldName then
            begin
                AFDrec.transicoes[i].toState := stateRenameMap[j].newName;
            end;
        end;
    end;

    // Aplicar renomeação nos estados finais
    for i := 0 to High(AFDrec.estadosFinais) do
    begin
        for j := 0 to High(stateRenameMap) do
        begin
            if AFDrec.estadosFinais[i] = stateRenameMap[j].oldName then
            begin
                AFDrec.estadosFinais[i] := stateRenameMap[j].newName;
            end;
        end;
    end;

    // Aplicar renomeação no estado inicial
    for j := 0 to High(stateRenameMap) do
    begin
        if AFDrec.estadoInicial = stateRenameMap[j].oldName then
        begin
            AFDrec.estadoInicial := stateRenameMap[j].newName;
            Break;
        end;
    end;

    // Atualizar lista de estados do AFD

    for i := 0 to High(AFDrec.estados) do
    begin
        for j := 0 to High(stateRenameMap) do
        begin
            if AFDrec.estados[i] = stateRenameMap[j].oldName then
            begin
                AFDrec.estados[i] := stateRenameMap[j].newName;
            end;
        end;
    end;

    // Printar o AFD renomeado
    WriteLn('AFD Renomeado:');
    for i := 0 to High(AFDrec.estados) do
        WriteLn('Estado: ', AFDrec.estados[i]);
    WriteLn('Estado Inicial: ', AFDrec.estadoInicial);
    WriteLn('Estados Finais: ');
    for i := 0 to High(AFDrec.estadosFinais) do
        WriteLn(AFDrec.estadosFinais[i]);
    WriteLn('Transições: ');
    for i := 0 to High(AFDrec.transicoes) do
    begin
        WriteLn('From: ', AFDrec.transicoes[i].fromState,
                ' To: ', AFDrec.transicoes[i].toState,
                ' Symbol: ', AFDrec.transicoes[i].symbol);
    end;

    ConvertAFNtoAFD := AFDrec;
end;
end.