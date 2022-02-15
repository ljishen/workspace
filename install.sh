#!/usr/bin/env bash

set -euo pipefail

# https://stackoverflow.com/a/51548669
shopt -s expand_aliases
alias trace_on="{ set -x; } 2>/dev/null"
alias trace_off="{ set +x; } 2>/dev/null"

# $BASH_SOURCE can be empty, if no named file is involved
#   https://stackoverflow.com/a/35006505
export PS4='# ${BASH_SOURCE:-"$0"}:${LINENO} - ${FUNCNAME[0]:+${FUNCNAME[0]}()} > '

FOLLOWUP_MSG_OF_STAGE=0
stage() {
  # more color styles: https://stackoverflow.com/a/28938235
  printf "\\n\\n\\033[1;33m[STAGE] %s\\033[0m\\n" "$*"
  FOLLOWUP_MSG_OF_STAGE=0
}
separate() { printf "\\033[1;33m------------------------------------------\\033[0m\\n"; }
msg() {
  if (( FOLLOWUP_MSG_OF_STAGE )); then
    echo
  fi
  printf "\\033[1;32m%s\\033[0m\\n" "$*"
  FOLLOWUP_MSG_OF_STAGE=1
}
err() { printf "\\033[1;31m[ERROR] %s\\033[0m\\n" "$*" >&2; }

program_installed() { command -v "$1" >/dev/null 2>&1; }

if ! program_installed git; then
  err "Please install git first."
  exit 1
fi

if ! program_installed curl; then
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
  ( cd "$OH_MY_TMUX_DIR" && git pull --ff-only )
  trace_off
else
  trace_on
  git clone https://github.com/gpakosz/.tmux.git "$OH_MY_TMUX_DIR" >/dev/null 2>&1
  ln --symbolic --force "$OH_MY_TMUX_DIR"/.tmux.conf "$HOME"
  cp --force "$OH_MY_TMUX_DIR"/.tmux.conf.local "$HOME"

  # enable the TPM plugin tmux-resurrect and restore ssh sessions
  #   https://github.com/tmux-plugins/tmux-resurrect/blob/master/docs/restoring_programs.md
  #
  # selecting lines with address:
  #   https://www.gnu.org/software/sed/manual/sed.html#Addresses-overview
  sed --in-place "/set -g @plugin 'tmux-plugins\/tmux-resurrect'/ \
    {s/^#//;s/$/\\nset -g @resurrect-processes 'ssh'\\nset -g @plugin 'tmux-plugins\/tmux-logging'/}" \
    "$HOME"/.tmux.conf.local
  trace_off
fi


vergte() { printf '%s\n%s' "$1" "$2" | sort -rCV; }
show_diff() {
  local -r origin_file="$1" update_content="$2"

  diff --unified <(cat "$origin_file") <(echo "$update_content") |\
    sed "s/^-/$(tput setaf 1)&/; s/^+/$(tput setaf 2)&/; s/^@/$(tput setaf 6)&/; s/$/$(tput sgr0)/" || {
    # Exit status is 0 if inputs are the same, 1 if different, 2 if trouble.
    status="$?"
    if (( status < 2 )); then
      true  # we ignore this type of error
    else
      exit "$status"
    fi
  }
}


stage "Install/Update Oh My Zsh..."
separate
if ! program_installed zsh; then
  err "Please install zsh first."
  exit 1
fi
ZSH_VERSION="$(zsh --version | cut --delimiter=' ' --fields=2)"
if ! vergte "$ZSH_VERSION" "5.4"; then
  # See https://github.com/romkatv/powerlevel10k#what-is-the-minimum-supported-zsh-version
  err "Require Zsh >= 5.4 (current $ZSH_VERSION)"
  exit 2
fi
export OH_MY_ZSH_DIR=${OH_MY_ZSH_DIR:-"$HOME"/.oh-my-zsh}
export POWERLEVEL10K_DIR="$OH_MY_ZSH_DIR"/custom/themes/powerlevel10k
msg "Installation directory: $OH_MY_ZSH_DIR"
if [[ -d "$OH_MY_ZSH_DIR" ]]; then
  msg "Updating Oh My Zsh"
  trace_on
  ( zsh -c "source $HOME/.zshrc && omz update --unattended >/dev/null" && exit )
  trace_off

  msg "Updating theme Powerlevel10k"
  trace_on
  ( cd "$POWERLEVEL10K_DIR" && git pull --ff-only )
  trace_off

  msg "Updating zsh-autosuggestions"
  trace_on
  (
    cd ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions &&
      git fetch &&
      git reset --hard HEAD
  )
  trace_off
else
  msg "Installing Oh My Zsh"
  trace_on
  curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh |\
    env ZSH="$OH_MY_ZSH_DIR" sh >/dev/null 2>&1
  trace_off

  msg "Installing theme Powerlevel10k"
  trace_on
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
    "$POWERLEVEL10K_DIR" >/dev/null 2>&1
  trace_off

  msg "Installing zsh-autosuggestions"
  trace_on
  git clone https://github.com/zsh-users/zsh-autosuggestions \
    ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions >/dev/null 2>&1
  trace_off
