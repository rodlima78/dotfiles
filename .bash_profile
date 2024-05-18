# Sourced on bash login shells.

# Just forward to ~/.profile
[ -r ~/.profile ] && . ~/.profile

# Do not add entries here. Do it in ~/.profile and
# make sure it's compatible with /bin/sh.

# Source config for interactive shells
[[ $- == *i* && -r ~/.bashrc ]] && . ~/.bashrc
