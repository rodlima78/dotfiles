#!/bin/bash

set -e

# Command line processing ===================================
if [ $# -gt 1 ]; then
    echo "Usage: install.sh [branch]" >&2
    exit 1
fi

branch=
if [ $# = 1 ]; then
    branch=$1
    shift
fi

repo=$HOME/.dotfiles
if [ -d $repo ]; then
    echo "dotfiles already installed" >&2
    exit
fi

# Rollback in case of failure ============================================
cleanup()
{
    # Revert all changes in case of errors
    if [ $? != 0 ]; then
        local -
        set +e

        # If local repository exists,
        if [ -d "$repo" ] && config config --get core.worktree > /dev/null; then
            # Remove checked out files by resetting to the first commit
            # (we know it's empty)
            config reset --hard $(config rev-list --max-parents=0 HEAD)
            # Nuke the repo
            rm -rf "$repo"
        fi

        # Do we need to restore the backed up files?
        if [ -f ~/.dotfiles-backup/files ]; then
            tmpfile=$(mktemp)
            mv ~/.dotfiles-backup/files $tmpfile

            local IFS=
            cd ~
            while read -r file; do
                (cd .dotfiles-backup && cp --parents -avr "$file" ~ && rm -r "$file")
                # Try to remove the subdirectories
                local hfile=.dotfiles-backup/$file
                rmdir --ignore-fail-on-non-empty --parents "${hfile%/*}"
            done < $tmpfile
            rm $tmpfile
        fi
        rm -f "$filelist"
    fi
}
trap cleanup EXIT

# Clone my dotfiles ================================================
git clone --bare https://github.com/rodlima78/dotfiles.git "$repo"
config()
{
    git "--git-dir=$repo" "$@"
}

# Avoid showing all other files in $HOME as being untracked.
config config status.showUntrackedFiles no
# Update all submodules during checkout (avoids warning)
config config submodule.recurse true

# If not specified, user selects what branch to checkout ============
defbranch=$(config branch --show-current)
# If no branch was given
if [ -z "$branch" ]; then
    # User can select which one to checkout based on
    # local and remote branches

    # default branch comes first
    echo
    PS3="Choose what branch to checkout (y|yes = $defbranch): "
    select branch in $defbranch $(config branch -a --column=never --list --format '%(refname:short)' | grep -v $defbranch); do
        if [[ $branch == $defbranch ]]; then
            break;
        elif [[ $REPLY == @(y|yes) ]]; then
            branch=$defbranch
            break
        else
            echo "ERROR invalid choice"
        fi
    done < /dev/tty # use tty directly to read user input when doing 'curl | bash'
    unset PS3
fi >&2

# Backup any files that might be overwritten ==========================
cd ~
mkdir -p .dotfiles-backup

filelist=$(mktemp)
mv --backup=numbered "$filelist" .dotfiles-backup/files
unset filelist
config ls-tree -r --name-only --full-name $branch :/ \
    | while read -r file; do
         if [ -e "$file" ]; then
             cp --backup=numbered -avr --parents "$file" .dotfiles-backup/
             echo "$file" >> .dotfiles-backup/files
             rm -r "$file"
         fi
      done
# Remove backup directory if empty (nothing backed up).
rmdir --ignore-fail-on-non-empty .dotfiles-backup

# Checkout the dotfiles =================================================
config --work-tree=$HOME checkout "$branch"

# Not bare anymore
config config core.bare false
config config core.worktree "$HOME"

config submodule update --init

# The end ==============================================================

cat <<EOS >&2

dotfiles from $repo @ $branch installed in $HOME.
Load them now with:

exec $(getent passwd "$(id -u)" | cut -d: -f7) -l

EOS
