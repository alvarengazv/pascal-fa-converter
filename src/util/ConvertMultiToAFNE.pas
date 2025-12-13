unit ConvertMultiToAFNE;

{$mode fpc}{$H+}

interface

uses
    AFN, CommonTypes, SysUtils;

function ConvertMultiToAFNE(const inputAFN: TAFN): TAFN;

implementation

function ConvertMultiToAFNE(const inputAFN: TAFN): TAFN;
var
    outputAFN: TAFN;
    i, j: Integer;
    newInitialState: string;
    epsilonExists: Boolean;
begin
    Writeln('Iniciando conversao de AFN multiestado inicial para AFN-&...');
    
    // Verificar se realmente tem múltiplos estados iniciais
    if Length(inputAFN.estadosIniciais) <= 1 then
    begin
        Writeln('AVISO: O automato nao possui multiplos estados iniciais.');
        ConvertMultiToAFNE := inputAFN;
        Exit;
    end;
    
    // 1. Criar nome para o novo estado inicial único
    // Garantir que o nome não conflite com estados existentes
    newInitialState := 'q_init';
    i := 0;
    while True do
    begin
        epsilonExists := False;
        for j := 0 to High(inputAFN.estados) do
        begin
            if inputAFN.estados[j] = newInitialState then
            begin
                epsilonExists := True;
                Break;
            end;
        end;
        
        if not epsilonExists then
            Break;
            
        Inc(i);
        newInitialState := 'q_init' + IntToStr(i);
    end;
    
    Writeln('Novo estado inicial criado: ', newInitialState);
    
    // 2. Copiar alfabeto (adicionar & se não existir)
    epsilonExists := False;
    for i := 0 to High(inputAFN.alfabeto) do
    begin
        if inputAFN.alfabeto[i] = '&' then
        begin
            epsilonExists := True;
            Break;
        end;
    end;
    
    if epsilonExists then
    begin
        // Alfabeto já contém &, apenas copiar
        SetLength(outputAFN.alfabeto, Length(inputAFN.alfabeto));
        for i := 0 to High(inputAFN.alfabeto) do
            outputAFN.alfabeto[i] := inputAFN.alfabeto[i];
    end
    else
    begin
        // Adicionar & ao alfabeto
        SetLength(outputAFN.alfabeto, Length(inputAFN.alfabeto) + 1);
        for i := 0 to High(inputAFN.alfabeto) do
            outputAFN.alfabeto[i] := inputAFN.alfabeto[i];
        outputAFN.alfabeto[High(outputAFN.alfabeto)] := '&';
    end;
    
    // 3. Copiar estados + adicionar novo estado inicial
    SetLength(outputAFN.estados, Length(inputAFN.estados) + 1);
    outputAFN.estados[0] := newInitialState;
    for i := 0 to High(inputAFN.estados) do
        outputAFN.estados[i + 1] := inputAFN.estados[i];
    
    // 4. Definir novo estado inicial único
    SetLength(outputAFN.estadosIniciais, 1);
    outputAFN.estadosIniciais[0] := newInitialState;
    
    // 5. Copiar estados finais (inalterados)
    SetLength(outputAFN.estadosFinais, Length(inputAFN.estadosFinais));
    for i := 0 to High(inputAFN.estadosFinais) do
        outputAFN.estadosFinais[i] := inputAFN.estadosFinais[i];
    
    // 6. Copiar transições existentes + adicionar transições epsilon
    SetLength(outputAFN.transicoes, Length(inputAFN.transicoes) + Length(inputAFN.estadosIniciais));
    
    // Copiar transições originais
    for i := 0 to High(inputAFN.transicoes) do
        outputAFN.transicoes[i] := inputAFN.transicoes[i];
    
    // Adicionar transições epsilon do novo estado inicial para cada estado inicial original
    for i := 0 to High(inputAFN.estadosIniciais) do
    begin
        j := Length(inputAFN.transicoes) + i;
        outputAFN.transicoes[j].fromState := newInitialState;
        outputAFN.transicoes[j].toState := inputAFN.estadosIniciais[i];
        outputAFN.transicoes[j].symbol := '&';
        
        Writeln('Adicionada transicao epsilon: ', newInitialState, ' -> ', inputAFN.estadosIniciais[i]);
    end;
    
    // 7. Definir flags do resultado
    outputAFN.isAFN := True;
    outputAFN.isAFN_E := True;  // Agora tem transições epsilon
    outputAFN.isAFN_Multiestado_Inicial := False;  // Agora tem apenas um estado inicial
    
    Writeln('Conversao concluida com sucesso!');
    Writeln('Estados totais: ', Length(outputAFN.estados));
    Writeln('Transicoes totais: ', Length(outputAFN.transicoes));
    
    ConvertMultiToAFNE := outputAFN;
end;

end.
