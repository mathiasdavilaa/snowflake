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
flake na VM. `modules/system/graphics.nix` está reservado para ajustes da GPU
física, quando seus dados estiverem disponíveis.
