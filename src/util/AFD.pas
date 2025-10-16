unit AFD;
interface

type
    TTransicao = record
        fromState: string;
        toState: string;
        symbol: char; // Usar char para representar o símbolo da transição
    end;

    TAFD = record
        alfabeto: array of char;
        estados: array of string;
        estadoInicial: string;
        estadosFinais: array of string;
        transicoes: array of TTransicao;
    end;
end.