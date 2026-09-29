# Zed para desenvolver e aprender

## Aplicar

Esta entrega parte de snowflake-completo.zip, versão salva em 29/09/2026.
Para aplicar somente o Zed, copie `modules/home/zed.nix` e
`modules/programs/zed.nix` para os mesmos caminhos do seu flake.
Os dois hosts já importam esses módulos. Os exemplos e este guia são opcionais.

Dentro de ~/snowflake, execute `sudo nixos-rebuild switch --flake .#desktop`
(ou `.#laptop`). Feche completamente e reabra o Zed. Aguarde a extensão Nix
instalar na primeira abertura. Não é preciso atualizar o lock para esta alteração.
Se sua cópia local mudou depois da versão usada, preserve essas alterações.

## O que foi ativado

- Autocompletar ao digitar, documentação no menu e ao passar o mouse.
- Assinaturas de funções, dicas de tipos/parâmetros e ações de correção do LSP.
- Erros e avisos na linha, indentação automática, guias e dobramento de blocos.
- Formatação ao salvar desativada. Enter segue a indentação da sintaxe;
  a formatação completa fica disponível manualmente.
- Barra de status e indicadores Git, restauração do último projeto.
- Nix: nixd e nixfmt, incluindo opções do host atual e do Home Manager.
- C/C++: clangd, clang-tidy, clang-format, GCC, CMake, Ninja, GDB e lldb-dap.
- Python: Pyright e Ruff; Lua: lua-language-server e StyLua; Bash: LSP e shfmt.
  Lua e Luau usam servidores distintos. O complemento está em `modules/programs/roblox.nix`; veja [Roblox](roblox.md).

O tema Aura Dark, ícones e fontes existentes foram mantidos.
A instalação do Zed agora fica no Home Manager, com suas ferramentas disponíveis
no ambiente do editor. Isso não instala todas elas no terminal externo ao Zed.
Os caminhos dos LSPs são absolutos para usar os pacotes do NixOS.

## Primeiro teste

Abra a pasta do projeto, não apenas um arquivo isolado. Em um .cpp salvo, escreva
`int numero = ;`: o clangd deve apontar o erro. Corrija para `int numero = 10;`.
Passe o mouse sobre um nome, experimente o menu de sugestões e use `editor: format` na paleta para formatar manualmente.
Em Nix, abra ~/snowflake e experimente completar `pkgs.` ou uma opção NixOS.
Algumas sugestões de opções exigem que o flake possa ser avaliado; isso inclui
inputs disponíveis, imports válidos e arquivos novos registrados no Git.

Se o flake estiver fora de ~/snowflake, ajuste `flakePath` em modules/home/zed.nix.
O servidor não substitui `nix flake check` ou o rebuild: nem todo erro de avaliação
ou de execução pode ser detectado enquanto você digita.

## Exercícios de um arquivo C++

Salve o arquivo, abra Ctrl+Shift+P, procure `task: spawn` e selecione:

- C++: compilar e executar arquivo — GCC com C++20 e avisos úteis.
- C++: verificar memoria (sanitizers) — procura erros de memória e comportamento indefinido durante a execução.
- C++: depurar arquivo com GDB — depuração no terminal.

Os executáveis ficam em .zed-build ao lado do arquivo. Adicione `.zed-build/` ao
.gitignore do projeto. Essas tarefas são para um único .cpp; para múltiplos
arquivos e bibliotecas, use CMake. Não force -Werror no início: avisos devem ser
entendidos, mas não precisam impedir todos os exercícios de compilar.
No GDB: `break main`, `run`, `next`, `print numero`, `continue`, `quit`.
As verificações de memória só examinam os caminhos efetivamente executados.

## Projeto com CMake e depurador gráfico

Copie examples/cpp-iniciante para sua pasta de estudos e abra a pasta copiada
como projeto no Zed. Use `task: spawn` → `CMake: configurar` primeiro.
Isso gera build/compile_commands.json, que informa ao clangd o compilador,
C++20, os includes e os flags reais. Em projetos existentes, preserve o padrão
C++ e as dependências definidos pelo próprio projeto.

Para executar, escolha `CMake: compilar e executar`. O terminal aceita entrada.
Para depurar, salve os arquivos, configure o CMake, clique na margem de uma linha
para marcar um breakpoint e use `debugger: start`, escolhendo
`C++: depurar projeto`. O build ocorre antes do início da sessão. Observe as
variáveis e avance linha por linha; o adaptador usado é o lldb-dap do NixOS.
Se precisar de entrada interativa durante a depuração e o terminal do adaptador
não a disponibilizar na sua versão do Zed, use a tarefa de GDB no terminal.

Ao adicionar outro .cpp, inclua seu nome em add_executable no CMakeLists.txt.
Se houver dois exercícios com funções main diferentes, eles precisam de alvos
separados. Não junte todos os exercícios num único executável.

## Adicionar linguagens

Não existe uma extensão única que configure qualquer linguagem automaticamente.
Para cada linguagem suportada pelo Zed, instale sua extensão quando necessária,
o compilador/interpretador e o servidor de linguagem. Verifique o identificador
exato do servidor na documentação da linguagem e configure o caminho em `lsp`.
Acrescente os pacotes em `extraPackages` e a extensão em `extensions` deste módulo.
Exemplos de ferramentas: Rust usa rust-analyzer + cargo/rustc; Go usa gopls + go;
JavaScript/TypeScript usa Node e o servidor indicado pelo Zed; Java precisa de JDK
e servidor Java. Só instalar realce de sintaxe não garante diagnósticos.

Para dependências específicas de projetos, use um devShell Nix e .envrc com
`use flake`. Direnv e nix-direnv já estão habilitados. Após revisar o .envrc,
rode `direnv allow` na pasta; o Zed carrega esse ambiente. Se um projeto exigir
outra versão de um LSP fixado nesta configuração, sobrescreva seu caminho nas
configurações locais .zed/settings.json.

## Aprendizado

Leia a primeira mensagem de erro e corrija uma coisa por vez. Antes de rodar,
preveja o resultado; depois compare. Use o depurador para enxergar como variáveis
mudam. Autocompletar de LSP funciona sem assinatura de IA. Recursos de IA são
opcionais e não foram conectados nem configurados nesta entrega.

## Diagnóstico e limites da verificação

Se o servidor não iniciar, procure `zed: open log` na paleta e copie o erro.
Se aparecer 'iostream not found', configure o projeto CMake primeiro e confira
build/compile_commands.json. Compiladores diferentes ou devShells próprios podem
exigir ajustar --query-driver para o caminho exato e confiável do compilador.

Sintaxe Nix e JSON verificada; script Bash validado e exemplo C++ compilado e
executado com GCC (entrada 21, saída 42).

Não há Nix nem sessão gráfica do Zed neste ambiente: avaliação do Home Manager,
rebuild e funcionamento dos LSPs/depurador precisam ser confirmados no seu NixOS.

Referências oficiais consultadas:
- https://zed.dev/docs/languages/cpp
- https://github.com/zed-extensions/nix
- https://zed.dev/docs/tasks
- https://zed.dev/docs/debugger
- https://zed.dev/docs/languages/python
- https://github.com/nix-community/nixd/blob/main/nixd/docs/configuration.md
