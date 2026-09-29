# Snowflake

O `flake.nix` declara inputs e importa `parts/` e `modules/` com import-tree.
`parts/hosts.nix` cria os hosts; cada `hosts/<nome>/default.nix` escolhe os
módulos. A configuração de cada ambiente gráfico acompanha seu módulo em
`modules/desktop/`. O Zed é a exceção: o host escolhe sua instalação e importa
`modules/home/zed.nix` para os ajustes do usuário.

Adicione pacotes individuais em `modules/programs/packages.nix`. O arquivo tem
três listas: compartilhados, só desktop e só laptop. Os hosts passam o nome do
perfil automaticamente; para adicionar um pacote, basta incluí-lo na lista
correspondente e rodar `nrs`.

O módulo `pleamar` acrescenta `programs.pleamar-wm.extraConfig` localmente.
Os campos `session.conf`, `keys.conf` e `autostart` são publicados em
`/etc/pleamar/`, com `PLEAMAR_CONFIG=/etc/pleamar` na sessão. O módulo upstream
do pleamar-wm não define essa opção. Essas configurações são declarativas;
alterações diretas nos arquivos gerados não persistem.

## Conferência em uma instalação com Nix

```sh
nix flake check --no-build
nix eval .#nixosConfigurations.desktop.config.system.build.toplevel.drvPath --raw
nix eval .#nixosConfigurations.laptop.config.system.build.toplevel.drvPath --raw
```

O laptop ainda contém UUIDs provisórios em
`hosts/laptop/hardware-configuration.nix`. Substitua esse arquivo pelo hardware
gerado no laptop antes de instalar. O desktop guarda seus próprios UUIDs e o
SSD em `hosts/desktop/`; use um hardware-configuration da VM se for aplicar o
flake na VM. `modules/system/graphics.nix` contém os ajustes NVIDIA do desktop físico;
`modules/system/optimization.nix` habilita Steam, GameMode, MangoHud e TRIM.


## Atualização: Pleamar e Hyprland

Este pacote completo usa a versão reorganizada `snowflake-reestruturado.zip`
como base, integra o patch de jogos anterior, o Hyprland no estilo Mango e
as alterações do Pleamar desta conversa. Não inclui alterações feitas apenas
no seu computador depois dos arquivos fornecidos.

### Pleamar

- Ghostty em Super+Return e Super+T; Yazi em Super+E.
- Mouse com perfil flat e velocidade 0.
- Teclados us,br, Caps como Escape, repetição 30/s e atraso 400 ms.
- Monitores declarados em cada host: HDMI-A-1 vertical à esquerda e DP-3 à
  direita no desktop; eDP-1 na origem no laptop.
- Fullscreen em Super+Shift+F; Super+F fica livre.
- H/K navegam para a janela anterior; J/L para a próxima.
- Shift+H/J/K/L chama as mesmas ações das setas correspondentes do Pleamar.
- Bloqueio em Super+Alt+L para liberar Super+L para navegação.
- Workspaces 1–9 e atalhos de captura/Marea continuam nos defaults.

A navegação é sequencial, não direcional como no Mango. As ações move_left e
move_right da cena padrão podem trocar a janela de monitor. Não implementamos
scrolling, floating individual ou envio entre monitores com/sem seguir como
novas ações. O foco por passagem do mouse continua sendo o comportamento
padrão da cena; alterá-lo exige uma etapa específica na cena `.plm`.

### Aplicar no desktop

Dentro da pasta `snowflake` extraída:

```sh
nix flake lock
sudo nixos-rebuild switch --flake .#desktop
```

Se copiar os arquivos para seu repositório Git existente, registre os arquivos
novos antes do rebuild (`git add modules/system/optimization.nix`, por exemplo).
O `flake.lock` original foi preservado. `nix flake lock` resolve os novos inputs
Hyprland e split-monitor-workspaces; não fizemos essa resolução neste ambiente.
Para atualizar posteriormente os dois juntos:

```sh
nix flake update hyprland split-monitor-workspaces
```

Após o rebuild, saia e entre novamente na sessão Pleamar para reler os binds
e aplicar as opções de dispositivos. No laptop, o alvo é `.#laptop`.

### Verificação desta entrega

Sintaxe de todos os arquivos Nix verificada com tree-sitter-nix; sintaxe da
configuração Lua do Hyprland verificada com Lua 5.4. Caminhos locais de scripts
e arquivos de hardware preservados. Não foram executados avaliação Nix,
build do sistema nem testes gráficos; precisam ocorrer na máquina de destino.


## Correção: portal duplicado

O módulo Pleamar normaliza `xdg.portal.extraPortals`: se Hyprland está
habilitado, todas as entradas de xdg-desktop-portal-hyprland usam
`config.programs.hyprland.portalPackage`, com remoção das duplicatas.
Isso elimina a colisão de `xdg-desktop-portal-hyprland.service` na construção
de user-units sem remover os provedores GTK/KDE/wlr/Pleamar.
Para aplicar apenas esta correção, substitua `modules/desktop/pleamar.nix`
pelo arquivo deste ZIP e execute seu `nrs`. Não é preciso atualizar inputs.
