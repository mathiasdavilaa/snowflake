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

## Desbloqueio facial IR no laptop (Howdy)

O host `laptop` importa `howdy`; o desktop permanece sem esse módulo.
A câmera IR identificada é `/dev/video2`, com formato GREY, 640×360.
A configuração usa o caminho persistente em `/dev/v4l/by-id/`.

O módulo usa o Howdy nativo do nixpkgs fixado neste flake e habilita o
linux-enable-ir-emitter. A integração é específica para a lockscreen qylock
incluída na revisão atual do Ryoku: uma conversa PAM facial independente
começa quando o compositor confirma o bloqueio. A senha continua disponível
em paralelo. A tentativa facial dura até 8 segundos; se falhar, use a senha.
Uma nova tentativa acontece no próximo bloqueio. Para habilitar também no
SDDM, acrescente ao módulo `howdy.nix`, junto da configuração PAM:

```nix
security.pam.services.sddm.howdy = {
  enable = true;
  control = "sufficient";
};
```

Faça o rebuild do laptop depois da alteração. A senha permanece como alternativa
no SDDM; sudo e outros serviços continuam com seus métodos anteriores.

Howdy é menos seguro que uma senha, mesmo com câmera IR. Mantenha a senha
configurada; o projeto alerta que reconhecimento pode ser enganado por uma
pessoa parecida ou uma foto bem impressa.

### Ativação no laptop

Copie os arquivos atualizados para seu checkout do flake. Antes do rebuild,
adicione os arquivos novos ao índice do Git (não é necessário fazer commit):

```bash
cd ~/snowflake
git add modules/system/howdy.nix modules/system/howdy-ryoku.py hosts/laptop/default.nix
sudo nixos-rebuild switch --flake .#laptop
```

Reinicie o laptop para carregar os novos grupos e rematerializar o bloqueador.
Depois configure o emissor e cadastre o rosto para o usuário do host:

```bash
nix shell nixpkgs#xhost --command xhost +SI:localuser:root
sudo env DISPLAY="$DISPLAY" GDK_BACKEND=x11 linux-enable-ir-emitter configure
sudo systemctl restart linux-enable-ir-emitter
sudo howdy -U mathias add
sudo systemd-tmpfiles --create
sudo env DISPLAY="$DISPLAY" GDK_BACKEND=x11 howdy -U mathias test
nix shell nixpkgs#xhost --command xhost -SI:localuser:root
```

Execute os comandos um por vez, no terminal da sessão gráfica. O `xhost`
libera temporariamente o acesso de root ao Xwayland para as janelas de teste;
o último comando remove essa autorização. Feche o teste com `Ctrl+C` antes
de executá-lo. Essa autorização não é necessária para o reconhecimento na
lockscreen. Se um comando falhar, resolva o erro antes de continuar.

O configurador do emissor é interativo: responda conforme o comportamento
observado do emissor IR. Se a imagem permanecer escura, confira esse passo
antes de alterar os limites de reconhecimento. O cadastro fica em
`/var/lib/howdy/models/mathias.dat`, fora do flake, com acesso restrito ao grupo
`howdy`. O último comando testa imagem/reconhecimento; o teste definitivo da
integração deve ser feito bloqueando a sessão normalmente pelo Ryoku.

Se o teste como root funcionar mas o desbloqueio não, confira os grupos na
sessão (`id`) e as permissões do modelo (`ls -l /var/lib/howdy/models/mathias.dat`).
O usuário deve pertencer aos grupos `video` e `howdy`, e o modelo deve pertencer
a `root:howdy` com modo `0640`. Repita `sudo systemd-tmpfiles --create` após
recadastrar o rosto.

O script aplica a integração depois do materializador do Ryoku. Se uma revisão
futura mudar os pontos de integração do QML, ele interrompe a aplicação sem
reescrever parcialmente a lockscreen e exige revisão do script.

Validação desta alteração: conferência dos módulos e opções na revisão fixada
do nixpkgs/Ryoku, teste de aplicação do patch sobre o QML dessa revisão,
idempotência e rejeição de QML incompatível. Não foi executado rebuild NixOS
nem teste físico da câmera no ambiente de edição.

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
plano enquanto você usa outras aplicações. Não foi projetado para Plasma.

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

Acrescente estas linhas ao bloco `binds` de `niri/user.kdl` no módulo Ryoku
(`modules/desktop/ryoku.nix`), escolhendo teclas livres na sua configuração:

```kdl
Super+M repeat=false { spawn "macro"; }
Super+Shift+M repeat=false { spawn "macro" "--stop"; }
```

Na sessão Niri independente, adicione ao bloco `binds` de
`modules/desktop/niri.nix`. Os atalhos não são instalados automaticamente para
não substituir binds do Ryoku.

Se aparecer erro de permissão no socket, confira `id -nG` (deve incluir
`ydotool`) e `systemctl status ydotoold`. Se o leitor encerrar por uma mudança de
dispositivos/monitores, execute o comando novamente.
