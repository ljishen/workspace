# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# if running bash
if [ -n "$BASH_VERSION" ]; then
  # include .bashrc if it exists
  if [ -f "$HOME/.bashrc" ]; then
    # shellcheck disable=SC1091
    # shellcheck source=.bashrc
    . "$HOME/.bashrc"
  fi
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ]; then
  PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ]; then
  PATH="$HOME/.local/bin:$PATH"
fi

mkdir -p .local/bin

GIT_PROMPT=.local/bin/.git-prompt.sh
if [[ ! -f "$GIT_PROMPT" ]]; then
  wget \
    https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh \
    -O "$GIT_PROMPT" > /dev/null 2>&1
fi

if [[ -f "$GIT_PROMPT" ]]; then
  # shellcheck disable=SC1091
  # shellcheck source=.local/bin/.git-prompt.sh
  source "$GIT_PROMPT"

  SHELL_NAME="$(basename "$SHELL")"
  if [[ "$SHELL_NAME" == "bash" ]]; then
    PS1='[\u@\h \W$(__git_ps1 " (%s)")]\$ '
  elif [[ "$SHELL_NAME" == "zsh" ]]; then
    setopt PROMPT_SUBST
    PS1='[%n@%m %c$(__git_ps1 " (%s)")]\$ '
  fi
fi

# This function update the name of window for tmux
ssh() {
  # shellcheck disable=SC2009
  ps -p "$(ps -p $$ -o ppid= | tr -d '[:space:]')" -o comm= 2> /dev/null | grep -w tmux > /dev/null
  outside_tmux="$?"

  if ((!outside_tmux)); then
    printf "\\033k%s\\033\\" \
      "$(echo "$*" | awk '$1 !~ /^-|^[0-9]+$/ { print $1 }' RS=' ' | rev | cut -d '@' -f 1 | rev)"
  fi

  command ssh "$@"

  if ((!outside_tmux)); then
    printf "\\033k%s\\033\\" "$(basename "$SHELL")"
  fi
}
