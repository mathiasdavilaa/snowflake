# snowflake

Minha configuração do NixOS para desktop e laptop. Uso Plasma e Niri com iNiR,
com SDDM na tela de login. O flake também cuida dos programas, do ambiente do
usuário e das configurações de cada máquina.

O desktop tem os ajustes de NVIDIA e jogos. O laptop compartilha a base, mas
mantém seu próprio hardware e seus monitores.

## Instalação

As instruções abaixo partem de um NixOS já instalado. Para usar em outra máquina,
ajuste o usuário, os discos e o hardware antes de aplicar a configuração.

### 1. Clonar

Com Git instalado:

```sh
git clone https://github.com/mathiasdavilaa/snowflake.git ~/snowflake
cd ~/snowflake
```

Se precisar do Git, abra um shell temporário com `nix-shell -p git`.

O caminho `~/snowflake` é usado pelos atalhos de rebuild e pelo `nh`. Se preferir
outra pasta, ajuste `modules/programs/fish.nix` e `modules/programs/nh.nix`.

### 2. Escolher o perfil e ajustar o usuário

Os perfis disponíveis são `desktop` e `laptop`. Cada um tem seus imports em
`hosts/<perfil>/default.nix`.

Em `parts/hosts.nix`, troque `mad` pelo usuário que vai usar o sistema. Usar o
nome do seu usuário atual facilita manter a conta e a senha existentes. Confira
também o hostname no arquivo do host; a função `nrs` identifica o perfil por ele.

### 3. Gerar a configuração de hardware

Guarde sua configuração atual antes de começar. Gere o arquivo de hardware
para a máquina onde o flake será aplicado:

```sh
# Desktop
sudo nixos-generate-config --show-hardware-config > hosts/desktop/hardware-configuration.nix
```

No laptop, use `hosts/laptop/hardware-configuration.nix` como destino.

Confira as montagens e os UUIDs gerados. O desktop também importa `ssd.nix`,
que monta um disco extra em `/mnt/ssd`. Ajuste esse arquivo ou remova seu import
se não usar esse disco.

O módulo `graphics` configura a NVIDIA do desktop. Se sua GPU for diferente,
adapte o módulo ou retire-o dos imports. Revise os dados de `monitors` no host
para definir as saídas, resoluções, frequências e posições do Niri.

O boot usa Limine com suporte a UEFI. Confira se essa configuração corresponde
à instalação da sua máquina. Preserve os valores de `system.stateVersion` e
`home.stateVersion` apropriados à sua instalação; eles não são números de
versão para aumentar a cada atualização.

### 4. Conferir e aplicar

Arquivos novos precisam estar no Git para entrar no flake. Depois dos ajustes,
confira `git status` e adicione os arquivos que você criou. Por exemplo:

```sh
git add hosts/desktop/hardware-configuration.nix
nix --extra-experimental-features 'nix-command flakes' flake check --no-build
sudo nixos-rebuild switch --flake .#desktop --option experimental-features 'nix-command flakes'
```

Para o laptop, use `.#laptop`. O primeiro rebuild pode levar um tempo por causa
dos downloads e das compilações. Se você criou um usuário novo, defina sua senha
com `sudo passwd nome-do-usuario` antes de sair da sessão.

### 5. Entrar na sessão

Depois do rebuild, execute como seu usuário:

```sh
systemd-tmpfiles --user --create
```

Isso cria os links de usuário usados pela integração do iNiR. Saia da sessão e
entre novamente para carregar os grupos e o ambiente atualizados.

No SDDM, escolha Plasma ou Niri. Plasma é a sessão padrão. Para iniciar o Niri
por uma TTY, use `niri-session`.

## Windows e Secure Boot

No desktop, o menu do Limine tem uma entrada `Windows` que usa a entrada UEFI
`Windows Boot Manager` já existente. Ao selecioná-la, o computador reinicia
para o firmware abrir o Windows diretamente. Se reinstalar o Windows, confira
se essa entrada ainda aparece em `sudo efibootmgr -v`.

A assinatura do Limine está habilitada no desktop. O primeiro rebuild gera as
chaves locais em `/var/lib/sbctl` quando elas ainda não existem e assina o
bootloader. As chaves privadas ficam fora do repositório; não as coloque no Git.
Isso prepara o boot, mas cadastrar as chaves na UEFI exige uma etapa manual em
cada computador. O laptop mantém Secure Boot desabilitado no módulo até ser
configurado separadamente.

Para concluir no desktop:

1. Com Secure Boot ainda desabilitado na BIOS, aplique o flake com `nrs` e
   confira `sudo sbctl status`.
