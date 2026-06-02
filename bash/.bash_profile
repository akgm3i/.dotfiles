#
# Login shell configuration for Bash.
#

if [ -r "$HOME/.bashrc" ]; then
  . "$HOME/.bashrc"
fi

if [ -r "$HOME/.bash_profile.local" ]; then
  . "$HOME/.bash_profile.local"
fi
