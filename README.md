# snowflake

Flake NixOS compartilhado entre desktop e laptop, com flake-parts, import-tree
e Home Manager. As sessões são Hyprland, Niri e MangoWM, com Niri como padrão.
A sanctuary inicia nas três sessões e fornece launcher, lock, captura e OSD.
O pacote vem de `github:mathiasdavilaa/sanctuary`, sem pasta local da shell.

## Aplicar

O ZIP contém `snowflake/`. Extraia em uma pasta temporária e copie os arquivos
para seu checkout atual, preservando `.git` e seus dados pessoais. O repositório
da sanctuary precisa conter a versão 0.8.3 antes de resolver o novo input.

Na pasta onde você extraiu o ZIP, execute como seu usuário normal:

```sh
cp -a snowflake/. "$HOME/snowflake/"
cd "$HOME/snowflake"
git add -A
nix flake lock
```

O lock mantém as revisões existentes dos outros inputs. `nix flake lock`
resolve somente o input novo. Após o rebuild, saia da sessão e entre novamente
para carregar a nova inicialização e os atalhos do compositor.

Aplique somente o comando correspondente à máquina:

| Host | Comando |
| --- | --- |
| Desktop | `sudo nixos-rebuild switch --flake ~/snowflake#desktop` |
| Laptop | `sudo nixos-rebuild switch --flake ~/snowflake#laptop` |

No Fish, `nrs` detecta a máquina e faz o rebuild; `nru` atualiza os inputs.

## Sanctuary

`modules/desktop/sanctuary.nix` importa os módulos NixOS e Home Manager da shell,
configura PAM e escolhe Ghostty para entradas de terminal. As preferências da
interface ficam em `~/.config/sanctuary/settings.json`; o flake fornece defaults
e não substitui as mudanças feitas no painel de settings.

| Tecla | Função |
| --- | --- |
| Super+D | Launcher sanctuary |
| Super+L / tecla de cadeado | Lock sanctuary |
| Print | Seleção e edição da captura sanctuary |
| Teclas de volume | Volume com OSD |
| Teclas de brilho | Brilho com OSD |

Mute e controles de mídia mantêm seus comandos existentes. As capturas nativas
de tela inteira/janela continuam disponíveis nas teclas específicas que já
existiam. A shell inicia pelo compositor; não há uma segunda inicialização por
Home Manager. O agente Polkit da sanctuary assume a autenticação da sessão.
Swaybg mantém o fundo estático até você configurar um wallpaper na shell.

Para atualizar somente a sanctuary, no diretório do flake:

```sh
nix flake update sanctuary
nrs
```

Para desativar em uma máquina, remova `sanctuary` dos imports do respectivo
`hosts/*/default.nix` e faça rebuild. Os comandos de Fuzzel, Swaylock e os
controles nativos voltam automaticamente naquele host.

Os outros painéis estão disponíveis por `sanctuary settings`,
`sanctuary notifications`, `sanctuary wallpaper`, `sanctuary theme`,
`sanctuary clipboard` e `sanctuary recorder`.

## Ativar ou desativar programas

| O que editar | Arquivo |
| --- | --- |
| Pacotes comuns, por host e exclusões | `modules/packages.nix` |
| Módulos ativos no desktop | `hosts/desktop/default.nix` |
| Módulos ativos no laptop | `hosts/laptop/default.nix` |
| Ferramentas básicas da sessão Wayland | `modules/desktop/common.nix` |
| Ferramentas e extensões do editor | `modules/programs/zed.nix` |
| Yazi, Fzf e ferramentas do terminal | `modules/programs/terminal-tools.nix` |

Em `modules/packages.nix`, `common` vale para ambos os hosts; `desktop` e
`laptop` acrescentam pacotes somente à máquina correspondente. Remova uma
linha para retirar um pacote dessa lista. Para excluir um pacote comum de
apenas uma máquina, use `disabled`. Por exemplo, para retirar Zen só do laptop:

```nix
disabled = {
  desktop = [ ];
  laptop = [ zenBrowser ];
};
```

