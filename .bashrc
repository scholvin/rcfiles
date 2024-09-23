# aws: ~/env

# big reorg, 2019-Sep
# another big reorg, 2024-Jul
if [ ! -t 0 ]  # if we are not interactive, we're out of here
then
    return 
fi

echo configuring interactive bash for $OSTYPE

# hashing: often broken, never important
set +h
set -o emacs

# these only make sense interactively
export HISTSIZE=100000
export HISTFILESIZE=100000
export HISTCONTROL="erasedups:ignoreboth"
export PAGER=less
export LESS=-eR
export EDITOR=vi
export LSCMD=/bin/ls
export LESSBINFMT="*u<%02X>"
declare -g LAST_STATUS=1 # global var?

black='\e[30;1m'
red='\e[31;1m'
green='\e[32;1m'
yellow='\e[33;1m'
blue='\e[34;1m'
magenta='\e[35;1m'
cyan='\e[36;1m'
gray='\e[37;1m'
reset='\e[37;0m'
red_bg='\e[41;1m'
green_bg='\e[42;1m'
gray_bg='\e[47;1m'

# background color doesn't look great on mac terminal
com='' #'\e[48;5;237m'
ot=${red}
dt=${magenta}
us=${green}
at=${gray}
ho=${blue}
pa=${yellow}
        
if [ x"$WINDOWS_SHELL" != "x" ]; then
    export PRE_PS1="${red}${WINDOWS_SHELL}${reset} "
fi

# save the return status of the previous command, since we're
# going to do a bunch of other stuff inside $PS1 that will overwrite it
pcmd()
{
    LAST_STATUS=$?
    set_term_name
}
PROMPT_COMMAND=pcmd

happy_sad_emoji()
{
    if [ $LAST_STATUS -eq 0 ]; then
        echo -ne "✅"
    else
        echo -ne "❌"
    fi
}

export PS1="${PRE_PS1}"          # prefix
PS1+="\[${reset}\]\[${com}\]"    # set base color
PS1+="[ "                        # open bracket
PS1+="\[${dt}\]\t \d "           # add time and date
PS1+="\[${ot}\]"
PS1+="\$(other)"                 # is OTHER set? place to put other info
PS1+="\[${us}\]\u\[${dt}\]"      # username
PS1+="\[${at}\]@"                # @
PS1+="\[${ho}\]\h "              # host
PS1+="\[\$(git_color)\]"         # colors git status
PS1+="\$(git_branch)"            # prints git branch
PS1+="\[\$(ab_color)\]"          # colors ab initio status
PS1+="\$(ab_branch)"             # prints ab branch
PS1+="\[${pa}\]\w\[${reset}\]"   # working directory and reset text
PS1+=" ]\n"                      # close bracket and line break
PS1+="\! "                       # command number

# This little trick is based on a hack using ssh's SendEnv
# In the source system's .profile, export XMODIFIERS=1 if that terminal
# supports emoji (MacOS terminal, or Windows WSL terminal). You also need
# to set SendEnv XMODIFIERS in .ssh/config on the sending side. There may
# be a side effect here in some literal X11 terminals but who knows.
#
# also, more TODO here to get spacing right 
# https://stackoverflow.com/questions/7112774/how-to-escape-unicode-characters-in-bash-prompt-correctly
# note: CURRENTLY BROKEN FOR EMOJI
if [ "$XMODIFIERS" == "1" ]; then
    # THIS WORKS! now make it dynamic based on LAST_STATUS
    # PS1+='\['"`tput sc`"'\]  \['"`tput rc`"'✅\] '
    # THIS WORKS TOO
    # PS1+="\["$(tput sc)"\]  \["$(tput rc)"✅\] "
    # this is *very* close, may be bumping into shell bugs on ^R searches
    PS1+="\["$(tput sc)"\]  \["$(tput rc)
    PS1+="\$(happy_sad_emoji)\] "
else
    PS1+="\[\$(happy_sad_color)\]"
    PS1+="\$(happy_sad_chars)"
fi
PS1+="\[${reset}\] "

PS1+="$ "                        # closing $

