{ ... }: {
  flake.nixosModules.git = { pkgs, username, ... }: {
    home-manager.users.${username} = {
      programs.git = {
        enable = true;
        settings = {
          user = {
            name = "mathiasdavila";
            email = "mathiasaug@proton.me";
            signingKey = "~/.ssh/id_ed25519.pub";
          };
          init.defaultBranch = "main";
          gpg = {
            format = "ssh";
            ssh.allowedSignersFile = "~/.ssh/allowed_signers";
          };
          commit.gpgsign = true;
        };
      };
      programs.gh = {
        enable = true;
        gitCredentialHelper.enable = true;
      };

      home.file.".ssh/allowed_signers".text = ''
        mathiasaug@proton.me ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINwLD/aEx8KzOU3YTcFJE2TcV0fok+wR8UdtUwLSwaIn mathiasaug@proton.me
      '';
      home.packages = with pkgs; [
        lazygit
      ];
    };
  };
}
