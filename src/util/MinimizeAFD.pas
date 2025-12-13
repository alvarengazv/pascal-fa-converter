unit MinimizeAFD;

{$mode fpc}{$H+}

interface

uses
  AFD, CommonTypes;

procedure MinimizarAFD(const Orig: TAFD; var Min: TAFD);

implementation

type
  // Representação interna do AFD
  TDFAInt = record
    Num_Estados   : Integer;
    Num_Simbolos  : Integer;
    eInicial     : Integer;
    eFinal     : array of Boolean;
    Trans       : array of array of Integer; // [estado, símbolo]
    StateNames  : array of string;
    Alphabeto    : array of char;
  end;

//Funçoes de busca

function EncontrarIndice_estado(const arr: array of string; const s: string): Integer;
var
  i: Integer;
begin
  for i := 0 to High(arr) do
    if arr[i] = s then
    begin
      EncontrarIndice_estado := i;
      Exit;
    end;
  EncontrarIndice_estado := -1;
end;

function EncontrarIndice_simbolo(const arr: array of char; const c: char): Integer;
var
  i: Integer;
begin
  for i := 0 to High(arr) do
    if arr[i] = c then
    begin
      EncontrarIndice_simbolo := i;
      Exit;
    end;
  EncontrarIndice_simbolo := -1;
end;

//Converter o externo (TFDA) para o interno (TFDInt)

procedure ToInternal(const A: TAFD; var D: TDFAInt);
var
  i, idx, fromIdx, toIdx, symIdx: Integer;
begin
  D.Num_Estados  := Length(A.estados);
  D.Num_Simbolos := Length(A.alfabeto);

  SetLength(D.StateNames, D.Num_Estados);
  for i := 0 to D.Num_Estados - 1 do
    D.StateNames[i] := A.estados[i];

  SetLength(D.Alphabeto, D.Num_Simbolos);
  for i := 0 to D.Num_Simbolos - 1 do
    D.Alphabeto[i] := A.alfabeto[i];

  // Estado inicial
  D.eInicial := EncontrarIndice_estado(D.StateNames, A.estadoInicial);

  // Estados finais
  SetLength(D.eFinal, D.Num_Estados);
  for i := 0 to D.Num_Estados - 1 do
    D.eFinal[i] := False;

  for i := 0 to High(A.estadosFinais) do
  begin
    idx := EncontrarIndice_estado(D.StateNames, A.estadosFinais[i]);
    if idx <> -1 then
      D.eFinal[idx] := True;
  end;

  // Transições
  SetLength(D.Trans, D.Num_Estados);
  for i := 0 to D.Num_Estados - 1 do
    SetLength(D.Trans[i], D.Num_Simbolos);

  // Inicializa com -1 (sem transição)
  for fromIdx := 0 to D.Num_Estados - 1 do
    for symIdx := 0 to D.Num_Simbolos - 1 do
      D.Trans[fromIdx, symIdx] := -1;

  // Preenche com as transições do AFD original
  for i := 0 to High(A.transicoes) do
  begin
    fromIdx := EncontrarIndice_estado(D.StateNames, A.transicoes[i].fromState);
    toIdx   := EncontrarIndice_estado(D.StateNames, A.transicoes[i].toState);
    symIdx  := EncontrarIndice_simbolo(D.Alphabeto, A.transicoes[i].symbol);

    if (fromIdx <> -1) and (toIdx <> -1) and (symIdx <> -1) then
      D.Trans[fromIdx, symIdx] := toIdx;
  end;
end;

//Faz o inverso, converte o interno (TDFAInt) para o externo (TDFA)

procedure ToExternal(const D: TDFAInt; var A: TAFD);
var
  i, j, k, countFinal: Integer;
