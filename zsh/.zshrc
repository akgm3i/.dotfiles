#
# Executes commands at the start of an interactive session.
#

# default permission
umask 022

# no dump core file
limit coredumpsize 0

# Load the shared environment only for interactive Zsh sessions.
if [[ -r "${DOTPATH}/shell/env.sh" ]]; then
    source "${DOTPATH}/shell/env.sh"
fi

# Keep Zsh state out of the configuration directory on fresh installations.
_dotfiles_zsh_state_dir="${XDG_STATE_HOME}/zsh"
_dotfiles_zsh_cache_dir="${XDG_CACHE_HOME}/zsh"
mkdir -p "${_dotfiles_zsh_state_dir}" "${_dotfiles_zsh_cache_dir}"
chmod 700 "${_dotfiles_zsh_state_dir}" 2>/dev/null || true

export HISTFILE="${_dotfiles_zsh_state_dir}/history"
export HISTSIZE=10000
export SAVEHIST=1000000
export LISTMAX=50

if [[ ${UID} -eq 0 ]]; then
    unset HISTFILE
    export SAVEHIST=0
else
    # Append commands incrementally and import commands from concurrent shells.
    setopt append_history
    setopt share_history
fi

unset _dotfiles_zsh_state_dir _dotfiles_zsh_cache_dir

# Spell correction configuration.
export CORRECT_IGNORE='_*'
export CORRECT_IGNORE_FILE='.*'

# Word characters used when moving across words.
export WORDCHARS='*?_-.[]~=&;!#$%^(){}<>'

# Ensure PATH stays unique when converted to the Zsh array form.
typeset -gU path
path=(${(s/:/)PATH})

# Return if zsh is called from Vim
if [[ -n ${VIMRUNTIME} ]]; then
    return 0
fi


########
# mise #
########
if command -v mise >/dev/null 2>&1; then
    eval "$(mise activate zsh)"
fi


###########
# sheldon #
###########
if command -v sheldon >/dev/null 2>&1; then
    eval "$(sheldon source)"
fi


# load local settings
if [[ -f ${HOME}/.zshrc.local ]]; then
    source ${HOME}/.zshrc.local
fi
