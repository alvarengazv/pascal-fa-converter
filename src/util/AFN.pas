unit AFN;
{$mode fpc}{$H+}

interface

uses
    CommonTypes;

type
    TAFN = record
        alfabeto: array of char;
        estados: array of string;
        estadosIniciais: array of string;
        estadosFinais: array of string;
        transicoes: array of CommonTypes.TTransicao;
        isAFN: boolean;
        isAFN_E: boolean; 
        isAFN_Multiestado_Inicial: boolean;
    end;
implementation
end.