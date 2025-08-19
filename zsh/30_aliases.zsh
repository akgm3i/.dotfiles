#
# Defines aliases.
#

# Common aliases
# ls
alias ..='cd ../'          # Move to parent directory
alias ls='eza --git --icons' # List files with eza (git & icons)
alias ld='eza -ld'          # Show info about the directory
alias ll='eza -lF'          # Show long file information
alias la='eza -aF'          # Show hidden files
alias lla='eza -laF'        # Show hidden all files
alias lx='eza -lXB'         # Sort by extension
alias lk='eza -lSr'         # Sort by size, biggest last
alias lt='eza -ltr'         # Sort by date, most recent last
alias lc='eza -ltcr'        # Sort by and show change time, most recent last
alias lu='eza -ltur'        # Sort by and show access time, most recent last
alias lr='eza -lR'          # Recursive ls

# cat
alias cat='bat'             # Display file content with bat
