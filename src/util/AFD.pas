unit AFD;
interface

uses
    CommonTypes;

type
    TAFD = record
        alfabeto: array of char;
        estados: array of string;
        estadoInicial: string;
        estadosFinais: array of string;
        transicoes: array of CommonTypes.TTransicao;
    end;
implementation
end.