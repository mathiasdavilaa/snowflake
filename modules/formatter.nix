{
  # Formatador do flake: `nix fmt` roda o nixfmt-rfc-style (o formatador
  # oficial recomendado pela RFC 166) sobre todos os .nix do repositório.
  # Isto é o que de fato formata o flake — o `nh` (features/system/nh.nix)
  # é só um CLI de rebuild/limpeza, não formata nada.
  perSystem = { pkgs, ... }: {
    formatter = pkgs.nixfmt-rfc-style;
  };
}
