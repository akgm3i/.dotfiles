#!/bin/sh

command_name=${0##*/}
printf '%s %s\n' "$command_name" "$*" >> "${MOTD_COMMAND_LOG:?}"

if [ "$command_name" != git ]; then
    exit 0
fi

case "$*" in
    *"rev-parse --is-inside-work-tree"*)
        printf 'true\n'
        ;;
    *"symbolic-ref --short -q HEAD"*)
        printf 'feature/test\n'
        ;;
    *"rev-parse --abbrev-ref --symbolic-full-name @{upstream}"*)
        printf 'origin/feature/test\n'
        ;;
    *"rev-list --left-right --count HEAD...@{upstream}"*)
        printf '2\t1\n'
        ;;
    *"status --porcelain --untracked-files=normal"*)
        printf ' M bin/motd\n'
        ;;
esac
