# snowflake

Configuração declarativa do NixOS organizada em módulos. O flake reúne as
dependências e as configurações de cada máquina, permitindo compartilhar uma
base e manter os ajustes de cada host separados.

## Baixar

Com o NixOS instalado e o suporte a flakes habilitado:

```sh
nix shell nixpkgs#git
git clone https://github.com/mathiasdavilaa/snowflake.git ~/snowflake
cd ~/snowflake
```

Se usar um fork, substitua a URL pela do seu repositório. Você também pode
baixar o repositório como ZIP e extrair o conteúdo em `~/snowflake`.

## Adaptar à sua máquina

Antes de aplicar, confira o perfil que deseja usar e ajuste o nome do usuário,
o hostname, o hardware, os discos e as configurações de boot. Use o
`hardware-configuration.nix` da sua instalação como referência para o host.

Confira também os módulos importados por esse perfil: eles determinam quais
serviços, programas e ambientes serão ativados.

Mantenha `system.stateVersion` e `home.stateVersion` de acordo com sua
instalação. Atualizar os pacotes não exige aumentar esses valores.

## Aplicar

Para consultar os perfis disponíveis:

```sh
nix flake show
```

Aplique a configuração substituindo `PERFIL` pelo nome de uma entrada em
`nixosConfigurations`:

```sh
sudo nixos-rebuild switch --flake ~/snowflake#PERFIL
```

Repita esse comando depois de editar a configuração. Alterações que dependem
de uma nova sessão ou da inicialização do sistema exigem sair e entrar
novamente ou reiniciar.

Se estiver usando Git, adicione os arquivos novos com `git add` antes do
rebuild para que sejam incluídos pelo Nix. Não é necessário fazer um commit
para aplicar alterações locais.

## Organização

| Local | Função |
| --- | --- |
| `flake.nix` | Declara as dependências e os pontos de entrada da configuração. |
| `flake.lock` | Registra as revisões das dependências. |
| `parts/` | Organiza os perfis e a composição do flake. |
| `hosts/` | Guarda o hardware e os ajustes específicos de cada máquina. |
| `modules/` | Reúne configurações reutilizáveis do sistema e dos programas. |

Os hosts escolhem os módulos que utilizam pela lista `imports`. Para mudar
um programa ou serviço, edite o módulo correspondente; para ativar ou remover
um módulo de um perfil, ajuste seus imports.

As configurações compartilhadas ficam nos módulos. As diferenças entre
máquinas ficam nos hosts. Depois de qualquer alteração, faça o rebuild do
perfil desejado.

O sistema base e os programas pessoais não dependem de um ambiente gráfico.
A escolha do ambiente acontece nos imports de `hosts/<perfil>/default.nix`:

| Módulo | Responsabilidade |
| --- | --- |
| `base` | Sistema, Home Manager, boot e programas compartilhados. |
| `ryoku` | Integração completa do Ryoku e seus overrides pessoais. |
| `niri` | Sessão Niri independente, com launcher e bloqueio próprios. |
| `plasma` | Sessão KDE Plasma. |
| `dms` | Shell opcional para a sessão Niri independente. |

Escolha `ryoku`, `niri` ou `plasma` como base gráfica de cada host. Para usar
Niri com DMS, escolha `niri` e acrescente `dms`. Os inputs de `flake.nix` apenas
declaram dependências; um ambiente só é ativado quando seu módulo é importado.
Hardware, jogos, editor, rede e demais programas seguem os mesmos módulos em
qualquer escolha.

## Ambiente e personalização

### WM e interface

`modules/desktop/ryoku.nix` reúne toda a integração do Ryoku: módulo oficial,
sessão principal, aplicativos opcionais, atualização pelo flake, preparação da
base, overrides de Niri e Ghostty e ativação pelo Home Manager. Niri é o
compositor principal; Hyprland também é disponibilizado pelo módulo oficial.
O Hub cuida da aparência, das cores, das animações e dos ajustes do compositor.