begin
  // Alfabeto
  SetLength(A.alfabeto, D.Num_Simbolos);
  for i := 0 to D.Num_Simbolos - 1 do
    A.alfabeto[i] := D.Alphabeto[i];

  // Estados
  SetLength(A.estados, D.Num_Estados);
  for i := 0 to D.Num_Estados - 1 do
    A.estados[i] := D.StateNames[i];

  // Estado inicial
  if (D.eInicial >= 0) and (D.eInicial < D.Num_Estados) then
    A.estadoInicial := D.StateNames[D.eInicial]
  else
    A.estadoInicial := '';

  // Estados finais
  countFinal := 0;
  for i := 0 to D.Num_Estados - 1 do
    if D.eFinal[i] then
      Inc(countFinal);

  SetLength(A.estadosFinais, countFinal);
  k := 0;
  for i := 0 to D.Num_Estados - 1 do
    if D.eFinal[i] then
    begin
      A.estadosFinais[k] := D.StateNames[i];
      Inc(k);
    end;

  // Transições: uma por (estado, símbolo)
  SetLength(A.transicoes, D.Num_Estados * D.Num_Simbolos);
  k := 0;
  for i := 0 to D.Num_Estados - 1 do
    for j := 0 to D.Num_Simbolos - 1 do
    begin
      A.transicoes[k].fromState := D.StateNames[i];
      A.transicoes[k].symbol    := D.Alphabeto[j];
      if (D.Trans[i, j] >= 0) and (D.Trans[i, j] < D.Num_Estados) then
        A.transicoes[k].toState := D.StateNames[D.Trans[i, j]]
      else
        A.transicoes[k].toState := '';
      Inc(k);
    end;
end;

procedure RemoverInalcancaveis(const D: TDFAInt; var R: TDFAInt);
var
  Alcancaveis: array of Boolean;
  OldToNew : array of Integer;
  Alterado  : Boolean;
  i, s, t, a, countReach: Integer;
begin
  SetLength(Alcancaveis, D.Num_Estados);
  for i := 0 to D.Num_Estados - 1 do
    Alcancaveis[i] := False;

  if (D.eInicial >= 0) and (D.eInicial < D.Num_Estados) then
    Alcancaveis[D.eInicial] := True;

  repeat
    Alterado := False;
    for s := 0 to D.Num_Estados - 1 do
      if Alcancaveis[s] then
        for a := 0 to D.Num_Simbolos - 1 do
        begin
          t := D.Trans[s, a];
          if (t >= 0) and (t < D.Num_Estados) and (not Alcancaveis[t]) then
          begin
            Alcancaveis[t] := True;
            Alterado := True;
          end;
        end;
  until not Alterado;

  // Mapeia estados alcançáveis para novos índices
  SetLength(OldToNew, D.Num_Estados);
  for i := 0 to D.Num_Estados - 1 do
    OldToNew[i] := -1;

  countReach := 0;
  for i := 0 to D.Num_Estados - 1 do
    if Alcancaveis[i] then
    begin
      OldToNew[i] := countReach;
      Inc(countReach);
    end;

  R.Num_Estados  := countReach;
  R.Num_Simbolos := D.Num_Simbolos;

  SetLength(R.StateNames, R.Num_Estados);
  SetLength(R.Alphabeto, R.Num_Simbolos);
  SetLength(R.eFinal, R.Num_Estados);
  SetLength(R.Trans, R.Num_Estados);
  for i := 0 to R.Num_Estados - 1 do
    SetLength(R.Trans[i], R.Num_Simbolos);

  // Copia alfabeto
  for a := 0 to D.Num_Simbolos - 1 do
    R.Alphabeto[a] := D.Alphabeto[a];

  // Copia estados, finais e transições
  for s := 0 to D.Num_Estados - 1 do
    if Alcancaveis[s] then
    begin
      t := OldToNew[s]; // novo índice
      R.StateNames[t] := D.StateNames[s];
      R.eFinal[t]    := D.eFinal[s];
      for a := 0 to D.Num_Simbolos - 1 do
      begin
        i := D.Trans[s, a];
        if (i >= 0) and (i < D.Num_Estados) and Alcancaveis[i] then
          R.Trans[t, a] := OldToNew[i]
        else
          R.Trans[t, a] := -1;
      end;
    end;

  // Estado inicial
  if (D.eInicial >= 0) and (D.eInicial < D.Num_Estados) and Alcancaveis[D.eInicial] then
    R.eInicial := OldToNew[D.eInicial]
  else
    R.eInicial := -1;
