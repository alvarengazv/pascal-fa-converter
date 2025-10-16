unit AFN;
interface

type
    TTransicao = record
        fromState: string;
        toState: string;
        symbol: char; // Usar char para representar o símbolo da transição
    end;

    TAFN = record
        alfabeto: array of char;
        estados: array of string;
        estadosIniciais: array of string;
        estadosFinais: array of string;
        transicoes: array of TTransicao;
        isAFN: boolean;
        isAFN_E: boolean; 
        isAFN_Multiestado_Inicial: boolean;
    end;
end.