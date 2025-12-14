unit MinimizeAFD;

{$mode fpc}{$H+}

interface

uses
  AFD, CommonTypes, SysUtils;

procedure MinimizarAFD(const Orig: TAFD; var Min: TAFD);

implementation

type
  // Representação interna do AFD
  TDFAInt = record
    Num_Estados   : Integer;
    Num_Simbolos  : Integer;
    eInicial     : Integer;
    eFinal       : array of Boolean;
    Trans        : array of array of Integer; // [estado, símbolo]
    StateNames   : array of string;
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

// Totalização do AFD mandando p/ estado morto

function TemTransicao(const trans: array of TTransicao; const fromS: string; const sym: char): Boolean;
var
  i: Integer;
begin
  TemTransicao := False;
  for i := 0 to High(trans) do
  begin
    if (trans[i].fromState = fromS) and (trans[i].symbol = sym) then
    begin
      TemTransicao := True;
      Exit;
    end;
  end;
end;

function EstadoExiste(const estados: array of string; const s: string): Boolean;
begin
  EstadoExiste := (EncontrarIndice_estado(estados, s) >= 0);
end;

function IsFinalState(const finais: array of string; const s: string): Boolean;
begin
  IsFinalState := (EncontrarIndice_estado(finais, s) >= 0);
end;

//Só considera transição existente se o destino também for válidonão vazio e existente em estados
function TemTransicaoValida(const trans: array of TTransicao; const estados: array of string; const fromS: string; const sym: char): Boolean;
var
  i: Integer;
begin
  TemTransicaoValida := False;
  for i := 0 to High(trans) do
  begin
    if (trans[i].fromState = fromS) and (trans[i].symbol = sym) then
    begin
      if (trans[i].toState <> '') and EstadoExiste(estados, trans[i].toState) then
      begin
        TemTransicaoValida := True;
        Exit;
      end;
    end;
  end;
end;

function CriarEstadoMorto(const estados: array of string): string;
var
  base: string;
  i: Integer;
  cand: string;
begin
  base := 'EstadoMorto';
  if not EstadoExiste(estados, base) then
  begin
    CriarEstadoMorto := base;
    Exit;
  end;

  i := 0;
  while True do
  begin
    cand := base + '_' + IntToStr(i);
    if not EstadoExiste(estados, cand) then
    begin
      CriarEstadoMorto := cand;
      Exit;
    end;
    Inc(i);
  end;
end;

procedure AdicionarTransicao(var A: TAFD; const fromS, toS: string; const sym: char);
var
  n: Integer;
begin
  n := Length(A.transicoes);
  SetLength(A.transicoes, n + 1);
  A.transicoes[n].fromState := fromS;
  A.transicoes[n].toState   := toS;
  A.transicoes[n].symbol    := sym;
end;

procedure TotalizarAFD(var A: TAFD);
var
  EstadoMorto: string;
  i, j: Integer;
  PrecisaEstadoMorto: Boolean;
begin
  // Se não tem estados ou alfabeto, não há o que totalizar
  if (Length(A.estados) = 0) or (Length(A.alfabeto) = 0) then
    Exit;

  // Checa se falta alguma transição: se faltar, então precisa do EstadoMorto
  // Aqui, se encontrar qualquer, QAUlQUER lugar sem transição, então a boolena fica true.
  PrecisaEstadoMorto := False;
  for i := 0 to High(A.estados) do
  begin
    for j := 0 to High(A.alfabeto) do
    begin
      //usa TemTransicaoValida para não "enganar" quando existe transição com toState inválido, tipo ''.
      if not TemTransicaoValida(A.transicoes, A.estados, A.estados[i], A.alfabeto[j]) then
      begin
        PrecisaEstadoMorto := True;
        Break;
      end;
    end;
    if PrecisaEstadoMorto then Break;
  end;

  if not PrecisaEstadoMorto then
  begin
    // debug
    // Writeln('O AFD ja é total.');
    Exit;
  end;


  // Cria estado morto único
  EstadoMorto := CriarEstadoMorto(A.estados);


  // Adiciona EstadoMorto aos estados que já existem
  // A partir daqui, o estado morto começa a contar
  SetLength(A.estados, Length(A.estados) + 1);
  A.estados[High(A.estados)] := EstadoMorto;


  // Aqui o código vai percorrer cada par de (estado, símbolo) do WORK
  // que eh um objeto TAFD. Se uma transição não existir, ele criado
  // o estado morto para essa transição.

  for i := 0 to High(A.estados) do
  begin
    for j := 0 to High(A.alfabeto) do
    begin
      //usa TemTransicaoValida para evitar contar transição "quebrada" como existente (quebrada seria transição com -1)
      if not TemTransicaoValida(A.transicoes, A.estados, A.estados[i], A.alfabeto[j]) then
      begin
        AdicionarTransicao(A, A.estados[i], EstadoMorto, A.alfabeto[j]);
        //debug
        // Writeln(' Add ', A.estados[i], ' --', A.alfabeto[j], '--> ', EstadoMorto);
      end;
    end;
  end;

  // Garante loops do EstadoMorto (caso não existam)
  //Isso daqui é redundante mas melhor garantir que remediar (de novo)
  for j := 0 to High(A.alfabeto) do
  begin
    if not TemTransicaoValida(A.transicoes, A.estados, EstadoMorto, A.alfabeto[j]) then
      AdicionarTransicao(A, EstadoMorto, EstadoMorto, A.alfabeto[j]);
  end;
  // Debug
  // Writeln('AFD totalizado. EstadoMorto=', EstadoMorto, ' | Estados=', Length(A.estados), ' | Transicoes=', Length(A.transicoes));
end;


// Converter o externo (TAFD) para o interno (TDFAInt)
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

//Faz o inverso, converte o interno (TDFAInt) para o externo (TAFD)

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
  Work: TAFD;                  // cópia para totalizar
  D0, D1, D2: TDFAInt;         // D0 = e o AFD original, D1 é o tratado sem inalcançáveis e, finalmente, D2 é o minimizado
  Dist      : array of array of Boolean;
  RepToNew  : array of Integer;
  Alterado   : Boolean;
  p, q, a, p2, q2: Integer;
  i, rep, newIdx: Integer;

begin
  // Totalizando o AFD antes de minimizar (se for AFD parcial não funciona)
  Work := Orig;
  TotalizarAFD(Work);

  // Converte para o tipo interno para facilitar aplicação de algoritmos em matriz;
  ToInternal(Work, D0);

  //DEBUG ==========================
  //Writeln('Entrou na MinimizarAFD');
  //Writeln('D0.Num_Estados=', D0.Num_Estados, ' D0.eInicial=', D0.eInicial);

  // Remove os estados inalcançáveis, que é uma etapa de minimização;
  RemoverInalcancaveis(D0, D1);

  //DEBUG ==========================
  Writeln('Depois de RemoverInalcancaveis');
  Writeln('D1.Num_Estados=', D1.Num_Estados, ' D1.eInicial=', D1.eInicial);


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