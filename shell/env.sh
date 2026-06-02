# shellcheck shell=sh
#
# Shared environment configuration for POSIX-compatible shells.
#

# Ensure DOTPATH is set so other scripts can reference the dotfiles repo.
if [ -z "${DOTPATH:-}" ]; then
  DOTPATH="$HOME/.dotfiles"
fi
export DOTPATH

# XDG Base Directory defaults (allow user overrides).
: "${XDG_CONFIG_HOME:=$HOME/.config}"
: "${XDG_CACHE_HOME:=$HOME/.cache}"
: "${XDG_DATA_HOME:=$HOME/.local/share}"
: "${XDG_STATE_HOME:=$HOME/.local/state}"
: "${XDG_RUNTIME_DIR:=$HOME/.temp}"
export XDG_CONFIG_HOME XDG_CACHE_HOME XDG_DATA_HOME XDG_STATE_HOME XDG_RUNTIME_DIR

# Editor / pager
: "${EDITOR:=nvim}"
export EDITOR
export CVSEDITOR="$EDITOR"
export SVN_EDITOR="$EDITOR"
export GIT_EDITOR="$EDITOR"
export PAGER="${PAGER:-less}"

# Locale
export LANGUAGE="${LANGUAGE:-en_US.UTF-8}"
export LANG="$LANGUAGE"
export LC_ALL="$LANGUAGE"
export LC_CTYPE="$LANGUAGE"

# Less configuration
export LESS='-R -f -X -i -P ?f%f:(stdin). ?lb%lb?L/%L.. [?eEOF:?pb%pb\%..]'
export LESSCHARSET='utf-8'
export LESS_TERMCAP_mb='\E[01;31m'
export LESS_TERMCAP_md='\E[01;31m'
export LESS_TERMCAP_me='\E[0m'
export LESS_TERMCAP_se='\E[0m'
export LESS_TERMCAP_so='\E[00;44;37m'
export LESS_TERMCAP_ue='\E[0m'
export LESS_TERMCAP_us='\E[01;32m'

# Colors
export LSCOLORS="${LSCOLORS:-exfxcxdxbxegedabagacad}"
export LS_COLORS="${LS_COLORS:-di=34:ln=35:so=32:pi=33:ex=31:bd=46;34:cd=43;34:su=41;30:sg=46;30:tw=42;30:ow=43;30}"

# Tool-specific configuration
export TMUX_HOME="$DOTPATH/tmux"
export TMUX_TMPDIR="$XDG_RUNTIME_DIR"
export GHQ_ROOT="${GHQ_ROOT:-$HOME/Projects}"
export GOPATH="${GOPATH:-$XDG_DATA_HOME/go}"
export NODE_REPL_HISTORY="$XDG_DATA_HOME/node_repl_history"
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"
export MISE_RUSTUP_HOME="$XDG_DATA_HOME/rustup"
export MISE_CARGO_HOME="$XDG_DATA_HOME/cargo"

# History directories can be handled per-shell, but ensure base directories exist.
mkdir -p "$XDG_STATE_HOME" "$XDG_CACHE_HOME" "$XDG_DATA_HOME" "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR" 2>/dev/null || true

# Configure fzf defaults if available.
export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:---extended --ansi --multi}"
export INTERACTIVE_FILTER="${INTERACTIVE_FILTER:-fzf:peco:percol:gof:pick}"

# Helper to prepend directories to PATH without duplicates.
_path_prepend() {
  case ":$PATH:" in
    *":$1:") return 0 ;;
  esac

  if [ -d "$1" ]; then
    if [ -n "$PATH" ]; then
      PATH="$1:$PATH"
    else
      PATH="$1"
    fi
  fi
}

_path_prepend "$HOME/bin"
_path_prepend "$HOME/.local/bin"
_path_prepend "$DOTPATH/bin"
_path_prepend /usr/local/bin
export PATH

unset -f _path_prepend
