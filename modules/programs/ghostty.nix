{ ... }: {
  flake.nixosModules.ghostty = { username, ... }: {
    home-manager.users.${username} =
      { config, lib, ... }:
      let
        hasNativeSearch = lib.versionAtLeast config.programs.ghostty.package.version "1.3.0";
      in
      {
        programs.ghostty = {
          enable = true;
          settings = {
            confirm-close-surface = false;
            font-family = "GeistMono Nerd Font";
            cursor-style = "block";
            window-padding-x = 8;
            window-padding-y = 8;
            shell-integration = "detect";
            shell-integration-features = "no-cursor,sudo,title,ssh-env,ssh-terminfo";
            custom-shader = "${../../assets/ghostty/cursor-trail.glsl}";
            custom-shader-animation = true;
            scrollback-limit = 32 * 1024 * 1024;
            copy-on-select = "clipboard";
            clipboard-paste-protection = true;
            window-inherit-working-directory = true;

            config-file = "?user.conf";

            keybind = [
              "ctrl+shift+t=new_tab"
              "ctrl+shift+n=new_window"
              "ctrl+shift+w=close_surface"
              "ctrl+tab=next_tab"
              "ctrl+shift+tab=previous_tab"
              "ctrl+shift+alt+page_up=move_tab:-1"
              "ctrl+shift+alt+page_down=move_tab:1"
              "ctrl+shift+e=new_split:right"
              "ctrl+shift+o=new_split:down"
              "ctrl+shift+left=goto_split:left"
              "ctrl+shift+right=goto_split:right"
              "ctrl+shift+up=goto_split:up"
              "ctrl+shift+down=goto_split:down"
              "ctrl+shift+alt+left=resize_split:left,20"
              "ctrl+shift+alt+right=resize_split:right,20"
              "ctrl+shift+alt+up=resize_split:up,20"
              "ctrl+shift+alt+down=resize_split:down,20"
              "ctrl+shift+z=toggle_split_zoom"
              "ctrl+shift+alt+0=equalize_splits"

              "performable:ctrl+c=copy_to_clipboard"
              "ctrl+shift+c=copy_to_clipboard"
              "ctrl+shift+v=paste_from_clipboard"
              "ctrl+shift+u=copy_url_to_clipboard"
              "ctrl+shift+page_up=jump_to_prompt:-1"
              "ctrl+shift+page_down=jump_to_prompt:1"
              "ctrl+shift+home=scroll_to_top"
              "ctrl+shift+end=scroll_to_bottom"
              "shift+page_up=scroll_page_up"
              "shift+page_down=scroll_page_down"
              "ctrl+shift+h=write_scrollback_file:open"
              "ctrl+shift+alt+h=write_screen_file:open"
              "performable:ctrl+shift+alt+s=write_selection_file:open"
              "ctrl+shift+f=${if hasNativeSearch then "start_search" else "write_scrollback_file:open"}"
              "ctrl+shift+p=toggle_command_palette"
              "ctrl+shift+r=reload_config"

              "all:ctrl+equal=increase_font_size:1"
              "all:ctrl+plus=increase_font_size:1"
              "all:ctrl+shift+equal=increase_font_size:1"
              "all:ctrl+kp_add=increase_font_size:1"
              "all:ctrl+minus=decrease_font_size:1"
              "all:ctrl+shift+minus=decrease_font_size:1"
              "all:ctrl+kp_subtract=decrease_font_size:1"
              "all:ctrl+0=reset_font_size"
              "all:ctrl+kp_0=reset_font_size"
            ]
            ++ map (n: "ctrl+shift+${toString n}=goto_tab:${toString n}") (lib.range 1 9)
            ++ lib.optionals hasNativeSearch [
              "ctrl+shift+alt+t=prompt_tab_title"
            ];
          }
          // lib.optionalAttrs hasNativeSearch {
            tab-inherit-working-directory = true;
            split-inherit-working-directory = true;
          };
        };
        xdg.configFile."ghostty/config".force = true;
      };
  };
}
