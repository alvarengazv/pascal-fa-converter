unit TestarPalavraMultiEstadoInicial;

{$mode fpc}{$H+}

interface

uses
  CommonTypes;

// Testa se uma palavra é aceita por um autômato com múltiplos estados iniciais
// Esta função realiza uma simulação estilo AFN (não determinístico) e inclui transições ε ('&').
// Parâmetros:
//  - estados: vetor com os nomes dos estados do autômato
//  - alfabeto: vetor com os símbolos do alfabeto (cada símbolo é um char)
//  - estadosIniciais: vetor contendo os nomes dos estados iniciais (pode ter mais de um)
//  - estadosFinais: vetor contendo os nomes dos estados finais
//  - trans: vetor de transições (TTransicao com fromState, toState, symbol)
//  - palavra: a palavra a ser testada (string)
function TestarPalavraMultiEstadoInicial_(const estados: array of string; const alfabeto: array of char; const estadosIniciais: array of string; const estadosFinais: array of string; const trans: array of TTransicao; const palavra: string): Boolean;

implementation

type
  // Máscaras booleanas para representar conjuntos de estados ativos (curMask, nextMask)
  IntMatriz = array of array of Integer;

// Retorna o índice de uma string em um vetor de strings, ou -1 se não existir
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

// Retorna o índice de um char em um vetor de char, ou -1 se não existir
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

// Expande por transições epsilon ('&') a partir do conjunto fornecido (fecho-epsilon).
procedure ExpandEpsilonGlobal(const estados: array of string; const trans: array of TTransicao; var mask: array of Boolean);
var
  changed: Boolean;
  tt, fromIdx, toIdx: Integer;
begin
  if Length(mask) = 0 then Exit;
  repeat
    changed := False;
    for tt := 0 to High(trans) do
    begin
      if trans[tt].symbol = '&' then
      begin
        fromIdx := IndexOfStr(estados, trans[tt].fromState);
        toIdx := IndexOfStr(estados, trans[tt].toState);
        if (fromIdx >= 0) and (toIdx >= 0) and mask[fromIdx] and (not mask[toIdx]) then
        begin
          mask[toIdx] := True;
          changed := True;
        end;
      end;
    end;
  until not changed;
end;

function TestarPalavraMultiEstadoInicial_(const estados: array of string; const alfabeto: array of char; const estadosIniciais: array of string; const estadosFinais: array of string; const trans: array of TTransicao; const palavra: string): Boolean;
var
  // curMask: estados atualmente alcançáveis após processar prefixo da palavra
  // nextMask: estados alcançáveis após consumir o próximo símbolo
  // finalsMask: marca quais índices correspondem a estados finais
  curMask, nextMask, finalsMask: array of Boolean;
  i, t, fidx, tidx, symi: Integer;
begin
  // Visão geral:
  // - Representamos conjuntos de estados através de máscaras booleanas (arrays de Boolean).
  // - `curMask` contém os estados alcançáveis no momento atual (inicialmente os estados iniciais
  //    expandidos por ε). Para cada símbolo da palavra, calculamos `nextMask` a partir de `curMask`
  //    aplicando transições com o símbolo e então expandimos por transições ε novamente.
  // - Ao final, aceitamos se algum estado em `curMask` for final.

  // valor padrão: rejeita
  TestarPalavraMultiEstadoInicial_ := False;

  // se não há estados definidos, rejeita imediatamente
  if Length(estados) = 0 then Exit;

  // inicializa as máscaras com tamanho igual ao número de estados
  SetLength(curMask, Length(estados));
  SetLength(nextMask, Length(estados));
  SetLength(finalsMask, Length(estados));
  for i := 0 to High(curMask) do
  begin
    curMask[i] := False;
    nextMask[i] := False;
    finalsMask[i] := False;
  end;

  // Marca como ativas (curMask) todas as posições correspondentes aos estados iniciais
  for i := 0 to High(estadosIniciais) do
  begin
    fidx := IndexOfStr(estados, estadosIniciais[i]);
    if fidx >= 0 then curMask[fidx] := True;
  end;

  // Expande estados iniciais por transições epsilon (fecho-epsilon)
  ExpandEpsilonGlobal(estados, trans, curMask);

  // Se nenhum estado inicial válido foi marcado, rejeita
  t := 0; for i := 0 to High(curMask) do if curMask[i] then Inc(t);
  if t = 0 then Exit;

  // Prepara a máscara de estados finais para checagem rápida ao final
  for i := 0 to High(estadosFinais) do
  begin
    tidx := IndexOfStr(estados, estadosFinais[i]);
    if tidx >= 0 then finalsMask[tidx] := True;
  end;

  // Simula passo a passo o autômato não-determinístico para cada símbolo da palavra
  for i := 1 to Length(palavra) do
  begin
    // Verifica se o símbolo pertence ao alfabeto; se não, rejeita
    symi := IndexOfChar(alfabeto, palavra[i]);
    if symi < 0 then Exit;

    // Limpa nextMask antes de calcular os próximos estados
    for t := 0 to High(nextMask) do nextMask[t] := False;

    // Para cada transição: se o estado origem estiver ativo e o símbolo coincidir,
    // marca o estado destino como alcançável em nextMask.
    for t := 0 to High(trans) do
    begin
      fidx := IndexOfStr(estados, trans[t].fromState);
      tidx := IndexOfStr(estados, trans[t].toState);
      if (fidx >= 0) and (tidx >= 0) and (trans[t].symbol = palavra[i]) then
      begin
        if curMask[fidx] then nextMask[tidx] := True;
      end;
    end;

    // Após mover por símbolos, também expandir por transições epsilon a partir dos estados alcançados
    ExpandEpsilonGlobal(estados, trans, nextMask);

    // Se não houver estados alcançáveis após o símbolo, rejeita (nenhuma execução vitoriosa)
    t := 0; for fidx := 0 to High(nextMask) do if nextMask[fidx] then Inc(t);
    if t = 0 then Exit;

    // Copia nextMask para curMask para prosseguir com o próximo símbolo
    for fidx := 0 to High(curMask) do curMask[fidx] := nextMask[fidx];
  end;

  // Se depois de consumir toda a palavra qualquer estado atual for final, aceita
  for i := 0 to High(curMask) do
    if curMask[i] and finalsMask[i] then
    begin
      TestarPalavraMultiEstadoInicial_ := True; Exit;
    end;
end;

end.