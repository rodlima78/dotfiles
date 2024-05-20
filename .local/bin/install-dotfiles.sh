#!/bin/bash

set -e

SDIR=$(dirname "$(readlink -f "$0")")

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

config()
{
    git "--git-dir=$repo" "$@"
}

if [ -d "$repo" ]; then
    defbranch=$(config branch --show-current || true)
    if [[ "$defbranch" ]]; then
        echo "Dotfiles already installed, branch $defbranch checked out."
        echo "To change branches, uninstall it first with '$SDIR/uninstall-dotfiles.sh'"
        exit 1
    else >&2
        # remove cruft left behind
        rm -rf "$repo"
    fi
fi

# Rollback in case of failure ============================================
cleanup()
{
    # Revert all changes in case of errors
    if [ $? != 0 ]; then
        echo
        echo "Rolling back changes due to failure" >&2
        $SDIR/uninstall-dotfiles.sh
        rm -f "$filelist"
    fi
}
trap cleanup EXIT

# Clone my dotfiles ================================================
git clone --bare https://github.com/rodlima78/dotfiles.git "$repo"

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
