#
# Defines environment variables for Zsh.
#

# Avoid sourcing /etc/zshenv when possible.
setopt no_global_rcs

# Ensure DOTPATH is available before loading shared configuration.
if [[ -z ${DOTPATH:-} ]]; then
    _dotfiles_zshenv_file="${ZDOTDIR:-$HOME}/.zshenv"
    if [[ -L "${_dotfiles_zshenv_file}" ]] && command -v readlink >/dev/null 2>&1; then
        _dotfiles_zshenv_target="$(readlink "${_dotfiles_zshenv_file}")"
        if [[ "${_dotfiles_zshenv_target}" == /* ]]; then
            _dotfiles_zshenv_file="${_dotfiles_zshenv_target}"
        else
            _dotfiles_zshenv_file="${_dotfiles_zshenv_file:h}/${_dotfiles_zshenv_target}"
        fi
    fi
    _dotfiles_zshenv_dir="$(cd "${_dotfiles_zshenv_file:h}" 2>/dev/null && pwd -P)"
    if [[ -n "${_dotfiles_zshenv_dir}" ]]; then
        _dotfiles_zshenv_file="${_dotfiles_zshenv_dir}/${_dotfiles_zshenv_file:t}"
    fi
    _dotfiles_candidate="${_dotfiles_zshenv_file:h:h}"
    if [[ -r "${_dotfiles_candidate}/shell/env.sh" ]]; then
        export DOTPATH="${_dotfiles_candidate}"
    else
        export DOTPATH=${HOME}/.dotfiles
    fi
    unset _dotfiles_zshenv_file _dotfiles_zshenv_target _dotfiles_zshenv_dir _dotfiles_candidate
fi

# Load shared, POSIX-compatible environment configuration.
if [[ -r "${DOTPATH}/shell/env.sh" ]]; then
    source "${DOTPATH}/shell/env.sh"
fi

# Zsh-specific directories and history configuration.
export ZDOTDIR=${XDG_CONFIG_HOME}/zsh
export HISTFILE=${XDG_STATE_HOME}/zsh/history
export HISTSIZE=10000
export SAVEHIST=1000000
export LISTMAX=50

if [[ ${UID} -eq 0 ]]; then
    unset HISTFILE
    export SAVEHIST=0
fi

# Spell correction configuration.
export CORRECT_IGNORE='_*'
export CORRECT_IGNORE_FILE='.*'

# Word characters used when moving across words.
export WORDCHARS='*?_-.[]~=&;!#$%^(){}<>'

# Ensure PATH stays unique when converted to the Zsh array form.
typeset -gU path
path=(${(s/:/)PATH})