end;

//Agrupamento dos estados equivalentes (minimização de fato)

var
  Parent: array of Integer;

function UF_Find(x: Integer): Integer;
begin
  if Parent[x] <> x then
    Parent[x] := UF_Find(Parent[x]);
  UF_Find := Parent[x];
end;

procedure UF_Union(x, y: Integer);
var
  rx, ry: Integer;
begin
  rx := UF_Find(x);
  ry := UF_Find(y);
  if rx <> ry then
    Parent[ry] := rx;
end;

//Minimização utilizando a matriz de distinção

procedure MinimizarAFD(const Orig: TAFD; var Min: TAFD);
var
  D0, D1, D2: TDFAInt;         // D0 = e o AFD original, D1 é o tratado sem inalcançáveis e, finalmente, D2 é o minimizado
  Dist      : array of array of Boolean;
  RepToNew  : array of Integer;
  Alterado   : Boolean;
  p, q, a, p2, q2: Integer;
  i, rep, newIdx: Integer;

begin
  // Converte para o tipo interno para facilitar aplicação de algoritmos em matriz;
  ToInternal(Orig, D0);

  //DEBUG ==========================
  Writeln('[MIN] Entrou na MinimizarAFD');
  Writeln('[MIN] D0.Num_Estados=', D0.Num_Estados, ' D0.eInicial=', D0.eInicial);


  // Remove os estados inalcançáveis, que é uma etapa de minimização;
  RemoverInalcancaveis(D0, D1);

  //DEBUG ==========================
  Writeln('[MIN] Depois de RemoverInalcancaveis');
  Writeln('[MIN] D1.Num_Estados=', D1.Num_Estados, ' D1.eInicial=', D1.eInicial);


  // Caso trivial
  if D1.Num_Estados <= 1 then
  begin
    D2 := D1;
    ToExternal(D2, Min);
    Exit;
  end;

  // Aplicação da matriz de distinção;
  SetLength(Dist, D1.Num_Estados);
  for p := 0 to D1.Num_Estados - 1 do
  begin
    SetLength(Dist[p], D1.Num_Estados);
    for q := 0 to D1.Num_Estados - 1 do
      Dist[p, q] := False;
  end;

  // Realiza a marcação de pares (p,q) em que apenas um é final;
  for p := 0 to D1.Num_Estados - 1 do
    for q := p + 1 to D1.Num_Estados - 1 do
      if D1.eFinal[p] <> D1.eFinal[q] then
        Dist[p, q] := True;

  // Faz a propagação das marcações;
  repeat
    Alterado := False;
    for p := 0 to D1.Num_Estados - 1 do
      for q := p + 1 to D1.Num_Estados - 1 do
      begin
        if not Dist[p, q] then
        begin
          for a := 0 to D1.Num_Simbolos - 1 do
          begin
            p2 := D1.Trans[p, a];
            q2 := D1.Trans[q, a];
            if (p2 <> -1) and (q2 <> -1) and (p2 <> q2) then
            begin
              if p2 > q2 then
              begin
                i  := p2;
                p2 := q2;
                q2 := i;
              end;
              if Dist[p2, q2] then
              begin
                Dist[p, q] := True;
                Alterado := True;
                Break;
              end;
            end;
          end;
        end;
      end;
  until not Alterado;

  // faz o agrupamento de estados equivalentes (estados não marcados -> equivalentes)
  SetLength(Parent, D1.Num_Estados);
  for i := 0 to D1.Num_Estados - 1 do
    Parent[i] := i;

  for p := 0 to D1.Num_Estados - 1 do
    for q := p + 1 to D1.Num_Estados - 1 do
      if not Dist[p, q] then
        UF_Union(p, q);

  // Mapeia representante -> novo índice em D2
  SetLength(RepToNew, D1.Num_Estados);
  for i := 0 to D1.Num_Estados - 1 do
    RepToNew[i] := -1;

  D2.Num_Estados  := 0;
  D2.Num_Simbolos := D1.Num_Simbolos;

  SetLength(D2.StateNames, D1.Num_Estados);
  SetLength(D2.Alphabeto, D2.Num_Simbolos);
  SetLength(D2.eFinal, D1.Num_Estados);
  SetLength(D2.Trans, D1.Num_Estados);
  for i := 0 to D1.Num_Estados - 1 do
    SetLength(D2.Trans[i], D2.Num_Simbolos);

  // Copia alfabeto
  for a := 0 to D2.Num_Simbolos - 1 do
    D2.Alphabeto[a] := D1.Alphabeto[a];

  // Cria estados representativos
  for p := 0 to D1.Num_Estados - 1 do
  begin
    rep := UF_Find(p);
    if RepToNew[rep] = -1 then
    begin
      RepToNew[rep] := D2.Num_Estados;
      D2.StateNames[D2.Num_Estados] := D1.StateNames[rep];
      D2.eFinal[D2.Num_Estados]    := False;
      Inc(D2.Num_Estados);
    end;
  end;

  // Ajusta tamanhos efetivos
  SetLength(D2.StateNames, D2.Num_Estados);
  SetLength(D2.eFinal, D2.Num_Estados);
  SetLength(D2.Trans, D2.Num_Estados);
  for i := 0 to D2.Num_Estados - 1 do
    SetLength(D2.Trans[i], D2.Num_Simbolos);

  // Transições do AFD minimizado
  for p := 0 to D1.Num_Estados - 1 do
  begin
    rep := UF_Find(p);
    newIdx := RepToNew[rep];
    for a := 0 to D1.Num_Simbolos - 1 do
    begin
      p2 := D1.Trans[p, a];
      if (p2 >= 0) and (p2 < D1.Num_Estados) then
      begin
        q2 := UF_Find(p2);
        D2.Trans[newIdx, a] := RepToNew[q2];
      end
      else
        D2.Trans[newIdx, a] := -1;
    end;
  end;

  // Estados finais
  for i := 0 to D2.Num_Estados - 1 do
    D2.eFinal[i] := False;

  for p := 0 to D1.Num_Estados - 1 do
    if D1.eFinal[p] then
    begin
      rep := UF_Find(p);
      newIdx := RepToNew[rep];
      D2.eFinal[newIdx] := True;
    end;

  // Estado inicial
  if (D1.eInicial >= 0) and (D1.eInicial < D1.Num_Estados) then
  begin
    rep := UF_Find(D1.eInicial);
    D2.eInicial := RepToNew[rep];
  end
  else
    D2.eInicial := -1;

//-------PRINT DA MINIMIZAÇÃO----------

Writeln('--- MINIMIZACAO: RESULTADO INTERNO ---');
Writeln('Num estados: ', D2.Num_Estados);
Writeln('Estado inicial idx: ', D2.eInicial);
Writeln('Estados:');
for i := 0 to D2.Num_Estados - 1 do
  Writeln('  ', i, ': ', D2.StateNames[i], ' final=', D2.eFinal[i]);
Writeln('Transicoes:');
for i := 0 to D2.Num_Estados - 1 do
  for a := 0 to D2.Num_Simbolos - 1 do
  begin
    if D2.Trans[i,a] >= 0 then
      Writeln('  ', D2.StateNames[i], ' --', D2.Alphabeto[a], '--> ', D2.StateNames[D2.Trans[i,a]])
    else
      Writeln('  ', D2.StateNames[i], ' --', D2.Alphabeto[a], '--> (sem)');
  end;

Writeln('-------------------');


//-------------------------------------

  // Converte de volta para TAFD

  ToExternal(D2, Min);

end;

end.