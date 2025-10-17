#!/bin/bash

# Criar diretório build, se não existir
mkdir -p build

# Compilar com saída para o diretório build
# -Fusrc/units: Adicionar src/units ao caminho de busca de unidades
# -Fusrc: Adicionar src ao caminho de busca
# -FUbuild: Colocar arquivos de unidade compilados no diretório build
# -Fibuild: Procurar unidades compiladas no diretório build
# -obuild/main: Saída do executável para build/main
fpc -Fusrc/units -Fusrc -Fusrc/util -FUbuild -Fibuild -obuild/main src/main.pas

# Check if compilation was successful
if [ $? -eq 0 ]; then
    echo "Compilation successful!"
    echo "Running program..."
    
    # Run the program with optional command line argument
    if [ $# -eq 0 ]; then
        echo "No input file specified, using default: input/automato.json"
        ./build/main
    else
        echo "Using input file: $1"
        ./build/main "$1"
    fi
else
    echo "Compilation failed!"
    exit 1
fi