Para adicionar um programa apenas no desktop:

```nix
desktop = with pkgs; [
  discord
  prismLauncher
  mpv
];
```

Os módulos configuram e instalam seus próprios programas. Para desativar Zed
somente no laptop, remova `zed` dos imports de `hosts/laptop/default.nix`.
Isso retira o editor, a configuração e suas ferramentas daquele host.
A mesma regra vale para `vm-curator`, `macro`, `ghostty`, `fastfetch`, `nh` e
os compositores. Para desligar somente Fzf ou Yazi, mude o `enable` desse
programa em `terminal-tools.nix`. Retirar `fastfetch` dos imports também
remove sua execução automática no Fish.

`base` fornece Home Manager, boot e a lista de pacotes. Os demais módulos
aparecem individualmente nos imports de cada host. `roblox` depende de
`flatpak`: para retirar todo o suporte Flatpak, retire ambos os módulos.
Mantenha os módulos necessários aos comandos usados nos seus atalhos.
Faça o rebuild depois de cada alteração.

## Organização

| Local | Conteúdo |
| --- | --- |
| `flake.nix` / `flake.lock` | Inputs e revisões |
| `parts/hosts.nix` | Perfis desktop (`mad`) e laptop (`mathias`) |
| `hosts/*/default.nix` | Módulos ativos e monitores |
| `hosts/*/hardware-configuration.nix` | Hardware de cada máquina |
| `modules/system/` | Base, boot, GPU, jogos e Howdy |
| `modules/programs/` | Programas e suas configurações |
| `modules/desktop/` | Sessões e ferramentas Wayland |
| `assets/` | Shader do cursor e logo de fallback |

Edite os monitores em cada host; os três compositores usam esses dados.
Zed mantém suporte configurado a Nix, C e C++. Python continua disponível
como dependência dos scripts do macro e da configuração do Sober.

## Terminal e Fastfetch

Fish e Ghostty são configurados pelo Home Manager. Fish abre o
Fastfetch ao iniciar um terminal e mantém `nrs` e `nru`. Ghostty utiliza
GeistMono Nerd Font.

Ghostty é o terminal padrão e possui um rastro de cursor implementado por um shader local. O cursor usa
formato de bloco no prompt. O efeito precisa de Ghostty 1.2 ou mais recente.
Ele anima a superfície enquanto o terminal está focado, conforme a opção
`custom-shader-animation` do Ghostty; isso tem custo adicional de renderização.
Para ajustar velocidade ou intensidade, edite `TRAIL_DURATION` e
`TRAIL_OPACITY` em `assets/ghostty/cursor-trail.glsl` e faça o rebuild.
Para desativar o efeito, retire `custom-shader` e `custom-shader-animation`
das configurações em `modules/programs/ghostty.nix`. Reabra o Ghostty depois
do primeiro rebuild para carregar a nova configuração.

### Recursos úteis do terminal

Os atalhos de terminal usam Ctrl/Shift; as binds dos compositores com Super
continuam independentes. Os ajustes ficam em `modules/programs/ghostty.nix`;
Fzf e a integração do Yazi ficam em `modules/programs/terminal-tools.nix`.

