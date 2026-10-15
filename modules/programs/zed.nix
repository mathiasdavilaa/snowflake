{ ... }: {
  flake.nixosModules.zed = { username, ... }: {
    home-manager.users.${username} = { pkgs, ... }: {
      programs.zed-editor = {
        enable = true;
        defaultEditor = true;

        mutableUserSettings = false;

        extensions = [
          "nix"

          "material-icon-theme"

          "make"
          "toml"
          "dockerfile"

          "git-firefly"
        ];

        extraPackages = with pkgs; [
          gcc
          clang
          clang-tools
          gdb

          nixd

          nixfmt

          git
          git-lfs
          lazygit

          jq
          ripgrep
          fd
        ];

        userSettings = {
          agent_servers = {
            "codex-acp" = {
              type = "registry";
            };
          };

          agent = {
            tool_permissions = {
              default = "allow";

              tools = {
                terminal = {
                  always_confirm = [
                    { pattern = "sudo\\s"; }
                    { pattern = "git\\s+push"; }
                    { pattern = "nixos-rebuild"; }
                    { pattern = "git\\s+reset\\s+--hard"; }
                  ];
                };
              };
            };
          };

          theme = {
            mode = "dark";
            dark = "One Dark";
            light = "One Light";
          };

          icon_theme = "Material Icon Theme";

          ui_font_size = 16;
          buffer_font_size = 15;

          ui_font_family = "GeistMono Nerd Font";
          buffer_font_family = "GeistMono Nerd Font";

          tab_size = 2;

          soft_wrap = "none";

          relative_line_numbers = false;

          show_whitespaces = "selection";

          cursor_blink = true;

          use_smartcase_search = true;

          seed_search_query_from_cursor = "always";

          show_completions_on_input = true;

          use_autoclose = true;

          use_on_type_format = false;

          format_on_save = "off";

          formatter = "language_server";

          terminal = {
            font_family = "GeistMono Nerd Font";
            font_size = 14;

            shell = {
              program = "${pkgs.fish}/bin/fish";
            };

            blinking = "terminal_controlled";

            working_directory = "current_project_directory";
          };

          git = {
            inline_blame = {
              enabled = false;
            };

            gutter = {
              enabled = true;
            };
          };

          file_scan_exclusions = [
            "**/.git"
            "**/.hg"
            "**/.svn"
            "**/node_modules"
            "**/target"
            "**/build"
            "**/.direnv"
            "**/result"
          ];

          project_panel = {
            dock = "right";
            default_width = 300;
            git_status = true;
          };

          minimap = {
            show = "never";
          };

          diagnostics = {
            inline = {
              enabled = true;
            };

            include_warnings = true;
          };

          languages = {
            Nix = {
              language_servers = [
                "nixd"
                "!nil"
              ];

              formatter = {
                external = {
                  command = "nixfmt";
                  arguments = [ "--" ];
                };
              };

              tab_size = 2;
            };

            C = {
              language_servers = [
                "clangd"
              ];

              formatter = {
                language_server = {
                  name = "clangd";
                };
              };

              tab_size = 2;
            };

            "C++" = {
              language_servers = [
                "clangd"
              ];

              formatter = {
                language_server = {
                  name = "clangd";
                };
              };

              tab_size = 2;
            };
          };

          telemetry = {
            diagnostics = false;
            metrics = false;
          };
        };

        userKeymaps = [
          {
            context = "Workspace";

            bindings = {
              "ctrl-`" = "workspace::ToggleBottomDock";
            };
          }

          {
            context = "Workspace";

            bindings = {
              "ctrl-shift-b" = "task::Spawn";
            };
          }

          {
            context = "Workspace";

            bindings = {
              "f6" = "task::Rerun";
            };
          }

          {
            context = "Editor";

            bindings = {
              "f5" = [
                "task::Spawn"
                {
                  task_name = "C++: Build & Run";
                }
              ];
            };
          }

          {
            context = "Workspace";

            bindings = {
              "f9" = "debugger::Start";
            };
          }

          {
            context = "Editor";

            bindings = {
              "ctrl-s" = "workspace::Save";
            };
          }

          {
            context = "Editor";

            bindings = {
              "ctrl-shift-i" = "editor::Format";
            };
          }

          {
            context = "Workspace";

            bindings = {
              "ctrl-p" = "file_finder::Toggle";
            };
          }

          {
            context = "Workspace";

            bindings = {
              "ctrl-shift-p" = "command_palette::Toggle";
            };
          }
        ];

        userTasks = [
          {
            label = "C++: Build & Run";

            command = ''
              set -e

              mkdir -p "$ZED_WORKTREE_ROOT/outputs"

              g++ \
                -std=c++23 \
                -Wall \
                -Wextra \
                -Wpedantic \
                -O2 \
                "$ZED_FILE" \
                -o "$ZED_WORKTREE_ROOT/outputs/$ZED_STEM"

              echo "==============================================="

              "$ZED_WORKTREE_ROOT/outputs/$ZED_STEM"

              echo ""
              echo "==============================================="
              echo "✓ A tarnished cannot become a Lord."
            '';

            cwd = "$ZED_WORKTREE_ROOT";

            save = "current";

            reveal = "always";
            hide = "never";

            show_summary = false;
            show_command = false;

            shell = {
              with_arguments = {
                program = "${pkgs.bash}/bin/bash";
                args = [
                  "--noprofile"
                  "--norc"
                ];
              };
            };

            use_new_terminal = false;

            allow_concurrent_runs = false;
          }

          {
            label = "C++: Build Debug";

            command = "bash";

            args = [
              "-c"
              ''
                set -e

                mkdir -p "$ZED_WORKTREE_ROOT/outputs"

                g++ \
                  -std=c++23 \
                  -Wall \
                  -Wextra \
                  -Wpedantic \
                  -g \
                  "$ZED_FILE" \
                  -o "$ZED_WORKTREE_ROOT/outputs/$ZED_STEM"
              ''
            ];

            cwd = "$ZED_WORKTREE_ROOT";

            save = "current";

            reveal = "always";

            allow_concurrent_runs = false;
          }

          {
            label = "C++: Run";

            command = "bash";

            args = [
              "-c"
              ''exec "$ZED_WORKTREE_ROOT/outputs/$ZED_STEM"''
            ];

            cwd = "$ZED_WORKTREE_ROOT";

            reveal = "always";

            allow_concurrent_runs = false;
          }

          {
            label = "Nix: Format";

            command = "nix";

            args = [
              "fmt"
              "$ZED_WORKTREE_ROOT"
            ];

            cwd = "$ZED_WORKTREE_ROOT";

            reveal = "always";
          }

          {
            label = "Nix: Flake Check";

            command = "nix";

            args = [
              "flake"
              "check"
              "$ZED_WORKTREE_ROOT"
            ];

            cwd = "$ZED_WORKTREE_ROOT";

            reveal = "always";
          }

          {
            label = "NixOS: Rebuild Laptop";

            command = "sudo";

            args = [
              "nixos-rebuild"
              "switch"
              "--flake"
              "$ZED_WORKTREE_ROOT#laptop"
            ];

            cwd = "$ZED_WORKTREE_ROOT";

            reveal = "always";
          }

          {
            label = "NixOS: Rebuild Desktop";

            command = "sudo";

            args = [
              "nixos-rebuild"
              "switch"
              "--flake"
              "$ZED_WORKTREE_ROOT#desktop"
            ];

            cwd = "$ZED_WORKTREE_ROOT";

            reveal = "always";
          }

          {
            label = "Git: Status";

            command = "git";

            args = [
              "status"
              "--short"
            ];

            cwd = "$ZED_WORKTREE_ROOT";

            reveal = "always";
          }

          {
            label = "Git: LazyGit";

            command = "lazygit";

            cwd = "$ZED_WORKTREE_ROOT";

            reveal = "always";
          }
        ];

        userDebug = [
          {
            label = "C++: Debug";

            adapter = "CodeLLDB";

            request = "launch";

            program = "$ZED_WORKTREE_ROOT/outputs/$ZED_STEM";

            cwd = "$ZED_WORKTREE_ROOT";

            build = {
              command = "${pkgs.bash}/bin/bash";
              args = [
                "-c"
                ''
                  set -e
                  mkdir -p "$ZED_WORKTREE_ROOT/outputs"
                  g++ -std=c++23 -Wall -Wextra -g "$ZED_FILE" \
                    -o "$ZED_WORKTREE_ROOT/outputs/$ZED_STEM"
                ''
              ];
            };
          }
        ];
      };
    };
  };
}
