unit TestarPalavraAFN_E;

{$mode fpc}{$H+}

interface

uses
  CommonTypes;

// Testa palavra em AFN com transições ε ('&') e único estado inicial
function TestarPalavraAFN_E_(const estados: array of string; const alfabeto: array of char; const estadoInicial: string; const estadosFinais: array of string; const trans: array of TTransicao; const palavra: string): Boolean;

implementation

function IndexOfStr(const arr: array of string; const s: string): Integer;
var i: Integer;
begin
  for i := 0 to High(arr) do
    if arr[i] = s then
    begin
      IndexOfStr := i; Exit;
    end;
  IndexOfStr := -1;
end;

// Expande por transições epsilon ('&') a partir do conjunto fornecido (fecho-epsilon).
procedure ExpandEpsilonLocal(const estados: array of string; const trans: array of TTransicao; var mask: array of Boolean);
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

function TestarPalavraAFN_E_(const estados: array of string; const alfabeto: array of char; const estadoInicial: string; const estadosFinais: array of string; const trans: array of TTransicao; const palavra: string): Boolean;
var
  curMask, nextMask, finalsMask: array of Boolean;
  i, t, fidx, tidx, symi: Integer;
begin
  // Visão geral para AFN com ε:
  // - Começamos marcando o estado inicial e expandimos por ε (fecho-epsilon) para incluir
  //   estados alcançáveis gratuitamente antes de ler qualquer símbolo.
  // - Para cada símbolo construímos `nextMask` a partir de `curMask` por transições que
  //   correspondam ao símbolo e, em seguida, expandimos `nextMask` por ε novamente.
  // - Se em qualquer passo não houver estados alcançáveis, a palavra é rejeitada.

  TestarPalavraAFN_E_ := False;
  if Length(estados) = 0 then Exit;

  SetLength(curMask, Length(estados));
  SetLength(nextMask, Length(estados));
  SetLength(finalsMask, Length(estados));
  for i := 0 to High(curMask) do
  begin
    curMask[i] := False; nextMask[i] := False; finalsMask[i] := False;
  end;

  fidx := IndexOfStr(estados, estadoInicial);
  if fidx < 0 then Exit;
  curMask[fidx] := True;

  // expande ε a partir do inicial
  ExpandEpsilonLocal(estados, trans, curMask);

  for i := 0 to High(estadosFinais) do
  begin
    tidx := IndexOfStr(estados, estadosFinais[i]);
    if tidx >= 0 then finalsMask[tidx] := True;
  end;

  for i := 1 to Length(palavra) do
  begin
    symi := -1; // not used directly but keep parity
    // verifica símbolo no alfabeto
    for t := 0 to High(alfabeto) do if alfabeto[t] = palavra[i] then symi := t;
    if symi < 0 then Exit;

    for t := 0 to High(nextMask) do nextMask[t] := False;

    for t := 0 to High(trans) do
    begin
      fidx := IndexOfStr(estados, trans[t].fromState);
      tidx := IndexOfStr(estados, trans[t].toState);
      if (fidx >= 0) and (tidx >= 0) and (trans[t].symbol = palavra[i]) then
      begin
        if curMask[fidx] then nextMask[tidx] := True;
      end;
    end;

    // expande ε a partir dos alcançados
    ExpandEpsilonLocal(estados, trans, nextMask);

    t := 0; for fidx := 0 to High(nextMask) do if nextMask[fidx] then Inc(t);
    if t = 0 then Exit;

    for fidx := 0 to High(curMask) do curMask[fidx] := nextMask[fidx];
  end;

  for i := 0 to High(curMask) do
    if curMask[i] and finalsMask[i] then
    begin
      TestarPalavraAFN_E_ := True; Exit;
    end;
end;

end.