#!/usr/bin/env bash

set -euo pipefail

# https://stackoverflow.com/a/51548669
shopt -s expand_aliases
alias trace_on="set -x"
alias trace_off="{ set +x; } 2>/dev/null; echo"

# more color styles: https://stackoverflow.com/a/28938235
echo_prog() { printf "\n\033[1;33m[INFO] %s\033[0m\n" "$*"; }
separator() { printf "\033[1;33m------------------------------------------\033[0m\n"; }
echo_msg() { { printf "\033[1;32m%s\033[0m\n" "$*"; } 2>/dev/null; }
echo_err() { printf "\033[1;31m[ERROR] %s\033[0m\n" "$*" >&2; }

if ! command -v git >/dev/null 2>&1; then
  echo_err "Please install git first."
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  echo_err "Please install curl first."
  exit 1
fi


echo_prog "Install/Update Oh My Tmux..."
separator
export OH_MY_TMUX_DIR=${OH_MY_TMUX_DIR:="$HOME"/.tmux}
echo_msg "Installation directory: $OH_MY_TMUX_DIR"
if [[ -d "$OH_MY_TMUX_DIR" ]]; then
  trace_on
  ( cd "$OH_MY_TMUX_DIR" && git pull )
  trace_off
else
  trace_on
  git clone https://github.com/gpakosz/.tmux.git "$OH_MY_TMUX_DIR" >/dev/null 2>&1
  ln --symbolic --force "$OH_MY_TMUX_DIR"/.tmux.conf "$HOME"
  cp --force "$OH_MY_TMUX_DIR"/.tmux.conf.local "$HOME"
  trace_off
fi


echo_prog "Install/Update Oh My Zsh..."
separator
if ! command -v zsh >/dev/null 2>&1; then
  echo_err "Please install zsh first."
  exit 1
fi
export OH_MY_ZSH_DIR=${OH_MY_ZSH_DIR:="$HOME"/.oh-my-zsh}
echo_msg "Installation directory: $OH_MY_ZSH_DIR"
if [[ -d "$OH_MY_ZSH_DIR" ]]; then
  trace_on
  # execute the content of command 'upgrade_oh_my_zsh'
  env ZSH="$OH_MY_ZSH_DIR" sh "$OH_MY_ZSH_DIR/tools/upgrade.sh" >/dev/null
  command rm -rf "$OH_MY_ZSH_DIR/log/update.lock"
  trace_off
else
  trace_on
  curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh |\
    env ZSH="$OH_MY_ZSH_DIR" sh >/dev/null 2>&1
  trace_off

  echo_prog "Apply my .zshrc"
  separator
  zshrc="$(curl -fsSL https://raw.githubusercontent.com/ljishen/dotfiles/master/.zshrc)"
  echo_msg "###### diff of my .zshrc ######"
  diff --unified=1 <(cat "$HOME"/.zshrc) <(echo "$zshrc") |\
    sed "s/^-/$(tput setaf 1)&/; s/^+/$(tput setaf 2)&/; s/^@/$(tput setaf 6)&/; s/$/$(tput sgr0)/" || {
    # Exit status is 0 if inputs are the same, 1 if different, 2 if trouble.
    status="$?"
    if (( "$status" < 2 )); then
      true  # we ignore this type of error
    else
      exit "$status"
    fi
  }
  echo "$zshrc" > "$HOME/.zshrc"
  echo
fi


echo_prog "Install/Update SpaceVim..."
separator
SPACEVIM_DIR="$HOME/.SpaceVim"
[[ -d "$SPACEVIM_DIR" ]] && SPACEVIM_OP=update || SPACEVIM_OP=install
trace_on
curl -sLf https://spacevim.org/install.sh | bash >/dev/null 2>&1
if [[ "$SPACEVIM_OP" == "install" ]]; then
  mkdir -p "$HOME"/.SpaceVim.d
  curl -fsSLo "$HOME"/.SpaceVim.d/init.toml \
    https://raw.githubusercontent.com/ljishen/dotfiles/master/.SpaceVim.d/init.toml

  # fix the vimproc's DLL error
  #   https://spacevim.org/quick-start-guide/#install
  if command -v make >/dev/null 2>&1 && \
    command -v gcc >/dev/null 2>&1; then
    make -C "$SPACEVIM_DIR"/bundle/vimproc.vim >/dev/null
  else
    echo_err "Please install make and gcc, then run 'make -C \"\$SPACEVIM_DIR\"/bundle/vimproc.vim'"
  fi
fi
trace_off


echo_prog "Optional post-installation actions"
separator
verlte() { printf '%s\n%s' "$1" "$2" | sort -C -V; }
VIM_VERSION="$(vim --version | awk 'NR==1 { print $5 }')"
if ! verlte "8.0" "$VIM_VERSION"; then
  echo "- VIM version is less then 8.0. Consider to upgrade it to a newer version."
fi
if ! command -v tmux >/dev/null 2>&1; then
  echo "- install Tmux"
fi
echo "- change the default shell to zsh in file /etc/passwd, or run 'chsh -s \$(which zsh)'"
echo "- install packages: global, cscope, shellcheck"
echo

echo_prog "Done!"
