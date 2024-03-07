# dotfiles installer.

# --------------------------------
printf "Install dot files.\n"


# --------------------------------
printf "Check envs.\n"

dep_envs='
    DOTPATH
    XDG_CONFIG_HOME
'

for dep_env in $dep_envs
do
    if [ -z ${!dep_env} ]; then
        printf "env \$$dep_env is not defined.\n"
        exit 1
    fi
done

has() {
    type "${1:?too few arguments}" &>/dev/null
}


# --------------------------------
printf "Check dependencies.\n"

dep_commands='
    git
    tmux
    zsh
'

#local dep_cmd
for dep_cmd in $dep_commands
do
    if ! has $dep_cmd; then
        printf "$dep_cmd is not found.\n"
        exit 1
    fi
done


# --------------------------------
printf "Installing sheldon.\n"

if [[ ! -f ~/.local/bin/sheldon ]]; then
    curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh \
        | bash -s -- --repo rossmacarthur/sheldon --to ~/.local/bin
fi

# --------------------------------
printf "Making links.\n"

ln -sf $DOTPATH/git $XDG_CONFIG_HOME/git
ln -sf $DOTPATH/tmux $XDG_CONFIG_HOME/tmux
ln -sf $DOTPATH/sheldon $XDG_CONFIG_HOME/sheldon
ln -sf $DOTPATH/zsh $XDG_CONFIG_HOME/zsh
ln -sf $XDG_CONFIG_HOME/zsh/.zshenv $HOME/.zshenv

ln -sf $DOTPATH/iterm2 $XDG_CONFIG_HOME/iterm2
