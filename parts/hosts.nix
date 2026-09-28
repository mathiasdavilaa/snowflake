{ inputs, self, ... }:
let
  mkHost = name: username: inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {
      inherit self inputs username;
      profile = name;
    };
    modules = [ ../hosts/${name} ];
  };
in
{
  flake.nixosConfigurations = {
    desktop = mkHost "desktop" "mad";
    laptop = mkHost "laptop" "mad";
  };
}
