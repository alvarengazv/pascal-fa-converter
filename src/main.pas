{$mode fpc}
program main;

uses
    SysUtils, Classes, StrUtils;

var
  jsonFile: TextFile;
  line: string;
  position, i: integer;
  choice, subchoice: string;
  inputFileName: string;
  alfabeto: array of char;
  estados: array of string;
  estados_iniciais: array of string;
  estados_finais: array of string;
  transicoes: array of record
    from_state: string;
    to_state: string;
    symbol: char;
  end;

procedure ShowMenu;
begin
    Writeln('Menu:');
    Writeln('0. Converter multiestado inicial em AFN-&');
    Writeln('1. Converter AFN-& em AFN');
    Writeln('2. Converter AFN em AFD');
    Writeln('3. Minimizar AFD');
    Writeln('4. Testar palavras');
    Writeln('5. Sair');
end;

begin
    // Checar argumentos de linha de comando para arquivo de entrada
    if ParamCount >= 1 then
        inputFileName := 'input/' + ParamStr(1)
    else
        inputFileName := 'input/automato.json';
        
    WriteLn('Using input file: ', inputFileName);
    
    // Carregar e exibir conteúdo do arquivo JSON
    WriteLn('JSON content loaded successfully.');
    WriteLn('--- JSON Content ---');
    
    Assign(jsonFile, inputFileName);
    Reset(jsonFile);
    while not EOF(jsonFile) do
    begin
      ReadLn(jsonFile, line);
      
      // Simple detection of JSON sections (just display for now)
      position := Pos('alfabeto', line);
      if position > 0 then
        WriteLn('-> Alfabeto section found');

      position := Pos('estados', line);  
      if position > 0 then
        WriteLn('-> Estados section found');
        
      position := Pos('transicoes', line);
      if position > 0 then
        WriteLn('-> Transicoes section found');

      WriteLn(line);
    end;
    Close(jsonFile);
    
    WriteLn('--- End JSON ---');

    while True do
    begin
        ShowMenu;
        Write('Escolha uma opção: ');
        Readln(choice);
        case choice of
            '0': Writeln('Função 0 selecionada');
            '1': Writeln('Função 1 selecionada');
            '2': Writeln('Função 2 selecionada');
            '3': Writeln('Função 3 selecionada');
            '4':
            begin
                Writeln('Função 4 selecionada');
                Writeln('1 Via Arquivo');
                Writeln('2 Via Terminal');
                Write('Escolha uma opcao: ');
                Readln(subchoice);
                case subchoice of
                    '1': Writeln('Função 1 selecionada');
                    '2': Writeln('Função 2 selecionada');
                else
                    Writeln('Opcao invalida');
                end;
            end;
            '5':
            begin
                Writeln('Saindo...');
                Break;
            end;
        else
            Writeln('Opcao invalida');
        end;
    end;
end.