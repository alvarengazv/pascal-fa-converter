unit CommonTypes;
{$mode fpc}{$H+}

interface
type
    TTransicao = record
        fromState: string;
        toState: string;
        symbol: char; // Usar char para representar o símbolo da transição
    end;
implementation
end.