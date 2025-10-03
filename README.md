<a name="readme-topo"></a>

<h1 align='center'>
  🧮 Pascal Finite Automata Converter
</h1>

<div align='center'>

[![SO][Ubuntu-badge]][Ubuntu-url]
[![IDE][vscode-badge]][vscode-url]
<!-- [![Make][make-badge]][make-url] -->
[![Language][pascal-badge]][pascal-url]

Linguagens Formais e Autômatos <br>
Engenharia de Computação <br>
Prof. Eduardo Gabriel Reis Miranda <br>
CEFET-MG Campus V <br>
2025/2 
</div>

Finite Automata Converter written in Pascal Programming Language


## 🔨 Começando

Nesta seção estão exemplificados os meios através dos quais se tornam possíveis a compilação e execução do programa apresentado.

### Pré-requisitos

Inicialmente, algumas considerações importantes sobre como se deve preparar o ambiente para compilar e executar o programa:

> [!NOTE]
> Recomenda-se usar uma distribuição de sistema operacional Linux ou o Windows Subsystem for Linux (WSL), pois os comandos no [`exec.sh`](exec.sh) foram selecionados para funcionar em um ambiente [_shell/bash_][bash-url].

Considerando um ambiente _shell_, garanta que os seguintes comandos já foram executados:
  - Atualize os pacotes antes da instalação dos compiladores:
  ```console
  sudo apt update
  ```
  - Instale o compilador de Pascal ___FPC___:
  ```console
  sudo apt install fpc
  ```

## 🔨 Instalando

<div align="justify">
  Com o ambiente preparado, os seguintes passos são para a instalação, compilação e execução do programa localmente:

  1. Clone o repositório no diretório desejado:
  ```console
  git clone https://github.com/alvarengazv/pascal-fa-converter.git
  cd pascal-fa-converter
  ```
  2. Execute o script `exec.sh` para compilar e executar o programa, indicando, se necessário, o nome do arquivo json de `input`:
  ```console
  ./exec.sh
  ```
  ou
  ```console
  ./exec.sh automato.json
  ```

  O programa estará pronto para ser testado.

<p align="right">(<a href="#readme-topo">voltar ao topo</a>)</p>

</div>

## 📨 Contato

<div align="center">
<i>Eduardo Henrique Queiroz Almeida - Computer Engineering Student @ CEFET-MG</i>
<br><br>

[![Gmail][gmail-badge]][gmail-autor1]
[![Linkedin][linkedin-badge]][linkedin-autor1]
[![Telegram][telegram-badge]][telegram-autor1]

<br><br>


<i>Guilherme Alvarenga de Azevedo - Computer Engineering Student @ CEFET-MG</i>
<br><br>

[![Gmail][gmail-badge]][gmail-autor2]
[![Linkedin][linkedin-badge]][linkedin-autor2]
[![Telegram][telegram-badge]][telegram-autor2]

<br><br>


<i>Jader Oliveira Silva - Computer Engineering Student @ CEFET-MG</i>
<br><br>

[![Gmail][gmail-badge]][gmail-autor3]
[![Linkedin][linkedin-badge]][linkedin-autor3]
[![Telegram][telegram-badge]][telegram-autor3]

<br><br>


<i>Joaquim Cézar Santana da Cruz - Computer Engineering Student @ CEFET-MG</i>
<br><br>

[![Gmail][gmail-badge]][gmail-autor4]
[![Linkedin][linkedin-badge]][linkedin-autor4]
[![Telegram][telegram-badge]][telegram-autor4]

<p align="right">(<a href="#readme-topo">voltar ao topo</a>)</p>

</div>

[linkedin-badge]: https://img.shields.io/badge/-LinkedIn-0077B5?style=for-the-badge&logo=Linkedin&logoColor=white
[telegram-badge]: https://img.shields.io/badge/Telegram-2CA5E0?style=for-the-badge&logo=telegram&logoColor=white
[gmail-badge]: https://img.shields.io/badge/-Gmail-D14836?style=for-the-badge&logo=Gmail&logoColor=white

[linkedin-autor1]: https://www.linkedin.com/in/eduardo-henrique-queiroz-almeida-61378a124/
[telegram-autor1]: https://t.me
[gmail-autor1]: mailto:eduardohenriquecruzeiro123@gmail.com

[linkedin-autor2]: https://www.linkedin.com/in/guilherme-alvarenga-de-azevedo-959474201/
[telegram-autor2]: https://t.me/alvarengazv
[gmail-autor2]: mailto:gui.alvarengas234@gmail.com

[linkedin-autor3]: https://www.linkedin.com
[telegram-autor3]:  https://t.me
[gmail-autor3]: mailto:jaderoliveira28@gmail.com

[linkedin-autor4]: https://www.linkedin.com/in/joaquim-cruz-b760bb350/
[telegram-autor4]: https://t.me/
[gmail-autor4]: mailto:joaquimcezar930@gmail.com

[ubuntu-badge]: https://img.shields.io/badge/Ubuntu-E95420?style=for-the-badge&logo=ubuntu&logoColor=white
[Ubuntu-url]: https://ubuntu.com/
[vscode-badge]: https://img.shields.io/badge/Visual%20Studio%20Code-0078d7.svg?style=for-the-badge&logo=visual-studio-code&logoColor=white
[vscode-url]: https://code.visualstudio.com/docs/?dv=linux64_deb
[make-badge]: https://img.shields.io/badge/_-MAKEFILE-427819.svg?style=for-the-badge
[make-url]: https://www.gnu.org/software/make/manual/make.html
[pascal-badge]: https://img.shields.io/badge/pascal-376aa8.svg?style=for-the-badge&logo=javafx&logoColor=white
[pascal-url]: https://www.freepascal.org/docs-html/ref/ref.html

[bash-url]: https://www.hostgator.com.br/blog/o-que-e-bash/
