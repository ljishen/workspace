#!/usr/bin/env bash

set -euo pipefail

# https://stackoverflow.com/a/51548669
shopt -s expand_aliases
alias trace_on="set -x"
alias trace_off="{ set +x; } 2>/dev/null; echo"

# more color styles: https://stackoverflow.com/a/28938235
echo_stage() { printf "\\n\\033[1;33m[STAGE] %s\\033[0m\\n" "$*"; }
separator() { printf "\\033[1;33m------------------------------------------\\033[0m\\n"; }
echo_msg() { { printf "\\033[1;32m%s\\033[0m\\n" "$*"; } 2>/dev/null; }
echo_err() { printf "\\033[1;31m[ERROR] %s\\033[0m\\n" "$*" >&2; }

prog_installed() { command -v "$1" >/dev/null 2>&1; }

if ! prog_installed git; then
  echo_err "Please install git first."
  exit 1
fi

if ! prog_installed curl; then
  echo_err "Please install curl first."
  exit 1
fi


echo_stage "Install/Update Oh My Tmux..."
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


echo_stage "Install/Update Oh My Zsh..."
separator
if ! prog_installed zsh; then
  echo_err "Please install zsh first."
  exit 1
fi
export OH_MY_ZSH_DIR=${OH_MY_ZSH_DIR:="$HOME"/.oh-my-zsh}
echo_msg "Installation directory: $OH_MY_ZSH_DIR"
if [[ -d "$OH_MY_ZSH_DIR" ]]; then
  trace_on
  ( zsh -c "source $HOME/.zshrc && omz update >/dev/null" )
  trace_off
else
  trace_on
  curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh |\
    env ZSH="$OH_MY_ZSH_DIR" sh >/dev/null 2>&1
  trace_off

  echo_stage "Apply my .zshrc"
  separator
  zshrc="$(curl -fsSL https://raw.githubusercontent.com/ljishen/workspace/master/.zshrc)"
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


echo_stage "Install/Update SpaceVim..."
separator
SPACEVIM_DIR="$HOME/.SpaceVim"
[[ -d "$SPACEVIM_DIR" ]] && SPACEVIM_OP=update || SPACEVIM_OP=install
trace_on
curl -sLf https://spacevim.org/install.sh | bash >/dev/null 2>&1
if [[ "$SPACEVIM_OP" == "install" ]]; then
  mkdir -p "$HOME"/.SpaceVim.d/autoload
  curl -fsSLo "$HOME"/.SpaceVim.d/init.toml \
    https://raw.githubusercontent.com/ljishen/workspace/master/.SpaceVim.d/init.toml
  curl -fsSLo "$HOME"/.SpaceVim.d/autoload/myspacevim.vim \
    https://raw.githubusercontent.com/ljishen/workspace/master/.SpaceVim.d/autoload/myspacevim.vim

  # fix the vimproc's DLL error
  #   https://spacevim.org/quick-start-guide/#install
  if prog_installed make && prog_installed gcc; then
    make -C "$SPACEVIM_DIR"/bundle/vimproc.vim >/dev/null
  else
    echo_err "Please install make and gcc, then run 'make -C \"\$SPACEVIM_DIR\"/bundle/vimproc.vim'"
  fi
fi
trace_off


verlte() { printf '%s\n%s' "$1" "$2" | sort -C -V; }

echo_stage "Optional post-installation actions"
separator
if ! prog_installed vim; then
  echo "- install VIM"
else
  VIM_VERSION="$(vim --version | awk 'NR==1 { print $5 }')"
  if ! verlte "8.0" "$VIM_VERSION"; then
    echo "- VIM version is less then 8.0. Consider to upgrade it to a newer version."
  fi
fi

if ! prog_installed tmux; then
  echo "- install Tmux"
else
  TMUX_VERSION="$(tmux -V | awk '{ print $2 }')"
  if ! verlte "2.1" "$TMUX_VERSION"; then
    echo "- Tmux version is less then 2.1. Consider to upgrade it to a newer version."
  fi
fi

package_deps=( global cscope shellcheck npm )
for idx in "${!package_deps[@]}"; do
  if prog_installed "${package_deps[idx]}"; then
    unset 'package_deps[idx]'
  fi
done

if [[ "${#package_deps[@]}" -gt 0 ]]; then
  echo "- install packages: ${package_deps[*]}"
fi

# see https://spacevim.org/layers/language-server-protocol/
if ! prog_installed npm \
  || ! npm list -g --depth 0 bash-language-server >/dev/null; then
  echo "- install language server protocol for bash script: \`sudo npm i -g bash-language-server\`"
fi

# check string contains: https://stackoverflow.com/a/20460402/2926646
if [[ -n "${SHELL##*/zsh*}" ]]; then
  echo "- change the default shell to zsh in file /etc/passwd, or run 'chsh -s \$(which zsh)'"
fi

echo
echo_stage "Good Job!"
