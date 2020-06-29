mkdir -p .local/bin

GIT_PROMPT=.local/bin/.git-prompt.sh
if [[ ! -f "$GIT_PROMPT" ]]; then
  wget \
    https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh \
    -O "$GIT_PROMPT" > /dev/null 2>&1
fi

if [[ -f "$GIT_PROMPT" ]]; then
  # shellcheck source=/dev/null
  source "$GIT_PROMPT"

  SHELL_NAME="$(basename "$SHELL")"
  if [[ "$SHELL_NAME" == "bash" ]]; then
    PS1='[\u@\h \W$(__git_ps1 " (%s)")]\$ '
  elif [[ "$SHELL_NAME" == "zsh" ]]; then
    setopt PROMPT_SUBST
    PS1='[%n@%m %c$(__git_ps1 " (%s)")]\$ '
  fi
fi

if [[ ! -d .tmux ]]; then
  echo "[INFO] Install tmux configuration..."
  # See https://github.com/gpakosz/.tmux
  git clone https://github.com/gpakosz/.tmux.git
  ln -s -f .tmux/.tmux.conf
  cp .tmux/.tmux.conf.local .
fi

# This function update the name of window for tmux
ssh() {
  # shellcheck disable=SC2009
  ps -p "$(ps -p $$ -o ppid= | tr -d '[:space:]')" -o comm= 2> /dev/null | grep -w tmux > /dev/null
  outside_tmux="$?"

  if ((!outside_tmux)); then
    tmux rename-window \
      "$(echo "$*" | awk '$1 !~ /^-|^[0-9]+$/ { print $1 }' RS=' ' | rev | cut -d '@' -f 1 | rev)"
  fi

  command ssh "$@"

  if ((!outside_tmux)); then
    tmux rename-window "$(basename "$SHELL")"
  fi
}
