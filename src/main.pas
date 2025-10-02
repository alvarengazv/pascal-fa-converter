{$mode objfpc}{$H+}
program main;

uses
{ JSON Parser Unit from units/jsonParser }
    jsonParser, SysUtils, Classes;

var
  jsonString: string;
  jsonFile: file of char;
  c: char;

begin
    { 
        Menu:
        0. Converter multiestado inicial em AFN-&
        1. Converter AFN-& em AFN
        2. Converter AFN em AFD
        3. Minimizar AFD
        4. Testar palavras
            4.1 Via Arquivo
            4.2 Via Terminal
        5. Sair
    }

    { Read JSON File from input/automato.json and print the result of ParseJson }

    jsonString := '';
    Assign(jsonFile, 'input/automato.json');
    Reset(jsonFile);
    try
      while not EOF(jsonFile) do
      begin
        Read(jsonFile, c);
        jsonString := jsonString + c;
      end;
      Write(jsonString);
    finally
      Close(jsonFile);
    end;
end.