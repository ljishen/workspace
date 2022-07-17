# workspace

A one-liner command to (re-)construct my workspace, which includes three popular components:

- [Oh My Tmux](https://github.com/gpakosz/.tmux)
- [Oh My Zsh](https://ohmyz.sh/) configured with theme [powerlevel10k](https://github.com/romkatv/powerlevel10k) and [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
- [SpaceVim](https://spacevim.org/)

## Requirements

Bash and Zsh (aka Z shell). Yes, that's it. Of course you will also need Internet connection.

## Install

Use the one-liner command

```bash
curl -fsSL https://raw.githubusercontent.com/ljishen/workspace/main/install.sh | bash
```

## Features

### Auto Color Schemes Switch

Light & Dark color schemes automatically switch based on current time.

- Light: 8am ~ 6pm
- Dark: the reset of time

### Integrated Tmux Plugins

- [tmux-plugins/tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect): restoring programs including `ssh` `vi` `vim` `nvim` `emacs` `man` `less` `more` `tail` `top` `htop` `irssi` `weechat` `mutt`
- [tmux-plugins/tmux-logging](https://github.com/tmux-plugins/tmux-logging): Save the text of current pane to a file under `$HOME`
  - Save visible text `prefix + alt + p`
  - Save complete history `prefix + alt + shift + p`
  - Clear pane history `prefix + alt + c`
