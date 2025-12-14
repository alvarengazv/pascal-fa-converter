unit TestarPalavraAFD;

{$mode fpc}{$H+}

interface

uses
    CommonTypes;

function TestarPalavraAFD_(const estados: array of string; const alfabeto: array of char; const estadoInicial: string; const estadosFinais: array of string; const trans: array of TTransicao; const palavra: string): Boolean;

implementation

type
    //Vetor de vetores... Matriz.
    IntMatriz = array of array of Integer;

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

function TestarPalavraAFD_(const estados: array of string; const alfabeto: array of char;
  const estadoInicial: string; const estadosFinais: array of string;
  const trans: array of TTransicao; const palavra: string): Boolean;
var
  delta: IntMatriz;
  i, cur, symi, nxt: Integer;
  finalsMask: array of Boolean;
begin
  // Visão geral AFD (determinístico):
  // - Primeiro construímos a matriz `delta` onde cada linha corresponde a um estado e cada
  //   coluna a um símbolo do alfabeto; valor -1 indica ausência de transição.
  // - Em seguida, percorremos a palavra símbolo a símbolo, consultando `delta[cur][sym]`
  //   para encontrar o próximo estado. Se em algum passo não existir transição definida,
  //   rejeitamos. Ao final, aceitamos se o estado corrente for final.

  TestarPalavraAFD_ := False;

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
    TestarPalavraAFD_ := False; Exit;
  end;

  for i := 1 to Length(palavra) do
  begin
    symi := IndexOfChar(alfabeto, palavra[i]);
    if symi < 0 then
    begin
      TestarPalavraAFD_ := False; Exit; // símbolo fora do alfabeto
    end;

    //Pega a transição do estado atual com o símbolo atual e diz o próximo estado.
    nxt := delta[cur][symi];
    if nxt < 0 then
    begin
      TestarPalavraAFD_ := False; Exit; // transição não definida
    end;
    cur := nxt;
  end;

  TestarPalavraAFD_ := finalsMask[cur];
end;

end.