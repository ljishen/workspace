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

# This function update the name of window for tmux
ssh() {
  # shellcheck disable=SC2009
  ps -p "$(ps -p $$ -o ppid=)" -o comm= 2> /dev/null | grep -w tmux > /dev/null
  outside_tmux="$?"

  if ((!outside_tmux)); then
    printf "\\033k%s\\033\\" \
      "$(echo "$*" | awk '$1 !~ /^-/ { print $1 }' RS=' ' | rev | cut -d '@' -f 1 | rev)"
    echo "12123"
  fi

  command ssh "$@"

  if ((!outside_tmux)); then
    printf "\\033k%s\\033\\" "$(basename "$SHELL")"
  fi
}