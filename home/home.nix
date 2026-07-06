# User-level config shared by every machine (NixOS desktop/laptop and WSL).
# On NixOS this is loaded as a home-manager module from flake.nix; on WSL it
# is applied standalone with `home-manager switch`.
{ config, pkgs, lib, inputs, ... }:

let
  dotfiles = "${config.home.homeDirectory}/dotfiles";
in
{
  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    # cli staples
    ripgrep
    fd
    jq
    lazygit
    tmux

    # dev toolchain
    git
    gh
    gnumake
    uv
    nodejs_24
    yarn
    pnpm
    bun
    ffmpeg
    claude-code

    # networking / misc
    nmap
    traceroute
    vim

    # so `home-manager switch` works on WSL after bootstrap
    home-manager

    # zsh prompt plugin, from its own flake (not in nixpkgs); activated in
    # zsh initContent below
    inputs.zsh-patina.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  home.sessionPath = [
    "$HOME/bin"
    "$HOME/.local/bin"
  ];

  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.git = {
    enable = true;
    lfs.enable = true;
    settings = {
      user = {
        name = "dagleaves";
        email = "68761152+dagleaves@users.noreply.github.com";
      };
      alias = {
        co = "checkout";
        b = "branch";
        pu = "push -u origin HEAD";
        ci = "commit -m";
        st = "status";
        ap = "add --patch";
        rename = "branch -m";
        rn = "rename";
      };
      init.defaultBranch = "main";
      credential.helper = "store";
      credential."https://github.com".helper = "!gh auth git-credential";
    };
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "docker"
        "z"
      ];
      # No omz theme - powerlevel10k is loaded as a plugin below.
    };

    # Plugins that aren't part of oh-my-zsh core, installed from nixpkgs
    # instead of git-cloning into $ZSH_CUSTOM.
    plugins = [
      {
        name = "fzf-tab";
        src = pkgs.zsh-fzf-tab;
        file = "share/fzf-tab/fzf-tab.plugin.zsh";
      }
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
    ];

    history = {
      size = 10000;
      path = "${config.home.homeDirectory}/.zsh_history";
      ignoreAllDups = true;
    };

    shellAliases = {
      ".." = "cd ..";
      ll = "ls -l";
      lg = "lazygit";
      edit = "sudo -e";
      update = "$HOME/dotfiles/rebuild.sh";
      gti = "git";
      add = "git add .";
      push = "git push";
      pull = "git pull";
      m = "git switch main";
    };

    initContent = lib.mkMerge [
      # Must run before everything else in .zshrc (instant prompt) and
      # before oh-my-zsh is sourced (ENABLE_CORRECTION).
      (lib.mkOrder 500 ''
        # Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
        if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
          source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
        fi

        ENABLE_CORRECTION="true"
      '')
      ''
        # To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
        [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

        if command -v zsh-patina >/dev/null 2>&1; then
          eval "$(zsh-patina activate)"
        fi
      ''
    ];
  };

  programs.tmux = {
    enable = true;
    prefix = "C-a";
    baseIndex = 1;          # windows and panes start at 1, not 0
    keyMode = "vi";
    mouse = true;
    historyLimit = 100000;
    terminal = "tmux-256color";

    plugins = with pkgs.tmuxPlugins; [
      sensible
      {
        plugin = rose-pine;
        extraConfig = ''
          set -g @rose_pine_variant 'moon' # Options are 'main', 'moon' or 'dawn'
          set -g @rose_pine_host 'on' # Enables hostname in the status bar
          set -g @rose_pine_hostname_short 'on' # Makes the hostname shorter by using tmux's '#h' format
          set -g @rose_pine_window_separator ' ➔ ' # Replaces the default `:` between the window number and name
          set -g @rose_pine_right_separator ' ' # Accepts both normal chars & nerdfont icons
          set -g @rose_pine_date_time '%H:%M' # It accepts the date UNIX command format (man date for info)
        '';
      }
    ];

    extraConfig = ''
      # Fix colors and enable true color/undercurl support
      set -as terminal-features ",xterm-256color:RGB"
      set -as terminal-overrides ",xterm-256color:Smulx=\E[4::%p1%dm"

      set-option -g renumber-windows on

      # Smart pane switching with awareness of Vim splits
      is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
          | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?$'"
      bind-key -n 'C-h' if-shell "$is_vim" 'send-keys C-h'  'select-pane -L'
      bind-key -n 'C-j' if-shell "$is_vim" 'send-keys C-j'  'select-pane -D'
      bind-key -n 'C-k' if-shell "$is_vim" 'send-keys C-k'  'select-pane -U'
      bind-key -n 'C-l' if-shell "$is_vim" 'send-keys C-l'  'select-pane -R'

      # Quick reload
      bind r source ~/.config/tmux/tmux.conf \; display "Config reloaded!"

      # Split panes using | and - in current directory
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"

      # Move status bar to the top
      set -g status-position top
    '';
  };

  # Edit-in-place: the real file stays in this repo, ~/.p10k.zsh just points
  # at it (`p10k configure` writes straight through the symlink).
  home.file.".p10k.zsh".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/p10k.zsh";

  # WezTerm reads ~/.wezterm.lua on NixOS. On WSL the terminal runs on the
  # Windows side, which can't follow this symlink - rebuild.sh copies the
  # repo file to C:\Users\<user>\.wezterm.lua instead.
  home.file.".wezterm.lua".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/wezterm.lua";
}
