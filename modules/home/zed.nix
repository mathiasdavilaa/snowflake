{ ... }: {
  # Zed como IDE principal e única: editor + compiladores/interpretadores +
  # LSPs + formatadores + debugger para o que você usa agora (C++ em
  # Estrutura de Dados, Python em Algoritmos, este flake em Nix, scripts em
  # fish/bash) e pra quando entrar em Lua/Roblox.
  #
  # A instalação é escolhida pelo host; os ajustes do usuário ficam aqui.
  # A toolchain em extraPackages é disponibilizada ao Zed.
  flake.homeModules.zed = { pkgs, ... }: {
      programs.zed-editor = {
        enable = true;

        # $EDITOR/$VISUAL e app padrão pra abrir arquivos de texto no sistema.
        defaultEditor = true;

        # Populam "auto_install_extensions": baixam sozinhas no primeiro start.
        # aura-theme = tema "Aura Dark"; charmed-icons = ícones "Warm Charmed
        # Icons" — os dois vêm do visual abaixo.
        extensions = [ "nix" "toml" "lua" "make" "aura-theme" "charmed-icons" ];

        extraPackages = with pkgs; [
          # ---- C / C++ (Estrutura de Dados) ----
          clang-tools # clangd (LSP) + clang-format (formatter) + clang-tidy
          gcc
          cmake
          gnumake
          gdb
          lldb # dá o lldb-dap, usado pelo debugger nativo do Zed

          # ---- Python (Algoritmos) ----
          python3
          pyright # LSP
          ruff # lint + formatter (bem mais rápido que black)

          # ---- Lua / Roblox ----
          lua-language-server
          stylua # formatter

          # ---- Nix (este próprio flake) ----
          nil # LSP; o formatter do flake está em parts/systems.nix
          nixfmt-rfc-style

          # ---- Bash / scripts do fish ----
          bash-language-server
          shfmt
          shellcheck

          # ---- Markdown / genérico ----
          marksman
        ];

        userSettings = {
          # Quem atualiza o Zed é o Nix, não ele mesmo — senão ele tenta
          # baixar um binário novo por cima do da store e quebra.
          auto_update = false;

          telemetry = {
            diagnostics = false;
            metrics = false;
          };

          terminal.shell.program = "fish";

          # ---------------------------------------------------------------
          # Visual: baseado numa config de um youtuber (tema Aura Dark +
          # ícones Warm Charmed Icons, bem clean/minimalista). Troquei duas
          # coisas do original: as abas dos arquivos abertos (tab_bar) e o
          # painel de arquivos (project_panel) continuam aparecendo, e
          # adicionei o painel do git (git_panel) do lado direito.
          # ---------------------------------------------------------------
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

          # Fonte "Dank Mono" é paga (não tá nos nixpkgs) — instale o
          # arquivo da fonte à mão em ~/.local/share/fonts se já comprou;
          # senão o Zed cai pra fonte padrão sozinho, sem erro.
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

          # Diferente do original: quero ver as abas dos arquivos abertos.
          tab_bar.show = true;

          toolbar.quick_actions = false;
          status_bar."experimental.show" = false;

          # Diferente do original: painel de arquivos na esquerda (não na
          # direita) e já aberto ao iniciar.
          project_panel = {
            dock = "left";
            default_width = 400;
            hide_root = true;
            auto_fold_dirs = false;
            starts_open = true;
            git_status = false;
            sticky_scroll = false;
            scrollbar.show = "never";
            indent_guides.show = "never";
          };

          # Novo (não tava no original): painel do git na direita, também
          # já aberto. Se o seu Zed ainda não tiver `starts_open` pra esse
          # painel, é só abrir com o ícone de git na status bar / Cmd+Shift+G.
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
            folds = false;
            runnables = false;
          };

          indent_guides.enabled = false;

          vim_mode = false;
          multi_cursor_modifier = "cmd_or_ctrl";
          cursor_shape = "underline";
          cursor_blink = true;
          selection_highlight = false;
          drag_and_drop_selection.enabled = false;
          seed_search_query_from_cursor = "never";
          current_line_highlight = "none";
          show_whitespaces = "none";
          tab_size = 2;
          auto_indent = false;
          auto_indent_on_paste = false;
          show_completions_on_input = false;
          show_completion_documentation = false;
          inline_code_actions = false;
          lsp_document_colors = "none";
          hover_popover_enabled = false;

          # Format-on-save fica desligado (igual ao original) — os
          # formatters por linguagem lá embaixo continuam definidos, dá pra
          # rodar na mão (`editor: format document`) quando quiser.
          format_on_save = "off";

          autosave.after_delay.milliseconds = 1000;
          extend_comment_on_newline = false;
          horizontal_scroll_margin = 1;
          vertical_scroll_margin = 1;
          when_closing_with_no_tabs = "keep_window_open";
          close_on_file_delete = true;
          restore_on_file_reopen = false;
          restore_on_startup = "empty_tab";
          session.restore_unsaved_buffers = false;

          git = {
            git_gutter = "hide";
            inline_blame.enabled = false;
          };

          centered_layout = {
            right_padding = 0.15;
            left_padding = 0.15;
          };

          # Aponta os LSPs pro binário do Nix em vez do Zed tentar baixar o
          # dele (o que costuma falhar no NixOS por causa do linking). Os
          # nomes de chave abaixo são os que o Zed usa hoje para cada
          # servidor — se algum não pegar, confira o nome exato em
          # `zed: open log` e ajusta aqui.
          lsp = {
            clangd.binary.path = "clangd";
            pyright.binary = {
              path = "pyright-langserver";
              arguments = [ "--stdio" ];
            };
            nil.binary.path = "nil";
            lua-language-server.binary.path = "lua-language-server";
            bash-language-server.binary = {
              path = "bash-language-server";
              arguments = [ "start" ];
            };
          };

          languages = {
            "C" = {
              formatter.external = {
                command = "clang-format";
                arguments = [ "--assume-filename={buffer_path}" ];
              };
            };
            "C++" = {
              formatter.external = {
                command = "clang-format";
                arguments = [ "--assume-filename={buffer_path}" ];
              };
            };
            "Python" = {
              formatter.external = {
                command = "ruff";
                arguments = [ "format" "-" ];
              };
            };
            "Lua" = {
              formatter.external = {
                command = "stylua";
                arguments = [ "-" ];
              };
            };
            "Nix" = {
              formatter.external = {
                command = "nixfmt";
              };
            };
            "Shell Script" = {
              formatter.external = {
                command = "shfmt";
                arguments = [ "-i" "2" ];
              };
            };
          };
        };
      };
  };
}
