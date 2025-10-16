unit ConverterAFNtoAFD;
interface

uses
    AFN, AFD;

function ConvertAFNtoAFD(const AFNrec: TAFN): TAFD;

implementation

function ConvertAFNtoAFD(const AFNrec: TAFN): TAFD;
var
    AFDrec: TAFD;
begin
    // Inicializar o AFD
    SetLength(AFDrec.alfabeto, Length(AFNrec.alfabeto));
    for var i := 0 to High(AFNrec.alfabeto) do
        AFDrec.alfabeto[i] := AFNrec.alfabeto[i];

    SetLength(AFDrec.estados, 0);
    SetLength(AFDrec.estadosFinais, 0);
    SetLength(AFDrec.transicoes, 0);

    // Tabela de transição do AFN, com fromState, toState (pode ser conjunto) e symbol
    afnTransitionTable: array of record
        fromState: string;
        toStates: array of string; // Pode ser um conjunto de estados
        symbol: char;
    end;
    for var i := 0 to Length(AFNrec.transicoes) - 1 do
    begin
        // Processar cada transição do AFN
        var trans := AFNrec.transicoes[i];
        // se o estado fromState já foi adicionado na tabela
        var fromStateIndex := -1;
        for var j := 0 to High(afnTransitionTable) do
        begin
            if afnTransitionTable[j].fromState = trans.fromState then
            begin
                fromStateIndex := j;
                Break;
            end;
        end;

        // Se o estado fromState não foi encontrado, adicioná-lo
        if fromStateIndex = -1 then
        begin
            SetLength(afnTransitionTable, Length(afnTransitionTable) + 1);
            fromStateIndex := High(afnTransitionTable);
            afnTransitionTable[fromStateIndex].fromState := trans.fromState;
            SetLength(afnTransitionTable[fromStateIndex].toStates, 0);
            afnTransitionTable[fromStateIndex].symbol := trans.symbol;
        end;

        // Adicionar o estado de destino à lista de estados de destino
        SetLength(afnTransitionTable[fromStateIndex].toStates,
            Length(afnTransitionTable[fromStateIndex].toStates) + 1);
        afnTransitionTable[fromStateIndex].toStates[High(afnTransitionTable[fromStateIndex].toStates)] := trans.toState;
    end;

    // Tabela de transição do AFD - Terão 2^(estados do AFN) estados possíveis
    // Cada estado do AFD será uma combinação de estados do AFN
    // Exemplo: Se o AFN tem estados {q0, q1}, o AFD terá estados { {}, {q0}, {q1}, {q0,q1} }
    
    afdTransitionTable: array of record
        fromState: string; // Combinação de estados do AFN
        toState: string;   // Combinação de estados do AFN
        symbol: char;
    end;
    // Mapeamento de estados do AFD para combinações de estados do AFN
    afdStateMap: array of record
        afdState: string; // Estado do AFD
        afnStates: array of string; // Combinação de estados do AFN
    end;

    // Função para encontrar ou adicionar um estado do AFD baseado na combinação de estados do AFN
    function GetOrAddAfdState(const afnStates: array of string): string;
    var
        stateName: string;
    begin
        // Criar nome do estado do AFD baseado na combinação de estados do AFN
        stateName := '{' + String.Join(',', afnStates) + '}';
        // Verificar se o estado já existe
        for var i := 0 to High(afdStateMap) do
        begin
            if afdStateMap[i].afdState = stateName then
            begin
                Result := stateName;
                Exit;
            end;
        end;
        // Se não existir, adicionar novo estado
        SetLength(afdStateMap, Length(afdStateMap) + 1);
        afdStateMap[High(afdStateMap)].afdState := stateName;
        afdStateMap[High(afdStateMap)].afnStates := Copy(afnStates);
        Result := stateName;
    end;

    // Encontrar os estados finais do AFD, que são aqueles que contêm pelo menos um estado final do AFN
    for var i := 0 to High(afdStateMap) do
    begin
        for var j := 0 to High(afdStateMap[i].afnStates) do
        begin
            if Pos(afdStateMap[i].afnStates[j], String.Join(',', AFNrec.estadosFinais)) > 0 then
            begin
                // Adicionar estado final do AFD
                SetLength(AFDrec.estadosFinais, Length(AFDrec.estadosFinais) + 1);
                AFDrec.estadosFinais[High(AFDrec.estadosFinais)] := afdStateMap[i].afdState;
                Break;
            end;
        end;
    end;

    // Eliminar estados inalcançáveis
    for var i := 0 to High(AFDrec.estados) do
    begin
        var reachable := False;
        for var j := 0 to High(AFDrec.transicoes) do
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
    var tempEstados: array of string;
    for var i := 0 to High(AFDrec.estados) do
    begin
        if AFDrec.estados[i] <> '' then
        begin
            SetLength(tempEstados, Length(tempEstados) + 1);
            tempEstados[High(tempEstados)] := AFDrec.estados[i];
        end;
    end;
    AFDrec.estados := Copy(tempEstados);

end.