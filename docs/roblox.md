# Roblox como complemento do Zed

O módulo `modules/programs/roblox.nix` está importado no desktop e no laptop.
Ele adiciona Vinegar pelo Flatpak, Rojo e suporte a Luau no Zed. Os recursos
principais de Nix, C++ e outras linguagens continuam em modules/home/zed.nix.

## Aplicar

Copie os arquivos atualizados para seu flake. Como há um novo módulo, dentro
de ~/snowflake execute:

```sh
git add modules/programs/roblox.nix hosts/desktop/default.nix hosts/laptop/default.nix
sudo nixos-rebuild switch --flake .#desktop
```

No laptop use .#laptop. Reinicie o Zed. O módulo Flatpak existente instala o
Vinegar declarativamente; o Studio e seu login são preparados na primeira
abertura do Vinegar. Se a instalação Flatpak ainda estiver em andamento,
consulte `flatpak list` antes de abrir o aplicativo.

## Primeiro projeto

1. Abra o Vinegar pelo launcher e conclua a instalação e o login no Studio.
2. Copie examples/roblox-iniciante para sua pasta de estudos. Abra a pasta
   copiada como um projeto próprio no Zed: ela contém default.project.json.
3. Instale no Studio o plugin oficial do Rojo, compatível com a versão indicada
   por `rojo --version`. Use a página oficial de instalação abaixo. Se a
   instalação pelo site não funcionar no Wine, baixe o .rbxm da release
   correspondente e coloque-o na pasta aberta por **Plugins Folder** no Studio.
   O caminho dessa pasta vem do Studio; não presuma um prefixo Wine do host,
   pois o Flatpak usa seu próprio ambiente.
4. No Zed, Ctrl+Shift+P → `task: spawn` → `Roblox: iniciar Rojo`.
5. Execute também `Roblox: atualizar sourcemap`. Mantenha as duas tarefas
   abertas. O sourcemap permite que o LSP conheça a árvore descrita pelo Rojo.
6. No Studio, abra um place novo (por exemplo Baseplate). No plugin Rojo,
   conecte ao servidor local na porta exibida no terminal, normalmente 34872,
   e revise a sincronização inicial.
7. Edite os arquivos .luau no Zed e salve. Teste com Play no Studio e observe
   as mensagens no painel Output. Breakpoints do jogo ficam no Studio.

O exemplo sincroniza as pastas de scripts indicadas em default.project.json;
o mapa continua sendo editado e salvo no Studio. A tarefa de gerar .rbxlx cria
um place a partir do projeto em disco; ela não exporta o mapa que você construiu
apenas no Studio. Para projetos existentes, use o guia de migração do Rojo e
confira o que será sincronizado antes de conectar.

## Limites e funcionamento

O .zed/settings.json do exemplo habilita as definições da API Roblox na extensão
Luau e o uso do sourcemap. A extensão pode baixar documentação e definições na
primeira abertura. O servidor luau-lsp é fornecido pelo Nix. Os arquivos .lua
comuns continuam usando Lua; prefira .luau para Roblox.

Rojo e Studio não iniciam automaticamente com a sessão. As tarefas Roblox
existem apenas nesse projeto. Para outros projetos Roblox, copie/adapte a pasta
.zed e mantenha o nome do arquivo de projeto consistente.

O sourcemap conhece os objetos representados no projeto Rojo. Objetos criados
somente dentro do Studio podem não aparecer nas sugestões do Zed. A integração
adicional com o plugin de luau-lsp/proxy não foi ativada.

Vinegar é uma camada comunitária de compatibilidade, não uma versão oficial do
Studio para Linux. A execução e o login dependem da compatibilidade atual do
Wine e do Studio. Não foram testados neste ambiente.

## Desativar o complemento

Remova `roblox` dos imports em hosts/<host>/default.nix e faça rebuild.
A configuração principal do Zed permanece. Instalações Flatpak já feitas e
extensões já baixadas podem permanecer: remover a declaração não garante a
desinstalação, especialmente com configurações mutáveis do Home Manager.
Se quiser removê-las também, desinstale a extensão Luau no Zed e use
`flatpak uninstall org.vinegarhq.Vinegar` (sem --delete-data para preservar dados).

## Referências

- https://github.com/4teapo/zed-luau
- https://vinegarhq.org/Vinegar/Installation.html
- https://rojo.space/docs/v7/getting-started/installation/
- https://rojo.space/docs/v7/getting-started/porting-an-existing-game/

## Verificação desta entrega

Sintaxe Nix, JSON e TOML validada. A comparação estrutural dos arquivos Nix
confirmou que a limpeza não alterou o código; nos hosts foi acrescentado o
import roblox. O flake.lock foi preservado. Não foram executados rebuild NixOS,
Rojo, Studio ou a sessão gráfica do Zed neste ambiente.

## Desempenho

Os ajustes ficam em modules/programs/roblox.nix e valem nos hosts que o importam:

- Sober: graphics_optimization_mode = "balanced" equilibra qualidade visual e
  desempenho. O perfil "performance", que reduz texturas e detalhes distantes,
  não é imposto. A qualidade gráfica dentro de cada jogo continua ajustável.
- GameMode: habilitado no sistema e solicitado pelo Sober. O governador de CPU
  desejado é performance durante o uso, conforme o suporte do hardware. No
  desktop, os ajustes de optimization.nix continuam valendo.
- Studio/Vinegar: carrega ntsync em kernels 6.14 ou mais novos e permite acesso
  ao dispositivo pelo grupo gamemode. O Wine precisa oferecer suporte e usar
  o dispositivo; carregar o módulo sozinho não comprova um ganho.

Feche o Sober antes do rebuild. Se estiver aberto, a aplicação do JSON é adiada:
feche-o e repita o rebuild. Reinicie o computador após a primeira aplicação para
carregar o módulo e atualizar os grupos da sessão.

A ativação mescla somente os dois ajustes do Sober, preservando outras opções e
mantendo o arquivo gravável. Se houver configuração anterior, guarda uma cópia
em config.json.before-performance, ao lado de config.json. Um JSON inválido é
preservado e gera aviso. As opções geridas pelo módulo são reaplicadas no rebuild.
Remover o módulo não restaura automaticamente o JSON: para desfazer o modo de
qualidade, altere-o nas configurações do Sober depois de remover o módulo.

Não foi imposto outro renderizador ao Studio. A recomendação do Vinegar é DXVK
para GPUs com Vulkan 1.4; em outros casos, o renderizador precisa ser escolhido
conforme o suporte da GPU. No Sober também foi preservada qualquer escolha
anterior de renderizador. Não foram adicionados pacotes de FastFlags.

Para conferir após reiniciar:

```sh
ls -l /dev/ntsync
gamemoded -s
```

Execute a consulta de GameMode durante uma partida no Sober. Para verificar se
o Wine realmente abriu NTSync enquanto o Studio está em execução, use lsof
sobre /dev/ntsync, caso tenha essa ferramenta instalada. Compare desempenho no
mesmo jogo/cena e nas mesmas condições; não há ganho de FPS medido nesta entrega.

A sintaxe e o script de mescla foram verificados, incluindo preservação de
opções, backup, execução repetida, JSON inválido e Sober aberto. O rebuild,
GameMode e NTSync não puderam ser testados no sistema de destino.

Fontes consultadas:
- https://vinegarhq.org/Sober/Configuration/index.html
- https://vinegarhq.org/Vinegar/FAQ/index.html
- https://vinegarhq.org/Vinegar/Configuration/TipsAndTricks.html
- https://docs.kernel.org/userspace-api/ntsync.html
