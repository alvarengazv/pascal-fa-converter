unit ConvertAFNEtoAFN;

{$mode fpc}{$H+}

interface

uses
    AFN, CommonTypes, SysUtils;

function ConvertAFNEtoAFN(const inputAFN: TAFN): TAFN;

implementation

// Verifica se um estado está na lista 
function ArrayContains(const arr: array of string; const val: string): Boolean;
var
    i: Integer;
begin
    ArrayContains := False;
    for i := 0 to High(arr) do
    begin
        if arr[i] = val then
        begin
            ArrayContains := True;
            Exit;
        end;
    end;
end;


function ConvertAFNEtoAFN(const inputAFN: TAFN): TAFN;
var
    outputAFN: TAFN;
    i, j, k, tIdx, idxC: Integer;
    q, s, neighbor: string; 
    symbol: char;
    
    // Mapa de Fecho Lambda: Estado -> Lista de Estados alcançáveis por &
    lambdaClosures: array of record
        state: string;
        closure: array of string;
    end;
    
    // Variáveis para o cálculo do Fecho (DFS/Stack)
    stack: array of string;
    closureQ: array of string;
    currentState: string;
    
    // Variáveis para cálculo de novas transições
    statesFromClosure: array of string; 
    intermediateStates: array of string; 
    finalDestinations: array of string; 
    
    // Variável temporária
    isFinal: Boolean;
    exists: Boolean;
    
