#!/bin/bash

set +e

repo=$HOME/.dotfiles

config()
{
    git "--git-dir=$repo" "--work-tree=$HOME" "$@"
}

# If local repository exists,
if [ -d "$repo" ]; then
    config fetch
    if [[ "$(config stash list | tee >(cat 1>&2))" ]]; then
        echo "There are stashed items, refusing to uninstall" >&2
        exit 1
    fi
    if [[ "$(config status -s | tee >(cat 1>&2))" ]]; then
        echo "There are non-committed items, refusing to uninstall" >&2
        exit 1
    fi
    if config branch --list --format='%(upstream:trackshort)' | grep -vq =; then
        config branch -vv >&2
        echo "There branches not synchronized with upstream, refusing to uninstall" >&2
        exit 1
    fi

    # Remove checked out files by resetting to the first commit
    # (we know it's empty)
    config reset --hard $(config rev-list --max-parents=0 HEAD)
    # Nuke the repo
    rm -rf "$repo"
fi

# Do we need to restore backed up files?
if [ -f ~/.dotfiles-backup/files ]; then
    tmpfile=$(mktemp)
    # Move files out of backup dir so that we can more easily
    # remove the directory if empty
    mv ~/.dotfiles-backup/files $tmpfile

    pushd ~ >/dev/null
    # For each file,
    while IFS= read -r file; do
        # Move files to their original place
        (cd .dotfiles-backup && cp --backup=numbered --parents -avr "$file" ~ && rm -r "$file")
        # Remove the empty subdirectories left behind
        hfile=.dotfiles-backup/$file
        rmdir --ignore-fail-on-non-empty --parents "${hfile%/*}"
    done < $tmpfile
    rm $tmpfile
    popd > /dev/null
elif [ -d ~/.dotfiles-backup ]; then
    rmdir --ignore-fail-on-non-empty ~/.dotfiles-backup
fi

echo "dotfiles uninstalled successfully" >&2
