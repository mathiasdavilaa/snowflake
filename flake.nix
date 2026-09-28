{
  description = "snowflake — NixOS (flake-parts + import-tree)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-flatpak.url = "github:gmodena/nix-flatpak/v0.7.0";

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mango = {
      url = "github:mangowm/mango";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ---- Pleamar: compositor + runtime das scenes + shell (Marea) ----
    # Um único pleamar / marea para todo mundo (follows), evitando builds duplicados.
    pleamar = {
      url = "github:k4ditano/pleamar";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    marea = {
      url = "github:k4ditano/marea-plm";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.pleamar.follows = "pleamar";
    };

    pleamar-wm = {
      url = "github:k4ditano/pleamar-wm";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.pleamar.follows = "pleamar";
      inputs.marea.follows = "marea";
    };
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        (inputs.import-tree ./parts)
        (inputs.import-tree ./modules)
      ];
    };
}
