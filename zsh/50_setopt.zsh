#
# set opts.
#

# == Changing Directories ==
setopt auto_cd
setopt auto_pushd

# Ignore duplicates to add to pushd
setopt pushd_ignore_dups

# Replace 'cd -' with 'cd +'
setopt pushd_minus

# pushd no arg == pushd $HOME
setopt pushd_to_home

# == Completion ==
setopt always_last_prompt

# use menu completion after the second consecutive request for completion
setopt auto_menu

setopt auto_param_keys
setopt auto_param_slash

# Automatically delete slash complemented by supplemented by inserting a space.
setopt auto_remove_slash

setopt complete_in_word
setopt list_types


# Do not record an event that was just recorded again.
setopt hist_ignore_dups

# Delete an old recorded event if a new event is a duplicate.
setopt hist_ignore_all_dups
setopt hist_save_nodups

# Expire a duplicate event first when trimming history.
setopt hist_expire_dups_first

# Do not display a previously found event.
setopt hist_find_no_dups
