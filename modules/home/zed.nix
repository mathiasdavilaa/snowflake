{ ... }: {
  flake.homeModules.zed = { pkgs, config, snowflakeProfile, ... }:
    let
      # Atualize se mover seu flake para outra pasta.
      flakePath = "${config.home.homeDirectory}/snowflake";
      flakeExpr = "(builtins.getFlake ${builtins.toJSON flakePath})";
      cppStudy = pkgs.writeShellApplication {
        name = "cpp-study";
        runtimeInputs = [ pkgs.gcc pkgs.gdb pkgs.coreutils ];
        text = ''
          source_file="$1"
          mode="$2"
          case "$source_file" in
            *.cpp|*.cc|*.cxx) ;;
            *) echo "Abra e salve um arquivo C++ antes de executar esta tarefa." >&2; exit 1 ;;
          esac
          source_file="$(realpath -- "$source_file")"
          output_dir="$(dirname -- "$source_file")/.zed-build"
          mkdir -p -- "$output_dir"
          output="$output_dir/$(basename -- "$source_file").out"
          flags=(-std=c++20 -Wall -Wextra -Wpedantic -Wshadow -g -O0)
          if [[ "$mode" == sanitize ]]; then
            flags+=("-fsanitize=address,undefined" "-fno-omit-frame-pointer")
          fi
          g++ "''${flags[@]}" "$source_file" -o "$output"
          case "$mode" in
            run|sanitize) "$output" ;;
            debug) gdb --quiet "$output" ;;
          esac
        '';
      };
    in {
      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
        enableFishIntegration = true;
      };
      programs.zed-editor = {
        enable = true;

        # Define EDITOR e VISUAL para os programas que abrem um editor externo.
        defaultEditor = true;

        # Extensões instaladas automaticamente ao abrir o Zed.
        extensions = [ "nix" "toml" "lua" "make" "aura-theme" "charmed-icons" ];

        extraPackages = with pkgs; [
          # C e C++: análise, compilação e depuração.
          clang-tools # clangd (LSP) + clang-format (formatter) + clang-tidy
          gcc
          cmake
          gnumake
          gdb
          lldb # adaptador lldb-dap para depuração gráfica
          ninja

          # Python: execução, análise de tipos e formatação.
          python3
          pyright # LSP
          ruff # lint + formatter (bem mais rápido que black)

          # Lua; o suporte a Luau/Roblox fica no módulo roblox.
          lua-language-server
          stylua # formatter

          # Nix: sugestões de pacotes/opções e formatação.
          nixd # autocompletar pacotes e opções NixOS/Home Manager
          nixfmt-rfc-style

          # Bash: análise e formatação de scripts.
          bash-language-server
          shfmt
          shellcheck

          # Markdown e ferramentas usadas pelos servidores e terminal.
          marksman
          nodejs
          fish
        ];

        userTasks = map (task: {
          inherit (task) label;
          command = "${cppStudy}/bin/cpp-study \"$ZED_FILE\" ${task.mode}";
          cwd = "$ZED_DIRNAME";
          shell.program = "${pkgs.bash}/bin/bash";
          save = "current";
          reveal = "always";
          allow_concurrent_runs = false;
        }) [
          { label = "C++: compilar e executar arquivo"; mode = "run"; }
          { label = "C++: verificar memoria (sanitizers)"; mode = "sanitize"; }
          { label = "C++: depurar arquivo com GDB"; mode = "debug"; }
        ];

        userSettings = {
          # O Zed é atualizado pelo rebuild do NixOS.
          auto_update = false;

          telemetry = {
            diagnostics = false;
            metrics = false;
          };

          terminal.shell.program = "fish";

          # Tema, ícones e cores do editor.
          icon_theme = "Warm Charmed Icons";
          theme = "Aura Dark";
          theme_overrides = {
            "Aura Dark" = {
              "editor.document_highlight.read_background" = "#00000000";
              "editor.document_highlight.write_background" = "#00000000";
              border = "#15141C";
              "border.variant" = "#15141C";
              "title_bar.background" = "#15141C";
              "panel.background" = "#15141C";
              "panel.focused_border" = "#4E466E";
              players = [ { cursor = "#BD9DFF"; } ];
              syntax = {
                comment.font_style = "italic";
                "comment.doc".font_style = "italic";
              };
            };
          };

          # Dank Mono exige instalação manual em ~/.local/share/fonts.
          ui_font_family = "Dank Mono";
          ui_font_size = 20;
          buffer_font_family = "Dank Mono";
          buffer_font_size = 20;
          buffer_line_height.custom = 2;
          agent_buffer_font_size = 20;

          title_bar = {
            show_onboarding_banner = false;
            show_project_items = false;
            show_branch_name = false;
            show_user_menu = false;
          };

          tab_bar.show = true;

          toolbar.quick_actions = true;
          status_bar."experimental.show" = true;

          # Explorador de arquivos à esquerda.
          project_panel = {
            dock = "left";
            default_width = 400;
            hide_root = true;
            auto_fold_dirs = false;
            starts_open = true;
            git_status = true;
            sticky_scroll = false;
            scrollbar.show = "never";
            indent_guides.show = "never";
          };

          # Painel de alterações Git à direita.
          git_panel = {
            dock = "right";
            starts_open = true;
          };

          outline_panel = {
            default_width = 300;
            indent_guides.show = "never";
          };

          file_finder.modal_max_width = "large";
          scrollbar.show = "never";

          gutter = {
            min_line_number_digits = 0;
            folds = true;
            runnables = true;
          };

          indent_guides.enabled = true;

          vim_mode = false;
          multi_cursor_modifier = "cmd_or_ctrl";
          cursor_shape = "underline";
          cursor_blink = true;
          selection_highlight = true;
          drag_and_drop_selection.enabled = false;
          seed_search_query_from_cursor = "never";
          current_line_highlight = "none";
          show_whitespaces = "none";
          tab_size = 2;
          auto_indent = "syntax_aware";
          auto_indent_on_paste = true;
          show_completions_on_input = true;
          show_completion_documentation = true;
          inline_code_actions = true;
          lsp_document_colors = "none";
          hover_popover_enabled = true;

          format_on_save = "off";
          autosave = "off"; # Salva apenas quando solicitado.
          auto_signature_help = true;
          inlay_hints.enabled = true;
          diagnostics.inline = {
            enabled = true;
            max_severity = "warning";
          };
          load_direnv = "direct";
          dap.CodeLLDB = {
            binary = "${pkgs.lldb}/bin/lldb-dap";
            args = [ ];
          };

          extend_comment_on_newline = false;
          horizontal_scroll_margin = 1;
          vertical_scroll_margin = 1;
          when_closing_with_no_tabs = "keep_window_open";
          close_on_file_delete = true;
          restore_on_file_reopen = false;
          restore_on_startup = "last_workspace";
          session.restore_unsaved_buffers = true;

          git = {
            git_gutter = "hide";
            inline_blame.enabled = false;
          };

          centered_layout = {
            right_padding = 0.15;
            left_padding = 0.15;
          };

          # Caminhos absolutos evitam downloads de binários incompatíveis com NixOS.
          lsp = {
            clangd.binary = {
              path = "${pkgs.clang-tools}/bin/clangd";
              arguments = [
                "--background-index"
                "--clang-tidy"
                "--completion-style=detailed"
                "--query-driver=${pkgs.gcc}/bin/g++,${pkgs.gcc}/bin/gcc"
              ];
            };
            # Também funciona em exercícios soltos, sem CMake/compile_commands.json.
            clangd.initialization_options.fallbackFlags = [
              "-Wall" "-Wextra" "-Wpedantic"
              "-isystem" "${pkgs.gcc.cc}/include/c++/${pkgs.gcc.version}"
              "-isystem" "${pkgs.gcc.cc}/include/c++/${pkgs.gcc.version}/${pkgs.stdenv.hostPlatform.config}"
            ];
            pyright.binary = {
              path = "${pkgs.pyright}/bin/pyright-langserver";
              arguments = [ "--stdio" ];
            };
            ruff.binary = {
              path = "${pkgs.ruff}/bin/ruff";
              arguments = [ "server" ];
            };
            nixd = {
              binary.path = "${pkgs.nixd}/bin/nixd";
              settings = {
                nixpkgs.expr = "import ${pkgs.path} { }";
                options = {
                  nixos.expr = "${flakeExpr}.nixosConfigurations.${snowflakeProfile}.options";
                  home_manager.expr = "${flakeExpr}.nixosConfigurations.${snowflakeProfile}.options.home-manager.users.type.getSubOptions []";
                };
              };
            };
            lua-language-server.binary.path = "${pkgs.lua-language-server}/bin/lua-language-server";
            bash-language-server.binary = {
              path = "${pkgs.bash-language-server}/bin/bash-language-server";
              arguments = [ "start" ];
            };
          };

          languages = {
            "C" = {
              auto_indent = "syntax_aware";
              format_on_save = "off";
              tab_size = 4;
              formatter.external = {
                command = "${pkgs.clang-tools}/bin/clang-format";
                arguments = [ "--assume-filename={buffer_path}" ];
              };
            };
            "C++" = {
              auto_indent = "syntax_aware";
              format_on_save = "off";
              tab_size = 4;
              formatter.external = {
                command = "${pkgs.clang-tools}/bin/clang-format";
                arguments = [ "--assume-filename={buffer_path}" ];
              };
            };
            "Python" = {
              auto_indent = "syntax_aware";
              format_on_save = "off";
              tab_size = 4;
              language_servers = [ "pyright" "ruff" "!basedpyright" ];
              formatter.external = {
                command = "${pkgs.ruff}/bin/ruff";
                arguments = [ "format" "--stdin-filename" "{buffer_path}" "-" ];
              };
            };
            "Lua" = {
              auto_indent = "syntax_aware";
              format_on_save = "off";
              formatter.external = {
                command = "${pkgs.stylua}/bin/stylua";
                arguments = [ "-" ];
              };
            };
            "Nix" = {
              auto_indent = "syntax_aware";
              format_on_save = "off";
              language_servers = [ "nixd" "!nil" ];
              formatter.external = {
                command = "${pkgs.nixfmt-rfc-style}/bin/nixfmt";
              };
            };
            "Shell Script" = {
              auto_indent = "syntax_aware";
              format_on_save = "off";
              formatter.external = {
                command = "${pkgs.shfmt}/bin/shfmt";
                arguments = [ "-i" "2" ];
              };
            };
          };
        };
      };
  };
}