Nesse ambiente, o materializador oficial gera os arquivos necessários depois
de o Home Manager instalar os overrides. Na primeira ativação, as
configurações anteriores ficam guardadas em
`~/.local/state/snowflake/ryoku-base-v1/`; o arquivo `backup-path` indica a pasta.
Os overrides declarados no módulo têm prioridade sobre ajustes equivalentes
do Hub. As demais escolhas continuam sob controle da interface.

`modules/desktop/niri.nix` fornece uma sessão independente, com Fuzzel como
launcher e Swaylock para bloqueio. Sua configuração é um único `config.kdl`,
sem includes externos. Escolher esse módulo no host mantém Niri sem carregar
o Ryoku. O módulo Plasma também pode ser escolhido como base gráfica.

### Binds

Na sessão Ryoku, o Niri usa os atalhos fornecidos pelo próprio Ryoku e seus
ajustes pelo Hub. O flake não adiciona substituições pessoais de binds nesse
ambiente. Consulte os atalhos na interface do Ryoku.

Na sessão Niri independente, os atalhos são definidos em
`modules/desktop/niri.nix`. `Super` corresponde à tecla Windows.

### Teclado, mouse e touchpad

O teclado usa os layouts `us,br`, e `Caps Lock` funciona como `Escape`. A
repetição começa após 400 ms, a 30 repetições por segundo. O mouse usa um perfil
de aceleração plano. No touchpad, toque para clicar e rolagem natural ficam
habilitados; durante a digitação, o touchpad é desativado.

Essas opções ficam no bloco `input` do módulo do ambiente escolhido:
`ryoku.nix` ou `niri.nix`.

### Terminal e arquivos

Ghostty e Fish têm configurações independentes em `modules/programs/`.
O módulo Fish também disponibiliza Fastfetch quando sua configuração é usada.

Ao escolher Ryoku, `ryoku.nix` deixa o materializador cuidar dos arquivos
principais de Fish, Ghostty e Fastfetch. A configuração do Ghostty segue a
paleta do ambiente, com escolhas pessoais em `ghostty/user.conf`. Esses ajustes
específicos ficam no próprio `ryoku.nix`; os módulos genéricos continuam
utilizáveis com outros ambientes.

`nrs` aplica o perfil da máquina; `nru` atualiza as dependências em
`~/snowflake`, e `nru ryoku` atualiza apenas esse input. São comandos disponíveis
em qualquer shell, definidos em `modules/programs/flake-tools.nix`.

### Editor

O Zed mantém sua configuração própria em `modules/programs/zed.nix`: tema One
Dark, ícones Material, fonte GeistMono Nerd Font e indentação padrão de dois
espaços. A formatação automática fica desabilitada, e a manual permanece
disponível. O terminal integrado usa Fish e abre no diretório do projeto.

### Monitores, hardware e jogos

Os hosts definem resolução, frequência, escala, posição e orientação dos
monitores. Com Ryoku, essas escolhas geram `niri/monitors_user.kdl`, que tem
prioridade sobre o layout automático. Na sessão Niri independente, elas entram
no próprio `config.kdl`. Para deixar um monitor sob controle do Ryoku, retire
sua entrada da lista do host. O Plasma usa suas próprias configurações de tela.

O desktop usa os módulos de GPU e jogos. Steam, GameMode e MangoHud ficam em
`modules/system/optimization.nix`; a GPU é configurada em
`modules/system/graphics.nix`. O bootloader é o Limine, configurado em
`modules/system/boot.nix` e complementado pelos ajustes de cada host.

## Atualizar

Para buscar as versões mais recentes das dependências e aplicá-las:

```sh
cd ~/snowflake
nix flake update
sudo nixos-rebuild switch --flake .#PERFIL
```

Para atualizar apenas uma dependência, substitua `INPUT` pelo nome declarado
em `flake.nix`:

```sh
nix flake update INPUT
```

A atualização modifica `flake.lock`; o rebuild aplica a configuração com as
novas revisões.

## Voltar à geração anterior

```sh
sudo nixos-rebuild switch --rollback
```

Se o sistema não iniciar corretamente, selecione uma geração anterior no menu
de boot. O rollback restaura a geração do sistema; não desfaz as edições feitas
nos arquivos do repositório.