| Ação | Atalho / comando |
| --- | --- |
| Nova aba / janela | `Ctrl+Shift+T` / `Ctrl+Shift+N` |
| Fechar o painel atual | `Ctrl+Shift+W` |
| Próxima / aba anterior | `Ctrl+Tab` / `Ctrl+Shift+Tab` |
| Escolher aba 1–9 | `Ctrl+Shift+1` até `Ctrl+Shift+9` |
| Mover aba | `Ctrl+Shift+Alt+PageUp` / `PageDown` |
| Split à direita / abaixo | `Ctrl+Shift+E` / `Ctrl+Shift+O` |
| Focar outro split | `Ctrl+Shift+setas` |
| Redimensionar split | `Ctrl+Shift+Alt+setas` |
| Ampliar/restaurar split | `Ctrl+Shift+Z` |
| Igualar os splits | `Ctrl+Shift+Alt+0` |
| Copiar seleção / interromper sem seleção | `Ctrl+C` |
| Copiar / colar | `Ctrl+Shift+C` / `Ctrl+Shift+V` |
| Copiar link sob o mouse | `Ctrl+Shift+U` |
| Pular ao prompt anterior / seguinte | `Ctrl+Shift+PageUp` / `PageDown` |
| Início / fim do histórico | `Ctrl+Shift+Home` / `End` |
| Exportar e abrir o histórico no Zed | `Ctrl+Shift+H` |
| Abrir apenas o texto da tela no Zed | `Ctrl+Shift+Alt+H` |
| Abrir o texto selecionado no Zed | `Ctrl+Shift+Alt+S` |
| Buscar texto no histórico | `Ctrl+Shift+F` |
| Paleta de comandos do Ghostty | `Ctrl+Shift+P` |
| Recarregar a configuração | `Ctrl+Shift+R` |
| Aumentar / diminuir / resetar fonte em todas as superfícies | `Ctrl+=` ou `Ctrl++` / `Ctrl+-` / `Ctrl+0` |
| Zoom no teclado numérico | `Ctrl+Num+` / `Ctrl+Num-` / `Ctrl+Num0` |
| Buscar comandos do Fish com Fzf | `Ctrl+R` |
| Escolher arquivo com prévia de texto | `Ctrl+T` |
| Buscar e mudar de diretório | `Alt+C` |
| Abrir Yazi e voltar na pasta escolhida | `y` |

O scrollback tem limite de 32 MiB por superfície. Selecionar texto também o
copia para o clipboard; a proteção de colagem permanece habilitada. Abas,
painéis e janelas aproveitam a pasta atual por meio da integração com o Fish.
A integração SSH ajusta o ambiente remoto e tenta instalar o terminfo do
Ghostty quando ele estiver ausente, com fallback de compatibilidade. Isso
não altera suas chaves SSH.

`Ctrl+C` copia quando existe uma seleção; sem seleção, chega normalmente ao
Fish ou ao programa em execução. `Ctrl+Shift+C` continua disponível para
copiar. O terminal tem margens internas de 8 pontos. A rolagem usa
`Shift+PageUp` e `Shift+PageDown`, deixando `PageUp` e `PageDown` disponíveis
para os editores, o Yazi e outros aplicativos interativos.

Para ajustes pessoais sem rebuild, crie `~/.config/ghostty/user.conf` e
recarregue com `Ctrl+Shift+R`. Esse arquivo é opcional, carrega por último e
não é gerenciado pelo Home Manager. Por exemplo:

```ini
font-size = 11
cursor-style = bar
```

O padrão mantém o cursor de bloco com o rastro configurado.

No Ghostty 1.3 ou superior, `Ctrl+Shift+F` abre a busca visual nativa e
`Ctrl+Shift+Alt+T` renomeia uma aba. Em versões anteriores, o atalho de busca
abre o histórico no Zed; use `Ctrl+F` no editor. A escolha é feita pela versão
do pacote no flake, sem incluir ações novas em versões que não as suportam.
Os atalhos de Fzf e o comando `y` funcionam no prompt do Fish; aplicativos
interativos como editores e multiplexadores têm suas próprias teclas.

Fastfetch conserva as seções Hardware, Software e System Informations. O logo
pessoal fica em `~/.config/fastfetch/ascii.txt`; o rebuild preserva um arquivo
existente e cria um logo de fallback quando ele está ausente.

## Compositores e atalhos

