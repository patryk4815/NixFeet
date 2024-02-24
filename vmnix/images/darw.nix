{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    vim
    lima
    htop
    python3Packages.binwalk
  ];

  programs.zsh.enable = true;
  services.nix-daemon.enable = true;
  nix.package = pkgs.nix;
  nix.settings.sandbox = "relaxed";

  environment.loginShell = "${pkgs.zsh}/bin/zsh -l";
  environment.variables.SHELL = "${pkgs.zsh}/bin/zsh";
  environment.shellAliases.ll = "ls -lh --color";

  programs.zsh.enableCompletion = false;
  programs.zsh.enableBashCompletion = false;
  programs.zsh.interactiveShellInit = ''
source ${./.p10k.zsh}
source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source ${pkgs.zsh-autocomplete}/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh
source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source ${pkgs.zsh-you-should-use}/share/zsh/plugins/you-should-use/you-should-use.plugin.zsh  # TODO: tput (ncurses)
source ${pkgs.zsh-nix-shell}/share/zsh-nix-shell/nix-shell.plugin.zsh

# TODO: vim
# TODO: zsh history
# podpowiadanie parametrow
fpath+=(${pkgs.oh-my-zsh}/share/oh-my-zsh/plugins/docker)
fpath+=(${pkgs.oh-my-zsh}/share/oh-my-zsh/plugins/golang)
fpath+=(${pkgs.nix-zsh-completions}/share/zsh/site-functions)

# nix-index
source ${pkgs.nix-index}/etc/profile.d/command-not-found.sh
export SHELL=zsh  # naprawa nix-shell

# binds
bindkey "\e[3~" delete-char

# history
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=10000
setopt extended_history       # record timestamp of command in HISTFILE
setopt hist_expire_dups_first # delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt hist_ignore_dups       # ignore duplicated commands history list
setopt hist_ignore_space      # ignore commands that start with space
setopt hist_verify            # show command with history expansion to user before running it
setopt share_history          # share command history data


export SSH_AUTH_SOCK=/Users/psondej/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh

  '';


  nix.extraOptions = ''
experimental-features = nix-command flakes repl-flake
builders-use-substitutes = true
builders = @/etc/nix/machines
#extra-platforms = aarch64-linux arm-linux armv7l-linux
  '';

  security.pam.enableSudoTouchIdAuth = true;
}