begin
    Writeln('Iniciando conversao de AFN-& para AFN...');

    // 1. Inicialização e Cópia Básica
    SetLength(outputAFN.estados, Length(inputAFN.estados));
    for i := 0 to High(inputAFN.estados) do
        outputAFN.estados[i] := inputAFN.estados[i];

    // Copiar alfabeto removendo o '&'
    SetLength(outputAFN.alfabeto, 0);
    for i := 0 to High(inputAFN.alfabeto) do
    begin
        if inputAFN.alfabeto[i] <> '&' then
        begin
            SetLength(outputAFN.alfabeto, Length(outputAFN.alfabeto) + 1);
            outputAFN.alfabeto[High(outputAFN.alfabeto)] := inputAFN.alfabeto[i];
        end;
    end;

    // Inicializar estruturas
    SetLength(outputAFN.transicoes, 0);
    SetLength(outputAFN.estadosIniciais, 0);
    SetLength(outputAFN.estadosFinais, 0);
    SetLength(lambdaClosures, Length(inputAFN.estados));

    // 2. Calcular Fecho-Lambda
    for i := 0 to High(inputAFN.estados) do
    begin
        q := inputAFN.estados[i];
        lambdaClosures[i].state := q;
        SetLength(lambdaClosures[i].closure, 0);
        
        // Inicializa pilha e closure com o próprio estado
        SetLength(stack, 1);
        stack[0] := q;
        SetLength(closureQ, 0);

        while Length(stack) > 0 do
        begin
            currentState := stack[High(stack)];
            SetLength(stack, Length(stack) - 1);

            if not ArrayContains(closureQ, currentState) then
            begin
                // Adicionar ao closureQ
                SetLength(closureQ, Length(closureQ) + 1);
                closureQ[High(closureQ)] := currentState;

                // Buscar vizinhos via transição '&'
                for tIdx := 0 to High(inputAFN.transicoes) do
                begin
                    if (inputAFN.transicoes[tIdx].fromState = currentState) and 
                       (inputAFN.transicoes[tIdx].symbol = '&') then
                    begin
                        neighbor := inputAFN.transicoes[tIdx].toState;
                        if not ArrayContains(closureQ, neighbor) then
                        begin
                            SetLength(stack, Length(stack) + 1);
                            stack[High(stack)] := neighbor;
                        end;
                    end;
                end;
            end;
        end;
        lambdaClosures[i].closure := closureQ;
    end;

    // 3. Calcular Novas Transições
    for i := 0 to High(inputAFN.estados) do
    begin
        q := inputAFN.estados[i];
        statesFromClosure := lambdaClosures[i].closure;

        for j := 0 to High(outputAFN.alfabeto) do
        begin
            symbol := outputAFN.alfabeto[j];
            SetLength(intermediateStates, 0);

            
            for k := 0 to High(statesFromClosure) do
            begin
                s := statesFromClosure[k];
                for tIdx := 0 to High(inputAFN.transicoes) do
                begin
                    if (inputAFN.transicoes[tIdx].fromState = s) and 
                       (inputAFN.transicoes[tIdx].symbol = symbol) then
                    begin
                        
                        if not ArrayContains(intermediateStates, inputAFN.transicoes[tIdx].toState) then
                        begin
                            SetLength(intermediateStates, Length(intermediateStates) + 1);
                            intermediateStates[High(intermediateStates)] := inputAFN.transicoes[tIdx].toState;
                        end;
                    end;
                end;
            end;

            // Fecho dos intermediários
            SetLength(finalDestinations, 0);
            for k := 0 to High(intermediateStates) do
            begin
                neighbor := intermediateStates[k];
                for tIdx := 0 to High(lambdaClosures) do
                begin
                    if lambdaClosures[tIdx].state = neighbor then
                    begin
                        
                        for idxC := 0 to High(lambdaClosures[tIdx].closure) do
                        begin
                            if not ArrayContains(finalDestinations, lambdaClosures[tIdx].closure[idxC]) then
                            begin
                                SetLength(finalDestinations, Length(finalDestinations) + 1);
                                finalDestinations[High(finalDestinations)] := lambdaClosures[tIdx].closure[idxC];
                            end;
                        end;
                        Break;
                    end;
                end;
            end;

            // Adicionar transições
            for k := 0 to High(finalDestinations) do
            begin
                // Verificar se a transição já existe para evitar duplicatas exatas
                exists := False;
                for tIdx := 0 to High(outputAFN.transicoes) do
                begin
                    if (outputAFN.transicoes[tIdx].fromState = q) and
                       (outputAFN.transicoes[tIdx].toState = finalDestinations[k]) and
                       (outputAFN.transicoes[tIdx].symbol = symbol) then
                    begin
                        exists := True;
                        Break;
                    end;
                end;

                if not exists then
                begin
                    SetLength(outputAFN.transicoes, Length(outputAFN.transicoes) + 1);
                    outputAFN.transicoes[High(outputAFN.transicoes)].fromState := q;
                    outputAFN.transicoes[High(outputAFN.transicoes)].toState := finalDestinations[k];
                    outputAFN.transicoes[High(outputAFN.transicoes)].symbol := symbol;
                end;
            end;
        end;
    end;

    Writeln('Novas transicoes calculadas: ', Length(outputAFN.transicoes));

    // 4. Novos Estados Iniciais
    
    SetLength(outputAFN.estadosIniciais, Length(inputAFN.estadosIniciais));
    for i := 0 to High(inputAFN.estadosIniciais) do
    begin
        outputAFN.estadosIniciais[i] := inputAFN.estadosIniciais[i];
    end;

    // 5. Novos Estados Finais

    SetLength(outputAFN.estadosFinais, 0);
    for i := 0 to High(inputAFN.estados) do
    begin
        q := inputAFN.estados[i];
        isFinal := False;
        statesFromClosure := lambdaClosures[i].closure;

        for j := 0 to High(statesFromClosure) do
        begin
            if ArrayContains(inputAFN.estadosFinais, statesFromClosure[j]) then
            begin
                isFinal := True;
                Break;
            end;
        end;

        if isFinal then
        begin
            if not ArrayContains(outputAFN.estadosFinais, q) then
            begin
                SetLength(outputAFN.estadosFinais, Length(outputAFN.estadosFinais) + 1);
                outputAFN.estadosFinais[High(outputAFN.estadosFinais)] := q;
            end;
        end;
    end;

    // 6. Finalizar Flags
    outputAFN.isAFN := True;
    outputAFN.isAFN_E := False;

    Writeln('Conversao concluida.');
    ConvertAFNEtoAFN := outputAFN;
end;

end.