| Ação | Niri | Hyprland | MangoWM |
| --- | --- | --- | --- |
| Terminal | `Super+Enter` | `Super+Enter` | `Super+Enter` |
| Arquivos (Yazi) | `Super+E` | `Super+E` | `Super+E` |
| Abrir aplicativos | `Super+D` | `Super+D` | `Super+D` |
| Fechar janela | `Super+Q` | `Super+Q` | `Super+Q` |
| Bloquear | `Super+L` / tecla de cadeado | `Super+L` / tecla de cadeado | `Super+L` / tecla de cadeado |
| Maximizar / fullscreen | `Super+F` / `Super+Shift+F` | `Super+F` / `Super+Shift+F` | `Super+F` / `Super+Shift+F` |
| Janela flutuante | `Super+V` | `Super+V` | `Super+V` |
| Overview | `Super+grave` | — | `Super+grave` |
| Sair | `Super+Alt+F4` | `Super+Alt+F4` | `Super+Alt+F4` |

Niri usa seus atalhos de foco, colunas, workspaces e monitores. Volume muda em
5% e brilho em 10%, com `wpctl`, `brightnessctl` e `playerctl`.

No Hyprland, as curvas de mola e Bézier animam:
janelas com `popin 92%`, layers com fade, workspaces horizontais e workspace
especial vertical. Home Manager escreve `~/.config/hypr/hyprland.lua` e
gerencia a sessão.

MangoWM usa o módulo NixOS e o módulo Home Manager oficiais. `Super+1` a
`Super+9` selecionam tags no monitor atual e `Super+Ctrl+número` move a janela.
`Super+T` escolhe scroller, `Super+Shift+T` escolhe tile e `Super+R` recarrega
a configuração. Sua configuração está em `~/.config/mango/config.conf`.

Niri mantém sua captura nativa. Hyprland usa Hyprshot. MangoWM usa Grim/Slurp:
`Print` ou `Super+Shift+S` seleciona uma área e envia a imagem ao clipboard.

## Howdy no laptop

Howdy é usado no SDDM do laptop. Swaylock usa senha.
As configurações de câmera IR e emissor existentes estão em
`modules/system/howdy.nix`.

Configure o emissor e cadastre seu rosto, quando necessário:

```sh
sudo linux-enable-ir-emitter configure
sudo systemctl restart linux-enable-ir-emitter
sudo howdy -U mathias add
sudo howdy -U mathias test
```

A senha continua disponível no SDDM. Se mudar de câmera, ajuste `device_path`
e `services.linux-enable-ir-emitter.device` no módulo antes do rebuild.

## Git e SSH (GitHub)

Faça estes passos como seu usuário normal, sem `sudo`. No desktop o usuário
é `mad`; no laptop é `mathias`. A identidade de autor do Git pode ser a mesma
nos dois, com uma chave SSH diferente em cada máquina.

### 1. Conferir a identidade do Git

O Home Manager já configura o Git em `modules/programs/git.nix`:

```nix
user = {
  name = "mathiasdavila";
  email = "mathiasaug@proton.me";
  signingKey = "~/.ssh/id_ed25519.pub";
};
```

Para mudar nome ou e-mail, edite esse bloco e faça o rebuild do host. Evite
`git config --global` para essas opções: a configuração global é gerenciada
pelo Home Manager. Confira o resultado:

```sh
git config --get user.name
git config --get user.email
git config --get user.signingKey
git config --get commit.gpgsign
```

Use um e-mail verificado na sua conta do GitHub, ou o endereço `noreply`
fornecido nas configurações da conta.

### 2. Criar a chave SSH em cada máquina

Confira primeiro se já existe uma chave:

```sh
ls -l ~/.ssh/id_ed25519 ~/.ssh/id_ed25519.pub
```

Se os arquivos existirem, use a chave atual. Se não existirem:

```sh
mkdir -p ~/.ssh
chmod 700 ~/.ssh
ssh-keygen -t ed25519 -C "email@email" -f ~/.ssh/id_ed25519
```

Escolha uma senha para proteger a chave. Se aparecer uma pergunta para
sobrescrever um arquivo existente, responda `n` e confira a chave atual.

`id_ed25519` é a chave privada: mantenha-a fora do repositório.
`id_ed25519.pub` é a chave pública: é ela que será cadastrada no GitHub.
Repita o procedimento em cada host; ambos podem usar o mesmo nome de arquivo,
pois cada chave fica no diretório pessoal da respectiva máquina.