2. Se o Windows usa BitLocker ou criptografia do dispositivo, guarde a chave
   de recuperação antes de alterar as chaves da UEFI.
3. Entre na BIOS e coloque Secure Boot em **Setup Mode**, conforme as instruções
   da placa-mãe. Volte ao NixOS com Secure Boot ainda desabilitado.
4. Confira que `sudo sbctl status` informa Setup Mode e cadastre as chaves:

   ```sh
   sudo sbctl enroll-keys --microsoft --firmware-builtin
   ```

5. Rode `nrs` novamente e confira as assinaturas com `sudo sbctl verify`.
   O verificador pode listar arquivos de outros bootloaders não assinados por
   suas chaves; o Limine em uso precisa estar assinado. Não assine o bootloader
   do Windows novamente: ele já tem assinatura Microsoft.
6. Habilite Secure Boot na BIOS. Após iniciar o NixOS, confira com
   `sudo sbctl status` e `sudo bootctl status`.

Os rebuilds seguintes assinam o Limine e atualizam a configuração autenticada
automaticamente. Edite as entradas pelo flake, sem alterar `limine.conf` à mão.
As instruções oficiais estão na [wiki do NixOS](https://wiki.nixos.org/wiki/Limine).

## Como o flake funciona

`flake.nix` declara as dependências e carrega os arquivos de `parts/` e
`modules/` com `flake-parts` e `import-tree`.

Os módulos são registrados em `self.nixosModules`. Cada host escolhe quais
ativar pela sua lista de imports. Colocar um arquivo em `modules/` faz o flake
carregá-lo, mas um módulo registrado só passa a configurar o sistema quando
é importado pelo host ou por outro módulo.

| Caminho | Função |
|---|---|
| `flake.nix` | Inputs e composição do flake |
| `flake.lock` | Revisões fixadas das dependências |
| `parts/hosts.nix` | Criação dos perfis e definição dos usuários |
| `parts/systems.nix` | Sistemas usados pelos outputs auxiliares e formatador |
| `hosts/` | Hardware, discos, hostname, monitores e imports de cada máquina |
| `modules/packages.nix` | Pacotes comuns e exclusivos de cada perfil |
| `modules/system/` | Base do sistema, boot, Home Manager, GPU e jogos |
| `modules/desktop/` | Plasma, Niri, iNiR e scripts da sessão |
| `modules/programs/` | Configuração de programas e ferramentas |

O módulo `base` reúne rede, áudio, fontes, usuário, SDDM e os programas básicos.
O Home Manager está integrado ao NixOS: configurações do usuário são aplicadas
no mesmo rebuild, sem precisar rodar `home-manager switch` separadamente.

Para desativar um módulo em uma máquina, retire-o dos imports desse host.
Confira as dependências: por exemplo, `niri` importa `inir`, e `base` importa
`packages` e `homeManager`.

## Pacotes

Em `modules/packages.nix`, a primeira lista vale para os dois hosts. As listas
condicionadas pelo `profile` ficam só no desktop ou só no laptop. Programas que
precisam de serviços ou configurações próprias têm módulos separados.

Uso o Zed como editor principal.

## Niri e iNiR

A configuração do Niri fica em `modules/desktop/niri.nix`. Os monitores são
lidos dos dados definidos no host; os atalhos e o layout ficam no módulo.

O iNiR usa a integração comunitária do
[LATAR-web/inir-nixos](https://github.com/LATAR-web/inir-nixos). O flake importa
os módulos e patches necessários, mantendo SDDM e a configuração local do Niri.
A shell e o sincronizador de cores acompanham a sessão Niri.

Um patch local no launcher evita que a ausência de variáveis opcionais no
config do Niri interrompa a inicialização da shell.

O arquivo principal do Niri é gerenciado pelo Home Manager. Para alterar seus
atalhos ou monitores, edite o flake. As cores geradas pelo iNiR ficam em um
fragmento separado, `~/.config/niri/colors.kdl`.

Se uma instalação manual antiga estiver em `~/.config/quickshell/inir`, renomeie
o diretório como backup antes de criar os links de usuário. Não é necessário
executar o instalador do projeto comunitário.

Alguns atalhos do Niri:

| Atalho | Ação |
|---|---|
| Super+Enter ou Super+W | Terminal |
| Super+E | Yazi |
| Super+D ou Super+Space | Launcher |
| Super+Q | Fechar janela |
| Super+V | Alternar janela flutuante |
| Super+Shift+F | Tela cheia |
| Super+H/J/K/L ou setas | Mudar o foco |
| Super+1–9 | Mudar de workspace |
| Super+Shift+1–9 | Mover janela para um workspace |
| Super+Comma | Configurações do iNiR |
| Super+Alt+L | Bloquear a sessão |

## Uso diário

No Fish, `nrs` aplica a configuração do host atual e `nru` atualiza os inputs.
A atualização das dependências só entra no sistema depois de um rebuild.

Também dá para usar os comandos diretamente, dentro do repositório:

```sh
nix fmt
nix flake check --no-build
nix flake update
sudo nixos-rebuild switch --flake .#desktop
```

Para atualizar somente a integração comunitária do iNiR:

```sh
nix flake update inir-nixos
```

O iNiR é atualizado pelo flake. Use esse caminho em vez de `inir update`.
Mantenha o `flake.lock` no Git para registrar quais dependências estão em uso.

O `nh` está disponível para rebuilds, e sua limpeza automática remove gerações
antigas periodicamente. Para voltar à geração anterior:

```sh
sudo nixos-rebuild switch --rollback
```

Se a sessão não abrir, também é possível selecionar uma geração anterior no
menu do Limine durante o boot.

Para investigar problemas na shell:

```sh
systemctl --user status inir
journalctl --user -u inir -b
inir logs --full
```

## Créditos

Este flake reúne meu jeito de configurar o sistema, mas depende do trabalho de
muita gente. Os projetos abaixo fornecem a base, os módulos e as ferramentas
usadas aqui. Os créditos de cada projeto pertencem aos seus autores e
colaboradores.

| Projeto | Uso neste flake |
|---|---|
| [Nix](https://github.com/NixOS/nix) | Gerenciador de pacotes e flakes |
| [NixOS / nixpkgs](https://github.com/NixOS/nixpkgs) | Sistema, pacotes e módulos do NixOS |
| [Home Manager](https://github.com/nix-community/home-manager) | Configurações do usuário |
| [flake-parts](https://github.com/hercules-ci/flake-parts) | Organização dos outputs do flake |
| [import-tree](https://github.com/vic/import-tree) | Carregamento dos arquivos de módulos |
| [nixpkgs.lib](https://github.com/nix-community/nixpkgs.lib) | Biblioteca usada pelo flake-parts |
| [nix-flatpak](https://github.com/gmodena/nix-flatpak) | Configuração declarativa dos aplicativos Flatpak |
| [zen-browser-flake](https://github.com/0xc000022070/zen-browser-flake) | Integração do Zen Browser com Nix |
| [Niri](https://github.com/niri-wm/niri) | Compositor Wayland |
| [iNiR](https://github.com/snowarch/inir) | Shell usada na sessão Niri |
| [inir-nixos](https://github.com/LATAR-web/inir-nixos) | Integração comunitária do iNiR com NixOS, módulos e patches |
| [Quickshell](https://github.com/quickshell-mirror/quickshell) | Base da interface do iNiR |
| [xwayland-satellite](https://github.com/Supreeeme/xwayland-satellite) | Aplicativos X11 na sessão Niri |
| [KDE Plasma](https://invent.kde.org/plasma) | Ambiente desktop |
| [SDDM](https://github.com/sddm/sddm) | Tela de login |
| [Limine](https://github.com/limine-bootloader/limine) | Bootloader |
| [sbctl](https://github.com/Foxboron/sbctl) | Chaves e assinatura para Secure Boot |
| [efibootmgr](https://github.com/rhboot/efibootmgr) | Consulta das entradas de boot UEFI |
| [nh](https://github.com/nix-community/nh) | Rebuilds e limpeza de gerações |
| [Zed](https://github.com/zed-industries/zed) | Editor principal |
| [VM Curator](https://github.com/mroboff/vm-curator) | Gerenciamento de máquinas virtuais |
| [QEMU](https://gitlab.com/qemu-project/qemu) | Execução das máquinas virtuais |
| [ydotool](https://github.com/ReimuNotMoe/ydotool) | Automação de teclado e mouse para o macro |
| [GameMode](https://github.com/FeralInteractive/gamemode) | Ajustes durante a execução de jogos |
| [MangoHud](https://github.com/flightlessmango/MangoHud) | Monitoramento de desempenho |
| [Prism Launcher](https://github.com/PrismLauncher/PrismLauncher) | Launcher do Minecraft |
| [Vinegar](https://github.com/vinegarhq/vinegar) | Roblox Studio no Linux |
| [Rojo](https://github.com/rojo-rbx/rojo) | Ferramenta para projetos do Roblox |

O [Sober](https://sober.vinegarhq.org/) também é usado para jogar Roblox. O link
leva à página oficial do projeto.
