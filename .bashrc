# Sourced by bash interactive shells

# Skip if non-interactive shell
[[ $- != *i* ]] && return

# Terminal
# Detect if colors are supported
use_color=false
if type -P dircolors >/dev/null ; then
    # Enable colors for ls, etc.  Prefer ~/.dir_colors #64489
    LS_COLORS=
    if [[ -f ~/.dir_colors ]] ; then
        eval "$(dircolors -b ~/.dir_colors)"
    elif [[ -f /etc/DIR_COLORS ]] ; then
        eval "$(dircolors -b /etc/DIR_COLORS)"
    else
        eval "$(dircolors -b)"
    fi
    # Note: We always evaluate the LS_COLORS setting even when it's the
    # default.  If it isn't set, then `ls` will only colorize by default
    # based on file attributes and ignore extensions (even the compiled
    # in defaults of dircolors). #583814
    if [[ -n ${LS_COLORS:+set} ]] ; then
        use_color=true
    else
        # Delete it if it's empty as it's useless in that case.
        unset LS_COLORS
    fi
else
    # Some systems (e.g. BSD & embedded) don't typically come with
    # dircolors so we need to hardcode some terminals in here.
    case ${TERM} in
        [aEkx]term*|rxvt*|gnome*|konsole*|screen|tmux|cons25|*color) use_color=true;;
    esac
fi

shopt -s checkwinsize # Keep LINES and COLUMNS updated

# History control
HISTCONTROL=ignorespace:ignoredup   # Ignore duplicated lines or lines starting with space
HISTTIMEFORMAT='%F %T '             # Prepend commands with timestamp
HISTSIZE=10000 	                    # How many history lines to keep
HISTFILESIZE=100000                 # How many history lines to keep across sessions
shopt -s histappend                 # Append to the history file, don't overwrite it

# Command completion
shopt -s no_empty_cmd_completion    # Avoid waiting too much when hitting tab on empty input

# Prompt
PROMPT_DIRTRIM=3    # Trim longer directories

if $use_colors; then
    PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='\u@\h:\w\$'
fi

# Add git info
if type -P git; then
    if source $(git --exec-path)/git-sh-prompt || source /usr/share/git/git-prompt.sh; then
        GIT_PS1_SHOWDIRTYSTATE=1
        GIT_PS1_SHOWCONFLICTSTATE=1
        GIT_PS1_DESCRIBE_STYLE=branch
        GIT_PS1_STATESEPARATOR=''
        $use_color && GIT_PS1_SHOWCOLORHINTS=1
        PROMPT_COMMAND="__git_ps1 '${PS1/\\$ /}' '\$ '"
    fi
fi >/dev/null 2>&1

# Locale
for loc in en_US.utf8 C.utf8 C; do
    if locale -a | egrep -q "^$loc$"; then
        export LANG=$loc
        break
    fi
done
if locale -a | egrep -q '^pt_BR.utf8$'; then
    export LC_TIME=pt_BR.utf8
    export LC_NUMERIC=pt_BR.utf8
    export LC_COLLATE=pt_BR.utf8
fi

# Editors
export EDITOR=$(type -p vim) || EDITOR=vi
export VISUAL=$EDITOR

# Pager
export LESS="--quit-if-one-screen"
LESS+=" --no-init"            # Keep contents upon exit
LESS+=" --RAW-CONTROL-CHARS"  # Process ANSI ESC sequences
$use_colors && LESS+=" --use-color"
type -P lesspipe >/dev/null && LESSOPEN='|lesspipe %s'
type -P less >/dev/null && export PAGER=$(type -P less)
: ${PAGER:=$(type -P more)}

# Man pages
export MANPAGER="$PAGER -Dd+B -Dk+R -Ds+g -Du+c" # Colors!

# Compiler
$use_colors && GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# Wine
export WINEARCH=win32

# Aliases
alias config='git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME"'
if $use_colors; then
    alias grep='grep --color=auto'
    alias egrep='egrep --color=auto'
    alias diff='diff --color=auto'
    alias ls='ls --color=auto'
fi

# Load local configuration
[ -r ~/.bashrc.local ] && . ~/.bashrc.local
