# sheldon completions --shell zsh > /path/to/completions/_sheldon

# asdf
export PATH="${ASDF_DATA_DIR}/shims:$PATH"
# append completions to fpath
fpath=(${ASDF_DATA_DIR}/completions $fpath)
# initialise completions with ZSH's compinit
autoload -Uz compinit && compinit -d "${XDG_CACHE_HOME}/zsh/zcompdump-${ZSH_VERSION}"


function cdrepo {
  local repodir="$( ghq list -p | fzf -1 +m )"
  if [ ! -z "$repodir" ] ; then
    cd "$repodir"
  fi
}