### 3. Carregar a chave no agente

```sh
ssh-add ~/.ssh/id_ed25519
ssh-add -l
```

Informe a senha da chave quando solicitada. Se aparecer
`Could not open a connection to your authentication agent`, abra uma sessão
Fish com um agente temporário e repita os comandos nela:

```sh
ssh-agent fish
ssh-add ~/.ssh/id_ed25519
ssh-add -l
```

Esse agente vale para essa sessão de terminal. A configuração atual aponta a
assinatura do Git para a chave pública, então mantenha a chave privada
correspondente carregada no agente quando fizer commits.

### 4. Cadastrar no GitHub

Mostre e copie a chave pública inteira:

```sh
cat ~/.ssh/id_ed25519.pub
```

No GitHub, abra **Settings → SSH and GPG keys → New SSH key** e cadastre a
chave como **Authentication Key**, com um título que identifique a máquina,
como `snowflake-laptop` ou `snowflake-desktop`.

Como este flake assina os commits com SSH, cadastre a mesma chave pública
novamente como **Signing Key**. Autenticação permite acessar o repositório;
assinatura permite ao GitHub verificar os commits.

Cadastre as chaves dos dois hosts na mesma conta, mantendo títulos separados.

### 5. Testar e usar o remoto SSH

```sh
ssh -T git@github.com
```

Na primeira conexão, confira a impressão digital do servidor na documentação
oficial antes de aceitar. A resposta esperada é uma saudação com seu usuário
do GitHub e a informação de que o serviço não oferece acesso a shell.
Esse teste pode retornar código de saída `1` mesmo quando a autenticação funciona.

No checkout existente:

```sh
cd ~/snowflake
git remote -v
git remote set-url origin git@github.com:mathiasdavilaa/snowflake.git
git ls-remote origin
```

Se estiver usando um fork, substitua `mathiasdavilaa/snowflake` pelo seu
repositório. Não é necessário clonar novamente para mudar de HTTPS para SSH.

Para uma instalação nova usando SSH:

```sh
git clone git@github.com:mathiasdavilaa/snowflake.git ~/snowflake
```

### 6. Permitir a verificação das assinaturas dos dois hosts

O módulo já habilita `gpg.format = "ssh"` e `commit.gpgsign = true`, mas o
arquivo `allowed_signers` contém atualmente apenas uma chave pública fixa.
Esse arquivo serve para verificar assinaturas localmente; não libera acesso
à conta do GitHub.

Em `modules/programs/git.nix`, substitua o conteúdo do bloco abaixo pelas
chaves públicas reais do desktop e do laptop. Cada linha começa pelo e-mail
do autor, seguido do tipo e do conteúdo da chave:

```nix
home.file.".ssh/allowed_signers".text = ''
  mathiasaug@proton.me ssh-ed25519 CHAVE_PUBLICA_DO_DESKTOP
  mathiasaug@proton.me ssh-ed25519 CHAVE_PUBLICA_DO_LAPTOP
'';
```

Os textos `CHAVE_PUBLICA_DO_DESKTOP` e `CHAVE_PUBLICA_DO_LAPTOP` são exemplos:
substitua-os pelo campo longo que começa com `AAAA` na saída de
`cat ~/.ssh/id_ed25519.pub` de cada máquina. Se usar outro e-mail de autor,
ajuste também o início das linhas. Somente as chaves públicas entram no flake.

Faça o rebuild em ambos os hosts. Cada um continua assinando com sua própria
chave local, enquanto os dois passam a reconhecer ambas as assinaturas.
Não edite `~/.ssh/allowed_signers` diretamente: ele é gerenciado pelo Home Manager.

### 7. Commit e push

```sh
cd ~/snowflake
git status
git add README.md modules/programs/git.nix
git diff --cached
git commit -m "docs: configurar Git e SSH"
git log -1 --show-signature
git push origin main
```