#unset black green cyan yellow blue red magenta gray reset red_bg
#unset com dt us at ho pa

export PS2='more> '

happy_sad_color()
{
    red_bg='\e[41;1m'
    green_bg='\e[42;1m'
    if [ $LAST_STATUS -eq 0 ]; then
        echo -ne $green_bg
    else
        echo -ne $red_bg
    fi
}

happy_sad_chars()
{
    if [ $LAST_STATUS -eq 0 ]; then
        echo -ne ":)"
    else
        echo -ne ":("
    fi 
}

# let's update the title bar in the terminal, if we can
function set_term_name()
if [ "$TERM" != "linux" ]; then
    if [ "$1" != "" ]; then
        echo -ne "\033]0;$1\007"
    else
        echo -ne "\033]0;${USER}@${HOSTNAME}\007"
    fi
fi

# show the time incrementing
function ticker
{
    while [ /bin/true ]; do
        echo -n "$(date) "
        sleep 1
        echo -ne '\r'
    done
}

# convert time_t's to something we can read
function tt
{
    if [ $# -eq 0 ]; then
        echo "usage: tt time_t [time_t time_t ...]"
        return
    fi
    while (($#)); do
        echo -n "$1 "
        if [[ "$OSTYPE" =~ darwin ]]; then
            date -r $1
        else
            date -d@$1
        fi
        shift
    done
}

function up
{
    if [ $# -eq 0 ]; then
        echo "usage: up num"
        return
    fi
    local dir=""
    for ((i = 0 ; i < $1 ; i++)); do
        dir="../${dir}"
    done
    echo ${dir}
    cd ${dir}
}

function check_and_append_to_pathvar()
{
    # $1 is the candidate dir to add
    # $2 is the name of the environment variable
    if [[ ! -d $1 ]]; then
        # this directory doesn't exist
        return
    fi
    if [[ $(eval echo \$$2) =~ $1 ]]; then
        # this directory is already on this path
        return
    fi
    if [ -z "$(eval echo \$$2)" ]; then
        # the var is empty; start with just this
        export $2=$1
    else
        # append
        export $2=$(eval echo \$$2):$1
    fi
}

function check_and_prepend_to_pathvar()
{
    # $1 is the candidate dir to add
    # $2 is the name of the environment variable
    if [[ ! -d $1 ]]; then
        # this directory doesn't exist
        return
    fi
    if [[ $(eval echo \$$2) =~ $1 ]]; then
        # this directory is already on this path
        return
    fi
    if [ -z "$(eval echo \$$2)" ]; then
        # the var is empty; start with just this
        export $2=$1
    else
        # append
        export $2=$1:$(eval echo \$$2)
    fi
}

function print_pathvar()
{
    echo "$1="
    eval echo \$$1 | awk -F: '{for(i=1;i<=NF;i++){printf "    %s\n", $i}}'
}

function other()
{
    if [ -n "$OTHER" ]; then
        echo -e "$OTHER "
    fi
}

# next two are from https://coderwall.com/p/pn8f0g/show-your-git-status-and-branch-in-color-at-the-command-prompt
function git_branch
{
    local git_status="$(git status 2> /dev/null)"
    local on_branch="On branch ([^${IFS}]*)"
    local on_commit="HEAD detached at ([^${IFS}]*)"
    local git_sym='\U0001F709'

    if [[ $git_status =~ $on_branch ]]; then
        local branch=${BASH_REMATCH[1]}
        echo -e "(${git_sym} ${branch}) "
    elif [[ $git_status =~ $on_commit ]]; then
        local commit=${BASH_REMATCH[1]}
        echo -e "(${git_sym} ${commit}) "
    fi
}

function git_color
{
    # simplified - is this dirty or not?
    # because what do I know about commits ahead and such anyway
    # btw - mac wc(1) has extra spaces in output
    local git_status="$(git status --porcelain 2> /dev/null | wc -l | tr -d ' ')"
    local red='\e[31;1m'
    local green='\e[32;1m'

    if [[ $git_status == "0" ]]; then
        echo -e ${green}
    else
        echo -e ${red}
    fi
}

function ab_color
{
    # only if we're at work
    if [ -d /ab ]; then
        local red='\e[31;1m'
        echo -e ${red}
    fi
}
        
function ab_branch
{
    # only if we're at work
    #if [ -d /ab -a -x $AB_HOME/bin/m_env ]; then
    command -v m_env > /dev/null 2>&1
    if [[ $? == 0 ]]; then
        root=$(m_env -terse AB_AIR_ROOT | awk '{if ($2 == "*") print $3;}')
        out=''
        if   [[ "$root" =~ "Banamex" ]]; then out=Banamex
        elif [[ "$root" =~ "FedEx" ]];   then out=FedEx
        elif [[ "$root" =~ "barclays" ]]; then out=Barx
        fi
        if [ -n "$out" ]; then
            branch=$(m_env -terse AB_AIR_BRANCH | awk '{if (NF == 2) print $2; else print $3}')
            echo -e "($out:$branch) "
        fi
    fi
}

# this is dodgy, be careful
function fix_history
{
    # https://unix.stackexchange.com/questions/48713/how-can-i-remove-duplicates-in-my-bash-history-preserving-order
    awk '!x[$0]++' ~/.bash_history > /tmp/bash_history.clean
    cp ~/.bash_history ~/.bash_history.bak
    history -c
    cp /tmp/bash_history.clean ~/.bash_history
    history -r
}

case $OSTYPE in
    *linux*)
        a='di=36:ln=35:so=32:bd=37;44:cd=30;46:ex=31:or=48;5;232;38;5;9:'
        b='mi=05;48;5;232;38;5;15:su=48;5;196;38;5;15:sg=48;5;11;38;5;16:'
        c='tw=48;5;10;38;5;16:ow=48;5;10;38;5;21:'
        d='st=48;5;21;38;5;15:pi=40;38;5;11:do=38;5;5:'
        if [ "${BASH_VERSINFO[0]}" == "4" ]
        then
            # WTF was I doing here?
            e=''
        else
            e=''
        fi

        export LS_COLORS=$a$b$c$d$e
        unset a b c d e
        export LSARG='--color=auto'
        # better directory navigation
        if [ "${BASH_VERSINFO[0]}" == "4" ]  # TODO make this >= 4
        then
            # Prepend cd to directory names automatically
            shopt -s autocd
            # Correct spelling errors during tab-completion
            shopt -s dirspell
        fi
        # Correct spelling errors in arguments supplied to cd
        shopt -s cdspell
        # check window size often
        shopt -s checkwinsize
        ;;
    *darwin*)
        export LSCOLORS=gxfxcxdxbxheaghbadacec
        export CLICOLOR=1
        alias top="top -F -R -o cpu"
        ;;
    *freebsd*)
        export LSCOLORS=gxfxcxdxbxheaghbadacec
        export CLICOLOR=1
        ;;
esac

ulimit -c unlimited

# aliases for all environments
alias ls="$LSCMD $LSARG"
alias la="$LSCMD $LSARG -a"
alias ll="$LSCMD $LSARG -FLgsA"
        
alias df='df -k'
alias du='du -k'
alias f='finger'
alias md=mkdir
alias rd=rmdir
alias gunzip='gzip -d'
alias gzcat='zcat'

alias ci=vi

alias grep='grep --color=auto --directories=skip'
alias egrep='egrep --color=auto --directories=skip'
alias sqlite=sqlite3

alias sudo="PS1='\[\e[0;31m\]\u@\h:\w\[\e[0m\]\\$ ' sudo "

# lastly, don't forget input bindings
if [ -f $HOME/.inputrc ] ; then
    bind -f $HOME/.inputrc
fi

# better tab completion
# Perform file completion in a case insensitive fashion
bind "set completion-ignore-case on"
# Treat hyphens and underscores as equivalent
bind "set completion-map-case on"
# Display matches for ambiguous patterns at first tab press
bind "set show-all-if-ambiguous on"

if [ -f $HOME/.local.bashrc ]; then
    source $HOME/.local.bashrc
fi

set_term_name
