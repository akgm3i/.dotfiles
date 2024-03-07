# Load a few important annexes, without Turbo
# (this is currently required for annexes)
# zinit light-mode for \
#     zinit-zsh/z-a-patch-dl \
#     zinit-zsh/z-a-as-monitor \
#     zinit-zsh/z-a-bin-gem-node


# 🌸 A command-line fuzzy finder
zinit ice as'program' from'gh-r' pick'fzf'
zinit light junegunn/fzf-bin

# Remote repository management made easy
zinit ice as'program' from'gh-r' pick'**/ghq'
zinit light x-motemen/ghq

# a lightweight and flexible command-line JSON processor.
zinit ice as'program' from'gh-r' pick'jq* -> jq'
zinit light jqlang/jq

# # A command-line tool that makes git easier to use with GitHub.
# zinit ice from'gh-r' sbin'**/hub' cp'**/hub.zsh_completion -> _hub' atload'eval "$(hub alias -s)"'
# zinit light github/hub

# # Extendable version manager
# zinit ice src'asdf.sh' atclone'git checkout "$(git describe --abbrev=0 --tags)"' atpull'%atclone'
# zinit light asdf-vm/asdf

# a simple, fast and user-friendly alternative to find.
zinit ice as'program' from'gh-r' pick'**/fd'
zinit light sharkdp/fd

# syntax highlighting for a large number of programming and markup languages
zinit ice as'program' from'gh-r' pick'**/bat'
zinit light sharkdp/bat

# a replacement for ls written in Rust.
zinit ice as'program' from'gh-r' pick'exa* -> exa'
zinit light ogham/exa

# docker completion
# zinit ice as'completion'
# zinit snippet https://github.com/docker/cli/blob/master/contrib/completion/zsh/_docker
# zinit ice as'completion'
# zinit snippet https://github.com/docker/compose/blob/master/contrib/completion/zsh/_docker-compose