fi

msg "Injecting configuration files"

msg "###### diff of my .zshrc ######"
readonly MY_ZSHRC="$(curl -fsSL https://raw.githubusercontent.com/ljishen/workspace/main/.zshrc)"
show_diff "$OH_MY_ZSH_DIR"/templates/zshrc.zsh-template "$MY_ZSHRC"
echo "$MY_ZSHRC" >"$HOME"/.zshrc

msg "###### diff of my .p10k.zsh ######"
readonly MY_P10K_ZSH="$(curl -fsSL https://raw.githubusercontent.com/ljishen/workspace/main/.p10k.zsh)"
show_diff "$POWERLEVEL10K_DIR"/config/p10k-lean.zsh "$MY_P10K_ZSH"
echo "$MY_P10K_ZSH" >"$HOME"/.p10k.zsh


stage "Install/Update SpaceVim..."
separate
if ! program_installed vim; then
  err "Please install vim first."
  exit 1
fi
readonly SPACEVIM_DIR="$HOME/.SpaceVim"
if [[ -d "$SPACEVIM_DIR" ]]; then
  readonly SPACEVIM_OP=update
else
  readonly SPACEVIM_OP=install
fi
msg "Running the $SPACEVIM_OP procedural"
trace_on
curl -sLf https://spacevim.org/install.sh | bash >/dev/null 2>&1
trace_off
if [[ "$SPACEVIM_OP" == "install" ]]; then
  msg "Injecting configuration files"
  trace_on
  mkdir -p "$HOME"/.SpaceVim.d/autoload
  curl -fsSLo "$HOME"/.SpaceVim.d/init.toml \
    https://raw.githubusercontent.com/ljishen/workspace/main/.SpaceVim.d/init.toml
  curl -fsSLo "$HOME"/.SpaceVim.d/autoload/myspacevim.vim \
    https://raw.githubusercontent.com/ljishen/workspace/main/.SpaceVim.d/autoload/myspacevim.vim
  trace_off

  # fix the vimproc's DLL error
  #   https://spacevim.org/quick-start-guide/#install
  #   https://github.com/SpaceVim/SpaceVim/issues/544
  msg "Pre-compiling vimproc.vim"
  if program_installed make && program_installed gcc; then
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
  # - Install/Update plugins from command line
  #     https://github.com/Shougo/dein.vim/blob/master/doc/dein.txt#L1248
  bash <<EOF
set -x
vim -e -i NONE -N -s -V1 -u "$SPACEVIM_DIR"/vimrc -U NONE \
  -c "try | call dein#install() | finally | qall! | endtry"
EOF
else
  msg "Updating VIM plugins"
  bash <<EOF
set -x
vim -e -i NONE -N -s -V1 -u "$SPACEVIM_DIR"/vimrc -U NONE \
  -c "try | call dein#update() | finally | qall! | endtry"
EOF
fi
echo


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
  if program_installed "$comm"; then
    unset PACKAGE_DEPS["$comm"]
  fi
done

if [[ "${#PACKAGE_DEPS[@]}" -gt 0 ]]; then
  printf -v str "%s, " "${PACKAGE_DEPS[@]}"
  echo "- install programs: ${str%, }"
fi

readonly VIM_VERSION="$(vim --version | awk 'NR==1 { print $5 }')"
if ! vergte "$VIM_VERSION" "8.0"; then
  echo "- VIM version is less then 8.0. Consider to upgrade it to a newer version."
fi

if program_installed tmux; then
  readonly TMUX_VERSION="$(tmux -V | awk '{ print $2 }')"
  if ! vergte "$TMUX_VERSION" "2.4"; then
    echo "- Tmux version is less then 2.4. Consider to upgrade it to a newer version."
  fi
fi

if program_installed ctags \
  && ! [[ "$(ctags --version)" =~ Exuberant|Universal ]]; then
  echo "- install Exuberant Ctags (required by Tagbar: https://github.com/preservim/tagbar)"
fi

# see https://spacevim.org/layers/language-server-protocol/
if ! program_installed npm \
  || ! npm list -g --depth 0 bash-language-server >/dev/null; then
  echo "- install language server protocol for bash script: \`sudo npm i -g bash-language-server\`"
fi

# check string contains: https://stackoverflow.com/a/20460402/2926646
if [[ -n "${SHELL##*/zsh*}" ]]; then
  # https://superuser.com/a/553939
  if sudo --non-interactive --validate 2>/dev/null; then
    # we have passwordless sudo privileges
    sudo chsh -s "$(command -v zsh)" "$USER"
    echo "- log out and log back in to use zsh"
  else
    echo "- change the default shell for you to zsh in file /etc/passwd," \
      "or simply run 'sudo chsh -s \$(which zsh) \$USER'"
  fi
fi

stage "Good Job!"
