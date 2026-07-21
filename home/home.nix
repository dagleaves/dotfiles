# User-level config shared by every machine (NixOS desktop/laptop and WSL).
# On NixOS this is loaded as a home-manager module from flake.nix; on WSL it
# is applied standalone with `home-manager switch`.
{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

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
    unzip
    uv
    ruff
    nodejs_24
    yarn
    pnpm
    bun
    cargo
    rustc
    ffmpeg
    claude-code

    # formatter / linters
    stylua # lua format (base LazyVim)
    markdownlint-cli2 # markdown lint + fix
    markdown-toc # markdown TOC
    nixfmt # nix format (provides the `nixfmt` binary the extra calls)
    hadolint # dockerfile lint
    ansible-lint # ansible lint
    sqlfluff # sql lint + format (the sql extra uses this for both)

    gofumpt # go format
    gotools # provides goimports
    golangci-lint # go lint

    go # gopls and the go toolchain need the compiler present
    terraform # `terraform fmt` — unfree, see note

    tree-sitter # builds TS parsers

    # networking / misc
    nmap
    traceroute
    vim

    # so `home-manager switch` works on WSL after bootstrap
    home-manager

    # zsh prompt plugin, from its own flake (not in nixpkgs); activated in
    # zsh initContent below
    inputs.zsh-patina.packages.${pkgs.stdenv.hostPlatform.system}.default

    # not in nixpkgs, packaged by its own flake
    inputs.treehouse.packages.${pkgs.stdenv.hostPlatform.system}.default

    # terminal multiplexer, not in nixpkgs, packaged by its own flake
    inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default

    # environment engine for agent worktrees, not in nixpkgs, packaged by its own flake
    inputs.workz.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  home.sessionVariables = {
    ANDROID_HOME = "$HOME/Android/Sdk";
  };

  home.sessionPath = [
    "$HOME/bin"
    "$HOME/.local/bin"
    "$HOME/Android/Sdk/emulator"
    "$HOME/Android/Sdk/platform-tools"
  ];

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    # The repo's home/.config/nvim is symlinked in whole further down via
    # home.file, so prevent home-manager's own generated init.lua (which
    # only disables unused providers) from colliding with it.
    initLua = lib.mkForce "";
    # Expose gcc to neovim for nvim-treesitter
    extraPackages = with pkgs; [
      lua-language-server # base LazyVim (its own Lua config)

      pyright # python  (extra's default LSP)

      vtsls # typescript
      biome # typescript.biome — LSP + formatter for JS/TS/JSON

      vscode-langservers-extracted # json (jsonls)
      marksman # markdown
      nil # nix
      taplo # toml
      yaml-language-server # yaml (+ GitHub Actions via SchemaStore)
      tailwindcss-language-server # tailwind
      astro-language-server # astro
      ansible-language-server # ansible

      dockerfile-language-server # docker
      docker-compose-language-service # docker

      gopls # go
      terraform-ls # terraform
      tflint # terraform (runs as an LSP too)

      gcc
    ];
    withPython3 = true;
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
      credential."https://gist.github.com".helper = "!gh auth git-credential";
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
    baseIndex = 1; # windows and panes start at 1, not 0
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
  home.file.".p10k.zsh".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/p10k.zsh";

  # WezTerm reads ~/.wezterm.lua on NixOS. On WSL the terminal runs on the
  # Windows side, which can't follow this symlink - rebuild.sh copies the
  # repo file to C:\Users\<user>\.wezterm.lua instead.
  home.file.".wezterm.lua".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/wezterm.lua";

  # Claude Code settings and statusline script, edited in place: Claude
  # writes to ~/.claude/settings.json directly, and these symlinks mean
  # those changes land in the repo.
  home.file.".claude/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/claude/settings.json";
  home.file.".claude/statusline-command.sh".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/claude/statusline-command.sh";
  home.file.".claude/agents".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/claude/agents";

  # Neovim config, edited in place: the whole directory lives in this repo.
  home.file.".config/nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/nvim";

  # herdr config, edited in place: the whole directory lives in this repo.
  home.file.".config/herdr".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/herdr";

  # Shared agent instructions, edited in place: one file in the repo, symlinked
  # into every agent CLI's expected location. Claude Code gets its own file
  # that @imports the shared one plus Claude-only orchestration policy
  # (pilotfish) that would confuse the other CLIs.
  home.file.".claude/CLAUDE.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/claude/CLAUDE.md";
  home.file.".codex/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".config/opencode/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
}
