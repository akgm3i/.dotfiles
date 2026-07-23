#
# User-facing navigation helpers.
#

cdrepo() {
    local repodir
    repodir="$(ghq list -p | fzf -1 +m --query "${*:-}")" || return
    [[ -n ${repodir} ]] && builtin cd -- "${repodir}"
}

cddot() {
    local target="${DOTPATH:-}"
    if [[ -z ${target} || ! -d ${target} ]]; then
        print -u2 'cddot: DOTPATH directory is unavailable'
        return 1
    fi
    builtin cd -- "${target}"
}
