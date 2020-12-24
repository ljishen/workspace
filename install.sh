#!/usr/bin/env bash

set -euo pipefail

# https://stackoverflow.com/a/51548669
shopt -s expand_aliases
alias trace_on="{ echo; set -x; } 2>/dev/null"
alias trace_off="{ set +x; } 2>/dev/null"

# $BASH_SOURCE can be empty, if no named file is involved
#   https://stackoverflow.com/a/35006505
export PS4='# ${BASH_SOURCE:-"$0"}:${LINENO} - ${FUNCNAME[0]:+${FUNCNAME[0]}()} > '

# more color styles: https://stackoverflow.com/a/28938235
stage() { printf "\\n\\n\\033[1;33m[STAGE] %s\\033[0m\\n" "$*"; }
separate() { printf "\\033[1;33m------------------------------------------\\033[0m\\n"; }
msg() { { printf "\\033[1;32m%s\\033[0m\\n" "$*"; } 2>/dev/null; }
err() { printf "\\033[1;31m[ERROR] %s\\033[0m\\n" "$*" >&2; }

prog_installed() { command -v "$1" >/dev/null 2>&1; }

if ! prog_installed git; then
  err "Please install git first."
  exit 1
fi

if ! prog_installed curl; then
  err "Please install curl first."
  exit 1
fi

msg "Perform installation for user '$USER'"


stage "Install/Update Oh My Tmux..."
separate
export OH_MY_TMUX_DIR=${OH_MY_TMUX_DIR:="$HOME"/.tmux}
msg "Installation directory: $OH_MY_TMUX_DIR"
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


stage "Install/Update Oh My Zsh..."
separate
if ! prog_installed zsh; then
  err "Please install zsh first."
  exit 1
fi
export OH_MY_ZSH_DIR=${OH_MY_ZSH_DIR:-"$HOME"/.oh-my-zsh}
msg "Installation directory: $OH_MY_ZSH_DIR"
if [[ -d "$OH_MY_ZSH_DIR" ]]; then
  trace_on
  ( zsh -c "source $HOME/.zshrc && omz update --unattended >/dev/null" && exit )
  trace_off
else
  trace_on
  curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh |\
    env ZSH="$OH_MY_ZSH_DIR" sh >/dev/null 2>&1
  trace_off

  stage "Apply My .zshrc"
  separate
  readonly MY_ZSHRC="$(curl -fsSL https://raw.githubusercontent.com/ljishen/workspace/master/.zshrc)"
  msg "###### diff of my .zshrc ######"
  diff --unified <(cat "$HOME"/.zshrc) <(echo "$MY_ZSHRC") |\
    sed "s/^-/$(tput setaf 1)&/; s/^+/$(tput setaf 2)&/; s/^@/$(tput setaf 6)&/; s/$/$(tput sgr0)/" || {
    # Exit status is 0 if inputs are the same, 1 if different, 2 if trouble.
    status="$?"
    if (( status < 2 )); then
      true  # we ignore this type of error
    else
      exit "$status"
    fi
  }
  echo "$MY_ZSHRC" > "$HOME/.zshrc"
fi


stage "Install/Update SpaceVim..."
separate
readonly SPACEVIM_DIR="$HOME/.SpaceVim"
if [[ -d "$SPACEVIM_DIR" ]]; then
  readonly SPACEVIM_OP=update
else
  readonly SPACEVIM_OP=install
fi
msg "Running $SPACEVIM_OP procedural"
trace_on
curl -sLf https://spacevim.org/install.sh | bash >/dev/null 2>&1
trace_off
if [[ "$SPACEVIM_OP" == "install" ]]; then
  msg "Injecting configuration files"
  trace_on
  mkdir -p "$HOME"/.SpaceVim.d/autoload
  curl -fsSLo "$HOME"/.SpaceVim.d/init.toml \
    https://raw.githubusercontent.com/ljishen/workspace/master/.SpaceVim.d/init.toml
  curl -fsSLo "$HOME"/.SpaceVim.d/autoload/myspacevim.vim \
    https://raw.githubusercontent.com/ljishen/workspace/master/.SpaceVim.d/autoload/myspacevim.vim
  trace_off

  # fix the vimproc's DLL error
  #   https://spacevim.org/quick-start-guide/#install
  #   https://github.com/SpaceVim/SpaceVim/issues/544
  msg "Pre-compiling vimproc.vim"
  if prog_installed make && prog_installed gcc; then
    trace_on
    make -C "$SPACEVIM_DIR"/bundle/vimproc.vim >/dev/null
    trace_off
  else
    err "Please install make and gcc, then run 'make -C $SPACEVIM_DIR/bundle/vimproc.vim'"
  fi

  msg "Installing VIM plugins"
  # - The Ex-mode makes VIM non-interactive and is usually used as part of a
  #   batch processing script. We use it to silence plugin installation errors.
  #     https://en.wikibooks.org/wiki/Learning_the_vi_Editor/Vim/Modes#Ex-mode
  # - Install plugins from command line
  #     https://github.com/Shougo/dein.vim/issues/232
  trace_on
  bash <<EOF
export PS4="$PS4"
set -x
vim -u "$SPACEVIM_DIR"/vimrc -E '+call dein#install()' +qall
EOF
  trace_off
fi


stage "Post-installation Actions"
separate

declare -A PACKAGE_DEPS=(
  [vim]=VIM
  [tmux]=Tmux
  [shellcheck]=ShellCheck
  [global]=global
  [cscope]=cscope
  [ctags]="Exuberant Ctags"
  [npm]=npm
)

for comm in "${!PACKAGE_DEPS[@]}"; do
  if prog_installed "$comm"; then
    unset PACKAGE_DEPS["$comm"]
  fi
done

if [[ "${#PACKAGE_DEPS[@]}" -gt 0 ]]; then
  printf -v str "%s, " "${PACKAGE_DEPS[@]}"
  echo "- install programs: ${str%, }"
fi

vergte() { printf '%s\n%s' "$1" "$2" | sort -rCV; }

if prog_installed vim; then
  readonly VIM_VERSION="$(vim --version | awk 'NR==1 { print $5 }')"
  if ! vergte "$VIM_VERSION" "8.0"; then
    echo "- VIM version is less then 8.0. Consider to upgrade it to a newer version."
  fi
fi

if prog_installed tmux; then
  readonly TMUX_VERSION="$(tmux -V | awk '{ print $2 }')"
  if ! vergte "$TMUX_VERSION" "2.1"; then
    echo "- Tmux version is less then 2.1. Consider to upgrade it to a newer version."
  fi
fi

if prog_installed ctags \
  && ! [[ "$(ctags --version)" =~ Exuberant|Universal ]]; then
  echo "- install Exuberant Ctags (required by Tagbar: https://github.com/preservim/tagbar)"
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

stage "Good Job!"
