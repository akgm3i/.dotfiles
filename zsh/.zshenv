#
# Defines environment variables.
#

# XDG Base Directory
export XDG_CONFIG_HOME=${HOME}/.config
export XDG_CACHE_HOME=${HOME}/.cache
export XDG_DATA_HOME=${HOME}/.local/share
export XDG_STATE_HOME=${HOME}/.local/state
export XDG_RUNTIME_DIR=${HOME}/.temp

# DOTPATH
export DOTPATH=${HOME}/.dotfiles
export ZDOTDIR=${XDG_CONFIG_HOME}/zsh

# sheldon

# zinit
declare -A ZINIT
ZINIT[HOME_DIR]=${XDG_DATA_HOME}/zinit
ZINIT[BIN_DIR]=${ZINIT[HOME_DIR]}/bin
export ZINIT

# tmux
export TMUX_HOME=${DOTPATH}/tmux
export TMUX_TMPDIR=${XDG_RUNTIME_DIR}

# LANGUAGE
export LANGUAGE='en_US.UTF-8'
export LANG=${LANGUAGE}
export LC_ALL=${LANGUAGE}
export LC_CTYPE=${LANGUAGE}

# Editor
export EDITOR=nvim
export CVSEDITOR=${EDITOR}
export SVN_EDITOR=${EDITOR}
export GIT_EDITOR=${EDITOR}

# Pager
export PAGER=less

# Less status line
export LESS='-R -f -X -i -P ?f%f:(stdin). ?lb%lb?L/%L.. [?eEOF:?pb%pb\%..]'
export LESSCHARSET='utf-8'

# LESS man page colors (makes Man pages more readable).
export LESS_TERMCAP_mb=$'\E[01;31m'
export LESS_TERMCAP_md=$'\E[01;31m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[00;44;37m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;32m'

# ls command colors
export LSCOLORS=exfxcxdxbxegedabagacad
export LS_COLORS='di=34:ln=35:so=32:pi=33:ex=31:bd=46;34:cd=43;34:su=41;30:sg=46;30:tw=42;30:ow=43;30'

# declare the environment variables
export CORRECT_IGNORE='_*'
export CORRECT_IGNORE_FILE='.*'

export WORDCHARS='*?_-.[]~=&;!#$%^(){}<>'

# fzf - command-line fuzzy finder (https://github.com/junegunn/fzf)
export FZF_DEFAULT_OPTS="--extended --ansi --multi"

# History
# History file
export HISTFILE=${XDG_STATE_HOME}/zsh/history
# History size in memory
export HISTSIZE=10000
# The number of histsize
export SAVEHIST=1000000
# The size of asking history
export LISTMAX=50
# Do not save history when running as root
if [[ ${UID} -eq 0 ]]; then
    unset HISTFILE
    export SAVEHIST=0
fi

# available $INTERACTIVE_FILTER
export INTERACTIVE_FILTER="fzf:peco:percol:gof:pick"

# ghq
export GHQ_ROOT=${HOME}/Projects

# Programing Languages
# asdf
export ASDF_CONFIG_FILE=${XDG_CONFIG_HOME}/asdf/asdfrc
export ASDF_DATA_DIR=${XDG_DATA_HOME}/asdf

# Settings for Go
export GOPATH=${XDG_DATA_HOME}/go
export GOBIN=${GOPATH}/bin

# PATH
setopt no_global_rcs
typeset -gx -U path
path=( \
    ${HOME}/bin(N-/) \
    ${HOME}/.local/bin \
    ${GOBIN} \
    ${DOTPATH}/bin(N-/) \
    /usr/local/bin(N-/) \
    ${path} \
    )
