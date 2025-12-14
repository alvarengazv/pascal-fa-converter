unit TestarPalavraAFN;

{$mode fpc}{$H+}

interface

uses
  CommonTypes;

// Testa palavra em AFN (não determinístico) com único estado inicial (sem ε)
function TestarPalavraAFN_(const estados: array of string; const alfabeto: array of char; const estadoInicial: string; const estadosFinais: array of string; const trans: array of TTransicao; const palavra: string): Boolean;

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

function IndexOfChar(const arr: array of char; const c: char): Integer;
var i: Integer;
begin
  for i := 0 to High(arr) do
    if arr[i] = c then
    begin
      IndexOfChar := i; Exit;
    end;
  IndexOfChar := -1;
end;

function TestarPalavraAFN_(const estados: array of string; const alfabeto: array of char; const estadoInicial: string; const estadosFinais: array of string; const trans: array of TTransicao; const palavra: string): Boolean;
var
  curMask, nextMask, finalsMask: array of Boolean;
  i, t, fidx, tidx, symi: Integer;
begin
  // Descrição geral:
  // - Implementa simulação de AFN sem transições ε usando máscaras booleanas para conjuntos de
  //   estados alcançáveis. `curMask` marca os estados ativos antes de ler o próximo símbolo.
  // - Para cada símbolo da palavra construímos `nextMask` a partir de `curMask` aplicando
  //   transições que correspondem ao símbolo. Se `nextMask` ficar vazio, rejeitamos.
  // - Ao final, aceitamos se algum dos estados em `curMask` for final.

  TestarPalavraAFN_ := False;
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

  for i := 0 to High(estadosFinais) do
  begin
    tidx := IndexOfStr(estados, estadosFinais[i]);
    if tidx >= 0 then finalsMask[tidx] := True;
  end;

  for i := 1 to Length(palavra) do
  begin
    symi := IndexOfChar(alfabeto, palavra[i]);
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

    t := 0; for fidx := 0 to High(nextMask) do if nextMask[fidx] then Inc(t);
    if t = 0 then Exit;

    for fidx := 0 to High(curMask) do curMask[fidx] := nextMask[fidx];
  end;

  for i := 0 to High(curMask) do
    if curMask[i] and finalsMask[i] then
    begin
      TestarPalavraAFN_ := True; Exit;
    end;
end;

end.