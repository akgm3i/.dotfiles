#
# Executes commands at the start of an interactive Bash session.
#

# Skip when not interactive.
case $- in
  *i*) ;;
  *) return ;;
esac

umask 022
ulimit -S -c 0 2>/dev/null || true

if [ -z "${DOTPATH:-}" ]; then
  _dotfiles_bashrc="${BASH_SOURCE[0]}"
  case "$_dotfiles_bashrc" in
    /*) ;;
    *) _dotfiles_bashrc="$PWD/$_dotfiles_bashrc" ;;
  esac
  if [ -L "$_dotfiles_bashrc" ] && command -v readlink >/dev/null 2>&1; then
    _dotfiles_bashrc_target="$(readlink "$_dotfiles_bashrc")"
    case "$_dotfiles_bashrc_target" in
      /*) _dotfiles_bashrc="$_dotfiles_bashrc_target" ;;
      *) _dotfiles_bashrc="$(dirname "$_dotfiles_bashrc")/$_dotfiles_bashrc_target" ;;
    esac
  fi
  _dotfiles_candidate="$(cd "$(dirname "$_dotfiles_bashrc")/.." 2>/dev/null && pwd -P)"
  if [ -r "$_dotfiles_candidate/shell/env.sh" ]; then
    DOTPATH="$_dotfiles_candidate"
  else
    DOTPATH="$HOME/.dotfiles"
  fi
  unset _dotfiles_bashrc _dotfiles_bashrc_target _dotfiles_candidate
fi
export DOTPATH

if [ -r "$DOTPATH/shell/env.sh" ]; then
  . "$DOTPATH/shell/env.sh"
fi

# History configuration
HISTDIR="$XDG_STATE_HOME/bash"
[ -d "$HISTDIR" ] || mkdir -p "$HISTDIR"
export HISTFILE="$HISTDIR/history"
export HISTSIZE=10000
export HISTFILESIZE=200000
shopt -s histappend cmdhist checkwinsize

########
# mise #
########
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate bash)"
fi

###########
# sheldon #
###########
if command -v sheldon >/dev/null 2>&1; then
  eval "$( \
    SHELDON_CONFIG_FILE="${XDG_CONFIG_HOME}/sheldon/plugins.bash.toml" \
    sheldon source
  )"
fi

# Load local settings if present.
if [ -r "$HOME/.bashrc.local" ]; then
  . "$HOME/.bashrc.local"
fi
