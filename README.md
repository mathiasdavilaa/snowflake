# Snowflake

Flake NixOS com `flake-parts` e `import-tree`. `parts/hosts.nix` define
`desktop` e `laptop`; os imports em `hosts/<perfil>/default.nix` escolhem os
módulos de cada host.

## Estrutura

- `modules/packages.nix`: pacotes comuns e específicos de cada host. Zed é
  instalado como `zed-editor` nos dois hosts, sem configuração do editor gerida
  pelo Home Manager. Os dois módulos `zed.nix` foram removidos.
- `modules/system/base.nix`: rede, áudio, fontes, usuário e tela de login SDDM.
- `modules/system/graphics.nix` e `optimization.nix`: NVIDIA e jogos do desktop.
- `modules/desktop/plasma.nix`: Plasma 6 nos dois hosts.
- `modules/desktop/niri.nix`: Niri, monitores por host e atalhos.
- `modules/desktop/inir.nix`: shell iNiR, iniciada somente com `niri.service`.

Hyprland, DMS, split-monitor-workspaces e hyprlauncher foram removidos, além de
MangoWM, Pleamar e Marea. O pacote iNiR também omite sua dependência opcional do
compositor Hyprland. Plasma 6 voltou nos dois hosts. MangoHud foi preservado:
é a ferramenta de métricas dos jogos, não o compositor.

## iNiR e Niri

O input `github:snowarch/inir/main` acompanha o ramo estável. O lock deste pacote
fixa iNiR 2.32.0, commit `c08bb928fe71c6a00bfede3e99ef26fb1825ebe2`.
O suporte upstream ao NixOS é **experimental**. O instalador Arch não é usado.
Niri vem do nixpkgs já fixado no flake. O xwayland-satellite foi atualizado
isoladamente de 0.8.2 para 0.8.3: a versão 0.8.2 tem uma regressão de popups do
Steam, corrigida no release de 24/09/2026. O overlay em `niri.nix` também aplica
a versão corrigida ao runtime do iNiR e deixa de substituir o pacote quando
nixpkgs fornecer 0.8.3 ou mais recente. O flake.lock permanece igual.
Fonte: https://github.com/Supreeeme/xwayland-satellite/releases/tag/v0.8.3

Após aplicar o rebuild, saia da sessão gráfica e entre novamente. Confira com
`xwayland-satellite --version`. Não basta reiniciar somente o Steam.

Na tela do SDDM, escolha **Niri** para iniciar Niri + iNiR ou **Plasma** para
Plasma 6. Plasma é a sessão padrão. Se iniciar por TTY,
use `niri-session`, pois a inicialização do iNiR depende da sessão systemd.

Os monitores usam os dados existentes em cada host, incluindo rotação, posição,
resolução e frequência. Não há variável DISPLAY fixada nem Satellite iniciado
manualmente: Niri faz a integração automática.

Atalhos principais do Niri:

| Atalho | Ação |
|---|---|
| Super+W / Super+Enter | Ghostty |
| Super+E | Yazi |
| Super+D / Super+Space | Launcher iNiR |
| Super+Q | Fechar janela |
| Super+V | Alternar janela flutuante |
| Super+F / Super+Shift+F | Maximizar coluna / fullscreen |
| Super+PageUp / Super+PageDown | Largura de 50% / 80% |
| Super+HJKL ou setas | Foco |
| Super+Shift+HJKL ou setas | Mover janela/coluna |
| Super+Ctrl+Left/Right | Foco no monitor à esquerda/direita |
| Super+Ctrl+Shift+Left/Right | Mover janela para outro monitor |
| Super+1–9 / Super+Shift+1–9 | Workspace / mover janela |
| Super+Ctrl+1–9 | Mover janela sem seguir |
| Super+I / Super+U | Workspace acima / abaixo |
| Super+Shift+V | Clipboard iNiR |
| Super+Comma | Configurações iNiR |
| Super+Alt+L | Bloquear |
| Super+Alt+F4 | Sair da sessão |
| Super+F6 | Executar o macro existente |

Niri usa workspaces dinâmicos: um número maior que a quantidade existente vai
para o último workspace vazio. Não replica os nove workspaces persistentes por
monitor de uma configuração estática. A configuração KDL é gerida neste flake; edite
`modules/desktop/niri.nix`, não o link em `~/.config/niri/config.kdl`.

O macro original foi preservado. Ele usa ydotool e seu array de posições está
vazio nesta versão de origem. O auxiliar `mouse-position`, que dependia de `hyprctl`, foi removido.
As coordenadas devem ser verificadas antes de usar um macro no Niri.

## Aplicar

Este ZIP é uma árvore completa substituta, não uma sobreposição: extrair por cima
não apaga os módulos antigos. Guarde a árvore anterior e substitua os arquivos
rastreados pelos deste pacote, preservando seu `.git`. Antes do rebuild, confira
`git status` e registre os arquivos novos e as remoções pretendidas.

```sh
nix flake check --no-build
nix eval .#nixosConfigurations.desktop.config.system.build.toplevel.drvPath --raw
nix eval .#nixosConfigurations.laptop.config.system.build.toplevel.drvPath --raw
sudo nixos-rebuild switch --flake .#desktop
# No laptop, use .#laptop.
```

Para atualizar apenas iNiR futuramente:

```sh
nix flake update inir
sudo nixos-rebuild switch --flake .#desktop
```

Não use `inir update` nesta instalação Nix. Preferências da shell continuam
nos arquivos graváveis de estado/configuração do iNiR. Para investigar falhas:
`systemctl --user status inir` e `inir logs --full`.

## Validação desta entrega

- `nix flake check --no-build`: aprovado para x86_64-linux.
- Avaliação completa de `system.build.toplevel.drvPath`: desktop e laptop aprovados.
- `niri validate` com Niri 26.04: configuração dos dois hosts aprovada.
- Inputs existentes preservados; somente iNiR adicionado e inputs removidos limpos.
- Não foi executado um build completo dos sistemas nem uma sessão gráfica/jogos.

O patch `snowflake-plasma-niri.patch` aplica esta mudança sobre o ZIP anterior
`snowflake-niri-inir-satellite-fix.zip`, incluindo as remoções. Execute dentro
do repositório:

```sh
git apply --check /caminho/snowflake-plasma-niri.patch
git apply /caminho/snowflake-plasma-niri.patch
```

### Verificação do Satellite 0.8.3

`nix flake check --no-build` passou novamente para os dois hosts. O build
isolado do Satellite foi tentado, mas parou na preparação das dependências
Cargo: o ambiente de execução bloqueou o socket AF_UNIX do multiprocessing
Python (PermissionError). O build completo e o comportamento gráfico não
foram confirmados aqui. As hashes de fonte e Cargo vieram da receita upstream
do nixpkgs para 0.8.3.
