#
# Defines the minimal environment required before Zsh selects its startup files.
#

# Resolve the repository from this file's installed symlink when possible.
if [[ -z ${DOTPATH:-} ]]; then
    _dotfiles_candidate="${${(%):-%N}:A:h:h}"
    if [[ -r "${_dotfiles_candidate}/shell/env.sh" ]]; then
        export DOTPATH="${_dotfiles_candidate}"
    else
        export DOTPATH=${HOME}/.dotfiles
    fi
    unset _dotfiles_candidate
fi

: "${XDG_CONFIG_HOME:=${HOME}/.config}"
export XDG_CONFIG_HOME
export ZDOTDIR=${XDG_CONFIG_HOME}/zsh
