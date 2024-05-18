# Sourced by Bourne-compatible login shells.

## Append/prepend helpers 
env_prepend()
{
    if [ $# -lt 2 ]; then
        echo 'usage: prepend <envvar> <values...>' >&2
        return 1
    fi

    eval local value="\$$1"; shift
    (IFS=:; echo "$*${value:+:$value}")
}

env_append()
{
    if [ $# -lt 2 ]; then
        echo 'usage: append <envvar> <values...>' >&2
        return 1
    fi
    eval local value="\$$1"; shift
    (IFS=:; echo "${value:+$value:}$*")
}

## Setup PATH 
[ -d ~/.local/bin ] && PATH=$(env_prepend PATH ~/.local/bin)
[ -d ~/bin ]        && PATH=$(env_prepend PATH ~/bin)

## XDG directories 
export XDG_RUNTIME_DIR=$HOME/.run
mkdir -m 700 -p $XDG_RUNTIME_DIR
export XDG_CONFIG_HOME=$HOME/.config
mkdir -m 755 -p $XDG_CONFIG_HOME

## Load up our ssh/gpg keys 
if type -p keychain >/dev/null; then
    eval "$(keychain --eval --quiet)"
fi

# Load custom login initialization
[ -r ~/.profile.local ] && { [ "$DEBUG_SHELL_INIT" ] && echo ~/.profile.local; . ~/.profile.local; }