Ajuste os arquivos passados ao `git add` conforme a alteração que quiser
publicar. Faça esses comandos depois de aplicar a configuração e carregar a
chave no agente. A assinatura local deve identificar uma chave autorizada;
no GitHub, o commit poderá aparecer como `Verified` quando a chave de assinatura
e a identidade atenderem aos requisitos da conta.

### GitHub CLI (opcional)

O flake também instala `gh`. Para entrar na conta e escolher SSH:

```sh
gh auth login --hostname github.com --git-protocol ssh --web
gh auth status
```

O login do `gh` é útil para operações da API, como issues e pull requests.
Ele não substitui o cadastro da chave de assinatura nem o agente SSH.

### Referências

- [Gerar uma chave SSH e adicioná-la ao agente](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)
- [Adicionar uma chave de autenticação ou assinatura ao GitHub](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account)
- [Impressões digitais SSH do GitHub](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints)
- [Configuração do Git](https://git-scm.com/docs/git-config)

## Atualizar e voltar à geração anterior

```sh
cd ~/snowflake
nix flake update
nrs
```

Para atualizar apenas MangoWM, use `nix flake update mango`. Para voltar à
geração anterior, execute `sudo nixos-rebuild switch --rollback` ou selecione
a geração no bootloader.

## Verificações

```sh
nix flake check --no-build
nix eval .#nixosConfigurations.desktop.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.laptop.config.system.build.toplevel.drvPath
```

Os arquivos e o Lua foram conferidos localmente. O ambiente usado para preparar
este ZIP não tinha Nix, Fish, Niri ou MangoWM, portanto o rebuild dos hosts e a
execução dos compositores precisam ser feitos nas suas máquinas. O input novo
de MangoWM também é resolvido pelo primeiro `nix flake lock`.

## Macro de cliques e posição do cursor (Niri + ydotool)

O módulo `macro` é importado pelo `base` nos dois hosts. Habilita `ydotoold`,
permite ao usuário usar o socket pelo grupo `ydotool` e instala `macro` e
`cursor-pos`. Após o primeiro `nrs`, encerre a sessão e entre novamente para
ativar a associação ao grupo (ou reinicie).

### Ver as coordenadas

```sh
cursor-pos
```

O terminal atualiza a mesma linha em tempo real, mostrando o monitor, os pixels
lógicos globais, os pixels locais ao monitor e os valores `x` e `y` em
porcentagem para usar no macro. Pare com `Ctrl+C`. Para uma saída estruturada,
use `cursor-pos --json`.

A leitura é compatível com o Niri 26.04 e usa uma camada transparente GTK
layer-shell sobre os monitores. Ela recebe os eventos reais do cursor em pixels
lógicos; as origens dos monitores vêm do IPC do Niri. Não precisa de `sudo`,
`xinput`, `xdotool` ou uma versão de desenvolvimento do compositor.

**Enquanto `cursor-pos` estiver aberto, o mouse interage com a camada de
medição, e os cliques não chegam às aplicações.** O terminal mantém o foco do
teclado: use `Ctrl+C` para retirar a camada e voltar a interagir normalmente.
Este modo serve para medir coordenadas, não para monitorar o cursor em segundo
plano enquanto você usa outras aplicações na sessão Niri.

O macro mede e move o cursor nessa camada temporária, depois a destrói e espera
o compositor confirmar a remoção antes de enviar cada clique à aplicação.
O Niri 26.04 não implementa `ext-image-copy-capture-v1`; por isso não usamos
esse protocolo nesta versão do módulo.

### Definir a sequência

Na primeira ativação é criado `~/.config/snowflake/macro.json`, editável e
preservado nos próximos rebuilds. Começa com `points` vazio: não envia cliques
até você definir a sequência. Abra com:

```sh
zed ~/.config/snowflake/macro.json
```

Exemplo de estrutura — substitua os pontos pelos valores do seu `cursor-pos`:

```json
{
  "output": "auto",
  "startDelay": 2,
  "points": [
    { "x": 50, "y": 50, "button": "left", "delay": 0.3 },
    { "x": 75, "y": 80, "button": "left", "delay": 0.5 }
  ],
  "hosts": {}
}
```

- `x` e `y`: porcentagens de 0 a 100, relativas ao monitor escolhido.
- `button`: `left`, `right` ou `middle`; o padrão é `left`.
- `delay`: pausa em segundos **depois** de cada clique; padrão de 0.3.
- `startDelay`: espera antes da sequência; padrão de 2 segundos.
- `output`: `auto` usa o monitor da workspace focada ao iniciar o comando.
  Também aceita um conector específico, como `DP-3` ou `eDP-1`.

Os pontos são recalculados pela resolução lógica real do monitor no momento da
execução. O centro permanece no centro tanto em 1920×1080 quanto em 1920×1200.
Isso requer que a interface mantenha os alvos nas mesmas posições proporcionais:
use a aplicação maximizada/em tela cheia e com o mesmo layout. Se os botões
mudarem de posição entre os dispositivos, use sequências separadas por host.

### Executar, conferir e interromper

```sh
macro --dry-run        # Mostra os destinos sem mover o cursor nem clicar.
macro                  # Executa a sequência uma vez.
macro --output DP-3     # Escolhe explicitamente o monitor do desktop.
macro --output eDP-1    # Escolhe explicitamente a tela do laptop.
macro --stop           # Interrompe a execução, inclusive durante a espera.
```

`Ctrl+C` também interrompe quando o macro é iniciado no terminal. Não mova o
mouse enquanto executa: o script envia movimentos pelo ydotool e verifica a
posição real antes de cada clique. Encerre `cursor-pos` antes de rodar `macro`,
pois uma camada de medição aberta em outro processo receberia os cliques. Se não chegar ao alvo, encerra com erro sem
clicar nesse ponto. Só permite uma execução simultânea por usuário. A sequência
fica vinculada ao monitor escolhido no início e não segue mudanças de foco
provocadas pelos cliques.

Para usar outro arquivo: `macro --config /caminho/macro.json`.

### Pontos diferentes no laptop e no desktop

É possível copiar o mesmo JSON para ambos os dispositivos e ajustar somente os
campos necessários em `hosts`. Os nomes são os perfis do flake (`desktop` e
`laptop`), não os hostnames (`tarnished` e `nixos`). Exemplo:

```json
{
  "output": "auto",
  "startDelay": 2,
  "points": [],
  "hosts": {
    "desktop": {
      "output": "DP-3",
      "points": [{ "x": 50, "y": 50, "delay": 0.3 }]
    },
    "laptop": {
      "output": "eDP-1",
      "points": [{ "x": 52, "y": 48, "delay": 0.3 }]
    }
  }
}
```

Os números acima são apenas exemplos. Os overrides substituem os campos
correspondentes da configuração comum; `--output` tem prioridade sobre ambos.

### Atalho opcional no Niri

Acrescente uma tecla livre ao bloco `binds` de `modules/desktop/niri.nix`:

```kdl
Super+X repeat=false { spawn "macro"; }
Super+Shift+X repeat=false { spawn "macro" "--stop"; }
```

Se aparecer erro de permissão no socket, confira `id -nG` (deve incluir
`ydotool`) e `systemctl status ydotoold`. O leitor de posição e os overrides
do macro continuam destinados ao Niri; não foi feita uma adaptação para os
outros compositores nesta alteração.

## Referências

- [Atalhos do Ghostty](https://ghostty.org/docs/config/keybind)
- [Ações do Ghostty](https://ghostty.org/docs/config/keybind/reference)
- [Opções do Ghostty](https://ghostty.org/docs/config/reference)
- [Instalação do MangoWM](https://mangowm.github.io/docs/installation/)
- [Módulos Nix do MangoWM](https://mangowm.github.io/docs/nix-options/)
- [Regras de monitores do MangoWM](https://mangowm.github.io/docs/configuration/monitors/)
- [Atalhos do MangoWM](https://mangowm.github.io/docs/bindings/keys/)
- [Animações do Hyprland](https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/)
