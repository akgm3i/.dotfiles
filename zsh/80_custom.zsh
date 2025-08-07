# sheldon completions --shell zsh > /path/to/completions/_sheldon

# Add local completions
fpath=("$XDG_CONFIG_HOME/zsh/completions" $fpath)

# Add completions from cache
local cache_completions_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/completions"
fpath=("$cache_completions_dir" $fpath)

if command -v mise &> /dev/null; then
  # mise completion
  local mise_completion_file="$cache_completions_dir/_mise"
  if [ ! -f "$mise_completion_file" ] || [ "$(command -v mise)" -nt "$mise_completion_file" ]; then
    mkdir -p "$cache_completions_dir"
    mise completion zsh > "$mise_completion_file"
  fi
fi

# initialise completions with ZSH's compinit
autoload -Uz compinit && compinit -d "${XDG_CACHE_HOME}/zsh/zcompdump-${ZSH_VERSION}"
zstyle ':completion:*' cache-path $XDG_CACHE_HOME/zsh/zcompcache

function cdrepo {
  local repodir="$( ghq list -p | fzf -1 +m )"
  if [ ! -z "$repodir" ] ; then
    cd "$repodir"
  fi
}
